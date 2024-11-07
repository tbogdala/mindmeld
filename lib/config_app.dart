import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:json_annotation/json_annotation.dart';

import 'platform_and_theming.dart';
part 'config_app.g.dart';

@JsonSerializable()
class ConfigApp {
  int version = 1;

  // stores advanced-usage configuration key-value string pairs.
  // prefer accessing this data through the helper methods in this class.
  Map<String, String> options = {};

  // Constructor to initialize the configuration
  ConfigApp();

  // simple wrapper to access the options map in a uniform way,
  // log access, and save the updated config to the file system.
  void setOption(String key, String value) {
    log('ConfigApp.setOption: $key ==> $value');
    options[key] = value;

    // saves the updated value out to the file
    saveJsonToConfigFile();
  }

  // simple wrapper to access the options map in a uniform way,
  // log access, and save the updated config to the file system.
  void unsetOption(String key) {
    log('ConfigApp.unsetOption: ☠️ $key ☠️');
    options.remove(key);

    // saves the updated value out to the file
    saveJsonToConfigFile();
  }

  // attempts to get the string value for `key` from `options`.
  // if the `key` does not exist in `options`, the value of `defaultValue`
  // will be returned, incluing null if not specified.
  String? getOption(String key, {String? defaultValue}) {
    if (options.containsKey(key)) {
      return options[key];
    }
    return defaultValue;
  }

  // attempts to get the string value for `key` from `options` and convert
  // it to a boolean with a potential `defaultValue`.
  // if the `key` does not exist in `options`, the value of `defaultValue`
  // will be returned, incluing null if not specified.
  bool? getOptionAsBool(String key, {bool? defaultValue}) {
    if (options.containsKey(key)) {
      String value = options[key]!.toLowerCase();
      return value == 'true' || value == '1';
    }
    return defaultValue;
  }

  // attempts to get the string value for `key` from `options` and convert
  // it to an int with a potential `defaultValue`.
  // if the `key` does not exist in `options`, the value of `defaultValue`
  // will be returned, incluing null if not specified.
  int? getOptionAsInt(String key, {int? defaultValue}) {
    if (options.containsKey(key)) {
      try {
        return int.parse(options[key]!);
      } catch (e) {
        log('ConfigApp.getOptionAsInt: Failed to parse value for key "$key" as int: $e');
      }
    }
    return defaultValue;
  }

  // attempts to get the string value for `key` from `options` and convert
  // it to an double with a potential `defaultValue`.
  // if the `key` does not exist in `options`, the value of `defaultValue`
  // will be returned, incluing null if not specified.
  double? getOptionAsDouble(String key, {double? defaultValue}) {
    if (options.containsKey(key)) {
      try {
        return double.parse(options[key]!);
      } catch (e) {
        log('ConfigApp.getOptionAsDouble: Failed to parse value for key "$key" as double: $e');
      }
    }
    return defaultValue;
  }

  Future<void> saveJsonToConfigFile() async {
    final json = toJson();
    final filepath = await getFilepath();
    final f = File(filepath);
    await f.writeAsString(json);
  }

  static Future<String> getFilepath() async {
    final directory = await getOurDocumentsDirectory();
    return p.join(directory, 'mindmeld.json');
  }

  static Future<ConfigApp?> loadFromConfigFile() async {
    final filepath = await getFilepath();
    try {
      final f = File(filepath);
      final contents = await f.readAsString();
      return ConfigApp.fromJson(contents);
    } catch (e) {
      log('Exception while trying to load ConfigApp from JSON: $e');
    }
    return null;
  }

  factory ConfigApp.fromJson(String jsonString) {
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
    return _$ConfigAppFromJson(jsonData);
  }

  String toJson() {
    var rawJsonMap = _$ConfigAppToJson(this);
    return const JsonEncoder.withIndent('  ').convert(rawJsonMap);
  }
}
