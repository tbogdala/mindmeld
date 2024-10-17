import 'package:flutter/material.dart';
import 'package:profile_photo/profile_photo.dart';
import 'dart:developer';

import 'chat_log.dart';
import 'chat_log_page.dart';
import 'config_models.dart';
import 'lorebook.dart';
import 'new_chat_log_page.dart';
import 'model_import_page.dart';

class MobileMindmeldApp extends StatefulWidget {
  final String appTitle = 'MindMeld';

  const MobileMindmeldApp({super.key});

  @override
  State<MobileMindmeldApp> createState() => _MobileMindmeldAppState();
}

class _MobileMindmeldAppState extends State<MobileMindmeldApp> {
  List<ChatLog> chatLogs = [];
  List<Lorebook> lorebooks = [];
  ConfigModelFiles? configModelFiles;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

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

  Future<String?> _showDuplicateChatlogDialog(String initialName) async {
    TextEditingController newNameFieldController = TextEditingController();
    newNameFieldController.text = '$initialName Copy';
    return showDialog<String?>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter duplicate chatlog name:'),
          content: TextField(
            controller: newNameFieldController,
            decoration:
                const InputDecoration(hintText: "Duplicate Chatlog Name"),
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
                'Duplicate',
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
                          final logRemoved = chatLogs.remove(chatlog);
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
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.file_copy),
                    label: Text("Duplicate Chatlog",
                        style: Theme.of(context).textTheme.titleLarge),
                    onPressed: () async {
                      var dupChatlogName =
                          await _showDuplicateChatlogDialog(chatlog.name);
                      if (dupChatlogName != null) {
                        log('Duplicate the ${chatlog.name} chatlog name to $dupChatlogName');
                        var newDupeLog =
                            await chatlog.duplicate(dupChatlogName);
                        setState(() {
                          chatLogs.add(newDupeLog);
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
    if (configModelFiles == null) {
      return Builder(builder: buildOnboarding);
    } else {
      return Builder(builder: buildChatlog);
    }
  }

  Widget buildOnboarding(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.appTitle),
        ),
        body: ModelImportPage(
          isMobile: true,
          onNewConfigModelFiles: (newConfigModelFiles) {
            setState(() {
              updateConfigModelFiles(newConfigModelFiles);
            });
          },
        ));
  }

  Widget buildChatlog(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appTitle),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Chatlogs',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 16),
              Expanded(
                  child: ListView.builder(
                itemCount: chatLogs.length,
                itemBuilder: (context, index) {
                  var thisLog = chatLogs[index];
                  return GestureDetector(
                    onLongPress: () {
                      _showModalLongPressMessageBottomSheet(context, thisLog);
                    },
                    child: Card(
                        child: ListTile(
                      leading: FutureBuilder(
                          future: thisLog
                              .getAICharacter()!
                              .getEffectiveProfilePic(),
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
                      title: Text(thisLog.name),
                      subtitle:
                          Text('message count: ${thisLog.messages.length}'),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChatLogPage(
                                    chatLog: thisLog,
                                    configModelFiles: configModelFiles!,
                                    lorebooks: lorebooks,
                                    onChatLogWidgetChange: () {
                                      setState(() {}); // trigger an update
                                    })));
                      },
                    )),
                  );
                },
              )),
            ],
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newChatLog = await Navigator.push<ChatLog>(
              context,
              MaterialPageRoute(
                  builder: (context) => NewChatLogPage(
                        configModelFiles:
                            configModelFiles!, // should only get to this widget if we have this data
                      )));
          if (newChatLog != null) {
            setState(() {
              chatLogs.add(newChatLog);
              newChatLog.saveToFile();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void updateConfigModelFiles(ConfigModelFiles newConfigModelFiles) async {
    final firstModelName = newConfigModelFiles.modelFiles.keys.first;
    final firstModel = newConfigModelFiles.modelFiles[firstModelName];

    // we should have a model configured now, so lets create a default chatlog
    final newChatlog = ChatLog.buildDefaultChatLog(firstModelName,
        modelPromptStyleFromString(firstModel?.promptFormat ?? "chatml"));

    setState(() {
      chatLogs.add(newChatlog);
      newChatlog.saveToFile();

      newConfigModelFiles.saveJsonToConfigFile().then((_) {
        configModelFiles = newConfigModelFiles;
        log('Saved ConfigModelFiles out to JSON config file.');
      });
    });
  }
}
