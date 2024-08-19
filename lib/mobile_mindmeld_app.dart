import 'dart:io';

import 'package:flutter/material.dart';
import 'package:profile_photo/profile_photo.dart';
import 'dart:developer';

import 'chat_log.dart';
import 'chat_log_page.dart';
import 'config_models.dart';
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
  ConfigModelFiles? configModelFiles;

  @override
  void initState() {
    super.initState();

    ConfigModelFiles.loadFromConfigFile().then((v) {
      setState(() {
        configModelFiles = v;
      });
    });

    ChatLog.ensureLogsFolderExists().then((_) {});
    ChatLog.getLogsFolder().then((chatLogFolder) async {
      try {
        var d = Directory(chatLogFolder);
        await for (final entity in d.list()) {
          if (entity is File && entity.path.endsWith(".json")) {
            var newChatLog = await ChatLog.loadFromFile(entity.path);
            if (newChatLog != null) {
              setState(() {
                chatLogs.add(newChatLog);
              });
            }
          }
        }
      } catch (e) {
        log("Failed to load all the chat files: $e");
      }
    });
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
    // update our internal variable first
    configModelFiles = newConfigModelFiles;

    // now write the new data out to our configuration file
    await configModelFiles!.saveJsonToConfigFile();

    log('Saved ConfigModelFiles out to JSON config file.');
  }
}