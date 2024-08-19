import 'dart:developer';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'platform_and_theming.dart';
part 'lorebook.g.dart';

// An individual entry in the Lorebook. When one of the comma-delimited strings
// in `patterns` is matched in the context or recent messages, then the `lore`
// is inserted into the prompt.
@JsonSerializable()
class LorebookEntry {
  String patterns;
  String lore;

  LorebookEntry({required this.patterns, required this.lore});

  factory LorebookEntry.fromJson(Map<String, dynamic> json) =>
      _$LorebookEntryFromJson(json);

  Map<String, dynamic> toJson() => _$LorebookEntryToJson(this);
}

// A Lorebook is a collection of patterns and lore entries (LorebookEntry) that, when
// the pattern is detected in the context or recent messages, will get the lore surfaced
// in the prompt sent to the LLM. This provides a mechanism for a primitive form of
// long-term memory.
@JsonSerializable()
class Lorebook {
  int version = 1;

  // The customizable name for the lorebook. Useful only for the UI.
  String name;

  // A comma-delimited set of patterns that, if they match a character in the current
  // chat log, will activate the lorebook `entries` for possible inclusion.
  String characterNames;

  // A list of Lorebook entries that get processed for potential matches if a
  // character in the current chatlog matches one of the `characterNames` patterns.
  List<LorebookEntry> entries;

  Lorebook(
      {required this.name,
      required this.characterNames,
      required this.entries});

  factory Lorebook.fromJson(Map<String, dynamic> json) {
    return _$LorebookFromJson(json);
  }

  String toJson() {
    return jsonEncode(_$LorebookToJson(this));
  }

  static Future<String> getLorebooksFolder() async {
    final directory = await getOurDocumentsDirectory();
    return p.join(directory, 'lorebooks');
  }

  static Future<void> ensureLorebooksFolderExists() async {
    var loreDir = await Lorebook.getLorebooksFolder();
    try {
      var d = Directory(loreDir);
      await d.create(recursive: true);
      log("Lorebooks folder was ensured.");
    } catch (e) {
      log("Failed to ensure Lorebooks folder exists at $loreDir");
      log("Error: $e");
    }
  }

  Future<String> getLorebookFilepath() async {
    var chatLogDirpath = await getLorebooksFolder();
    var directory = Directory(chatLogDirpath);
    var safeFilenameBase = getSafeFilename();
    return p.join(directory.path, safeFilenameBase);
  }

  String getSafeFilename() {
    final regex = RegExp(r'[^\w\s\.-_]');
    return '${name.replaceAll(regex, '_')}.json';
  }

  Future<void> saveToFile() async {
    try {
      var lorebookFilepath = await getLorebookFilepath();
      var f = File(lorebookFilepath);
      var jsonString = toJson();
      f.writeAsString(jsonString);
      log("Lorebook.saveToFile() finished writing chatlog to $lorebookFilepath");
    } catch (e) {
      log("FAILED to save the chat log: $e");
    }
  }

  static Future<Lorebook?> loadFromFile(String filepath) async {
    try {
      var f = File(filepath);
      final contents = await f.readAsString();
      return Lorebook.fromJson(jsonDecode(contents));
    } catch (e) {
      log("Lorebook failed to load json from file: $filepath");
      log("Error: $e");
      return null;
    }
  }

  static Future<List<Lorebook>> loadAllLorebooks() async {
    List<Lorebook> lorebooks = [];
    final lorebooksFolder = await Lorebook.getLorebooksFolder();
    try {
      var d = Directory(lorebooksFolder);
      await for (final entity in d.list()) {
        if (entity is File && entity.path.endsWith(".json")) {
          var newLorebook = await Lorebook.loadFromFile(entity.path);
          if (newLorebook != null) {
            lorebooks.add(newLorebook);
          }
        }
      }
    } catch (e) {
      log("Failed to load all the lorebook files: $e");
    }

    return lorebooks;
  }
}
