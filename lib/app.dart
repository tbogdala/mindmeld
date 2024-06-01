import 'package:flutter/material.dart';
import 'dart:developer';

import 'chat_log_page.dart';
import 'new_chat_log_page.dart';
import 'chat_log.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  List<ChatLog> chatLogs = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(builder: buildHomepage),
    );
  }

  Widget buildHomepage(BuildContext context) {
    const String appTitle = 'MindMeld';
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,

      // we use a new Builder here so that the theme choice above are applied
      // for the context object.
      home: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(appTitle),
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
                          Navigator.push<NewChatLogUserData>(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      ChatLogPage(chatLog: thisLog)));
                        },
                      ));
                    },
                  )),
                ],
              )),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push<NewChatLogUserData>(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NewChatLogPage()));
              if (result != null) {
                var newChatLog = ChatLog(
                    result.chatlogName,
                    result.modelFilepath,
                    modelPromptStyleFromString(result.promptFormat));

                // FIXME: no safety nets on making sure a model file was actually selected.
                // there's a delay because it haas to copy it over to the app storage...
                log('Main chatlog select screen got a new log named: ${newChatLog.name}');
                log('Selected gguf: ${newChatLog.modelFilepath}');
                log('Model prompt format: ${newChatLog.modelPromptStyle.nameAsString()}');

                setState(() {
                  chatLogs.add(newChatLog);
                });
              }
            },
            child: const Icon(Icons.add),
          ),
        );
      }),
    );
  }
}
