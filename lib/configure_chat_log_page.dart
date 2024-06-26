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
    super.initState();
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
    return Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              ListTile(
                  leading: const Icon(Icons.manage_search),
                  title: TextField(
                    controller: hpNewTokensController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "New Tokens",
                    ),
                    onChanged: (text) {
                      widget.chatLog.hyperparmeters.tokens =
                          int.tryParse(text) ?? 64;
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
                      widget.chatLog.hyperparmeters.topK =
                          int.tryParse(text) ?? 40;
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
                      widget.chatLog.hyperparmeters.seed =
                          int.tryParse(text) ?? -1;
                    },
                  )),
            ])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('ChatLog Configuration')),
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
          ],
        ),
        body: <Widget>[
          _buildCharactersPage(context),
          _buildParametersPage(context)
        ][currentPageIndex]);
  }
}
