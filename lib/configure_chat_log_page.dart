import 'package:flutter/material.dart';
import 'package:mindmeld/config_models.dart';
import 'package:mindmeld/model_import_page.dart';

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
  final hpTypicalPController = TextEditingController();
  final hpTFSController = TextEditingController();
  final hpRepPenController = TextEditingController();
  final hpRepPenRangeController = TextEditingController();
  final hpFreqPenController = TextEditingController();
  final hpPresencePenController = TextEditingController();
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
    hpTypicalPController.dispose();
    hpTFSController.dispose();
    hpRepPenController.dispose();
    hpRepPenRangeController.dispose();
    hpFreqPenController.dispose();
    hpPresencePenController.dispose();
    hpSeedController.dispose();

    modelGpuLayersController.dispose();
    modelContextSizeController.dispose();
    modelThreadCountController.dispose();
    modelBatchSizeController.dispose();

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

    hpNewTokensController.text =
        widget.chatLog.hyperparmeters.tokens.toString();
    hpTempController.text = widget.chatLog.hyperparmeters.temp.toString();
    hpTopKController.text = widget.chatLog.hyperparmeters.topK.toString();
    hpTopPController.text = widget.chatLog.hyperparmeters.topP.toString();
    hpMinPController.text = widget.chatLog.hyperparmeters.minP.toString();
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
    hpSeedController.text = widget.chatLog.hyperparmeters.seed.toString();

    // build the data for the model dropdown to select already imported models
    modelFileOptions = widget.configModelFiles.modelFiles.keys.toList();
    promptFormatOptions =
        ModelPromptStyle.values.map((v) => v.nameAsString()).toList();

    var currentModelConfig =
        widget.configModelFiles.modelFiles[widget.chatLog.modelName];
    if (currentModelConfig == null) {
      var firstInConfig = widget.configModelFiles.modelFiles.entries.first;
      currentModelConfig = firstInConfig.value;
      widget.chatLog.modelName = firstInConfig.key;
    }
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

    super.initState();
  }

  Widget _buildModelPage(BuildContext context) {
    Widget innerConntent(BuildContext context) {
      return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        FilledButton(
          child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.add), Text('Import a new GGUF model')]),
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
                widget.configModelFiles.saveJsonToConfigFile().then((_) {
                  Navigator.pop(context);
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
        const SizedBox(height: 16),
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
                    if (value == null) {
                      return;
                    }
                    var newConfig = widget.configModelFiles.modelFiles[value];
                    if (newConfig == null) {
                      return;
                    }
                    setState(() {
                      // we change the link to the model in the chatlog
                      widget.chatLog.modelName = value;

                      // and then update all the controllers for the selected model's configuration settings
                      modelGpuLayersController.text =
                          newConfig.gpuLayers.toString();
                      modelContextSizeController.text =
                          newConfig.contextSize != null
                              ? newConfig.contextSize.toString()
                              : '';
                      modelThreadCountController.text =
                          newConfig.threadCount != null
                              ? newConfig.threadCount.toString()
                              : '';
                      modelBatchSizeController.text =
                          newConfig.batchSize != null
                              ? newConfig.batchSize.toString()
                              : '';
                    });
                  },
                ),
              ),
            ])),
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
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
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

        // bool promptCache;
        // bool ignoreEos;
        // bool flashAttention;
      ]);
    }

    return Padding(
        padding: const EdgeInsets.all(16),
        child: widget.isFullPage
            ? SingleChildScrollView(child: innerConntent(context))
            : innerConntent(context));
  }

  Widget _buildCharactersPage(BuildContext context) {
    return Padding(
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
            ])));
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
            leading: const Icon(Icons.shuffle),
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
