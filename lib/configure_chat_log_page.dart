import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mindmeld/config_models.dart';
import 'package:mindmeld/model_import_page.dart';
import 'package:mindmeld/platform_and_theming.dart';
import 'package:profile_photo/profile_photo.dart';
import 'package:path/path.dart' as p;

import 'chat_log.dart';

class ConfigureChatLogPage extends StatefulWidget {
  final ChatLog chatLog;
  final ConfigModelFiles configModelFiles;
  final bool isFullPage;

  const ConfigureChatLogPage(
      {super.key,
      required this.isFullPage,
      required this.chatLog,
      required this.configModelFiles});

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

  final hpNewTokensController = TextEditingController();
  final hpTempController = TextEditingController();
  final hpTopKController = TextEditingController();
  final hpTopPController = TextEditingController();
  final hpMinPController = TextEditingController();
  final hpXtcProbController = TextEditingController();
  final hpXtcThreshController = TextEditingController();
  final hpDynatempRangeController = TextEditingController();
  final hpDynatempExpoController = TextEditingController();
  final hpTypicalPController = TextEditingController();
  final hpTFSController = TextEditingController();
  final hpRepPenController = TextEditingController();
  final hpRepPenRangeController = TextEditingController();
  final hpFreqPenController = TextEditingController();
  final hpPresencePenController = TextEditingController();
  final hpDryMultiController = TextEditingController();
  final hpDryBaseController = TextEditingController();
  final hpDryLengthController = TextEditingController();
  final hpDryPenaltyController = TextEditingController();
  final hpSeedController = TextEditingController();

  late List<String> modelFileOptions;
  late List<String> promptFormatOptions;
  final modelGpuLayersController = TextEditingController();
  final modelContextSizeController = TextEditingController();
  final modelThreadCountController = TextEditingController();
  final modelBatchSizeController = TextEditingController();

  var currentPageIndex = 0;

  @override
  void dispose() {
    userNameController.dispose();
    userDescController.dispose();
    aiNameController.dispose();
    aiDescController.dispose();
    aiPersonalityController.dispose();
    storyContextController.dispose();

    hpNewTokensController.dispose();
    hpTempController.dispose();
    hpTopKController.dispose();
    hpTopPController.dispose();
    hpMinPController.dispose();
    hpXtcProbController.dispose();
    hpXtcThreshController.dispose();
    hpDynatempRangeController.dispose();
    hpDynatempExpoController.dispose();
    hpTypicalPController.dispose();
    hpTFSController.dispose();
    hpRepPenController.dispose();
    hpRepPenRangeController.dispose();
    hpFreqPenController.dispose();
    hpPresencePenController.dispose();
    hpDryMultiController.dispose();
    hpDryBaseController.dispose();
    hpDryLengthController.dispose();
    hpDryPenaltyController.dispose();
    hpSeedController.dispose();

    modelGpuLayersController.dispose();
    modelContextSizeController.dispose();
    modelThreadCountController.dispose();
    modelBatchSizeController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    var humanCharacter = widget.chatLog.getHumanCharacter();
    var aiCharacter = widget.chatLog.getAICharacter();
    assert(humanCharacter != null);
    assert(aiCharacter != null);

    userNameController.text = humanCharacter?.name ?? "";
    userDescController.text = humanCharacter?.description ?? "";
    aiNameController.text = aiCharacter?.name ?? "";
    aiDescController.text = aiCharacter?.description ?? "";
    aiPersonalityController.text = aiCharacter?.personality ?? "";
    storyContextController.text = widget.chatLog.context;

    hpNewTokensController.text =
        widget.chatLog.hyperparmeters.tokens.toString();
    hpTempController.text = widget.chatLog.hyperparmeters.temp.toString();
    hpTopKController.text = widget.chatLog.hyperparmeters.topK.toString();
    hpTopPController.text = widget.chatLog.hyperparmeters.topP.toString();
    hpMinPController.text = widget.chatLog.hyperparmeters.minP.toString();
    hpXtcProbController.text =
        widget.chatLog.hyperparmeters.xtcProbability.toString();
    hpXtcThreshController.text =
        widget.chatLog.hyperparmeters.xtcThreshold.toString();
    hpDynatempRangeController.text =
        widget.chatLog.hyperparmeters.dynatempRange.toString();
    hpDynatempExpoController.text =
        widget.chatLog.hyperparmeters.dynatempExponent.toString();
    hpTypicalPController.text =
        widget.chatLog.hyperparmeters.typicalP.toString();
    hpTFSController.text = widget.chatLog.hyperparmeters.tfsZ.toString();
    hpRepPenController.text =
        widget.chatLog.hyperparmeters.repeatPenalty.toString();
    hpRepPenRangeController.text =
        widget.chatLog.hyperparmeters.repeatLastN.toString();
    hpFreqPenController.text =
        widget.chatLog.hyperparmeters.frequencyPenalty.toString();
    hpPresencePenController.text =
        widget.chatLog.hyperparmeters.presencePenalty.toString();
    hpDryMultiController.text =
        widget.chatLog.hyperparmeters.dryMultiplier.toString();
    hpDryBaseController.text = widget.chatLog.hyperparmeters.dryBase.toString();
    hpDryLengthController.text =
        widget.chatLog.hyperparmeters.dryAllowedLength.toString();
    hpDryPenaltyController.text =
        widget.chatLog.hyperparmeters.dryPenaltyLastN.toString();
    hpSeedController.text = widget.chatLog.hyperparmeters.seed.toString();

    // build the data for the model dropdown to select already imported models
    modelFileOptions = widget.configModelFiles.modelFiles.keys.toList();
    promptFormatOptions =
        ModelPromptStyle.values.map((v) => v.nameAsString()).toList();

    var currentModelConfig =
        widget.configModelFiles.modelFiles[widget.chatLog.modelName];
    if (currentModelConfig == null) {
      if (widget.configModelFiles.modelFiles.isNotEmpty) {
        var firstInConfig = widget.configModelFiles.modelFiles.entries.first;
        currentModelConfig = firstInConfig.value;
        widget.chatLog.modelName = firstInConfig.key;
      }
    } else {
      modelGpuLayersController.text = currentModelConfig.gpuLayers.toString();
      if (currentModelConfig.contextSize != null) {
        modelContextSizeController.text =
            currentModelConfig.contextSize.toString();
      }
      if (currentModelConfig.threadCount != null) {
        modelThreadCountController.text =
            currentModelConfig.threadCount.toString();
      }
      if (currentModelConfig.batchSize != null) {
        modelBatchSizeController.text = currentModelConfig.batchSize.toString();
      }
    }
  }

  void _doUpdateToSelectedModel(String? value) {
    if (value == null) {
      return;
    }
    var newConfig = widget.configModelFiles.modelFiles[value];
    setState(() {
      // we change the link to the model in the chatlog
      widget.chatLog.modelName = value;

      // and then update all the controllers for the selected model's configuration settings
      modelGpuLayersController.text =
          newConfig?.gpuLayers != null ? newConfig!.gpuLayers.toString() : '';
      modelContextSizeController.text = newConfig?.contextSize != null
          ? newConfig!.contextSize.toString()
          : '';
      modelThreadCountController.text = newConfig?.threadCount != null
          ? newConfig!.threadCount.toString()
          : '';
      modelBatchSizeController.text =
          newConfig?.batchSize != null ? newConfig!.batchSize.toString() : '';
    });
  }

  Future<bool?> _showConfirmDeleteModelDialog(String modelName) async {
    return showDialog<bool?>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete model?'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Would you like to remove "$modelName"?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildModelPage(BuildContext context) {
    final currentModelName = widget.chatLog.modelName;
    final currentModelConfig =
        widget.configModelFiles.modelFiles[currentModelName];
    Widget innerConntent(BuildContext context) {
      return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        ListTile(
            leading: const Icon(Icons.psychology),
            title: Row(children: [
              const Text('Model:'),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownMenu(
                  width: widget.isFullPage ? 210 : 410,
                  initialSelection: widget.chatLog.modelName,
                  dropdownMenuEntries: modelFileOptions
                      .map((option) => DropdownMenuEntry(
                          value: option,
                          label: option,
                          labelWidget: Text(
                            option,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )))
                      .toList(),
                  onSelected: (String? value) {
                    _doUpdateToSelectedModel(value);
                  },
                ),
              ),
            ])),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(right: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Tooltip(
                message: 'Import a new GGUF model file',
                child: FilledButton(
                  child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Icon(Icons.add), Text('Import')]),
                  onPressed: () async {
                    newConfigCallback(newConfigModelFiles) {
                      setState(() {
                        // update our own modelFiles with the new data
                        var key = newConfigModelFiles.modelFiles.keys.first;
                        var value = newConfigModelFiles.modelFiles[key]!;
                        widget.configModelFiles.modelFiles[key] = value;

                        // build the data for the model dropdown to select already imported models
                        modelFileOptions =
                            widget.configModelFiles.modelFiles.keys.toList();

                        // update the chatlog to use it
                        widget.chatLog.modelName = key;

                        // finally, save out the new config file
                        widget.configModelFiles
                            .saveJsonToConfigFile()
                            .then((_) {
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                          _doUpdateToSelectedModel(key);
                        });
                      });
                    }

                    if (widget.isFullPage) {
                      // move to model import page
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ModelImportPage(
                                  isMobile: widget.isFullPage,
                                  onNewConfigModelFiles: newConfigCallback)));
                    } else {
                      await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                                alignment: AlignmentDirectional.topCenter,
                                child: Container(
                                    constraints: const BoxConstraints.tightFor(
                                      width: 600,
                                    ),
                                    child: SingleChildScrollView(
                                        child: ModelImportPage(
                                            isMobile: false,
                                            onNewConfigModelFiles:
                                                newConfigCallback))));
                          });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Remove selected GGUF model',
                child: FilledButton(
                  child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Icon(Icons.remove), Text('Remove')]),
                  onPressed: () async {
                    final currentModelName = widget.chatLog.modelName;
                    final shouldDelete =
                        await _showConfirmDeleteModelDialog(currentModelName);
                    if (shouldDelete != null && shouldDelete == true) {
                      final currentModelConfig =
                          widget.configModelFiles.modelFiles[currentModelName];
                      final currentModelFilepath =
                          currentModelConfig?.modelFilepath;
                      if (currentModelFilepath == null) return;

                      // if we're using a relative path under our models folder, actually
                      // delete the file because we consider it 'ours' and managed. Other
                      // file paths are not managed by the app and we should therefore
                      // just remove the lhe entry in our model configs file.
                      log('Removing model filepath: $currentModelFilepath');
                      final appModelFolder =
                          await ConfigModelFiles.getModelsFolderpath();
                      if (p.isWithin(appModelFolder, currentModelFilepath)) {
                        var f = File(currentModelFilepath);
                        if (await f.exists()) {
                          await f.delete();
                          log('Model was deleted on the filesystem: $currentModelFilepath');
                        }
                      } else if (p.isRelative(currentModelFilepath)) {
                        var f =
                            File(p.join(appModelFolder, currentModelFilepath));
                        if (await f.exists()) {
                          f.delete();
                          log('Model was deleted on the filesystem: $currentModelFilepath');
                        }
                      }
                      setState(() {
                        widget.configModelFiles.modelFiles
                            .remove(currentModelName);
                        log('Model was removed from collection: $currentModelName');

                        // select the first model remaining
                        final otherModels =
                            widget.configModelFiles.modelFiles.keys;
                        _doUpdateToSelectedModel(
                            otherModels.isNotEmpty ? otherModels.first : '');

                        // and update the drop down box options
                        modelFileOptions =
                            widget.configModelFiles.modelFiles.keys.toList();
                      });

                      // finally, save all of this out to file since the model may
                      // have fully been deleted from the filesystem.
                      await widget.configModelFiles.saveJsonToConfigFile();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.engineering),
          title: Row(children: [
            const Text('Prompt Style:'),
            const SizedBox(width: 16),
            Flexible(
              child: DropdownMenu(
                initialSelection:
                    widget.chatLog.modelPromptStyle.nameAsString(),
                dropdownMenuEntries: promptFormatOptions
                    .map((option) => DropdownMenuEntry(
                        value: option,
                        label: option,
                        labelWidget: Text(
                          option,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )))
                    .toList(),
                onSelected: (value) {
                  setState(() {
                    widget.chatLog.modelPromptStyle =
                        modelPromptStyleFromString(value!);
                  });
                },
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        ListTile(
            leading: const Icon(Icons.list),
            title: TextField(
              controller: modelGpuLayersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "GPU Layers",
              ),
              onChanged: (text) {
                var currentModelConfig = widget
                    .configModelFiles.modelFiles[widget.chatLog.modelName]!;
                currentModelConfig.gpuLayers = int.tryParse(text) ?? 0;
              },
            )),
        //const SizedBox(height: 8),
        ListTile(
            leading: const Icon(Icons.list),
            title: TextField(
              controller: modelContextSizeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Context Size",
              ),
              onChanged: (text) {
                var currentModelConfig = widget
                    .configModelFiles.modelFiles[widget.chatLog.modelName]!;
                currentModelConfig.contextSize =
                    text.isEmpty ? null : int.tryParse(text);
              },
            )),
        //const SizedBox(height: 8),
        ListTile(
            leading: const Icon(Icons.list),
            title: TextField(
              controller: modelThreadCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Thread Count",
              ),
              onChanged: (text) {
                var currentModelConfig = widget
                    .configModelFiles.modelFiles[widget.chatLog.modelName]!;
                currentModelConfig.threadCount =
                    text.isEmpty ? null : int.tryParse(text);
              },
            )),
        //const SizedBox(height: 8),
        ListTile(
            leading: const Icon(Icons.list),
            title: TextField(
              controller: modelBatchSizeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Batch Size",
              ),
              onChanged: (text) {
                var currentModelConfig = widget
                    .configModelFiles.modelFiles[widget.chatLog.modelName]!;
                currentModelConfig.batchSize =
                    text.isEmpty ? null : int.tryParse(text);
              },
            )),
        //const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Flash Attention'),
          value: currentModelConfig!.flashAttention,
          onChanged: (bool? value) {
            if (value != null) {
              setState(() {
                currentModelConfig.flashAttention = value;
              });
            }
          },
        ),
        //const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Ignore EOS'),
          value: currentModelConfig.ignoreEos,
          onChanged: (bool? value) {
            if (value != null) {
              setState(() {
                currentModelConfig.ignoreEos = value;
              });
            }
          },
        ),
        //const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Cache Prompt'),
          value: currentModelConfig.promptCache,
          onChanged: (bool? value) {
            if (value != null) {
              setState(() {
                currentModelConfig.promptCache = value;
              });
            }
          },
        )
      ]);
    }

    return Padding(
        padding: const EdgeInsets.all(16),
        child: widget.isFullPage
            ? SingleChildScrollView(child: innerConntent(context))
            : innerConntent(context));
  }

  // this function will remove any profile pic for the character and on
  // mobile it will delete the file
  Future<void> _eraseProfilePic(ChatLogCharacter character) async {
    if (!isRunningOnDesktop()) {
      if (character.profilePicFilename != null) {
        if (!p.isAbsolute(character.profilePicFilename!)) {
          var pfpDir = await ChatLog.getProfilePicsFolder();
          var pfpRelativeFilepath =
              p.join(pfpDir, character.profilePicFilename!);
          File pfpFile = File(pfpRelativeFilepath);
          if (await pfpFile.exists()) {
            await pfpFile.delete();
            log('Deleted profile picture file: $pfpRelativeFilepath');
          }
        }
      }
    }
    setState(() {
      character.profilePicFilename = null;
    });
  }

  void _browseforNewProfilePic(ChatLogCharacter character) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: "Pick a new profile picture",
        type: FileType.image,
        allowMultiple: false,
        allowCompression: true);
    if (result != null) {
      var selectedPfpFilepath = result.files.first.path!;
      final selectedPfpFilename = p.basename(selectedPfpFilepath);
      log("new profile picture selected: $selectedPfpFilepath");

      // if we're running on mobile, we're going to have to make a copy of it
      if (widget.isFullPage) {
        await ChatLog.ensureProfilePicsFolderExists();
        final pfpFolderpath = await ChatLog.getProfilePicsFolder();
        final copyPfpFilepath = p.join(pfpFolderpath, selectedPfpFilename);

        final originalFile = File(selectedPfpFilepath);
        await originalFile.copy(copyPfpFilepath);
        log("Copy source: $selectedPfpFilepath");
        log("Copy deset : $copyPfpFilepath");
        await FilePicker.platform.clearTemporaryFiles();
        log("Temporary files have been cleared");

        // update the model filepath to use to point to our copy
        // and use a relative path ... which is actually just the filename
        selectedPfpFilepath = selectedPfpFilename;
      }

      setState(() {
        character.profilePicFilename = selectedPfpFilepath;
      });
    }
  }

  Widget _buildCharactersPage(BuildContext context) {
    var humanCharacter = widget.chatLog.getHumanCharacter()!;
    var aiCharacter = widget.chatLog.getAICharacter()!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ListTile(
            title: TextField(
              controller: storyContextController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Story Context",
              ),
              onChanged: (text) {
                widget.chatLog.context = text;
              },
            ),
          ),
          Row(children: [
            FutureBuilder(
                future: humanCharacter.getEffectiveProfilePic(),
                builder: (BuildContext context,
                    AsyncSnapshot<ImageProvider<Object>> snapshot) {
                  if (snapshot.hasData) {
                    return ProfilePhoto(
                      totalWidth: 96,
                      color: Colors.transparent,
                      outlineColor: Colors.transparent,
                      image: snapshot.data,
                      onTap: () {
                        _browseforNewProfilePic(humanCharacter);
                      },
                      onLongPress: () {
                        _eraseProfilePic(humanCharacter);
                      },
                    );
                  } else {
                    return ProfilePhoto(
                      totalWidth: 96,
                      color: Colors.transparent,
                      outlineColor: Colors.transparent,
                    );
                  }
                }),
            Expanded(
              child: Column(children: [
                ListTile(
                  title: TextField(
                    controller: userNameController,
                    decoration: const InputDecoration(
                      labelText: "Your Name",
                    ),
                    onChanged: (text) {
                      humanCharacter.name = text;
                    },
                  ),
                  subtitle: TextField(
                    controller: userDescController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Your Description",
                    ),
                    onChanged: (text) {
                      humanCharacter.description = text;
                    },
                  ),
                ),
              ]),
            ),
          ]),
          const Divider(),
          Row(
            children: [
              FutureBuilder(
                  future: aiCharacter.getEffectiveProfilePic(),
                  builder: (BuildContext context,
                      AsyncSnapshot<ImageProvider<Object>> snapshot) {
                    if (snapshot.hasData) {
                      return ProfilePhoto(
                        totalWidth: 96,
                        color: Colors.transparent,
                        outlineColor: Colors.transparent,
                        image: snapshot.data,
                        onTap: () {
                          _browseforNewProfilePic(aiCharacter);
                        },
                        onLongPress: () {
                          _eraseProfilePic(aiCharacter);
                        },
                      );
                    } else {
                      return ProfilePhoto(
                        totalWidth: 96,
                        color: Colors.transparent,
                        outlineColor: Colors.transparent,
                      );
                    }
                  }),
              Expanded(
                child: Column(children: [
                  ListTile(
                    title: TextField(
                      controller: aiNameController,
                      decoration: const InputDecoration(
                        labelText: "AI Name",
                      ),
                      onChanged: (text) {
                        aiCharacter.name = text;
                      },
                    ),
                    subtitle: TextField(
                      controller: aiDescController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "AI Description",
                      ),
                      onChanged: (text) {
                        aiCharacter.description = text;
                      },
                    ),
                  ),
                  ListTile(
                    title: TextField(
                      controller: aiPersonalityController,
                      decoration: const InputDecoration(
                        labelText: "AI Personality",
                      ),
                      onChanged: (text) {
                        aiCharacter.personality = text;
                      },
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParametersPage(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWidescreen = constraints.maxWidth > 400;
      final children = [
        ListTile(
            leading: const Icon(Icons.manage_search),
            title: TextField(
              controller: hpNewTokensController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "New Tokens",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.tokens = int.tryParse(text) ?? 64;
              },
            )),
        ListTile(
            leading: const Icon(Icons.thermostat),
            title: TextField(
              controller: hpTempController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Temperature",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.temp =
                    double.tryParse(text) ?? 0.8;
              },
            )),
        ListTile(
            leading: const Icon(Icons.list),
            title: TextField(
              controller: hpTopKController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Top-K",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.topK = int.tryParse(text) ?? 40;
              },
            )),
        ListTile(
            leading: const Icon(Icons.sort),
            title: TextField(
              controller: hpTopPController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Top-P",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.topP =
                    (double.tryParse(text) ?? 0.9).clamp(0.0, 1.0);
              },
            )),
        ListTile(
            leading: const Icon(Icons.short_text),
            title: TextField(
              controller: hpMinPController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Min-P",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.minP =
                    (double.tryParse(text) ?? 0.05).clamp(0.0, 1.0);
              },
            )),
        ListTile(
            leading: const Icon(Icons.thumbs_up_down),
            title: TextField(
              controller: hpTypicalPController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Typical-P",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.typicalP =
                    (double.tryParse(text) ?? 1.0).clamp(0.0, 1.0);
              },
            )),
        ListTile(
            leading: const Icon(Icons.not_interested),
            title: TextField(
              controller: hpDryMultiController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "DRY Multiplier",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.dryMultiplier =
                    double.tryParse(text) ?? 0.0;
              },
            )),
        ListTile(
            leading: const Icon(Icons.not_interested),
            title: TextField(
              controller: hpDryBaseController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "DRY Base",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.dryBase =
                    double.tryParse(text) ?? 0.0;
              },
            )),
        ListTile(
            leading: const Icon(Icons.not_interested),
            title: TextField(
              controller: hpDryLengthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "DRY Allowed Length",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.dryAllowedLength =
                    int.tryParse(text) ?? 2;
              },
            )),
        ListTile(
            leading: const Icon(Icons.not_interested),
            title: TextField(
              controller: hpDryPenaltyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "DRY Penalty Range",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.dryPenaltyLastN =
                    int.tryParse(text) ?? -1;
              },
            )),
        ListTile(
            leading: const Icon(Icons.storm),
            title: TextField(
              controller: hpDynatempRangeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Dynamic Temp Range",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.dynatempRange =
                    double.tryParse(text) ?? 0.0;
              },
            )),
        ListTile(
            leading: const Icon(Icons.storm),
            title: TextField(
              controller: hpDynatempExpoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Dynamic Temp Exponent",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.dynatempExponent =
                    double.tryParse(text) ?? 1.0;
              },
            )),
        ListTile(
            leading: const Icon(Icons.alt_route),
            title: TextField(
              controller: hpXtcProbController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "XTC Probability",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.xtcProbability =
                    double.tryParse(text) ?? 0.0;
              },
            )),
        ListTile(
            leading: const Icon(Icons.alt_route),
            title: TextField(
              controller: hpXtcThreshController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "XTC Threshold",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.xtcThreshold =
                    double.tryParse(text) ?? 0.1;
              },
            )),
        ListTile(
            leading: const Icon(Icons.trending_down),
            title: TextField(
              keyboardType: TextInputType.number,
              controller: hpTFSController,
              decoration: const InputDecoration(
                labelText: "Tail Free Sampling",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.tfsZ =
                    (double.tryParse(text) ?? 1.0).clamp(0.0, 1.0);
              },
            )),
        ListTile(
            leading: const Icon(Icons.filter_list_off),
            title: TextField(
              controller: hpRepPenController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Repeat Penalty",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.repeatPenalty =
                    double.tryParse(text) ?? 1.1;
              },
            )),
        ListTile(
            leading: const Icon(Icons.settings_ethernet),
            title: TextField(
              controller: hpRepPenRangeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Repeat Range",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.repeatLastN =
                    int.tryParse(text) ?? 64;
              },
            )),
        ListTile(
            leading: const Icon(Icons.filter_list_off),
            title: TextField(
              controller: hpFreqPenController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Frequency Penalty",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.frequencyPenalty =
                    (double.tryParse(text) ?? 0.0).clamp(0.0, 1.0);
              },
            )),
        ListTile(
            leading: const Icon(Icons.filter_list_off),
            title: TextField(
              controller: hpPresencePenController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Presence Penalty",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.presencePenalty =
                    (double.tryParse(text) ?? 0.0).clamp(0.0, 1.0);
              },
            )),
        ListTile(
            leading: const Icon(Icons.casino),
            title: TextField(
              controller: hpSeedController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Seed",
              ),
              onChanged: (text) {
                widget.chatLog.hyperparmeters.seed = int.tryParse(text) ?? -1;
              },
            )),
      ];
      return Padding(
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(
            child: isWidescreen
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: children.sublist(0, children.length ~/ 2),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: children.sublist(children.length ~/ 2),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: children,
                  ),
          ));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFullPage) {
      // the full page version returns a scaffold with a nav bar
      return Scaffold(
          appBar: AppBar(title: const Text('Chat Configuration')),
          bottomNavigationBar: NavigationBar(
            onDestinationSelected: (int index) {
              setState(() {
                currentPageIndex = index;
              });
            },
            selectedIndex: currentPageIndex,
            destinations: const <Widget>[
              NavigationDestination(
                selectedIcon: Icon(Icons.person),
                icon: Icon(Icons.person_outlined),
                label: 'Characters',
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.tune),
                icon: Icon(Icons.tune_outlined),
                label: 'Parameters',
              ),
              NavigationDestination(
                selectedIcon: Icon(Icons.psychology),
                icon: Icon(Icons.psychology_outlined),
                label: 'Model',
              ),
            ],
          ),
          body: <Widget>[
            _buildCharactersPage(context),
            _buildParametersPage(context),
            _buildModelPage(context),
          ][currentPageIndex]);
    } else {
      // the widget version returns a column with
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SegmentedButton(
                segments: const <ButtonSegment<int>>[
                  ButtonSegment<int>(value: 0, label: Text('Characters')),
                  ButtonSegment<int>(value: 1, label: Text('Parameters')),
                  ButtonSegment<int>(value: 2, label: Text('Model')),
                ],
                selected: {
                  currentPageIndex
                },
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() {
                    currentPageIndex = newSelection.first;
                  });
                }),
            const SizedBox(height: 8),
            <Widget>[
              _buildCharactersPage(context),
              _buildParametersPage(context),
              _buildModelPage(context),
            ][currentPageIndex],
          ],
        ),
      );
    }
  }
}
