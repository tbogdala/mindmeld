import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
      minimumSize: Size(480, 300),
      size: Size(800, 600),
      center: true,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    runApp(MacosMindmeldApp());
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
      return const CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
      );
    } else {
      final firstLog = chatLogs.elementAt(0);
      return MaterialApp(
        title: 'Mindmeld',
        theme: ThemeData(),
        darkTheme: ThemeData.dark(),
        home: Scaffold(
            // navigationBar: CupertinoNavigationBar(
            //   middle: Text('My Flutter App'),
            // ),
            body: Row(
          children: [
            SizedBox(
              width: 240,
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: DesktopChatLogListView(chatLogs: chatLogs)),
            ),
            Expanded(
              child: ChatLogWidget(
                  chatLog: firstLog, configModelFiles: configModelFiles!),
            )
          ],
        )),
      );
    }
  }
}

class DesktopChatLogListView extends StatelessWidget {
  final List<ChatLog> chatLogs;

  const DesktopChatLogListView({super.key, required this.chatLogs});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: getBackgroundDecorationColor(context),
            borderRadius: BorderRadius.circular(8)),
        child: Expanded(
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
              subtitle: Text('messages: ${thisLog.messages.length}'),
              onTap: () {
                // currently not doing anything
              },
            ));
          },
        )));
  }
}
