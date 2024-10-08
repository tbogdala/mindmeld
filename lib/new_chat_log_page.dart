import 'package:flutter/material.dart';

import 'chat_log.dart';
import 'config_models.dart';

class NewChatLogPage extends StatefulWidget {
  final String appTitle = 'MindMeld';
  final ConfigModelFiles configModelFiles;

  const NewChatLogPage({super.key, required this.configModelFiles});

  @override
  State<NewChatLogPage> createState() => _NewChatLogPageState();
}

class _NewChatLogPageState extends State<NewChatLogPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chatlog'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: NewChatLogWidget(configModelFiles: widget.configModelFiles),
        ),
      ),
    );
  }
}

class NewChatLogWidget extends StatefulWidget {
  final ConfigModelFiles configModelFiles;

  const NewChatLogWidget({super.key, required this.configModelFiles});

  @override
  State<NewChatLogWidget> createState() => _NewChatLogWidgetState();
}

class _NewChatLogWidgetState extends State<NewChatLogWidget> {
  final logNameController = TextEditingController();
  final userNameController = TextEditingController();
  final aiNameController = TextEditingController();

  late List<String> promptFormatOptions;
  late String selectedPromptFormatOption;

  late List<String> modelFileOptions;
  late String selectedModelFileOption;

  @override
  void dispose() {
    logNameController.dispose();
    userNameController.dispose();
    aiNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // build the data for the prompt format dropdown
    promptFormatOptions =
        ModelPromptStyle.values.map((v) => v.nameAsString()).toList();
    selectedPromptFormatOption = promptFormatOptions[0];

    // build the data for the model dropdown to select already imported models
    modelFileOptions = widget.configModelFiles.modelFiles.keys.toList();
    selectedModelFileOption = modelFileOptions.first;

    userNameController.text = "User";
    aiNameController.text = "Assistant";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'First, select an AI Model that has already been imported to use for this chatlog.'),
          const SizedBox(height: 16),
          DropdownMenu(
            initialSelection: selectedModelFileOption,
            dropdownMenuEntries: modelFileOptions
                .map(
                    (option) => DropdownMenuEntry(value: option, label: option))
                .toList(),
            onSelected: (value) {
              setState(() {
                selectedModelFileOption = value as String;
              });
            },
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
              'Next, choose the prompt template style to use when interfacing with this model. When in doubt, check the source page for the model to see what it suggests.'),
          const SizedBox(height: 8),
          DropdownMenu(
            initialSelection: selectedPromptFormatOption,
            dropdownMenuEntries: promptFormatOptions
                .map(
                    (option) => DropdownMenuEntry(value: option, label: option))
                .toList(),
            onSelected: (value) {
              setState(() {
                selectedPromptFormatOption = value as String;
              });
            },
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
              'Finally, personalize this chatlog by giving it a name and then press the \'Create Chatlog\' button.'),
          const SizedBox(height: 8),
          TextField(
            controller: logNameController,
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.account_box),
                labelText: 'New Chatlog Name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: userNameController,
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person), labelText: 'Your Name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: aiNameController,
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.precision_manufacturing),
                labelText: 'AI Name'),
          ),
          const SizedBox(height: 32),
          Center(
            child: FilledButton(
              child: const Text('Create Chatlog'),
              onPressed: () {
                var result = ChatLog(
                    logNameController.text,
                    selectedModelFileOption,
                    modelPromptStyleFromString(selectedPromptFormatOption),
                    '');
                result.characters.add(ChatLogCharacter(
                    name: userNameController.text,
                    description: '',
                    personality: '',
                    isUserControlled: true));
                result.characters.add(ChatLogCharacter(
                    name: aiNameController.text,
                    description: '',
                    personality: '',
                    isUserControlled: false));
                Navigator.pop(context, result);
              },
            ),
          ),
        ],
      ),
    );
  }
}
