import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mindmeld/chat_log.dart';
import 'package:mindmeld/config_models.dart';

import 'chat_log_select_page.dart';

void main() async {
  // right away try to detect if we're running a desktop build and do a different
  // interface that's more specialized for desktops
  if (Platform.isMacOS) {
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
    if (_isLoading) {
      return const CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
      );
    } else {
      return const CupertinoApp(
        title: 'Mindmeld',
        home: CupertinoPageScaffold(
          // navigationBar: CupertinoNavigationBar(
          //   middle: Text('My Flutter App'),
          // ),
          child: Center(
            child: Text('Hello, MacOS!'),
          ),
        ),
      );
    }
  }
}
