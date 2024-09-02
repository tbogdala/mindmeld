import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import 'dart:ffi';
import 'package:path/path.dart' as p;
import 'package:woolydart/woolydart.dart';
import 'dart:developer';
import 'package:format/format.dart';

import 'chat_log.dart';
import 'config_models.dart';
import 'platform_and_theming.dart';

class PredictReplyResult {
  bool success;
  String message;
  double generationSpeedTPS;

  PredictReplyResult(this.success, this.message, this.generationSpeedTPS);
}

class PredictReplyRequest {
  String modelFilepath;
  ConfigModelSettings modelSettings;
  String promptString;
  List<String> antipromptStrings;
  ChatLogHyperparameters hyperparameters;

  PredictReplyRequest(this.modelFilepath, this.modelSettings, this.promptString,
      this.antipromptStrings, this.hyperparameters);
}

class CloseModelRequest {}

// TODO: Things that need impl: * change model, * close model
class PredictionWorker {
  late Isolate _workerIsolate;
  late ReceivePort _fromIsoPort;
  SendPort? _toIsoPort;
  Completer<void> _isoReady = Completer.sync();
  Completer<PredictReplyResult> _isoResponse = Completer();

  static Future<PredictionWorker> spawn() async {
    log('PredictionWorker: spawning...');
    PredictionWorker obj = PredictionWorker();
    obj._fromIsoPort = ReceivePort();
    obj._fromIsoPort.listen(obj._handleResponsesFromIsolate);
    obj._workerIsolate =
        await Isolate.spawn(_isolateWorker, obj._fromIsoPort.sendPort);
    return obj;
  }

  Future<void> closeModel() async {
    log('PredictionWorker: close model...');
    await _isoReady.future;
    _isoResponse = Completer();
    _toIsoPort!.send(CloseModelRequest());
  }

  void killWorker() {
    log('PredictionWorker: killing worker...');
    _workerIsolate.kill(priority: Isolate.immediate);
    _fromIsoPort.close();
    _toIsoPort = null;
    _isoReady = Completer.sync();
    _isoResponse = Completer();
  }

  Future<PredictReplyResult> predictText(PredictReplyRequest request) async {
    await _isoReady.future;
    _isoResponse = Completer();
    _toIsoPort!.send(request);
    return _isoResponse.future;
  }

  void _handleResponsesFromIsolate(dynamic message) {
    if (message is SendPort) {
      log('PredictionWorker: _handleResponseFromIsolate() got a ready notification');
      _toIsoPort = message;
      _isoReady.complete();
    } else if (message is PredictReplyResult) {
      log('PredictionWorker: _handleResponseFromIsolate() got a prediction reply');
      _isoResponse.complete(message);
    } else {
      log("PredictionWorker: _handleResponseFromIsolate() got an unknown message: $message");
    }
  }

  static void _isolateWorker(SendPort port) {
    LlamaModel? llamaModel;

    try {
      // send the communication's port back right away
      final workerReceivePort = ReceivePort();
      port.send(workerReceivePort.sendPort);

      // an empty string for iOS to use the current process instead of a library file.
      String lib = "";
      if (Platform.isAndroid) {
        lib = "libwoolycore.so";
      } else if (Platform.isLinux) {
        final woolycorePath = p.joinAll(
            ["packages", "woolydart", "src", "build-linux", "libwoolycore.so"]);
        if (File(woolycorePath).existsSync()) {
          lib = woolycorePath;
        } else {
          lib = "libwoolycore.so";
        }
      }
      log("PredictionWorker: Library loaded through DynamicLibrary.");
      llamaModel = LlamaModel(lib);

      workerReceivePort.listen((dynamic message) async {
        if (message is PredictReplyRequest) {
          final result = _predictReply(llamaModel!, message);
          port.send(result);
          log('PredictionWorker: Finished reply prediction request...');
        } else if (message is CloseModelRequest) {
          if (llamaModel!.isModelLoaded()) {
            log("PredictionWorker: Worker is closing the loaded model...");
            llamaModel.freeModel();
          }
        }
      });
    } catch (e) {
      var errormsg = e.toString();
      log("PredictionWorker: _isolateWorker caught exception: $errormsg");
      log("... closing model.");
      try {
        llamaModel?.freeModel();
      } finally {}
    }
  }

  static PredictReplyResult _predictReply(
      LlamaModel llamaModel, PredictReplyRequest args) {
    wooly_gpt_params? params;
    try {
      if (!llamaModel.isModelLoaded()) {
        final modelParams = llamaModel.getDefaultModelParams()
          ..n_gpu_layers = args.modelSettings.gpuLayers
          ..use_mmap = isRunningOnDesktop() ? true : false;
        final contextParams = llamaModel.getDefaultContextParams()
          ..seed = args.hyperparameters.seed
          ..n_threads = args.modelSettings.threadCount ?? -1
          ..flash_attn = true
          ..n_ctx = args.modelSettings.contextSize ?? 2048;

        log("PredictionWorker: Attempting to load model: ${args.modelFilepath}");

        // we make the upstream llamacpp code 'chatty' in the log for debug builds
        final bool loadedResult = llamaModel.loadModel(
            args.modelFilepath, modelParams, contextParams, !kDebugMode);
        if (loadedResult == false) {
          return PredictReplyResult(
              false, '<Error: Failed to load the GGUF model.>', 0.0);
        }
      }

      params = llamaModel.getTextGenParams()
        ..seed = args.hyperparameters.seed
        ..n_threads = args.modelSettings.threadCount ?? 1
        ..n_predict = args.hyperparameters.tokens
        ..top_k = args.hyperparameters.topK
        ..top_p = args.hyperparameters.topP
        ..min_p = args.hyperparameters.minP
        ..tfs_z = args.hyperparameters.tfsZ
        ..typical_p = args.hyperparameters.typicalP
        ..penalty_repeat = args.hyperparameters.repeatPenalty
        ..penalty_last_n = args.hyperparameters.repeatLastN
        ..ignore_eos = false
        ..flash_attn = true
        ..prompt_cache_all = true
        ..n_batch = args.modelSettings.batchSize ?? 128;
      params.setPrompt(args.promptString);
      params.setAntiprompts(args.antipromptStrings);
      log('PredictionWorker: A total of ${args.antipromptStrings.length} antiprompt strings: ${args.antipromptStrings.join(",")}');

      final (predictResult, outputString) =
          llamaModel.predictText(params, nullptr);
      if (predictResult.result != 0) {
        return PredictReplyResult(
            false,
            '<Error: LlamaModel.predictText() returned ${predictResult.result}>',
            0.0);
      }
      var generationSpeed = 1e3 /
          (predictResult.t_end_ms - predictResult.t_start_ms) *
          predictResult.n_eval;

      log('Generated text:\n$outputString');
      log(format(
          '\nTiming Data: {} tokens total in {:.2f} ms ({:.2f} T/s) ; {} prompt tokens in {:.2f} ms ({:.2f} T/s)\n\n',
          predictResult.n_eval,
          (predictResult.t_end_ms - predictResult.t_start_ms),
          1e3 /
              (predictResult.t_end_ms - predictResult.t_start_ms) *
              predictResult.n_eval,
          predictResult.n_p_eval,
          predictResult.t_p_eval_ms,
          1e3 / predictResult.t_p_eval_ms * predictResult.n_p_eval));

      return PredictReplyResult((outputString != null ? true : false),
          outputString ?? "<Error: No response generated.>", generationSpeed);
    } catch (e) {
      var errormsg = e.toString();
      log("PredictionWorker: Caught exception trying to predict reply: $errormsg");
      return PredictReplyResult(false, '<Error: $errormsg>', 0.0);
    } finally {
      params?.dispose();
    }
  }
}
