import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mindmeld/configure_chat_log_page.dart';
import 'package:mindmeld/new_chat_log_page.dart';
import 'package:window_manager/window_manager.dart';

import 'package:mindmeld/chat_log.dart';
import 'package:mindmeld/chat_log_page.dart';
import 'package:mindmeld/color_theming.dart';
import 'package:mindmeld/config_models.dart';

import 'chat_log_select_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // right away try to detect if we're running a desktop build and do a different
  // interface that's more specialized for desktops
  if (Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(600, 420),
      size: Size(1024, 800),
      center: true,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    runApp(MaterialApp(
        title: 'Mindmeld',
        theme: ThemeData(),
        darkTheme: ThemeData.dark(),
        home: const MacosMindmeldApp()));
  } else {
    runApp(const ChatLogSelectPage());
  }
}

/* MacOS Support Code */

class MacosMindmeldApp extends StatefulWidget {
  const MacosMindmeldApp({
    super.key,
  });

  @override
  State<MacosMindmeldApp> createState() => _MacosMindmeldAppState();
}

class _MacosMindmeldAppState extends State<MacosMindmeldApp> {
  bool _isLoading = true;
  List<ChatLog> chatLogs = [];
  ConfigModelFiles? configModelFiles;
  int currentChatLog = 0;

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
    configModelFiles = await ConfigModelFiles.loadFromConfigFile();
    ChatLog.ensureLogsFolderExists();
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
    } else {
      final selectedLog = chatLogs.elementAt(currentChatLog);
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(selectedLog.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
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
                                    child: Container(
                                        constraints:
                                            const BoxConstraints.tightFor(
                                          width: 600,
                                        ),
                                        child: SingleChildScrollView(
                                            child: ConfigureChatLogPage(
                                          isFullPage: false,
                                          chatLog: selectedLog,
                                          configModelFiles: configModelFiles!,
                                        ))));
                              });

                          // once we've returned from the chatlog configuration page
                          // save the log in case changes were made.
                          await selectedLog.saveToFile();

                          // same with the models configuration file
                          await configModelFiles?.saveJsonToConfigFile();

                          // FIXME: now we dump the currently loaded model
                          // chatLogWidgetState.currentState
                          //     ?.closePrognosticatorModel();
                        },
                      ),
                    ],
                  )),
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ChatLogWidget(
                        chatLog: selectedLog,
                        configModelFiles: configModelFiles!,
                        onChatLogChange: () {
                          setState(() {}); // trigger a rebuild...
                        },
                      ))),
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
                  leading: CircleAvatar(
                    child: Text(thisLog.name.substring(0, 2)),
                  ),
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
