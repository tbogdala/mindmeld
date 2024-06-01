import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:format/format.dart';

import 'package:file_picker/file_picker.dart';
import 'package:woolydart/woolydart.dart';

import 'app.dart';

void main() {
  runApp(const App());
}

/*

class MaidLlmApp extends StatefulWidget {
  const MaidLlmApp({super.key});

  @override
  State<MaidLlmApp> createState() => _MaidLlmAppState();
}

class _MaidLlmAppState extends State<MaidLlmApp> {
  //List<ChatNode> messages = [];
  String modelPath = "";

  Future<String> loadModel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
          dialogTitle: "Load Model File",
          type: FileType.any,
          allowMultiple: false,
          allowCompression: false);

      File file;
      if (result != null && result.files.isNotEmpty) {
        file = File(result.files.single.path!);
      } else {
        throw Exception("File is null");
      }
      log("Chosen file is: $file");

      // android
      // const dylibPath = "libllama.so"; //android
      // final lib = woolydart(DynamicLibrary.open(dylibPath));
      final lib = woolydart(DynamicLibrary.process());
      var emptyString = "".toNativeUtf8() as Pointer<Char>;
      //log("Library loaded through DynamicLibrary: $dylibPath");

      setState(() {
        modelPath = 'Lib loaded; loding model...'; //file.path;
      });

      var llamaModelPath = result.files.single.path!.toNativeUtf8();
      log("Attempting to load model...");
      var loadedModel = lib.wooly_load_model(
          llamaModelPath as Pointer<Char>,
          1024, // ctx
          42, // seed
          true, // mlock
          false, // mmap
          false, // embeddings
          100, // gpu layers
          8, // batch
          0, // maingpu
          emptyString, //tensorsplit
          0.0, // rope freq
          0.0); // rope scale
      log("Woolydart: wooly_load_model() returned.");

      var prompt = "This is a joke: \n".toNativeUtf8();
      var seed = 42;
      var threads = 1;
      var tokens = 16;
      var topK = 40;
      var topP = 1.0;
      var minP = 0.08;
      var temp = 1.1;
      var repeatPenalty = 1.1;
      var repeatLastN = 64;
      var ignoreEos = true;
      var nBatch = 128;
      var nKeep = 128;
      var antiprompt = "".toNativeUtf8();
      var antipromptCount = 0;
      var tfsZ = 1.0;
      var typicalP = 1.0;
      var frequencyPenalty = 0.0;
      var presencePenalty = 0.0;
      var mirostat = 0;
      var mirostatEta = 0.1;
      var mirostatTau = 5.0;
      var penalizeNl = false;
      var logitBias = "".toNativeUtf8();
      var sessionFile = "".toNativeUtf8();
      var promptCacheInMemory = false;
      var mlock = true;
      var mmap = false;
      var maingpu = 0;
      var tensorsplit = "".toNativeUtf8();
      var filePromptCacheRo = false;
      var ropeFreqBase = 0.0;
      var ropeFreqScale = 0.0;
      var grammar = "".toNativeUtf8();

      var params = lib.wooly_allocate_params(
          prompt as Pointer<Char>,
          seed,
          threads,
          tokens,
          topK,
          topP,
          minP,
          temp,
          repeatPenalty,
          repeatLastN,
          ignoreEos,
          nBatch,
          nKeep,
          antiprompt as Pointer<Pointer<Char>>,
          antipromptCount,
          tfsZ,
          typicalP,
          frequencyPenalty,
          presencePenalty,
          mirostat,
          mirostatEta,
          mirostatTau,
          penalizeNl,
          logitBias as Pointer<Char>,
          sessionFile as Pointer<Char>,
          promptCacheInMemory,
          mlock,
          mmap,
          maingpu,
          tensorsplit as Pointer<Char>,
          filePromptCacheRo,
          ropeFreqBase,
          ropeFreqScale,
          grammar as Pointer<Char>);
      log("Woolydart: allocated params.");

      // allocate the buffer for the predicted text.
      final outputText = calloc.allocate((tokens + 1) * 4) as Pointer<Char>;
      log("Woolydart: allocated result buffer.");
      setState(() {
        modelPath = 'Model loaded; Predicting...'; //file.path;
      });

      var predictResult = lib.wooly_predict(params, loadedModel.ctx,
          loadedModel.model, false, outputText, nullptr);

      log("Woolydart: successlful predict, maybe?");
      final outputString = (outputText as Pointer<Utf8>).toDartString();
      log('Generated text:\n$outputString');

      log(format(
          '\nTiming Data: {} tokens total in {:.2} ms ; {:.2} T/s\n',
          predictResult.n_eval,
          (predictResult.t_end_ms - predictResult.t_start_ms),
          1e3 /
              (predictResult.t_end_ms - predictResult.t_start_ms) *
              predictResult.n_eval));

      setState(() {
        modelPath = format(
            '{:.2} T/s: {}',
            1e3 /
                (predictResult.t_end_ms - predictResult.t_start_ms) *
                predictResult.n_eval,
            outputString); //file.path;
      });

      malloc.free(llamaModelPath);
      malloc.free(emptyString);
    } catch (e) {
      var errormsg = e.toString();
      modelPath = errormsg;
      log("Caught exception trying to load model: $errormsg");
      return e.toString();
    }

    return "Model Successfully Loaded";
  }

  // this will load the llamam model
  //Llama.libraryPath = "../llama_cpp_dart/src/lib/libllama.dylib";
  //var llamar = Llama(file.path);

  //const dylibPath = "src/llama.cpp/build/libllama.dylib"; //mac
  // const dylibPath = "src/llama.cpp/build-android/libllama.so"; //android
  // final lib = woolydart(DynamicLibrary.open(dylibPath));
  // var emptyString = "".toNativeUtf8();

  // var loadedModel = lib.wooly_load_model(
  //     file.path as Pointer<Char>,
  //     2048, // ctx
  //     42, // seed
  //     false, // mlock
  //     true, // mmap
  //     false, // embeddings
  //     0, // gpu layers
  //     8, // batch
  //     0, // maingpu
  //     emptyString as Pointer<Char>, //tensorsplit
  //     0.0, // rope freq
  //     0.0); // rope scale

  @override
  void initState() {
    super.initState();
  }

  Widget buildHomepage(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);

    return Scaffold(
      appBar: AppBar(
        title: Text(modelPath.isEmpty ? "No Model Loaded" : modelPath),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: FutureBuilder<String>(
                    future: loadModel(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Text(snapshot.data!);
                      } else {
                        return const CircularProgressIndicator();
                      }
                    }),
              ));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: const Column(
            children: [
              Text(
                'This calls a native function through FFI that is shipped as source in the package. '
                'The native code is built as part of the Flutter Runner build.',
                style: textStyle,
                textAlign: TextAlign.center,
              ),
              spacerSmall,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(builder: buildHomepage),
    );
  }
}
*/