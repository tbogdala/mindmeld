import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'package:mindmeld/platform_and_theming.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;

part 'config_models.g.dart';

@JsonSerializable()
class ConfigModelSettings {
  int version = 1;
  String modelFilepath;
  int gpuLayers = 100;
  int? contextSize;
  int? threadCount;
  int? batchSize;
  bool promptCache;
  bool ignoreEos;
  bool flashAttention;
  String? promptFormat;

  ConfigModelSettings(
      this.modelFilepath,
      this.gpuLayers,
      this.contextSize,
      this.threadCount,
      this.batchSize,
      this.promptCache,
      this.ignoreEos,
      this.flashAttention,
      this.promptFormat);

  ConfigModelSettings clone() => ConfigModelSettings(
      modelFilepath,
      gpuLayers,
      contextSize,
      threadCount,
      batchSize,
      promptCache,
      ignoreEos,
      flashAttention,
      promptFormat);

  // returns true if current values are different than the original ones
  // in fields where a model reload would be necessary.
  bool doChangesRequireReload(ConfigModelSettings original) {
    if (modelFilepath.compareTo(original.modelFilepath) != 0) {
      return true;
    }
    if (gpuLayers != original.gpuLayers) {
      return true;
    }
    if (contextSize != original.contextSize) {
      return true;
    }
    if (threadCount != original.threadCount) {
      return true;
    }
    if (batchSize != original.batchSize) {
      return true;
    }
    if (promptCache != original.promptCache) {
      return true;
    }
    if (flashAttention != original.flashAttention) {
      return true;
    }

    return false;
  }

  factory ConfigModelSettings.fromJson(Map<String, dynamic> json) {
    return _$ConfigModelSettingsFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$ConfigModelSettingsToJson(this);
  }
}

/// This class represents the configuration data for all of the imported LLM
/// neural net models. When FilePicker selects a file it gets copied over to the
/// cache, so we have to keep track of it. Similarly if the user uses the app
/// to download a model, we need to track that too. Then these options can be
/// used when creating a new chatlog for the model.
@JsonSerializable()
class ConfigModelFiles {
  final Map<String, ConfigModelSettings> modelFiles;

  ConfigModelFiles({required this.modelFiles});

  factory ConfigModelFiles.fromJson(String jsonString) {
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
    return _$ConfigModelFilesFromJson(jsonData);
  }

  String toJson() {
    return jsonEncode(_$ConfigModelFilesToJson(this));
  }

  Future<void> saveJsonToConfigFile() async {
    final json = toJson();
    final filepath = await getFilepath();
    final f = File(filepath);
    await f.writeAsString(json);
  }

  static Future<String> getFilepath() async {
    final directory = await getOurDocumentsDirectory();
    return p.join(directory, 'model_configs.json');
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
    final directory = await getOurDocumentsDirectory();
    return p.join(directory, 'models');
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
