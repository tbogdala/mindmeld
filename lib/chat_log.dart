import 'dart:convert';
import 'dart:io';
import 'package:json_annotation/json_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer';

part 'chat_log.g.dart';

enum ModelPromptStyle {
  alpaca,
  chatml,
  llama3,
  phi3,
  tinyllama,
  vicuna,
  zephyr
}

extension ModelPromptStyleExtension on ModelPromptStyle {
  String nameAsString() => name;

  ModelPromptConfig getPromptConfig() {
    switch (this) {
      case ModelPromptStyle.alpaca:
        return ModelPromptConfig.alpaca();
      case ModelPromptStyle.chatml:
        return ModelPromptConfig.chatML();
      case ModelPromptStyle.llama3:
        return ModelPromptConfig.llama3();
      case ModelPromptStyle.phi3:
        return ModelPromptConfig.phi3();
      case ModelPromptStyle.tinyllama:
        return ModelPromptConfig.tinyllama();
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
  late String aiPrefix;
  late String aiSuffix;
  late List<String> stopPhrases;

  ModelPromptConfig.alpaca() {
    name = "Alpaca";
    system =
        "Below is an instruction that describes a task. Write a response that appropriately completes the request.";
    preSystemPrefix = "";
    preSystemSuffix = "";
    userPrefix = "\n### Instruction:\n";
    userSuffix = "";
    aiPrefix = "\n### Response:\n";
    aiSuffix = "";
    stopPhrases = ["### Instruction:"];
  }

  ModelPromptConfig.chatML() {
    name = "ChatML";
    system = "Perform the task to the best of your ability.";
    preSystemPrefix = "<|im_start|>system\n";
    preSystemSuffix = "<|im_end|>\n";
    userPrefix = "<|im_start|>user\n";
    userSuffix = "<|im_end|>\n";
    aiPrefix = "<|im_start|>assistant\n";
    aiSuffix = "<|im_end|>\n";
    stopPhrases = [
      "<|im_start|>",
      "<|im_end|>",
    ];
  }

  ModelPromptConfig.llama3() {
    name = "Llama3";
    system =
        "You are a helpful, smart, kind, and efficient AI assistant. You always fulfill the user's requests to the best of your ability.";
    preSystemPrefix = "<|start_header_id|>system<|end_header_id|>\n\n";
    preSystemSuffix = "<|eot_id|>";
    userPrefix = "<|start_header_id|>user<|end_header_id|>\n\n";
    userSuffix = "<|eot_id|>";
    aiPrefix = "<|start_header_id|>assistant<|end_header_id|>\n\n";
    aiSuffix = "<|eot_id|>";
    stopPhrases = ["<|start_header_id|>", "<|eot_id|>"];
  }

  ModelPromptConfig.phi3() {
    name = "Phi3";
    system = "";
    preSystemPrefix = "<|system|>\n";
    preSystemSuffix = "<|end|>\n";
    userPrefix = "<|user|>\n";
    userSuffix = "<|end|>\n";
    aiPrefix = "<|assistant|>\n";
    aiSuffix = "<|end|>\n";
    stopPhrases = ["<|end|>", "<|user|>"];
  }

  ModelPromptConfig.tinyllama() {
    name = "TinyLlama-Chat";
    system = "";
    preSystemPrefix = "<|system|>\n";
    preSystemSuffix = "\n";
    userPrefix = "<|user|>\n";
    userSuffix = "\n";
    aiPrefix = "<|assistant|>\n";
    aiSuffix = "\n";
    stopPhrases = ["<|system|>", "<|user|>"];
  }

  ModelPromptConfig.vicuna() {
    name = "Vicuna";
    system =
        "A chat between a curious user and an artificial intelligence assistant. The assistant gives helpful, detailed, and polite answers to the user's questions.";
    preSystemPrefix = "";
    preSystemSuffix = "\n\n";
    userPrefix = "USER: ";
    userSuffix = "\n";
    aiPrefix = "ASSISTANT: ";
    aiSuffix = "\n";
    stopPhrases = ["USER:"];
  }

  ModelPromptConfig.zephyr() {
    name = "Zephyr";
    system = "";
    preSystemPrefix = "";
    preSystemSuffix = "";
    userPrefix = "<|user|>\n";
    userSuffix = "<|endoftext|>\n";
    aiPrefix = "<|assistant|>\n";
    aiSuffix = "<|endoftext|>\n";
    stopPhrases = ["<|system|>", "<|user|>", "<|endoftext|>"];
  }
}

@JsonSerializable()
class ChatLogMessage {
  String senderName;
  String message;
  bool humanSent;
  DateTime messageCreatedAt = DateTime.now();

  // how long it took to generate the message in tokens / s
  // null if the message wasn't generated with AI
  double? generationSpeedTPS;

  ChatLogMessage(
      this.senderName, this.message, this.humanSent, this.generationSpeedTPS);

  factory ChatLogMessage.fromJson(Map<String, dynamic> json) {
    return _$ChatLogMessageFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$ChatLogMessageToJson(this);
  }
}

@JsonSerializable()
class ChatLogHyperparameters {
  int seed = -1;
  int tokens = 128;
  int topK = 40;
  double topP = 0.9;
  double minP = 0.05;
  double temp = 0.8;
  double repeatPenalty = 1.1;
  int repeatLastN = 64;
  double tfsZ = 1.0;
  double typicalP = 1.0;
  double frequencyPenalty = 0.0;
  double presencePenalty = 0.0;
  int mirostatType = 0;
  double mirostatEta = 0.1;
  double mirostatTau = 5.0;

  ChatLogHyperparameters();

  factory ChatLogHyperparameters.fromJson(Map<String, dynamic> json) {
    return _$ChatLogHyperparametersFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$ChatLogHyperparametersToJson(this);
  }
}

@JsonSerializable()
class ChatLog {
  int version = 1;
  String name;
  String humanName;
  String? humanDescription;
  String aiName;
  String? aiDescription;
  String? aiPersonality;
  String? context;
  String modelName;
  ModelPromptStyle modelPromptStyle;
  ChatLogHyperparameters hyperparmeters = ChatLogHyperparameters();
  List<ChatLogMessage> messages = [];

  ChatLog(this.name, this.humanName, this.aiName, this.modelName,
      this.modelPromptStyle);

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

  String buildPrompt(int tokenBudget, bool continueMsg) {
    // ballpark esimating for building up a prompt
    const charsPerToken = 3.5; // conservative...
    final estCharBudget = tokenBudget * charsPerToken;

    var promptConfig = modelPromptStyle.getPromptConfig();

    String humanDesc = humanDescription ?? "";
    String botDesc = aiDescription ?? "";
    String botPer = aiPersonality ?? "";
    String ctxDesc = context ??
        "$humanName and $aiName are having a conversation over text messaging.";

    // bulid the whole system preamble
    final system =
        "${promptConfig.system}$ctxDesc\n\n$humanName's Description:\n$humanDesc\n\n$aiName's Description:\n$botDesc\n$aiName's Personality: $botPer\n";

    final String preamble =
        promptConfig.preSystemPrefix + system + promptConfig.preSystemSuffix;

    // start keeping a running estimate of how many characters we have left to use
    var remainingBudget = estCharBudget - preamble.length;

    List<String> msgBuffer = [];
    for (final m in messages.reversed) {
      var formattedMsg = "";
      if (m.humanSent) {
        formattedMsg =
            "${promptConfig.userPrefix}$humanName: ${m.message}${promptConfig.userSuffix}";
      } else {
        formattedMsg = "${promptConfig.aiPrefix}$aiName: ${m.message}";
        // if we're trying to continue the chatlog, then for the first message we
        // encounter here, make sure not to include the suffix because it's been
        // deemed incomplete by the user and we want _moar_ ...
        if (msgBuffer.isNotEmpty) {
          formattedMsg += promptConfig.aiSuffix;
        }
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
    var budgettedChatlog = msgBuffer.reversed.join();

    // if we're not continuing the last message, add the prompt in to start
    // a new message prediction from the ai.
    if (!continueMsg) {
      budgettedChatlog += "${promptConfig.aiPrefix}$aiName: ";
    }

    final prompt = preamble + budgettedChatlog;

    return prompt;
  }
}
