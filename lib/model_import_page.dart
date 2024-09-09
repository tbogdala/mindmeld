import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mindmeld/platform_and_theming.dart';
import 'package:path/path.dart' as p;
import 'dart:developer';

import 'config_models.dart';

enum AutoDLModels {
  gemma2bInstruct,
  gemma9bInstruct,
  llama31V8bInstruct,
  mistral7bV03Instruct,
  mistralNemo2407,
  phi35MiniInstruct,
  stablelmZephyr3b,
  tinyDolphin,
  tinyLlama
}

extension AutoDLModelsExtension on AutoDLModels {
  String nameAsString() {
    switch (this) {
      case AutoDLModels.gemma2bInstruct:
        return 'Gemma-2-2b-it';
      case AutoDLModels.gemma9bInstruct:
        return 'Gemma-2-9b-it';
      case AutoDLModels.llama31V8bInstruct:
        return 'Llama-3.1-8B-Instruct';
      case AutoDLModels.mistral7bV03Instruct:
        return 'Mistral-7B-Instruct-v0.3';
      case AutoDLModels.mistralNemo2407:
        return 'Mistral-Nemo-Instruct';
      case AutoDLModels.phi35MiniInstruct:
        return 'Phi-3.5-mini-instruct';
      case AutoDLModels.stablelmZephyr3b:
        return 'Stablelm-zephyr-3b';
      case AutoDLModels.tinyDolphin:
        return 'TinyDolphin-2.8-1.1b';
      default:
        return 'TinyLlama-1.1B-Chat-v1.0';
    }
  }

  // Should return a valid URL to download models from. As a standard, this should
  // point to the Q4_K_M.
  // Favored providers of quants are TheBloke (RIP) and bartowski.
  String getModelURL() {
    switch (this) {
      case AutoDLModels.gemma2bInstruct:
        return 'https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf';
      case AutoDLModels.gemma9bInstruct:
        return 'https://huggingface.co/bartowski/gemma-2-9b-it-GGUF/resolve/main/gemma-2-9b-it-Q4_K_M.gguf';
      case AutoDLModels.llama31V8bInstruct:
        return 'https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf';
      case AutoDLModels.mistral7bV03Instruct:
        return 'https://huggingface.co/bartowski/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/Mistral-7B-Instruct-v0.3-Q4_K_M.gguf';
      case AutoDLModels.mistralNemo2407:
        return 'https://huggingface.co/bartowski/Mistral-Nemo-Instruct-2407-GGUF/resolve/main/Mistral-Nemo-Instruct-2407-Q4_K_M.gguf';
      case AutoDLModels.phi35MiniInstruct:
        return 'https://huggingface.co/bartowski/Phi-3.5-mini-instruct-GGUF/resolve/main/Phi-3.5-mini-instruct-Q4_K_M.gguf';
      case AutoDLModels.stablelmZephyr3b:
        return 'https://huggingface.co/TheBloke/stablelm-zephyr-3b-GGUF/resolve/main/stablelm-zephyr-3b.Q4_K_M.gguf';
      case AutoDLModels.tinyDolphin:
        return 'https://huggingface.co/tsunemoto/TinyDolphin-2.8-1.1b-GGUF/resolve/main/tinydolphin-2.8-1.1b.Q4_K_M.gguf';
      default:
        return 'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf';
    }
  }

  String getModelFilename() {
    switch (this) {
      case AutoDLModels.gemma2bInstruct:
        return 'gemma-2-2b-it-Q4_K_M.gguf';
      case AutoDLModels.gemma9bInstruct:
        return 'gemma-2-9b-it-Q4_K_M.gguf';
      case AutoDLModels.llama31V8bInstruct:
        return 'Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf';
      case AutoDLModels.mistral7bV03Instruct:
        return 'Mistral-7B-Instruct-v0.3-Q4_K_M.gguf';
      case AutoDLModels.mistralNemo2407:
        return 'Mistral-Nemo-Instruct-2407-Q4_K_M.gguf';
      case AutoDLModels.phi35MiniInstruct:
        return 'Phi-3.5-mini-instruct-Q4_K_M.gguf';
      case AutoDLModels.stablelmZephyr3b:
        return 'stablelm-zephyr-3b.Q4_K_M.gguf';
      case AutoDLModels.tinyDolphin:
        return 'tinydolphin-2.8-1.1b.Q4_K_M.gguf';
      default:
        return 'tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf';
    }
  }

  Future<ConfigModelSettings> getDefaultModelSettings() async {
    final modelFolderpath = await ConfigModelFiles.getModelsFolderpath();
    final filepath = isRunningOnDesktop()
        ? p.join(modelFolderpath, getModelFilename())
        : getModelFilename();
    switch (this) {
      case AutoDLModels.gemma2bInstruct:
        return ConfigModelSettings(
            filepath, 100, 8192, null, null, true, false, false, 'gemma');
      case AutoDLModels.gemma9bInstruct:
        return ConfigModelSettings(
            filepath, 100, 8192, null, null, true, false, false, 'gemma');
      case AutoDLModels.llama31V8bInstruct:
        return ConfigModelSettings(
            filepath, 100, 8192, null, null, true, false, true, 'llama3');
      case AutoDLModels.mistral7bV03Instruct:
        return ConfigModelSettings(filepath, 100, 8192, null, null, true, false,
            true, 'mistralInstruct');
      case AutoDLModels.mistralNemo2407:
        return ConfigModelSettings(filepath, 100, 8192, null, null, true, false,
            true, 'mistralInstruct');
      case AutoDLModels.phi35MiniInstruct:
        return ConfigModelSettings(
            filepath, 100, 8192, null, null, true, false, true, 'phi3');
      case AutoDLModels.stablelmZephyr3b:
        return ConfigModelSettings(
            filepath, 100, 4096, null, null, true, false, true, 'zephyr');
      case AutoDLModels.tinyDolphin:
        return ConfigModelSettings(
            filepath, 100, 4096, null, null, true, false, true, 'chatml');
      default:
        return ConfigModelSettings(
            filepath, 100, 2048, null, null, true, false, true, 'tinyllama');
    }
  }
}

AutoDLModels autoDLModelFromString(String stringValue) {
  return AutoDLModels.values
      .firstWhere((style) => style.nameAsString() == stringValue);
}

class ModelImportPage extends StatefulWidget {
  final bool isMobile;
  final void Function(ConfigModelFiles) onNewConfigModelFiles;

  const ModelImportPage(
      {super.key, required this.isMobile, required this.onNewConfigModelFiles});

  @override
  State<ModelImportPage> createState() => _ModelImportPageState();
}

class _ModelImportPageState extends State<ModelImportPage> {
  late String selectedAutoDLOption;
  late List<String> autoDLOptions;

  bool copyingSelectedModel = false;
  bool downloadingModel = false;
  double downloadModelProgress = 0.0;

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

  Widget buildInnerContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        const Text(
            'MindMeld needs a large language model ("LLM") neural net file in order to function. These files can be downloaded manually beforehand and then imported here.'),
        const SizedBox(height: 16),
        FilledButton(
          child: const Text('Import AI GGUF Model File'),
          onPressed: () async {
            try {
              setState(() {
                copyingSelectedModel = true;
              });

              FilePickerResult? result = await FilePicker.platform.pickFiles(
                  dialogTitle: "Load LLM File",
                  type: FileType.any,
                  allowMultiple: false,
                  allowCompression: false);
              if (result != null) {
                // get the selected filepath
                var selectedModelFilepath = result.files.first.path!;
                final selectedModelFilename = p.basename(selectedModelFilepath);

                // on mobile we have to copy the file to the application's documents
                // for the application to use it. sandboxing rules and all of that...
                if (widget.isMobile) {
                  await ConfigModelFiles.ensureModelsFolderExists();
                  final modelFolderpath =
                      await ConfigModelFiles.getModelsFolderpath();
                  final copyModelFilepath =
                      p.join(modelFolderpath, selectedModelFilename);
                  var originalFile = File(selectedModelFilepath);
                  await originalFile.copy(copyModelFilepath);
                  log("Copy source: $selectedModelFilepath");
                  log("Copy deset : $copyModelFilepath");
                  await FilePicker.platform.clearTemporaryFiles();
                  log("Temporary files have been cleared");

                  // update the model filepath to use to point to our copy
                  // and use a relative path ... which is actually just the filename
                  selectedModelFilepath = selectedModelFilename;
                }

                // build a new models configuration file. we no longer use the fullc
                // filepath for the file and instead just use the relative one based
                // on filename and our known models folder.
                final configModelFiles = ConfigModelFiles(modelFiles: {
                  selectedModelFilename: ConfigModelSettings(
                      selectedModelFilepath,
                      100,
                      null,
                      null,
                      null,
                      true,
                      false,
                      true,
                      null)
                });

                log("JSON for ModelFiles: ${ConfigModelFiles.getFilepath()}");
                final configModelFilesJson = configModelFiles.toJson();
                log(configModelFilesJson);

                // send the new data file over the callback.
                widget.onNewConfigModelFiles(configModelFiles);
              }
            } catch (e) {
              log("Got an error while trying to copy the new model file into the application's document folder: $e");
            } finally {
              setState(() {
                copyingSelectedModel = false;
              });
            }
          },
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 32),
        const Text(
            "If you don't know what file to download, MindMeld can download one of these automatically for you instead. These will be large files and you may want to make sure to have a WiFi connection!"),
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
          onPressed: () async {
            setState(() {
              downloadingModel = true;
              downloadModelProgress = 0.0;
            });
            // download the model from the internet
            try {
              var selectedAutoOpt = autoDLModelFromString(selectedAutoDLOption);

              final dlTask = DownloadTask(
                url: selectedAutoOpt.getModelURL(),
                filename: selectedAutoOpt.getModelFilename(),
                baseDirectory: BaseDirectory.root,
                directory: await ConfigModelFiles.getModelsFolderpath(),
                updates: Updates.progress,
              );

              final result = await FileDownloader().download(
                dlTask,
                onProgress: (progress) {
                  setState(() {
                    downloadModelProgress = progress;
                  });
                  log("Download progress: $downloadModelProgress");
                },
              );
              log('download finished! (${result.status})');

              // TODO: This segment is copied from above; refactor
              // build a new models configuration file. we no longer use the full
              // filepath for the file and instead just use the relative one based
              // on filename and our known models folder.
              final configModelFiles = ConfigModelFiles(modelFiles: {
                selectedAutoOpt.getModelFilename():
                    await selectedAutoOpt.getDefaultModelSettings()
              });

              log("JSON for ModelFiles: ${ConfigModelFiles.getFilepath()}");
              final configModelFilesJson = configModelFiles.toJson();
              log(configModelFilesJson);

              // send the new data file over the callback.
              widget.onNewConfigModelFiles(configModelFiles);
            } finally {
              setState(() {
                downloadingModel = false;
              });
            }
          },
        ),
      ]),
    );
  }

  Widget buildCopingWidgets(BuildContext context) {
    return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
              'Copying model file into the application. This should only take a few seconds...'),
        ));
  }

  Widget buildDownloadingWidgets(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text(
                  'Downloading GGUF file: ${(downloadModelProgress * 100.0).toStringAsFixed(2)}%',
                  style: const TextStyle(fontSize: 20)),
              LinearProgressIndicator(
                value: downloadModelProgress,
                semanticsLabel: 'download progress',
              )
            ]));
  }

  @override
  Widget build(BuildContext context) {
    const String pageName = 'Model Import';

    // the mobile version of the widget has a scaffold built into it
    if (widget.isMobile) {
      if (copyingSelectedModel) {
        return Scaffold(
            appBar: AppBar(title: const Text(pageName)),
            body: buildCopingWidgets(context));
      } else if (downloadingModel) {
        return Scaffold(
            appBar: AppBar(title: const Text(pageName)),
            body: buildDownloadingWidgets(context));
      } else {
        return Scaffold(
            appBar: AppBar(title: const Text(pageName)),
            body: buildInnerContent(context));
      }
    } else {
      if (copyingSelectedModel) {
        return const Column(children: [
          Center(child: Text(pageName, style: TextStyle(fontSize: 24))),
          SizedBox(height: 8),
          Divider(),
          Padding(
              padding: EdgeInsets.all(20),
              child: Text('Select a GGUF file to use...')),
        ]);
      } else if (downloadingModel) {
        return Column(children: [
          const Center(child: Text(pageName, style: TextStyle(fontSize: 24))),
          const SizedBox(height: 8),
          const Divider(),
          Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                  'Downloading GGUF file: ${(downloadModelProgress * 100.0).toStringAsFixed(2)}%',
                  style: const TextStyle(fontSize: 20))),
        ]);
      } else {
        return Column(
          children: [
            const Center(child: Text(pageName, style: TextStyle(fontSize: 24))),
            const SizedBox(height: 8),
            const Divider(),
            buildInnerContent(context)
          ],
        );
      }
    }
  }
}
