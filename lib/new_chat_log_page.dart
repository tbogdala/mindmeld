import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:developer';

import 'chat_log.dart';

class NewChatLogUserData {
  final String modelFilepath;
  final String chatlogName;
  final String promptFormat;

  NewChatLogUserData(this.modelFilepath, this.chatlogName, this.promptFormat);
}

class NewChatLogPage extends StatefulWidget {
  const NewChatLogPage({super.key});

  @override
  State<NewChatLogPage> createState() => _NewChatLogPageState();
}

class _NewChatLogPageState extends State<NewChatLogPage> {
  final logNameController = TextEditingController();

  late List<String> promptFormatOptions;
  late String selectedPromptFormatOption;
  String selectedModelFilepath = "";

  @override
  void dispose() {
    logNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    promptFormatOptions =
        ModelPromptStyle.values.map((v) => v.nameAsString()).toList();
    selectedPromptFormatOption = promptFormatOptions[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chatlog'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'First, choose an AI neural net model file to load by pressing the \'Select Model File\' button and browsing to an appropriate file.'),
              const SizedBox(height: 8),
              Text('Model: $selectedModelFilepath'),
              const SizedBox(height: 8),
              FilledButton(
                child: const Text('Select AI Model File'),
                onPressed: () async {
                  try {
                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles(
                            dialogTitle: "Load Model File",
                            type: FileType.any,
                            allowMultiple: false,
                            allowCompression: false);
                    log("await returned");
                    if (result != null) {
                      setState(() {
                        selectedModelFilepath = result.files.first.path!;
                        log("selected file: $selectedModelFilepath");
                      });
                    }
                  } catch (e) {
                    log("Excemption from the file picker: $e");
                  }
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
                    .map((option) =>
                        DropdownMenuEntry(value: option, label: option))
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
              const SizedBox(height: 32),
              Center(
                child: FilledButton(
                  child: const Text('Create Chatlog'),
                  onPressed: () {
                    var result = NewChatLogUserData(selectedModelFilepath,
                        logNameController.text, selectedPromptFormatOption);
                    Navigator.pop(context, result);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
