import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:mindmeld/configure_chat_log_page.dart';
import 'package:path/path.dart';
import 'package:woolydart/woolydart.dart';
import 'dart:developer';
import 'package:format/format.dart';

import 'chat_log.dart';
import 'config_models.dart';

class ChatLogPage extends StatefulWidget {
  final ChatLog chatLog;
  final ConfigModelFiles configModelFiles;

  const ChatLogPage(
      {super.key, required this.chatLog, required this.configModelFiles});

  @override
  State<ChatLogPage> createState() => _ChatLogPageState();
}

class _ChatLogPageState extends State<ChatLogPage>
    with TickerProviderStateMixin {
  final newMessgeController = TextEditingController();

  late AnimationController circularProgresAnimController;
  bool messageGenerationInProgress = false;

  // set this to non-null when a messages is getting edditt
  ChatLogMessage? messageBeingEdited;

  @override
  void dispose() {
    newMessgeController.dispose();
    circularProgresAnimController.dispose();
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

    super.initState();
  }

  Color _getMessageDecorationColor(BuildContext context, bool forAIMessage) {
    if (MediaQuery.of(context).platformBrightness == Brightness.dark) {
      return (forAIMessage ? Colors.grey.shade800 : Colors.blue.shade800);
    } else {
      return (forAIMessage ? Colors.grey.shade200 : Colors.blue.shade200);
    }
  }

  Color _getPrimaryDecorationColor(BuildContext context) {
    if (MediaQuery.of(context).platformBrightness == Brightness.dark) {
      return Colors.blue.shade800;
    } else {
      return Colors.blue.shade200;
    }
  }

  String _formatDurationString(int differenceInSeconds) {
    // Handle cases for seconds, minutes, hours
    if (differenceInSeconds < 60) {
      return "less than a minute ago";
    } else if (differenceInSeconds < 3600) {
      int minutes = differenceInSeconds ~/ 60;
      return "$minutes minutes ago";
    } else {
      int hours = differenceInSeconds ~/ 3600;
      return "$hours hours ago";
    }
  }

  Future<void> _generateAIMessage(bool continueMsg) async {
    setState(() {
      messageGenerationInProgress = true;
      circularProgresAnimController.repeat(reverse: true);
    });

    // get the model filepath for the selected model. right now this is a
    // relative path, so we have to combine it with our documents folder
    var modelFilepath = join(await ConfigModelFiles.getModelsFolderpath(),
        widget.configModelFiles.modelFiles[widget.chatLog.modelName]);

    // build the prompt to send off to the ai
    const int tokenBudget = 2048; //TODO: unhardcode this
    final promptConfig = widget.chatLog.modelPromptStyle.getPromptConfig();
    final prompt = widget.chatLog.buildPrompt(tokenBudget, continueMsg);
    log("Prompt Built:");
    log(prompt);

    // add the human user's name to the stop phrases
    List<String> stopPhrases = List.from(promptConfig.stopPhrases);
    stopPhrases.add('${widget.chatLog.humanName}:');

    // run the text inference in an isolate
    var receivePort = ReceivePort();
    await Isolate.spawn(predictReply, [
      receivePort.sendPort,
      modelFilepath,
      prompt,
      stopPhrases,
      widget.chatLog.hyperparmeters,
    ]);
    var predictedOutput = await receivePort.first as PredictReplyResult;

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
        widget.chatLog.messages.add(ChatLogMessage(
            widget.chatLog.aiName,
            predictedOutput.message.trimLeft(),
            false,
            predictedOutput.generationSpeedTPS));
      } else {
        widget.chatLog.messages.last.message += predictedOutput.message;
      }

      widget.chatLog.saveToFile().then((_) {
        messageGenerationInProgress = false;
        circularProgresAnimController.reset();
        circularProgresAnimController.stop();
      });
    });
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
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: Text("Delete Message",
                        style: Theme.of(context).textTheme.titleLarge),
                    onPressed: () {
                      setState(() {
                        widget.chatLog.messages.remove(msg);
                        widget.chatLog.saveToFile();
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ElevatedButton.icon(
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
                  if (msg == widget.chatLog.messages.last && !msg.humanSent)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.fast_forward),
                      label: Text("Continue Message",
                          style: Theme.of(context).textTheme.titleLarge),
                      onPressed: () {
                        // run the AI text generation
                        _generateAIMessage(true);

                        Navigator.pop(context);
                      },
                    ),
                  if (msg == widget.chatLog.messages.last)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.restart_alt),
                      label: Text("Regenerate Message",
                          style: Theme.of(context).textTheme.titleLarge),
                      onPressed: () async {
                        setState(() {
                          widget.chatLog.messages.removeLast();
                        });

                        // run the AI text generation
                        _generateAIMessage(false);

                        Navigator.pop(context);
                      },
                    ),
                ],
              ));
        });
  }

  Widget _buildMessageList(BuildContext context) {
    // we do a double reversal - messages and list - so they come out in the
    // intended order but the listview starts at the bottom (most recent).
    var reverseMessages = widget.chatLog.messages.reversed;
    var now = DateTime.now();

    return ListView.builder(
      reverse: true,
      itemCount: widget.chatLog.messages.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final msg =
            reverseMessages.elementAt(index); // widget.chatLog.messages[index];
        final msgTimeDiff = now.difference(msg.messageCreatedAt);
        final timeDiffString = _formatDurationString(msgTimeDiff.inSeconds);
        return GestureDetector(
          child: Container(
              // different padding here is what pushes the chat bubbles to either side.
              padding: (msg.humanSent
                  ? const EdgeInsets.only(left: 32, top: 8, bottom: 8)
                  : const EdgeInsets.only(right: 32, top: 8, bottom: 8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                      decoration: BoxDecoration(
                        border: (messageBeingEdited != msg
                            ? null
                            : const Border(
                                bottom:
                                    BorderSide(width: 4, color: Colors.grey),
                                top: BorderSide(width: 4, color: Colors.grey),
                                left: BorderSide(width: 4, color: Colors.grey),
                                right:
                                    BorderSide(width: 4, color: Colors.grey))),
                        borderRadius: BorderRadius.circular(20),
                        color:
                            _getMessageDecorationColor(context, !msg.humanSent),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Text(msg.message)),
                  (msg.generationSpeedTPS == null
                      ? Text(format('{}', timeDiffString))
                      : Text(format('{} ({:,.2n} T/s)', timeDiffString,
                          msg.generationSpeedTPS!))),
                ],
              )),
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
                    onPressed: () async {
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
                              widget.chatLog.humanName, newMsg, true, null);
                          // update the UI with the new chatlog message
                          setState(() {
                            newMessgeController.clear();
                            widget.chatLog.messages.add(chatLogMsg);
                          });

                          // send our message off to the AI for a reply
                          await _generateAIMessage(false);
                        }
                      }
                    },
                    backgroundColor: _getPrimaryDecorationColor(context),
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
                            chatLog: widget.chatLog,
                          )));

              // once we've returned from the chatlog configuration page
              // save the log incase changes were made.
              await widget.chatLog.saveToFile();
            }),
      ]),
      body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Expanded(child: _buildMessageList(context)),
            if (messageGenerationInProgress)
              CircularProgressIndicator(
                value: circularProgresAnimController.value,
                semanticsLabel: 'generating reply for AI',
              ),
            _buildTextEntry(context),
          ])),
    );
  }
}

// **********************************************************************

class PredictReplyResult {
  String message;
  double generationSpeedTPS;

  PredictReplyResult(this.message, this.generationSpeedTPS);
}

// predictReply parameters:
//  [0] sendPort
//  [1] modelFilepath
//  [2] promptString
//  [3] antipromptStrings
//  [4] hyperparameters
void predictReply(List<dynamic> args) {
  var sendPort = args[0] as SendPort;
  try {
    final lib = Platform.isAndroid
        ? woolydart(DynamicLibrary.open("libllama.so"))
        : //woolydart(DynamicLibrary.open("libllama"));
        woolydart(DynamicLibrary.process());
    log("Library loaded through DynamicLibrary.");

    var modelFilepath = args[1] as String;
    var nativeModelFilepath = modelFilepath.toNativeUtf8();
    var emptyString = "".toNativeUtf8() as Pointer<Char>;
    log("Attempting to load model: $modelFilepath");

    var hyperparams = args[4] as ChatLogHyperparameters;

    var loadedModel = lib.wooly_load_model(
        nativeModelFilepath as Pointer<Char>,
        0, // ctx size from the model
        hyperparams.seed, // seed
        false, // mlock
        true, // mmap
        false, // embeddings
        100, // gpu layers
        128, // batch
        0, // maingpu
        emptyString, //tensorsplit
        0.0, // rope freq
        0.0); // rope scale
    log("Woolydart: wooly_load_model() returned.");

    log("Allocating prompt string.");
    var prompt = args[2] as String;

    var nativePrompt = prompt.toNativeUtf8();
    var seed = hyperparams.seed;
    var threads = 4;
    var tokens = hyperparams.tokens;
    var topK = hyperparams.topK;
    var topP = hyperparams.topP;
    var minP = hyperparams.minP;
    var temp = hyperparams.temp;
    var repeatPenalty = hyperparams.repeatPenalty;
    var repeatLastN = hyperparams.repeatLastN;
    var ignoreEos = false;
    var nBatch = 128;
    var nKeep = 128;
    var antiprompt = emptyString as Pointer<Pointer<Char>>;
    var antipromptCount = 0; //antipromptStrings.length;
    var tfsZ = hyperparams.tfsZ;
    var typicalP = hyperparams.typicalP;
    var frequencyPenalty = hyperparams.frequencyPenalty;
    var presencePenalty = hyperparams.presencePenalty;
    var mirostat = hyperparams.mirostatType;
    var mirostatEta = hyperparams.mirostatEta;
    var mirostatTau = hyperparams.mirostatTau;
    var penalizeNl = false;
    var logitBias = emptyString;
    var sessionFile = emptyString;
    var promptCacheInMemory = false;
    var mlock = false;
    var mmap = true;
    var maingpu = 0;
    var tensorsplit = emptyString;
    var filePromptCacheRo = false;
    var ropeFreqBase = 0.0;
    var ropeFreqScale = 0.0;
    var grammar = emptyString;

    // if the last token in the prompt being generated is also an antiprompt string
    // that will result in an empty prediction
    var antipromptStrings = args[3] as List<String>;
    log('A total of ${antipromptStrings.length} antiprompt strings: ${antipromptStrings.join(",")}');

    // keep track of the native strings so we can deallocate them.
    List<Pointer<Char>> antipromptPointers = [];

    // okay now actually create the antiprompt native strings if we have them.
    if (antipromptStrings.isNotEmpty) {
      log("Making antiprompt strings native...");

      // allocate all the array of pointers.
      final Pointer<Pointer<Char>> antiPointers =
          calloc.allocate(antipromptStrings.length * sizeOf<Pointer<Char>>());

      // allocate each of the native strings
      for (int ai = 0; ai < antipromptStrings.length; ai++) {
        log("Allocating antipromtp #$ai");
        Pointer<Char> native =
            antipromptStrings[ai].toNativeUtf8() as Pointer<Char>;
        antiPointers[ai] = native;
        antipromptPointers.add(native);
      }

      antiprompt = antiPointers;
      antipromptCount = antipromptPointers.length;
    }

    log("Using a total of $antipromptCount antiprompts...");

    var params = lib.wooly_allocate_params(
        nativePrompt as Pointer<Char>,
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
        antiprompt,
        antipromptCount,
        tfsZ,
        typicalP,
        frequencyPenalty,
        presencePenalty,
        mirostat,
        mirostatEta,
        mirostatTau,
        penalizeNl,
        logitBias,
        sessionFile,
        promptCacheInMemory,
        mlock,
        mmap,
        maingpu,
        tensorsplit,
        filePromptCacheRo,
        ropeFreqBase,
        ropeFreqScale,
        grammar);
    log("Woolydart: allocated params.");

    // allocate the buffer for the predicted text.
    final outputText = calloc.allocate((tokens + 1) * 4) as Pointer<Char>;
    log("Woolydart: allocated result buffer; starting prediction");

    var predictResult = lib.wooly_predict(
        params, loadedModel.ctx, loadedModel.model, false, outputText, nullptr);

    log("Woolydart: successlful predict, maybe?");
    final outputString = (outputText as Pointer<Utf8>).toDartString();
    log('Generated text:\n$outputString');

    var generationSpeed = 1e3 /
        (predictResult.t_end_ms - predictResult.t_start_ms) *
        predictResult.n_eval;
    log(format(
        '\nTiming Data: {} tokens total in {:.2} ms ; {:.2} T/s\n',
        predictResult.n_eval,
        (predictResult.t_end_ms - predictResult.t_start_ms),
        generationSpeed));

    // free all the allocations made for the FFI calls
    malloc.free(nativeModelFilepath);
    malloc.free(emptyString);
    malloc.free(nativePrompt);
    malloc.free(outputText);
    if (antipromptPointers.isNotEmpty) {
      for (int ai = 0; ai < antipromptPointers.length; ai++) {
        malloc.free(antipromptPointers[ai]);
      }
      malloc.free(antiprompt);
    }

    // FIXME: this breaks on IOS simulator
    // for now, we free the model too
    lib.wooly_free_model(loadedModel.ctx, loadedModel.model);

    Isolate.exit(sendPort, PredictReplyResult(outputString, generationSpeed));
  } catch (e) {
    var errormsg = e.toString();
    log("Caught exception trying to load model: $errormsg");
    Isolate.exit(sendPort, 'exception caught');
  }
}
