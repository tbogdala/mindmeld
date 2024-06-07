import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'dart:developer';

import 'config_models.dart';

enum AutoDLModels { tinyllama }

extension AutoDLModelsExtension on AutoDLModels {
  String nameAsString() {
    switch (this) {
      default:
        return "TinyLlama-1.1B-Chat-v1.0";
    }
  }
}

class OnboardingPage extends StatefulWidget {
  final void Function(ConfigModelFiles) onNewConfigModelFiles;

  const OnboardingPage({super.key, required this.onNewConfigModelFiles});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late String selectedAutoDLOption;
  late List<String> autoDLOptions;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    autoDLOptions = AutoDLModels.values.map((v) => v.nameAsString()).toList();
    selectedAutoDLOption = autoDLOptions[0];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text('Model Setup', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 16),
        const Text(
            'MindMeld needs a large language model ("LLM") neural net file in order to function. These files can be downloaded manually and imported here.'),
        const SizedBox(height: 16),
        FilledButton(
          child: const Text('Import AI GGUF Model File'),
          onPressed: () async {
            try {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                  dialogTitle: "Load LLM File",
                  type: FileType.any,
                  allowMultiple: false,
                  allowCompression: false);
              if (result != null) {
                // get the selected filepath
                final selectedModelFilepath = result.files.first.path!;
                final selectedModelFilename =
                    basenameWithoutExtension(selectedModelFilepath);

                // build a new models configuration file
                final configModelFiles = ConfigModelFiles(
                    modelFiles: {selectedModelFilename: selectedModelFilepath});

                log("JSON for ModelFiles: ${ConfigModelFiles.getFilepath()}");
                final configModelFilesJson = configModelFiles.toJson();
                log(configModelFilesJson);

                // send the new data file over the callback.
                widget.onNewConfigModelFiles(configModelFiles);
              }
            } catch (_) {}
          },
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 32),
        const Text(
            "If you don't know what file to download, MindMeld can download one of these files automatically for you instead."),
        const SizedBox(height: 16),
        DropdownMenu(
          initialSelection: selectedAutoDLOption,
          dropdownMenuEntries: autoDLOptions
              .map((option) => DropdownMenuEntry(value: option, label: option))
              .toList(),
          onSelected: (value) {
            setState(() {
              selectedAutoDLOption = value as String;
            });
          },
        ),
        const SizedBox(height: 16),
        FilledButton(
          child: const Text('Automatically Download Model'),
          onPressed: () async {},
        ),
      ]),
    );
  }
}
