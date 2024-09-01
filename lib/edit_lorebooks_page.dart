import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mindmeld/chat_log.dart';
import 'package:mindmeld/lorebook.dart';

import 'platform_and_theming.dart';

class LorebookEntryWidget extends StatefulWidget {
  final LorebookEntry entry;
  final Function(LorebookEntry) onDelete;

  const LorebookEntryWidget({
    super.key,
    required this.entry,
    required this.onDelete,
  });

  @override
  State<LorebookEntryWidget> createState() => _LorebookEntryWidgetState();
}

class _LorebookEntryWidgetState extends State<LorebookEntryWidget> {
  late final TextEditingController _patternController;
  late final TextEditingController _loreController;

  @override
  void initState() {
    super.initState();
    _patternController = TextEditingController(text: widget.entry.patterns);
    _loreController = TextEditingController(text: widget.entry.lore);
  }

  @override
  void dispose() {
    _patternController.dispose();
    _loreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: getBackgroundDecorationColor(context),
            ),
            padding: const EdgeInsets.all(4),
            child: ListTile(
              title: TextField(
                  onChanged: (value) {
                    widget.entry.patterns = value;
                  },
                  decoration: const InputDecoration(
                    labelText: "Patterns",
                  ),
                  controller: _patternController),
              subtitle: TextField(
                onChanged: (value) {
                  widget.entry.lore = value;
                },
                decoration: const InputDecoration(
                  labelText: "Lore",
                ),
                controller: _loreController,
                minLines: 1,
                maxLines: 6,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => widget.onDelete(widget.entry),
              ),
            )));
  }
}

class EditLorebooksPage extends StatefulWidget {
  final String appTitle = 'MindMeld';
  final bool isFullPage;
  final List<Lorebook> lorebooks;
  final ChatLog? selectedChatLog;

  const EditLorebooksPage(
      {super.key,
      required this.isFullPage,
      required this.lorebooks,
      required this.selectedChatLog});

  @override
  State<EditLorebooksPage> createState() => _EditLorebooksPageState();
}

class _EditLorebooksPageState extends State<EditLorebooksPage> {
  late List<String> lorebookOptions;
  Lorebook? selectedLorebook;
  final matchingCharactersController = TextEditingController();

  @override
  void dispose() {
    matchingCharactersController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    lorebookOptions = [];
    _initLorebookOptions();

    //FIXME: select first matching lorebook by matching characters
    _doUpdateToSelectedLorebook(lorebookOptions.firstOrNull);
  }

  // setup the options for the lorebook dropdown menu
  void _initLorebookOptions() {
    lorebookOptions.clear();
    for (final book in widget.lorebooks) {
      lorebookOptions.add(book.name);
    }
  }

  Lorebook? _getSelectedLorebook(String? selectedLorebookOption) {
    log('attempting to get selected lorebook for $selectedLorebookOption ...');
    return selectedLorebookOption != null
        ? widget.lorebooks
            .firstWhere((book) => book.name == selectedLorebookOption)
        : null;
  }

  // this will return true if at least one lorebook has been created.
  bool _areLorebooksPresent() {
    return widget.lorebooks.isNotEmpty;
  }

  Future<void> _onCreateNewLorebook() async {
    // get the new lorebook name from the user
    final maybeNewName = await _showNewLorebookNameDialog();
    if (maybeNewName == null || maybeNewName.isEmpty) {
      return; // user cancelled
    }

    // FIXME: prevent the creation of duplicate named lorebooks

    // create the new lorebook and save it out to the filesystem
    final newLorebook =
        Lorebook(name: maybeNewName, characterNames: '', entries: []);
    await newLorebook.saveToFile();

    // make sure we add the new content to our collection and update state
    setState(() {
      widget.lorebooks.add(newLorebook);
      _initLorebookOptions();
      selectedLorebook = newLorebook;
    });
  }

  // shows a dialog box presenting the user with the option for a name to be
  // used when creeating a new lorebook.
  Future<String?> _showNewLorebookNameDialog() async {
    TextEditingController lorebookNameFieldController = TextEditingController();
    return showDialog<String?>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add new lorebook'),
          content: TextField(
            controller: lorebookNameFieldController,
            decoration: const InputDecoration(hintText: "New Lorebook Name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              child: const Text(
                'Create',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop(lorebookNameFieldController.text);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _onDeleteLorebook(Lorebook lorebook) async {
    // confirm with the user
    final shouldDelete = await _showConfirmDeleteLorebookDialog(lorebook.name);
    if (shouldDelete == null || shouldDelete == false) {
      return;
    }

    // find the old file and delete it if it exists
    final originalFilepath = await lorebook.getLorebookFilepath();
    final originalFile = File(originalFilepath);
    if (await originalFile.exists()) {
      await originalFile.delete();
    }

    // update the state of the app with the changes
    setState(() {
      widget.lorebooks.remove(lorebook);
      _initLorebookOptions();
      selectedLorebook = widget.lorebooks.firstOrNull;
    });
  }

  // shows a dialog box presenting the user with the option for a name to be
  // used when creeating a new lorebook.
  Future<bool?> _showConfirmDeleteLorebookDialog(String name) async {
    return showDialog<bool?>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permanently delete lorebook'),
          content: Text('Delete this lorebook permanently: $name?'),
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

  Future<void> _onRenameLorebook(Lorebook lorebook) async {
    final maybeNewName = await _showRenameLorebookDialog(lorebook.name);
    if (maybeNewName == null || maybeNewName.isEmpty) {
      return;
    }

    // FIXME: prevent the rename opteration to an existing lorebook name

    // find the old file and delete it if it exists
    final originalFilepath = await lorebook.getLorebookFilepath();
    final originalFile = File(originalFilepath);
    if (await originalFile.exists()) {
      await originalFile.delete();
    }

    // change the name and save the file out again
    lorebook.name = maybeNewName;
    await lorebook.saveToFile();

    // update the object to the new name selected by the user, rebuild the UI
    // dependencies as well
    setState(() {
      _initLorebookOptions();
      selectedLorebook = lorebook;
    });
    return;
  }

  // shows a dialog box presenting the user with the option for a name to be
  // used when creeating a new lorebook.
  Future<String?> _showRenameLorebookDialog(String initialName) async {
    TextEditingController lorebookNameFieldController = TextEditingController();
    lorebookNameFieldController.text = initialName;
    return showDialog<String?>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rename lorebook'),
          content: TextField(
            controller: lorebookNameFieldController,
            decoration: const InputDecoration(hintText: "New Lorebook Name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              child: const Text(
                'Create',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop(lorebookNameFieldController.text);
              },
            ),
          ],
        );
      },
    );
  }

  // should be called every time a new lorebook is selected in the UI. the
  // value passed in should be the lorebook `name` member value.
  void _doUpdateToSelectedLorebook(String? value) {
    // null updates are allowed
    setState(() {
      selectedLorebook = _getSelectedLorebook(value);
      if (selectedLorebook != null) {
        matchingCharactersController.text = selectedLorebook!.characterNames;
      }
    });
  }

  void _doAddNewEntry(Lorebook lorebook) {
    log('adding new lorebook entry to lorebook "${lorebook.name}"');
    final newLorebookEntry = LorebookEntry(patterns: '', lore: '');
    setState(() {
      lorebook.entries.add(newLorebookEntry);
    });
  }

  void _doDeleteEntry(Lorebook lorebook, LorebookEntry entry) {
    if (lorebook.entries.contains(entry)) {
      log('removing lorebook entry "${entry.patterns}" from the lorebook "${lorebook.name}"');
      setState(() {
        lorebook.entries.remove(entry);
      });
    }
  }

  Widget _buildEntryList(BuildContext context) {
    if (selectedLorebook == null) {
      return const SizedBox(height: 1);
    } else {
      return Column(
          children: selectedLorebook!.entries.asMap().entries.map((mapEntry) {
        final entryIndex = mapEntry.key;
        final entry = mapEntry.value;
        return LorebookEntryWidget(
            key: ValueKey('$entryIndex:${entry.patterns}${entry.lore}'),
            entry: entry,
            onDelete: (entry) {
              if (selectedLorebook != null) {
                _doDeleteEntry(selectedLorebook!, entry);
              }
            });
      }).toList());
    }
  }

  Widget buildInner(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ListTile(
          leading: const Icon(Icons.inventory),
          title: Row(children: [
            const Text('Lorebook:'),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                //enabled: _areLorebooksPresent(),
                //width: widget.isFullPage ? 210 : 410,
                value: selectedLorebook?.name,
                borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                items: lorebookOptions
                    .map((option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(
                          option,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )))
                    .toList(),
                onChanged: (String? value) {
                  _doUpdateToSelectedLorebook(value);
                },
              ),
            ),
          ])),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Tooltip(
            message: 'Create a new lorebook',
            child: FilledButton(
              onPressed: () => _onCreateNewLorebook(),
              child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.add), Text('Create')]),
            )),
        const SizedBox(width: 8),
        Tooltip(
            message: 'Rename a lorebook',
            child: FilledButton(
              onPressed: _areLorebooksPresent()
                  ? () => _onRenameLorebook(selectedLorebook!)
                  : null,
              child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.edit), Text('Rename')]),
            )),
        const SizedBox(width: 8),
        Tooltip(
            message: 'Delete a lorebook permanently',
            child: FilledButton(
              onPressed: _areLorebooksPresent()
                  ? () => _onDeleteLorebook(selectedLorebook!)
                  : null,
              child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.remove), Text('Delete')]),
            )),
      ]),
      if (selectedLorebook != null) const SizedBox(height: 8),
      if (selectedLorebook != null) const Divider(),
      if (selectedLorebook != null) const SizedBox(height: 8),
      if (selectedLorebook != null)
        ListTile(
            leading: const Icon(Icons.psychology),
            title: TextField(
              controller: matchingCharactersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Matching Characters",
              ),
              onChanged: (text) {
                selectedLorebook!.characterNames = text;
              },
            )),
      if (selectedLorebook != null) const SizedBox(height: 16),
      if (selectedLorebook != null) _buildEntryList(context),
      if (selectedLorebook != null) const SizedBox(height: 16),
      if (selectedLorebook != null)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Tooltip(
                message: 'Add a new entry to the selected lorebook',
                child: FilledButton(
                  onPressed: _areLorebooksPresent()
                      ? () => _doAddNewEntry(selectedLorebook!)
                      : null,
                  child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Icon(Icons.add), Text('Add Entry')]),
                )),
          ]),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFullPage) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Lorebooks'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: SingleChildScrollView(child: buildInner(context)),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: buildInner(context),
      );
    }
  }
}
