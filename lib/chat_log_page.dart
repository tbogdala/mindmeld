import 'dart:isolate';

import 'package:flutter/material.dart';

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:mindmeld/configure_chat_log_page.dart';
import 'package:woolydart/woolydart.dart';
import 'dart:developer';
import 'package:format/format.dart';

import 'chat_log.dart';

class ChatLogPage extends StatefulWidget {
  final ChatLog chatLog;

  const ChatLogPage({super.key, required this.chatLog});

  @override
  State<ChatLogPage> createState() => _ChatLogPageState();
}

class _ChatLogPageState extends State<ChatLogPage>
    with TickerProviderStateMixin {
  final newMessgeController = TextEditingController();

  late AnimationController circularProgresAnimController;
  bool messageGenerationInProgress = false;

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

  Color getMessageDecorationColor(BuildContext context, bool forAIMessage) {
    if (MediaQuery.of(context).platformBrightness == Brightness.dark) {
      return (forAIMessage ? Colors.grey.shade800 : Colors.blue.shade800);
    } else {
      return (forAIMessage ? Colors.grey.shade200 : Colors.blue.shade200);
    }
  }

  Color getPrimaryDecorationColor(BuildContext context) {
    if (MediaQuery.of(context).platformBrightness == Brightness.dark) {
      return Colors.blue.shade800;
    } else {
      return Colors.blue.shade200;
    }
  }

  String formatDurationString(int differenceInSeconds) {
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
                      log("Pressed Edit button");
                      Navigator.pop(context);
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.redo),
                    label: Text("Regenerate Message",
                        style: Theme.of(context).textTheme.titleLarge),
                    onPressed: () {
                      log("Pressed Regenerate button");
                      Navigator.pop(context);
                    },
                  ),
                ],
              ));
        });
  }

  Widget buildMessageList(BuildContext context) {
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
        final timeDiffString = formatDurationString(msgTimeDiff.inSeconds);
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
                        borderRadius: BorderRadius.circular(20),
                        color:
                            getMessageDecorationColor(context, !msg.humanSent),
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

  Widget buildTextEntry(BuildContext context) {
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
              FloatingActionButton(
                onPressed: () async {
                  final newMsg = newMessgeController.text;
                  if (newMsg.isNotEmpty) {
                    // update the UI with the new chatlog message
                    setState(() {
                      newMessgeController.clear();
                      widget.chatLog.messages.add(ChatLogMessage(
                          widget.chatLog.humanName, newMsg, true, null));
                      messageGenerationInProgress = true;
                      circularProgresAnimController.repeat(reverse: true);
                    });

                    // build the prompt to send off tot he ai
                    const int tokenBudget = 2048; //TODO: unhardcode this
                    final promptConfig =
                        widget.chatLog.modelPromptStyle.getPromptConfig();
                    final prompt = widget.chatLog.buildPrompt(tokenBudget);
                    log("Prompt Built:");
                    log(prompt);

                    // run the text inference in an isolate
                    var receivePort = ReceivePort();
                    await Isolate.spawn(predictReply, [
                      receivePort.sendPort,
                      widget.chatLog.modelFilepath,
                      prompt,
                      promptConfig.stopPhrases
                    ]);
                    var predictedOutput =
                        await receivePort.first as PredictReplyResult;
                    log("in the end we got $predictedOutput");

                    for (final anti in promptConfig.stopPhrases) {
                      if (predictedOutput.message.endsWith(anti)) {
                        predictedOutput.message = predictedOutput.message
                            .substring(
                                0, predictedOutput.message.length - anti.length)
                            .trim();
                        break;
                      }
                    }

                    setState(() {
                      widget.chatLog.messages.add(ChatLogMessage(
                          widget.chatLog.aiName,
                          predictedOutput.message.trim(),
                          false,
                          predictedOutput.generationSpeedTPS));
                      widget.chatLog
                          .saveToFile()
                          .then((_) => messageGenerationInProgress = false);
                      circularProgresAnimController.reset();
                      circularProgresAnimController.stop();
                    });
                  }
                },
                backgroundColor: getPrimaryDecorationColor(context),
                child: const Icon(Icons.reply, size: 18),
              )
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
            Expanded(child: buildMessageList(context)),
            if (messageGenerationInProgress)
              CircularProgressIndicator(
                value: circularProgresAnimController.value,
                semanticsLabel: 'generating reply for AI',
              ),
            buildTextEntry(context),
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
void predictReply(List<dynamic> args) {
  var sendPort = args[0] as SendPort;
  try {
    const dylibPath = "libllama.so"; //android
    final lib = woolydart(DynamicLibrary.open(dylibPath));
    var emptyString = "".toNativeUtf8() as Pointer<Char>;
    log("Library loaded through DynamicLibrary: $dylibPath");

    var modelFilepath = args[1] as String;
    log("Attempting to load model: $modelFilepath");
    var nativeModelFilepath = modelFilepath.toNativeUtf8();
    var loadedModel = lib.wooly_load_model(
        nativeModelFilepath as Pointer<Char>,
        1024, // ctx
        -1, // seed
        true, // mlock
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
    var seed = -1;
    var threads = 1;
    var tokens = 128;
    var topK = 40;
    var topP = 1.0;
    var minP = 0.08;
    var temp = 1.1;
    var repeatPenalty = 1.1;
    var repeatLastN = 64;
    var ignoreEos = false;
    var nBatch = 128;
    var nKeep = 128;
    var antiprompt = emptyString as Pointer<Pointer<Char>>;
    var antipromptCount = 0; //antipromptStrings.length;
    var tfsZ = 1.0;
    var typicalP = 1.0;
    var frequencyPenalty = 0.0;
    var presencePenalty = 0.0;
    var mirostat = 0;
    var mirostatEta = 0.1;
    var mirostatTau = 5.0;
    var penalizeNl = true; // turning penalize newline on!
    var logitBias = emptyString;
    var sessionFile = emptyString;
    var promptCacheInMemory = false;
    var mlock = true;
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
      }

      antiprompt = antiPointers;
      antipromptCount = antipromptStrings.length;
    }

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

    malloc.free(nativeModelFilepath);
    malloc.free(emptyString);
    malloc.free(nativePrompt);
    malloc.free(outputText);

    Isolate.exit(sendPort, PredictReplyResult(outputString, generationSpeed));
  } catch (e) {
    var errormsg = e.toString();
    log("Caught exception trying to load model: $errormsg");
    Isolate.exit(sendPort, 'exception caught');
  }
}
