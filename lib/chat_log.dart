import 'dart:convert';
import 'dart:io';
import 'package:json_annotation/json_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer';

part 'chat_log.g.dart';

enum ModelPromptStyle { alpaca, chatml, phi3, tinychat, vicuna, zephyr }

extension ModelPromptStyleExtension on ModelPromptStyle {
  String nameAsString() => name;

  ModelPromptConfig getPromptConfig() {
    switch (this) {
      case ModelPromptStyle.alpaca:
        return ModelPromptConfig.alpaca();
      case ModelPromptStyle.chatml:
        return ModelPromptConfig.chatML();
      case ModelPromptStyle.phi3:
        return ModelPromptConfig.phi3();
      case ModelPromptStyle.tinychat:
        return ModelPromptConfig.tinychat();
      case ModelPromptStyle.vicuna:
        return ModelPromptConfig.vicuna();
      case ModelPromptStyle.zephyr:
        return ModelPromptConfig.zephyr();
      default:
        return ModelPromptConfig.alpaca();
    }
  }
}

ModelPromptStyle modelPromptStyleFromString(String stringValue) {
  return ModelPromptStyle.values
      .firstWhere((style) => style.nameAsString() == stringValue);
}

// Many configurations were pulled from https://github.com/lmstudio-ai/configs (MIT)
class ModelPromptConfig {
  late String name;
  late String system;
  late String preSystemPrefix;
  late String preSystemSuffix;
  late String userPrefix;
  late String userSuffix;
  late List<String> stopPhrases;

  ModelPromptConfig.alpaca() {
    name = "Alpaca";
    system =
        "Below is an instruction that describes a task. Write a response that appropriately completes the request.";
    preSystemPrefix = "";
    preSystemSuffix = "";
    userPrefix = "\n### Instruction:\n";
    userSuffix = "\n### Response:\n";
    stopPhrases = ["### Instruction:"];
  }

  ModelPromptConfig.chatML() {
    name = "ChatML";
    system = "Perform the task to the best of your ability.";
    preSystemPrefix = "<|im_start|>system\n";
    preSystemSuffix = "";
    userPrefix = "<|im_end|>\n<|im_start|>user\n";
    userSuffix = "<|im_end|>\n<|im_start|>assistant\n";
    stopPhrases = [
      "<|im_start|>",
      "<|im_end|>",
    ];
  }

  ModelPromptConfig.phi3() {
    name = "Phi3";
    system = "";
    preSystemPrefix = "<|system|>\n";
    preSystemSuffix = "<|end|>\n";
    userPrefix = "<|user|>\n";
    userSuffix = "<|end|>\n<|assistant|>\n";
    stopPhrases = ["<|end|>", "<|user|>"];
  }

  ModelPromptConfig.tinychat() {
    name = "TinyChat-Zephyr";
    system = "";
    preSystemPrefix = "<|system|>\n";
    preSystemSuffix = "";
    userPrefix = "\n<|user|>\n";
    userSuffix = "\n<|assistant|>\n";
    stopPhrases = ["<|system|>", "<|user|>"];
  }

  ModelPromptConfig.vicuna() {
    name = "Vicuna";
    system =
        "A chat between a curious user and an artificial intelligence assistant. The assistant gives helpful, detailed, and polite answers to the user's questions.";
    preSystemPrefix = "";
    preSystemSuffix = "\n\n";
    userPrefix = "USER:";
    userSuffix = "ASSISTANT:";
    stopPhrases = ["USER:"];
  }

  ModelPromptConfig.zephyr() {
    name = "Zephyr";
    system = "";
    preSystemPrefix = "";
    preSystemSuffix = "";
    userPrefix = "\n<|user|>\n";
    userSuffix = "<|endoftext|>\n<|assistant|>\n";
    stopPhrases = ["<|system|>", "<|user|>", "<|endoftext|>"];
  }
}

@JsonSerializable()
class ChatLogMessage {
  String senderName;
  String message;
  DateTime messageCreatedAt = DateTime.now();

  // how long it took to generate the message in tokens / s
  // null if the message wasn't generated with AI
  double? generationSpeedTPS;

  ChatLogMessage(this.senderName, this.message, this.generationSpeedTPS);

  factory ChatLogMessage.fromJson(Map<String, dynamic> json) {
    return _$ChatLogMessageFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$ChatLogMessageToJson(this);
  }
}

@JsonSerializable()
class ChatLog {
  String name;
  String modelFilepath;
  ModelPromptStyle modelPromptStyle;
  List<ChatLogMessage> messages = [];

  ChatLog(this.name, this.modelFilepath, this.modelPromptStyle);

  static Future<String> getLogsFolder() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/chatlogs';
  }

  static Future<void> ensureLogsFolderExists() async {
    var logsDir = await ChatLog.getLogsFolder();
    try {
      var d = Directory(logsDir);
      await d.create(recursive: true);
      log("ChatLog folder was ensured.");
    } catch (e) {
      log("Failed to ensure ChatLog folder exists at $logsDir");
      log("Error: $e");
    }
  }

  // does io so may throw uncaught errors
  Future<String> getLogFilepath() async {
    var chatLogDirpath = await getLogsFolder();
    var directory = Directory(chatLogDirpath);
    var safeFilenameBase = getSafeFilename();
    return "${directory.path}/$safeFilenameBase";
  }

  String getSafeFilename() {
    final regex = RegExp(r'[^\w\s\.-_]');
    return '${name.replaceAll(regex, '_')}.json';
  }

  Future<void> saveToFile() async {
    try {
      var chatLogFilepath = await getLogFilepath();
      var f = File(chatLogFilepath);
      var jsonString = toJson();
      f.writeAsString(jsonString);
      log("ChatLog.saveToFile() finished writing chatlog to $chatLogFilepath");
    } catch (e) {
      log("FAILED to save the chat log: $e");
    }
  }

  static Future<ChatLog?> loadFromFile(String filepath) async {
    try {
      var f = File(filepath);
      final contents = await f.readAsString();
      return ChatLog.fromJson(jsonDecode(contents));
    } catch (e) {
      log("ChatLog failed to load chat log from file: $filepath");
      log("Error: $e");
      return null;
    }
  }

  factory ChatLog.fromJson(Map<String, dynamic> json) {
    return _$ChatLogFromJson(json);
  }

  String toJson() {
    return jsonEncode(_$ChatLogToJson(this));
  }

  String buildPrompt(int tokenBudget) {
    // ballpark esimating for building up a prompt
    const charsPerToken = 3.5;
    final estCharBudget = tokenBudget * charsPerToken;
    final aiName = "AI";

    // TODO: Eventually make this configurable
    const String sysMsg = '';

    // bulid the whole system preamble
    var promptConfig = modelPromptStyle.getPromptConfig();
    final String preamble =
        promptConfig.preSystemPrefix + sysMsg + promptConfig.preSystemSuffix;

    // start keeping a running estimate of how many characters we have left to use
    var remainingBudget = estCharBudget - preamble.length;

    List<String> msgBuffer = [];
    for (final m in messages.reversed) {
      var formattedMsg = "";
      if (m.senderName == "AI") {
        formattedMsg = "${m.senderName}: ${m.message}";
      } else {
        formattedMsg =
            "${promptConfig.userPrefix}${m.senderName}: ${m.message}${promptConfig.userSuffix}";
      }

      if (remainingBudget - formattedMsg.length < 0) {
        break;
      }

      // update our remaining budget
      remainingBudget -= formattedMsg.length;

      // and push a new message onto the list
      msgBuffer.add(formattedMsg);
    }

    // reverse the msgBuffer to get the correct ordering for the prompt
    final budgettedChatlog = "${msgBuffer.reversed.join()}$aiName: ";
    final prompt = preamble + budgettedChatlog;

    return prompt;
  }
}
