import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mindmeld/configure_chat_log_page.dart';
import 'package:mindmeld/edit_lorebooks_page.dart';
import 'package:mindmeld/lorebook.dart';
import 'package:mindmeld/model_import_page.dart';
import 'package:mindmeld/new_chat_log_page.dart';
import 'package:profile_photo/profile_photo.dart';

import 'package:mindmeld/chat_log.dart';
import 'package:mindmeld/chat_log_page.dart';
import 'package:mindmeld/platform_and_theming.dart';
import 'package:mindmeld/config_models.dart';

class DesktopMindmeldApp extends StatefulWidget {
  const DesktopMindmeldApp({
    super.key,
  });

  @override
  State<DesktopMindmeldApp> createState() => _DesktopMindmeldAppState();
}

class _DesktopMindmeldAppState extends State<DesktopMindmeldApp> {
  late GlobalKey<ChatLogWidgetState> chatLogWidgetState;
  bool _isLoading = true;
  List<ChatLog> chatLogs = [];
  List<Lorebook> lorebooks = [];
  ConfigModelFiles? configModelFiles;
  int currentChatLog = 0;

  @override
  void initState() {
    super.initState();
    chatLogWidgetState = GlobalKey();
    _loadConfigFiles().then((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _loadConfigFiles() async {
    await ConfigModelFiles.ensureModelsFolderExists();
    await ChatLog.ensureLogsFolderExists();
    await ChatLog.ensureProfilePicsFolderExists();
    await Lorebook.ensureLorebooksFolderExists();

    configModelFiles = await ConfigModelFiles.loadFromConfigFile();
    lorebooks = await Lorebook.loadAllLorebooks();
    chatLogs = await ChatLog.loadAllChatlogs();
  }

  @override
  Widget build(BuildContext context) {
    // we show a progress bar if we haven't finished loading our data yet.
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
      ));
    }
    if (configModelFiles == null) {
      newConfigCallback(newConfigModelFiles) {
        setState(() {
          newConfigModelFiles.saveJsonToConfigFile().then((_) {
            configModelFiles = newConfigModelFiles;
          });
        });
      }

      return Scaffold(
          body: ModelImportPage(
        isMobile: false,
        onNewConfigModelFiles: newConfigCallback,
      ));
    } else {
      final selectedLog = chatLogs.elementAtOrNull(currentChatLog);
      return Scaffold(
          body: Row(
        children: [
          SizedBox(
            width: 240,
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: DesktopChatLogListView(
                  chatLogs: chatLogs,
                  configModelFiles: configModelFiles!,
                  onLogSelection: (newIndex) {
                    setState(() {
                      currentChatLog = newIndex;
                    });
                  },
                )),
          ),
          Expanded(
              child: Column(
            children: [
              Container(
                  decoration: BoxDecoration(
                      color: getBackgroundDecorationColor(context),
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.all(2),
                  margin: const EdgeInsets.all(8),
                  child: (selectedLog == null
                      ? const Center(
                          child: Text('No Chatlog Selected',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: Text(selectedLog.name,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Configure lorebooks',
                              icon: const Icon(Icons.inventory),
                              onPressed: () async {
                                await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                          alignment:
                                              AlignmentDirectional.topCenter,
                                          child: Container(
                                              constraints:
                                                  const BoxConstraints.tightFor(
                                                width: 600,
                                              ),
                                              child: SingleChildScrollView(
                                                child: EditLorebooksPage(
                                                  isFullPage: false,
                                                  lorebooks: lorebooks,
                                                  selectedChatLog: selectedLog,
                                                ),
                                              )));
                                    });

                                // save out all the lorebooks, but no UI state update should be needed
                                for (final book in lorebooks) {
                                  await book.saveToFile();
                                }
                              },
                            ),
                            IconButton(
                              tooltip: 'Configure chatlog settings',
                              icon: const Icon(Icons.settings),
                              onPressed: () async {
                                await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                          alignment:
                                              AlignmentDirectional.topCenter,
                                          child: Container(
                                              constraints:
                                                  const BoxConstraints.tightFor(
                                                width: 600,
                                              ),
                                              child: SingleChildScrollView(
                                                  child: ConfigureChatLogPage(
                                                isFullPage: false,
                                                chatLog: selectedLog,
                                                configModelFiles:
                                                    configModelFiles!,
                                              ))));
                                    });

                                // once we've returned from the chatlog configuration page
                                // save the log in case changes were made.
                                await selectedLog.saveToFile();

                                // same with the models configuration file
                                await configModelFiles?.saveJsonToConfigFile();

                                // now we dump the currently loaded model
                                setState(() {
                                  chatLogWidgetState.currentState
                                      ?.closePrognosticatorModel();
                                });
                              },
                            ),
                          ],
                        ))),
              Expanded(
                  child: (selectedLog == null
                      ? const Center(child: Text('Create a log file ...'))
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: ChatLogWidget(
                            key: chatLogWidgetState,
                            chatLog: selectedLog,
                            configModelFiles: configModelFiles!,
                            lorebooks: lorebooks,
                            onChatLogChange: () {
                              setState(() {}); // trigger a rebuild...
                            },
                          )))),
            ],
          ))
        ],
      ));
    }
  }
}

class DesktopChatLogListView extends StatefulWidget {
  final List<ChatLog> chatLogs;
  final ConfigModelFiles configModelFiles;
  final Function(int) onLogSelection;

  const DesktopChatLogListView(
      {super.key,
      required this.chatLogs,
      required this.configModelFiles,
      required this.onLogSelection});

  @override
  State<DesktopChatLogListView> createState() => _DesktopChatLogListViewState();
}

class _DesktopChatLogListViewState extends State<DesktopChatLogListView> {
  Future<bool?> _showConfirmDeleteDialog() async {
    return showDialog<bool?>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Chatlog?'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Would you like to permanently delete the chatlog?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showRenameChatlogDialog(String initialName) async {
    TextEditingController newNameFieldController = TextEditingController();
    newNameFieldController.text = initialName;
    return showDialog<String?>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter new name:'),
          content: TextField(
            controller: newNameFieldController,
            decoration: const InputDecoration(hintText: "New Chatlog Name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              child: const Text(
                'Rename',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop(newNameFieldController.text);
              },
            ),
          ],
        );
      },
    );
  }

  void _showModalLongPressMessageBottomSheet(
      BuildContext context, ChatLog chatlog) {
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
                    label: Text("Delete Chatlog",
                        style: Theme.of(context).textTheme.titleLarge),
                    onPressed: () async {
                      var shouldDelete = await _showConfirmDeleteDialog();
                      if (shouldDelete != null && shouldDelete == true) {
                        await chatlog.deleteFile();
                        setState(() {
                          final logRemoved = widget.chatLogs.remove(chatlog);
                          log('Chatlog was removed from collection: $logRemoved');
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: Text("Rename Chatlog",
                        style: Theme.of(context).textTheme.titleLarge),
                    onPressed: () async {
                      var newChatlogName =
                          await _showRenameChatlogDialog(chatlog.name);
                      if (newChatlogName != null) {
                        setState(() {
                          log('New chatlog name chosen by user: $newChatlogName');
                          chatlog.rename(newChatlogName);
                        });
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  )
                ],
              ));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: getBackgroundDecorationColor(context),
            borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                const Padding(padding: EdgeInsets.only(left: 16)),
                const Text('Chatlogs', style: TextStyle(fontSize: 18)),
                const Expanded(
                  child: Padding(padding: EdgeInsets.only(left: 16)),
                ),
                Tooltip(
                  message: 'Create a new chatlog',
                  child: OutlinedButton(
                      onPressed: () async {
                        final newChatLog = await showDialog<ChatLog>(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                  child: Container(
                                      constraints:
                                          const BoxConstraints.tightFor(
                                        width: 400,
                                      ),
                                      child: SingleChildScrollView(
                                          child: Column(
                                        children: [
                                          const Text('New Chatlog',
                                              style: TextStyle(fontSize: 24)),
                                          const SizedBox(height: 16),
                                          NewChatLogWidget(
                                              configModelFiles:
                                                  widget.configModelFiles)
                                        ],
                                      ))));
                            });
                        if (newChatLog != null) {
                          setState(() {
                            widget.chatLogs.add(newChatLog);
                            newChatLog.saveToFile();
                          });
                        }
                      },
                      child: const Text('+ New')),
                )
              ],
            ),
            const Divider(height: 16),
            Expanded(
                child: ListView.builder(
              itemCount: widget.chatLogs.length,
              itemBuilder: (context, index) {
                var thisLog = widget.chatLogs[index];
                const shortLogNameLimit = 20;
                final shortLogName = thisLog.name.length < shortLogNameLimit
                    ? thisLog.name
                    : '${thisLog.name.substring(0, shortLogNameLimit)}...';

                return GestureDetector(
                  onLongPress: () {
                    _showModalLongPressMessageBottomSheet(context, thisLog);
                  },
                  child: Card(
                      child: ListTile(
                    leading: FutureBuilder(
                        future:
                            thisLog.getAICharacter()!.getEffectiveProfilePic(),
                        builder: (BuildContext context,
                            AsyncSnapshot<ImageProvider<Object>> snapshot) {
                          if (snapshot.hasData) {
                            return ProfilePhoto(
                                totalWidth: 48,
                                outlineColor: Colors.transparent,
                                color: Colors.transparent,
                                image: snapshot.data);
                          } else {
                            return ProfilePhoto(
                                totalWidth: 48,
                                outlineColor: Colors.transparent,
                                color: Colors.transparent);
                          }
                        }),
                    title: Text(shortLogName),
                    subtitle: Text('messages: ${thisLog.messages.length}'),
                    onTap: () {
                      widget.onLogSelection(index);
                    },
                  )),
                );
              },
            ))
          ],
        ));
  }
}
