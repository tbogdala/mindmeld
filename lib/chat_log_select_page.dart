import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:developer';

import 'chat_log.dart';
import 'chat_log_page.dart';
import 'config_models.dart';
import 'new_chat_log_page.dart';
import 'model_import_page.dart';

class ChatLogSelectPage extends StatefulWidget {
  final String appTitle = 'MindMeld';

  const ChatLogSelectPage({super.key});

  @override
  State<ChatLogSelectPage> createState() => _ChatLogSelectPageState();
}

class _ChatLogSelectPageState extends State<ChatLogSelectPage> {
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

  @override
  Widget build(BuildContext context) {
    if (configModelFiles == null) {
      return MaterialApp(
        home: Builder(builder: buildOnboarding),
      );
    } else {
      return MaterialApp(
        home: Builder(builder: buildChatlog),
      );
    }
  }

  Widget buildOnboarding(BuildContext context) {
    return MaterialApp(
        title: widget.appTitle,
        theme: ThemeData(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.system,

        // we use a new Builder here so that the theme choice above are applied
        // for the context object.
        home: Builder(builder: (context) {
          return Scaffold(
              appBar: AppBar(
                title: Text(widget.appTitle),
              ),
              body: ModelImportPage(
                onNewConfigModelFiles: (newConfigModelFiles) {
                  setState(() {
                    updateConfigModelFiles(newConfigModelFiles);
                  });
                },
              ));
        }));
  }

  Widget buildChatlog(BuildContext context) {
    return MaterialApp(
      title: widget.appTitle,
      theme: ThemeData(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,

      // we use a new Builder here so that the theme choice above are applied
      // for the context object.
      home: Builder(builder: (context) {
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
                      return Card(
                          child: ListTile(
                        leading: CircleAvatar(
                          child: Text(thisLog.name.substring(0, 2)),
                        ),
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
                      ));
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
                            // TODO: review if this is being handled elsewhere
                            // onConfigModelFilesChange: (newConfigModelFiles) {
                            //   setState(() {
                            //     updateConfigModelFiles(newConfigModelFiles);
                            //   });
                            // },
                          )));
              if (newChatLog != null) {
                // FIXME: no safety nets on making sure a model file was actually selected.
                // there's a delay because it haas to copy it over to the app storage...

                setState(() {
                  chatLogs.add(newChatLog);
                  newChatLog.saveToFile();
                });
              }
            },
            child: const Icon(Icons.add),
          ),
        );
      }),
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
