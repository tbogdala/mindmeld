import 'dart:isolate';

import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
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

class _ChatLogPageState extends State<ChatLogPage> {
  final newMessgeController = TextEditingController();

  @override
  void dispose() {
    newMessgeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  Color getMessageDecorationColor(BuildContext context, bool forUserMessage) {
    if (MediaQuery.of(context).platformBrightness == Brightness.dark) {
      return (forUserMessage ? Colors.grey.shade800 : Colors.blue.shade800);
    } else {
      return (forUserMessage ? Colors.grey.shade200 : Colors.blue.shade200);
    }
  }

  Color getPrimaryDecorationColor(BuildContext context) {
    if (MediaQuery.of(context).platformBrightness == Brightness.dark) {
      return Colors.blue.shade800;
    } else {
      return Colors.blue.shade200;
    }
  }

  Widget buildMessageList(BuildContext context) {
    // we do a double reversal - messages and list - so they come out in the
    // intended order but the listview starts at the bottom (most recent).
    var reverseMessages = widget.chatLog.messages.reversed;
    return ListView.builder(
      reverse: true,
      itemCount: widget.chatLog.messages.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        var msg =
            reverseMessages.elementAt(index); // widget.chatLog.messages[index];
        return Container(
            padding: const EdgeInsets.all(16),
            child: Align(
                alignment: (msg.senderName == "AI"
                    ? Alignment.topLeft
                    : Alignment.topRight),
                child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: getMessageDecorationColor(
                          context, msg.senderName == "AI"),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Text(msg.message))));
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
            const SizedBox(width: 16),
            FloatingActionButton(
              onPressed: () async {
                final newMsg = newMessgeController.text;
                if (newMsg.isNotEmpty) {
                  setState(() {
                    newMessgeController.clear();
                    widget.chatLog.messages
                        .add(ChatLogMessage("Human", newMsg));
                  });

                  var receivePort = ReceivePort();
                  await Isolate.spawn(predictReply,
                      [receivePort.sendPort, widget.chatLog.modelFilepath]);
                  var predictedOutput = await receivePort.first;
                  log("in the end we got $predictedOutput");

                  setState(() {
                    widget.chatLog.messages
                        .add(ChatLogMessage("AI", predictedOutput as String));
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
      appBar: AppBar(
        title: Text(widget.chatLog.name),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Expanded(child: buildMessageList(context)),
            buildTextEntry(context),
          ])),
    );
  }
}

// **********************************************************************

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
        42, // seed
        false, // mlock
        false, // mmap
        false, // embeddings
        100, // gpu layers
        8, // batch
        0, // maingpu
        emptyString, //tensorsplit
        0.0, // rope freq
        0.0); // rope scale
    log("Woolydart: wooly_load_model() returned.");

    var prompt =
        "Instruct: Write a funny joke in the style of a text message.\nOutput: "
            .toNativeUtf8();
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
    var antiprompt = emptyString;
    var antipromptCount = 0;
    var tfsZ = 1.0;
    var typicalP = 1.0;
    var frequencyPenalty = 0.0;
    var presencePenalty = 0.0;
    var mirostat = 0;
    var mirostatEta = 0.1;
    var mirostatTau = 5.0;
    var penalizeNl = false;
    var logitBias = emptyString;
    var sessionFile = emptyString;
    var promptCacheInMemory = false;
    var mlock = true;
    var mmap = false;
    var maingpu = 0;
    var tensorsplit = emptyString;
    var filePromptCacheRo = false;
    var ropeFreqBase = 0.0;
    var ropeFreqScale = 0.0;
    var grammar = emptyString;

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

    log(format(
        '\nTiming Data: {} tokens total in {:.2} ms ; {:.2} T/s\n',
        predictResult.n_eval,
        (predictResult.t_end_ms - predictResult.t_start_ms),
        1e3 /
            (predictResult.t_end_ms - predictResult.t_start_ms) *
            predictResult.n_eval));

    malloc.free(nativeModelFilepath);
    malloc.free(emptyString);
    malloc.free(prompt);
    malloc.free(outputText);

    Isolate.exit(sendPort, outputString);
  } catch (e) {
    var errormsg = e.toString();
    log("Caught exception trying to load model: $errormsg");
    Isolate.exit(sendPort, 'exception caught');
  }
}
