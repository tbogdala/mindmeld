import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mindmeld/platform_and_theming.dart';

import 'dart:ffi';
import 'package:mindmeld/configure_chat_log_page.dart';
import 'package:path/path.dart' as p;
import 'package:profile_photo/profile_photo.dart';
import 'package:woolydart/woolydart.dart';
import 'dart:developer';
import 'package:format/format.dart';

import 'chat_log.dart';
import 'config_models.dart';

class ChatLogPage extends StatefulWidget {
  final ChatLog chatLog;
  final ConfigModelFiles configModelFiles;

  // this callback is called when the inner ChatLogWidget has changed.
  final void Function() onChatLogWidgetChange;

  const ChatLogPage(
      {super.key,
      required this.chatLog,
      required this.configModelFiles,
      required this.onChatLogWidgetChange});

  @override
  State<ChatLogPage> createState() => _ChatLogPageState();
}

class _ChatLogPageState extends State<ChatLogPage> {
  late GlobalKey<ChatLogWidgetState> chatLogWidgetState;

  @override
  void initState() {
    super.initState();
    chatLogWidgetState = GlobalKey();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.chatLog.name), actions: [
          IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ConfigureChatLogPage(
                              isFullPage: true,
                              chatLog: widget.chatLog,
                              configModelFiles: widget.configModelFiles,
                            )));

                // once we've returned from the chatlog configuration page
                // save the log in case changes were made.
                await widget.chatLog.saveToFile();

                // same with the models configuration file
                await widget.configModelFiles.saveJsonToConfigFile();

                setState(() {
                  // now we dump the currently loaded model
                  chatLogWidgetState.currentState?.closePrognosticatorModel();

                  // let the parent context know something might have changed.
                  widget.onChatLogWidgetChange();
                });
              }),
        ]),
        body: Padding(
            padding: const EdgeInsets.all(16),
            child: ChatLogWidget(
              key: chatLogWidgetState,
              chatLog: widget.chatLog,
              configModelFiles: widget.configModelFiles,
              onChatLogChange: () {
                widget.onChatLogWidgetChange();
              },
            )));
  }
}

class ChatLogWidget extends StatefulWidget {
  final ChatLog chatLog;
  final ConfigModelFiles configModelFiles;

  // this callback is called when the chatlog has been changed by something
  // the widget does.
  final void Function() onChatLogChange;

  const ChatLogWidget(
      {super.key,
      required this.chatLog,
      required this.configModelFiles,
      required this.onChatLogChange});

  @override
  State<ChatLogWidget> createState() => ChatLogWidgetState();

  void test() {}
}

class ChatLogWidgetState extends State<ChatLogWidget>
    with TickerProviderStateMixin {
  final newMessgeController = TextEditingController();

  late AnimationController circularProgresAnimController;
  bool messageGenerationInProgress = false;
  bool closeModelAfterGeneration = false;

  // set this to non-null when a messages is getting edited
  ChatLogMessage? messageBeingEdited;

  PredictionWorker? prognosticator;

  @override
  void dispose() {
    newMessgeController.dispose();
    circularProgresAnimController.dispose();
    prognosticator?.killWorker();
    super.dispose();
  }

  @override
  void initState() {
    circularProgresAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
        setState(() {});
      });
    circularProgresAnimController.stop();

    PredictionWorker.spawn().then(
      (value) {
        log("PredictionWorker spawned.");
        prognosticator = value;
      },
    );

    super.initState();
  }

  String _formatDurationString(int differenceInSeconds) {
    // Handle cases for seconds, minutes, hours, and days
    if (differenceInSeconds < 60) {
      return "less than a minute ago";
    } else if (differenceInSeconds < 3600) {
      int minutes = differenceInSeconds ~/ 60;
      return "$minutes minutes ago";
    } else if (differenceInSeconds < 86400) {
      int hours = differenceInSeconds ~/ 3600;
      return "$hours hours ago";
    } else {
      int days = differenceInSeconds ~/ 86400;
      int remainingHours = (differenceInSeconds % 86400) ~/ 3600;
      if (remainingHours > 0) {
        return "$days days and $remainingHours hours ago";
      } else {
        return "$days days ago";
      }
    }
  }

  Future<void> closePrognosticatorModel() async {
    if (messageGenerationInProgress) {
      closeModelAfterGeneration = true;
      log('Will close model after prediction request is finished');
    } else {
      prognosticator?.closeModel();
    }
  }

  Future<void> _showErrorForMissingModel() async {
    return showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: const Text('Error'),
              content: const Text(
                  'No LLM model has been set up and therefore nothing can be generated from the AI. Please go to the chat configuration, select Model, and either select a valid model from the dropdown menu or import a new GGUF file.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'OK'),
                  child: const Text('OK'),
                ),
              ],
            ));
  }

  Future<void> _generateAIMessage(bool continueMsg) async {
    // get the model filepath for the selected model. right now this is a
    // relative path, so we have to combine it with our documents folder
    var currentModelConfig =
        widget.configModelFiles.modelFiles[widget.chatLog.modelName];
    if (currentModelConfig == null) {
      return await _showErrorForMissingModel();
    }

    var modelFilepath = (!p.isAbsolute(currentModelConfig.modelFilepath)
        ? p.join(await ConfigModelFiles.getModelsFolderpath(),
            currentModelConfig.modelFilepath)
        : currentModelConfig.modelFilepath);
    var existsMabye = await File(modelFilepath).exists();
    log("File for the model $modelFilepath exists: {$existsMabye}");

    // turn the busy flag and animation on
    setState(() {
      messageGenerationInProgress = true;
      closeModelAfterGeneration = false;
      circularProgresAnimController.repeat(reverse: true);
    });

    // store a reference to the chatlog used for generation so that
    // if the user switches the 'current' chatlog up while waiting
    // for generation, the message will still get added to this log.
    final targetChatlog = widget.chatLog;

    // build the prompt to send off to the ai
    int tokenBudget = (currentModelConfig.contextSize ?? 2048) -
        targetChatlog.hyperparmeters.tokens;
    final promptConfig = targetChatlog.modelPromptStyle.getPromptConfig();
    final prompt = targetChatlog.buildPrompt(tokenBudget, continueMsg);
    log("Prompt Built:");
    log(prompt);

    // add the human user's name to the stop phrases
    List<String> stopPhrases = List.from(promptConfig.stopPhrases);
    final humanChar = targetChatlog.getHumanCharacter();
    if (humanChar != null && humanChar.name.isNotEmpty) {
      stopPhrases.add('${humanChar.name}:');
      stopPhrases.add('### ${humanChar.name}');
    } else {
      stopPhrases.add('${ChatLog.defaultUserName}:');
    }

    // run the text inference in an isolate
    if (prognosticator == null) {
      log("prognosticator was not initialized yet, skipping _generateAIMessage...");
      return;
    }
    PredictReplyRequest request = PredictReplyRequest(modelFilepath,
        currentModelConfig, prompt, stopPhrases, targetChatlog.hyperparmeters);
    var predictedOutput = await prognosticator!.predictText(request);

    for (final anti in stopPhrases) {
      if (predictedOutput.message.endsWith(anti)) {
        predictedOutput.message = predictedOutput.message
            .substring(0, predictedOutput.message.length - anti.length)
            .trim();
        break;
      }
    }

    setState(() {
      if (!continueMsg) {
        targetChatlog.messages.add(ChatLogMessage(
            targetChatlog.getAICharacter()!.name,
            predictedOutput.message.trimLeft(),
            false,
            predictedOutput.generationSpeedTPS));
      } else {
        targetChatlog.messages.last.message += predictedOutput.message;
      }

      messageGenerationInProgress = false;
      circularProgresAnimController.reset();
      circularProgresAnimController.stop();
    });

    await targetChatlog.saveToFile();
    if (closeModelAfterGeneration) {
      await closePrognosticatorModel();
    }

    widget.onChatLogChange();
  }

  void _showModalLongPressMessageBottomSheet(
      BuildContext context, ChatLogMessage msg) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: Text("Delete Message",
                        style: Theme.of(context).textTheme.titleLarge),
                    onPressed: () {
                      setState(() {
                        widget.chatLog.messages.remove(msg);
                        widget.chatLog.saveToFile();
                      });
                      widget.onChatLogChange();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: Text("Edit Message",
                        style: Theme.of(context).textTheme.titleLarge),
                    onPressed: () {
                      setState(() {
                        messageBeingEdited = msg;
                        newMessgeController.text = msg.message;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  if (msg == widget.chatLog.messages.last &&
                      !messageGenerationInProgress &&
                      !msg.humanSent)
                    const SizedBox(height: 8),
                  if (msg == widget.chatLog.messages.last &&
                      !messageGenerationInProgress &&
                      !msg.humanSent)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.fast_forward),
                      label: Text("Continue Message",
                          style: Theme.of(context).textTheme.titleLarge),
                      onPressed: () {
                        Navigator.pop(context);

                        // run the AI text generation
                        _generateAIMessage(true);
                      },
                    ),
                  if (msg == widget.chatLog.messages.last &&
                      !messageGenerationInProgress &&
                      !msg.humanSent)
                    const SizedBox(height: 8),
                  if (msg == widget.chatLog.messages.last &&
                      !messageGenerationInProgress &&
                      !msg.humanSent)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.restart_alt),
                      label: Text("Regenerate Message",
                          style: Theme.of(context).textTheme.titleLarge),
                      onPressed: () async {
                        setState(() {
                          widget.chatLog.messages.removeLast();
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                        }

                        // run the AI text generation
                        await _generateAIMessage(false);
                      },
                    ),
                ],
              ));
        });
  }

  Widget _buildMessageList(BuildContext context) {
    // we do a double reversal - messages and list - so they come out in the
    // intended order but the listview starts at the bottom (most recent).
    final reverseMessages = widget.chatLog.messages.reversed;
    final now = DateTime.now();
    final humanCharacter = widget.chatLog.getHumanCharacter()!;
    final aiCharacter = widget.chatLog.getAICharacter()!;

    return ListView.builder(
      reverse: true,
      itemCount: widget.chatLog.messages.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final msg =
            reverseMessages.elementAt(index); // widget.chatLog.messages[index];
        final msgTimeDiff = now.difference(msg.messageCreatedAt);
        final timeDiffString = _formatDurationString(msgTimeDiff.inSeconds);
        final isHumanSent = msg.senderName == humanCharacter.name;

        return GestureDetector(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    (!isHumanSent
                        ? Container(
                            // different padding here is what pushes the chat bubbles to either side.
                            padding: (const EdgeInsets.only(
                                right: 16, top: 8, bottom: 8)),
                            child: FutureBuilder(
                                future: aiCharacter.getEffectiveProfilePic(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<ImageProvider<Object>>
                                        snapshot) {
                                  if (snapshot.hasData) {
                                    return ProfilePhoto(
                                        totalWidth: 64,
                                        outlineColor: Colors.transparent,
                                        color: Colors.transparent,
                                        image: snapshot.data);
                                  } else {
                                    return ProfilePhoto(
                                        totalWidth: 64,
                                        outlineColor: Colors.transparent,
                                        color: Colors.transparent);
                                  }
                                }),
                          )
                        : const SizedBox(
                            width: 1,
                          )),
                    Flexible(
                      child: Container(
                          decoration: BoxDecoration(
                            border: (messageBeingEdited != msg
                                ? null
                                : const Border(
                                    bottom: BorderSide(
                                        width: 4, color: Colors.grey),
                                    top: BorderSide(
                                        width: 4, color: Colors.grey),
                                    left: BorderSide(
                                        width: 4, color: Colors.grey),
                                    right: BorderSide(
                                        width: 4, color: Colors.grey))),
                            borderRadius: BorderRadius.circular(20),
                            color: getMessageDecorationColor(
                                context, !msg.humanSent),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Text(msg.message)),
                    ),
                    (isHumanSent
                        ? Container(
                            // different padding here is what pushes the chat bubbles to either side.
                            padding: (const EdgeInsets.only(
                                left: 16, top: 8, bottom: 8)),
                            child: FutureBuilder(
                                future: humanCharacter.getEffectiveProfilePic(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<ImageProvider<Object>>
                                        snapshot) {
                                  if (snapshot.hasData) {
                                    return ProfilePhoto(
                                        totalWidth: 64,
                                        color: Colors.transparent,
                                        outlineColor: Colors.transparent,
                                        image: snapshot.data);
                                  } else {
                                    return ProfilePhoto(
                                        totalWidth: 64,
                                        outlineColor: Colors.transparent,
                                        color: Colors.transparent);
                                  }
                                }),
                          )
                        : const SizedBox(
                            width: 1,
                          )),
                  ],
                ),
                (msg.generationSpeedTPS == null
                    ? Text(format('{}', timeDiffString))
                    : Text(format('{} ({:,.2n} T/s)', timeDiffString,
                        msg.generationSpeedTPS!))),
              ],
            ),
          ),
          onLongPress: () {
            _showModalLongPressMessageBottomSheet(context, msg);
          },
        );
      },
    );
  }

  Widget _buildTextEntry(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        padding: const EdgeInsets.all(10),
        width: double.infinity,
        child: Row(
          children: [
            Expanded(
                child: TextField(
              onSubmitted: (_) {
                _onMessageInputSend();
              },
              textInputAction: (isRunningOnDesktop()
                  ? TextInputAction.done
                  : TextInputAction.newline),
              controller: newMessgeController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: 'Write message...',
                border: InputBorder.none,
              ),
            )),
            if (!messageGenerationInProgress) const SizedBox(width: 16),
            if (!messageGenerationInProgress)
              GestureDetector(
                  child: FloatingActionButton(
                    onPressed: _onMessageInputSend,
                    backgroundColor: getPrimaryDecorationColor(context),
                    child: (messageBeingEdited == null
                        ? const Icon(Icons.reply, size: 18)
                        : const Icon(Icons.edit, size: 18)),
                  ),
                  onLongPress: () async {
                    // when a long press is detected we generate a new message from
                    // the AI, regardless of what's going on with the input state
                    // of the controls or anything else.
                    await _generateAIMessage(false);
                  }),
          ],
        ),
      ),
    );
  }

  // this function is meant to be called when the message being edited or composed
  // is ready to be 'sent' or processed in whatever way.
  void _onMessageInputSend() async {
    final newMsg = newMessgeController.text;

    if (messageBeingEdited != null) {
      // We're editing a message so simply update the message
      // and clear the editing 'flag'.
      setState(() {
        messageBeingEdited!.message = newMsg;
        messageBeingEdited = null;
        newMessgeController.clear();
      });
      await widget.chatLog.saveToFile();
    } else {
      // We're wanting to send a new message, so add it to
      // the log and start generating a new message.
      if (newMsg.isNotEmpty) {
        final chatLogMsg = ChatLogMessage(
            widget.chatLog.getHumanCharacter()!.name, newMsg, true, null);
        // update the UI with the new chatlog message
        setState(() {
          newMessgeController.clear();
          widget.chatLog.messages.add(chatLogMsg);
        });

        // send our message off to the AI for a reply
        await _generateAIMessage(false);
      }
    }

    widget.onChatLogChange();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: _buildMessageList(context)),
      if (messageGenerationInProgress)
        CircularProgressIndicator(
          value: circularProgresAnimController.value,
          semanticsLabel: 'generating reply for AI',
        ),
      _buildTextEntry(context),
    ]);
  }
}

// **********************************************************************

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
      final lib = Platform.isAndroid ? "libwoolycore.so" : "";
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
