import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:path/path.dart' as p;
import 'package:profile_photo/profile_photo.dart';
import 'dart:developer';
import 'package:format/format.dart';
import 'package:woolydart/woolydart.dart';

import 'chat_log.dart';
import 'config_models.dart';
import 'configure_chat_log_page.dart';
import 'edit_lorebooks_page.dart';
import 'lorebook.dart';
import 'platform_and_theming.dart';
import 'prediction_worker.dart';

class ChatLogPage extends StatefulWidget {
  final ChatLog chatLog;
  final ConfigModelFiles configModelFiles;
  final List<Lorebook> lorebooks;

  // this callback is called when the inner ChatLogWidget has changed.
  final void Function() onChatLogWidgetChange;

  const ChatLogPage(
      {super.key,
      required this.chatLog,
      required this.configModelFiles,
      required this.lorebooks,
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
            tooltip: 'Configure lorebooks',
            icon: const Icon(Icons.inventory),
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EditLorebooksPage(
                            isFullPage: true,
                            lorebooks: widget.lorebooks,
                            selectedChatLog: widget.chatLog,
                          )));

              // save out all the lorebooks, but no UI state update should be needed
              for (final book in widget.lorebooks) {
                await book.saveToFile();
              }
            },
          ),
          IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                // store original settings so we can compare for changes
                final originalSelectedModel = widget.chatLog.modelName;
                final originalModelSettings = widget
                    .configModelFiles.modelFiles[originalSelectedModel]
                    ?.clone();

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
                  // now we dump the currently loaded model if the model name changed
                  // or any values that would invalide that model state.
                  if ((widget.chatLog.modelName != originalSelectedModel) ||
                      (originalModelSettings != null &&
                          widget.configModelFiles
                              .modelFiles[widget.chatLog.modelName]!
                              .doChangesRequireReload(originalModelSettings))) {
                    log("New model file selected, closing previous one...");
                    chatLogWidgetState.currentState?.closePrognosticatorModel();
                  }

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
              lorebooks: widget.lorebooks,
              onChatLogChange: () {
                widget.onChatLogWidgetChange();
              },
            )));
  }
}

class ChatLogWidget extends StatefulWidget {
  final ChatLog chatLog;
  final ConfigModelFiles configModelFiles;
  final List<Lorebook> lorebooks;

  // this callback is called when the chatlog has been changed by something
  // the widget does.
  final void Function() onChatLogChange;

  const ChatLogWidget(
      {super.key,
      required this.chatLog,
      required this.configModelFiles,
      required this.lorebooks,
      required this.onChatLogChange});

  @override
  State<ChatLogWidget> createState() => ChatLogWidgetState();
}

class ChatLogWidgetState extends State<ChatLogWidget>
    with TickerProviderStateMixin {
  final newMessgeController = TextEditingController();

  late AnimationController circularProgresAnimController;
  bool messageGenerationInProgress = false;
  bool closeModelAfterGeneration = false;

  // set this to non-null when a messages is getting edited
  ChatLogMessage? messageBeingEdited;

  // this should be set to the chatlog that's generating a message
  ChatLog? inFlightChatLog;

  // if this is set to a string, this is the current prediction in process
  // as it comes in piece by piece. it should be nulled out when finished...
  String? inFlightMessage;

  // this should be set to the name of the character who's generating
  // the new message at present. it should be nulled out when finished...
  String? inFlightCharacterName;

  // this is the current speed of prediction in tokens per second
  double inFlightTokensPerSec = 0.0;

  // should be set to true if the current inFlightMessage is being
  // generated as a continuation of a previous message.
  bool isContinuingMessage = false;

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

  // call this when message generation ends to reset internal data structures
  void _resetMessageGenerationState() {
    messageGenerationInProgress = false;
    isContinuingMessage = false;
    inFlightChatLog = null;
    inFlightMessage = null;
    inFlightTokensPerSec = 0.0;
  }

  // call this when starting message generation to reset the local data
  // structures necessary
  void _initMessageInFlightState(ChatLog targetChatlog, bool continueMsg) {
    messageGenerationInProgress = true;
    isContinuingMessage = continueMsg;
    closeModelAfterGeneration = false;
    inFlightTokensPerSec = 0.0;
    inFlightChatLog = targetChatlog;
    inFlightMessage = "";
    inFlightCharacterName = "";
  }

  Future<void> _generateAIMessage(bool continueMsg) async {
    // get the model filepath for the selected model. right now this is a
    // relative path, so we have to combine it with our documents folder
    var currentModelConfig =
        widget.configModelFiles.modelFiles[widget.chatLog.modelName];
    if (currentModelConfig == null) {
      return await _showErrorForMissingModel();
    }

    // run the text inference in an isolate ... so make sure our
    // prognosticator object is all setup...
    if (prognosticator == null) {
      log("prognosticator was not initialized yet, skipping _generateAIMessage...");
      return;
    }

    var modelFilepath = (!p.isAbsolute(currentModelConfig.modelFilepath)
        ? p.join(await ConfigModelFiles.getModelsFolderpath(),
            currentModelConfig.modelFilepath)
        : currentModelConfig.modelFilepath);
    var existsMabye = await File(modelFilepath).exists();
    log("File for the model $modelFilepath exists: {$existsMabye}");

    // turn the busy flag and animation on
    setState(() {
      _initMessageInFlightState(widget.chatLog, continueMsg);
      circularProgresAnimController.repeat(reverse: true);
    });

    // store a reference to the chatlog used for generation so that
    // if the user switches the 'current' chatlog up while waiting
    // for generation, the message will still get added to this log.
    // this is the same as inFlightChatLog, but local to this function
    // and of use after the in-flight status gets reset.
    final targetChatlog = widget.chatLog;

    // make sure our model is loaded
    await prognosticator!.ensureModelLoaded(EnsureModelLoadedRequest(
        modelFilepath, currentModelConfig, targetChatlog.hyperparmeters));

    // build the prompt to send off to the ai
    int tokenBudget = (currentModelConfig.contextSize ?? 2048) -
        targetChatlog.hyperparmeters.tokens;
    final promptConfig = targetChatlog.modelPromptStyle.getPromptConfig();
    final prompt = await prognosticator!
        .buildPrompt(targetChatlog, widget.lorebooks, tokenBudget, continueMsg);
    log("Token budget: $tokenBudget");
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

    // throw in the narrator's name as well
    stopPhrases.add('Narrator:');

    // set up some other character data needed for AI and narrator work and
    // make sure we set the in-flight message generating character name.
    final aiCharacter = targetChatlog.getAICharacter();
    final isNarratorCommand =
        targetChatlog.messages.last.message.startsWith('/narrator ');
    inFlightCharacterName = isNarratorCommand ? 'Narrator' : aiCharacter!.name;

    final stopwatch = Stopwatch();

    // start the prediction stream, which will ingest the prompt. the response will
    // tell us how many tokens were processed which we use for speed metrics.
    stopwatch.start();
    StartPredictionStreamRequest request = StartPredictionStreamRequest(
        modelFilepath,
        currentModelConfig,
        prompt,
        stopPhrases,
        targetChatlog.hyperparmeters);
    var streamStartResult =
        await prognosticator!.startPredictionStream(request);
    stopwatch.stop();

    // at this point we can kill our animations, record our prompt metrics and get
    circularProgresAnimController.reset();
    circularProgresAnimController.stop();
    final promptTokensProcessed = streamStartResult.promptTokenCount;
    final promptProcessingMs = stopwatch.elapsedMilliseconds;
    final promptTokensPerSecond =
        promptTokensProcessed / (promptProcessingMs / 1000);
    stopwatch.reset();
    log("Prompt processing speed: $promptTokensProcessed in ${promptProcessingMs}ms (${promptTokensPerSecond.toStringAsFixed(2)}t/s)");

    // but if we faild the start of the prediction, we actually just stop here
    if (!streamStartResult.success) {
      log('Failed to start the prediction stream: ${streamStartResult.errorMessage}');
      _resetMessageGenerationState();
      return;
    } else {
      // now that the stream is started, keep rolling until we hit our desired
      // count in tokens or the model finds antiprompt or eog tokens.
      stopwatch.start();
      TokenList predictions = [];
      while (predictions.length <= targetChatlog.hyperparmeters.tokens) {
        var stepResult = await prognosticator!
            .continuePredictionStream(ContinuePredictionStreamRequest());
        if (stepResult.errorMessage != null) {
          log('Failed to continue the prediction stream.\n${stepResult.errorMessage}');
          break;
        }

        // update our in-flight speeds
        final elapsedMs = stopwatch.elapsedMilliseconds;
        final tps = (predictions.length + 1) / (elapsedMs / 1000);

        setState(() {
          inFlightMessage = stepResult.predictionSoFar ?? "";
          inFlightTokensPerSec = tps;
        });

        // finally, add our new token to the list and see if the model hit an antiprompt or eog token
        predictions.add(stepResult.nextToken);
        if (stepResult.isComplete) {
          log('Completed prediction stream.');
          break;
        }
      }
      stopwatch.stop();

      setState(() {
        // check to see if we're creating a new message
        if (!continueMsg) {
          targetChatlog.messages.add(ChatLogMessage(inFlightCharacterName ?? '',
              inFlightMessage!.trimLeft(), false, inFlightTokensPerSec));
        } else {
          // just continuing the last message, so append the new prediction
          targetChatlog.messages.last.message += inFlightMessage!;
        }

        _resetMessageGenerationState();
      });
    }

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
        ChatLogMessage msg;
        if (inFlightMessage != null &&
            inFlightMessage!.isNotEmpty &&
            widget.chatLog.name == inFlightChatLog?.name &&
            isContinuingMessage == false) {
          if (index > 0) {
            msg = reverseMessages.elementAt(index - 1);
          } else {
            msg = ChatLogMessage(inFlightCharacterName ?? '',
                inFlightMessage!.trimLeft(), false, inFlightTokensPerSec);
          }
        } else {
          msg = reverseMessages.elementAt(index);
        }
        final msgTimeDiff = now.difference(msg.messageCreatedAt);
        final timeDiffString = _formatDurationString(msgTimeDiff.inSeconds);
        final isHumanSent = msg.senderName == humanCharacter.name;
        final isNarrator = msg.senderName == 'Narrator';

        return GestureDetector(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    (!isHumanSent && !isNarrator
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
                                }))
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
                          child: (index == 0 &&
                                  inFlightMessage != null &&
                                  isContinuingMessage == true)
                              ? Text(msg.message + inFlightMessage!)
                              : Text(msg.message)),
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
              maxLines: 10,
              minLines: 1,
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
                    // the AI if the newMessage controller is empty.
                    if (newMessgeController.text.trim().isEmpty) {
                      await _generateAIMessage(false);
                    } else {
                      // if we have text, then a long press will just add the message
                      // to the chatlog without generating a message.
                      setState(() {
                        final humanCharacter =
                            widget.chatLog.getHumanCharacter();
                        widget.chatLog.messages.add(ChatLogMessage(
                            humanCharacter!.name,
                            newMessgeController.text.trimLeft(),
                            true,
                            null));
                        newMessgeController.clear();
                      });
                    }
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
      // we only show the progress indicator while the prediction is getting
      // started in the prefill stage. if we show it while the in-flight
      // message is shown in a chat bubble, it's obnoxious when tokens-per-second
      // is really fast and causes a jarring experience...
      if (messageGenerationInProgress &&
          widget.chatLog.name == inFlightChatLog?.name &&
          (inFlightMessage == null || inFlightMessage!.isEmpty))
        CircularProgressIndicator(
          value: circularProgresAnimController.value,
          semanticsLabel: 'generating reply for AI',
        ),
      _buildTextEntry(context),
    ]);
  }
}
