import 'package:flutter/material.dart';

import 'chat_log.dart';

class ConfigureChatLogPage extends StatefulWidget {
  final ChatLog chatLog;

  const ConfigureChatLogPage({super.key, required this.chatLog});

  @override
  State<ConfigureChatLogPage> createState() => _ConfigureChatLogPageState();
}

class _ConfigureChatLogPageState extends State<ConfigureChatLogPage> {
  final userNameController = TextEditingController();
  final userDescController = TextEditingController();
  final aiNameController = TextEditingController();
  final aiDescController = TextEditingController();
  final aiPersonalityController = TextEditingController();
  final storyContextController = TextEditingController();

  @override
  void dispose() {
    userNameController.dispose();
    userDescController.dispose();
    aiNameController.dispose();
    aiDescController.dispose();
    aiPersonalityController.dispose();
    storyContextController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    userNameController.text = widget.chatLog.humanName;
    userDescController.text = widget.chatLog.humanDescription ?? "";
    aiNameController.text = widget.chatLog.aiName;
    aiDescController.text = widget.chatLog.aiDescription ?? "";
    aiPersonalityController.text = widget.chatLog.aiPersonality ?? "";
    storyContextController.text = widget.chatLog.context ?? "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('ChatLog Configuration')),
        body: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: TextField(
                      controller: userNameController,
                      decoration: const InputDecoration(
                        labelText: "Your Name",
                      ),
                      onChanged: (text) {
                        widget.chatLog.humanName = text;
                      },
                    ),
                    subtitle: TextField(
                      controller: userDescController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Your Description",
                      ),
                      onChanged: (text) {
                        widget.chatLog.humanDescription = text;
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.precision_manufacturing),
                    title: TextField(
                      controller: aiNameController,
                      decoration: const InputDecoration(
                        labelText: "AI Name",
                      ),
                      onChanged: (text) {
                        widget.chatLog.aiName = text;
                      },
                    ),
                    subtitle: TextField(
                      controller: aiDescController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "AI Description",
                      ),
                      onChanged: (text) {
                        widget.chatLog.aiDescription = text;
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.psychology),
                    title: TextField(
                      controller: aiPersonalityController,
                      decoration: const InputDecoration(
                        labelText: "AI Personality",
                      ),
                      onChanged: (text) {
                        widget.chatLog.aiPersonality = text;
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.alt_route),
                    title: TextField(
                      controller: storyContextController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: "Story Context",
                      ),
                      onChanged: (text) {
                        widget.chatLog.context = text;
                      },
                    ),
                  ),
                ]))));
  }
}
