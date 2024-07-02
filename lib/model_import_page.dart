import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'dart:developer';

import 'config_models.dart';

enum AutoDLModels { opusV12Llama3_8B, tinyllama }

extension AutoDLModelsExtension on AutoDLModels {
  String nameAsString() {
    switch (this) {
      case AutoDLModels.opusV12Llama3_8B:
        return 'Opus-v1.2-llama-3-8b';
      default:
        return 'TinyLlama-1.1B-Chat-v1.0';
    }
  }

  String getModelURL() {
    switch (this) {
      case AutoDLModels.opusV12Llama3_8B:
        return 'https://huggingface.co/mradermacher/opus-v1.2-llama-3-8b-instruct-run3.5-epoch2.5-GGUF/resolve/main/opus-v1.2-llama-3-8b-instruct-run3.5-epoch2.5.IQ4_XS.gguf';
      default:
        return 'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf';
    }
  }

  String getModelFilename() {
    switch (this) {
      case AutoDLModels.opusV12Llama3_8B:
        return 'opus-v1.2-llama-3-8b-instruct-run3.5-epoch2.5.IQ4_XS.gguf';
      default:
        return 'tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf';
    }
  }

  ConfigModelSettings getDefaultModelSettings() {
    switch (this) {
      case AutoDLModels.opusV12Llama3_8B:
        return ConfigModelSettings(
            100, null, null, null, true, false, true, 'opusV12');
      default:
        return ConfigModelSettings(
            100, null, null, null, true, false, true, 'tinyllama');
    }
  }
}

AutoDLModels autoDLModelFromString(String stringValue) {
  return AutoDLModels.values
      .firstWhere((style) => style.nameAsString() == stringValue);
}

class ModelImportPage extends StatefulWidget {
  final void Function(ConfigModelFiles) onNewConfigModelFiles;

  const ModelImportPage({super.key, required this.onNewConfigModelFiles});

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

  @override
  Widget build(BuildContext context) {
    if (copyingSelectedModel) {
      return Scaffold(
          appBar: AppBar(title: const Text('Model Import')),
          body: const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                    'Copying model file into the application. This should only take a few seconds...'),
              )));
    } else if (downloadingModel) {
      return Scaffold(
          appBar: AppBar(title: const Text('Model Import')),
          body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    const Text(
                        'Downloading the selected model file into the application.',
                        style: TextStyle(fontSize: 20)),
                    LinearProgressIndicator(
                      value: downloadModelProgress,
                      semanticsLabel: 'download progress',
                    )
                  ])));
    } else {
      return Scaffold(
          appBar: AppBar(title: const Text('Model Import')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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

                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(
                                dialogTitle: "Load LLM File",
                                type: FileType.any,
                                allowMultiple: false,
                                allowCompression: false);
                        if (result != null) {
                          // get the selected filepath
                          final selectedModelFilepath =
                              result.files.first.path!;
                          final selectedModelFilename =
                              p.basename(selectedModelFilepath);

                          // copy the file to the application's documents
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

                          // build a new models configuration file. we no longer use the full
                          // filepath for the file and instead just use the relative one based
                          // on filename and our known models folder.
                          final configModelFiles =
                              ConfigModelFiles(modelFiles: {
                            selectedModelFilename: ConfigModelSettings(
                                100, null, null, null, true, false, true, null)
                          });

                          log("JSON for ModelFiles: ${ConfigModelFiles.getFilepath()}");
                          final configModelFilesJson =
                              configModelFiles.toJson();
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
                        .map((option) =>
                            DropdownMenuEntry(value: option, label: option))
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
                        var selectedAutoOpt =
                            autoDLModelFromString(selectedAutoDLOption);

                        final dlTask = DownloadTask(
                          url: selectedAutoOpt.getModelURL(),
                          filename: selectedAutoOpt.getModelFilename(),
                          directory: 'models',
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
                              selectedAutoOpt.getDefaultModelSettings()
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
          ));
    }
  }
}
