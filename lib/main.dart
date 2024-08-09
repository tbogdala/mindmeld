import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mindmeld/configure_chat_log_page.dart';
import 'package:mindmeld/model_import_page.dart';
import 'package:mindmeld/new_chat_log_page.dart';
import 'package:profile_photo/profile_photo.dart';
import 'package:window_manager/window_manager.dart';

import 'package:mindmeld/chat_log.dart';
import 'package:mindmeld/chat_log_page.dart';
import 'package:mindmeld/platform_and_theming.dart';
import 'package:mindmeld/config_models.dart';

import 'chat_log_select_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // right away try to detect if we're running a desktop build and do a different
  // interface that's more specialized for desktops
  if (isRunningOnDesktop()) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(600, 420),
      size: Size(1024, 800),
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    runApp(MaterialApp(
        title: 'Mindmeld',
        theme: ThemeData(),
        darkTheme: ThemeData.dark(),
        home: const DesktopMindmeldApp()));
  } else {
    runApp(const ChatLogSelectPage());
  }
}

/* Desktop Support Code */

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
    configModelFiles = await ConfigModelFiles.loadFromConfigFile();
    final chatLogFolder = await ChatLog.getLogsFolder();
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
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: getBackgroundDecorationColor(context),
            borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                const Padding(padding: EdgeInsets.only(left: 16)),
                const Text('Chatlogs', style: TextStyle(fontSize: 18)),
                const Expanded(
                  child: Padding(padding: EdgeInsets.only(left: 16)),
                ),
                OutlinedButton(
                    onPressed: () async {
                      final newChatLog = await showDialog<ChatLog>(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                                child: Container(
                                    constraints: const BoxConstraints.tightFor(
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
                        // FIXME: no safety nets on making sure a model file was actually selected.
                        // there's a delay because it haas to copy it over to the app storage...
                        setState(() {
                          widget.chatLogs.add(newChatLog);
                          newChatLog.saveToFile();
                        });
                      }
                    },
                    child: const Text('+ New'))
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

                return Card(
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
                ));
              },
            ))
          ],
        ));
  }
}
