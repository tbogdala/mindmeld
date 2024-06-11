import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:path_provider/path_provider.dart';
import 'package:json_annotation/json_annotation.dart';

part 'config_models.g.dart';

/// This class represents the configuration data for all of the imported LLM
/// neural net models. When FilePicker selects a file it gets copied over to the
/// cache, so we have to keep track of it. Similarly if the user uses the app
/// to download a model, we need to track that too. Then these options can be
/// used when creating a new chatlog for the model.
@JsonSerializable()
class ConfigModelFiles {
  final Map<String, String> modelFiles;

  ConfigModelFiles({required this.modelFiles});

  factory ConfigModelFiles.fromJson(String jsonString) {
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
    return _$ConfigModelFilesFromJson(jsonData);
  }

  String toJson() {
    return jsonEncode(_$ConfigModelFilesToJson(this));
  }

  static Future<String> getFilepath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/model_configs.json';
  }

  Future<void> saveJsonToConfigFile() async {
    //TODO: wrap in try/catch?
    final json = toJson();
    final filepath = await getFilepath();
    final f = File(filepath);
    await f.writeAsString(json);
  }

  static Future<ConfigModelFiles?> loadFromConfigFile() async {
    final filepath = await getFilepath();
    try {
      final f = File(filepath);
      final contents = await f.readAsString();
      return ConfigModelFiles.fromJson(contents);
    } catch (e) {
      log('Exception while trying to load ConfigModelFiles from JSON: $e');
    }
    return null;
  }

  static Future<String> getModelsFolderpath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/models';
  }

  static Future<void> ensureModelsFolderExists() async {
    var modelsDir = await getModelsFolderpath();
    try {
      var d = Directory(modelsDir);
      await d.create(recursive: true);
      log("Models folder was ensured.");
    } catch (e) {
      log("Failed to ensure models folder exists at $modelsDir");
      log("Error: $e");
    }
  }
}
