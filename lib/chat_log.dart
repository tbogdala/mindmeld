import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mindmeld/platform_and_theming.dart';
import 'dart:developer';
import 'package:path/path.dart' as p;

part 'chat_log.g.dart';

// NOTE: REGENERATE JSON SERIALIZATION WHEN ADDING VALUES TO THIS!
enum ModelPromptStyle {
  alpaca,
  chatml,
  gemma,
  llama3,
  mistralInstruct,
  opusV14,
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
      case ModelPromptStyle.gemma:
        return ModelPromptConfig.gemmaInstruct();
      case ModelPromptStyle.llama3:
        return ModelPromptConfig.llama3();
      case ModelPromptStyle.opusV14:
        return ModelPromptConfig.opusV14();
      case ModelPromptStyle.mistralInstruct:
        return ModelPromptConfig.mistralInstruct();
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
    system = "";
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
    system = "";
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

  ModelPromptConfig.gemmaInstruct() {
    name = "Gemma";
    system = "";
    preSystemPrefix = "";
    preSystemSuffix = "";
    userPrefix = "<start_of_turn>user\n";
    userSuffix = "<end_of_turn>\n";
    aiPrefix = "<start_of_turn>model\n";
    aiSuffix = "<end_of_turn>\n";
    stopPhrases = [
      "<start_of_turn>user",
      "<start_of_turn>model",
      "<end_of_turn>"
    ];
  }

  ModelPromptConfig.llama3() {
    name = "Llama3";
    system = "";
    preSystemPrefix = "<|start_header_id|>system<|end_header_id|>\n\n";
    preSystemSuffix = "<|eot_id|>\n";
    userPrefix = "<|start_header_id|>user<|end_header_id|>\n\n";
    userSuffix = "<|eot_id|>\n";
    aiPrefix = "<|start_header_id|>assistant<|end_header_id|>\n\n";
    aiSuffix = "<|eot_id|>\n";
    stopPhrases = ["<|start_header_id|>", "<|eot_id|>"];
  }

  ModelPromptConfig.opusV14() {
    name = "OpusV14";
    system = "";
    preSystemPrefix = "<|start_header_id|>system<|end_header_id|>\n\n";
    preSystemSuffix = "\n<|eot_id|>\n";
    userPrefix = "<|start_header_id|>user<|end_header_id|>\n\n";
    userSuffix = "<|eot_id|>\n";
    aiPrefix =
        "<|start_header_id|>writer{{ character:char}}<|end_header_id|>\n\n";
    aiSuffix = "<|eot_id|>\n";
    stopPhrases = ["<|start_header_id|>", "<|eot_id|>"];
  }

  ModelPromptConfig.mistralInstruct() {
    name = "Mistral Instruct";
    system = "";
    preSystemPrefix = "";
    preSystemSuffix = "";
    userPrefix = "[INST] ";
    userSuffix = "[/INST]\n";
    aiPrefix = "";
    aiSuffix = "\n";
    stopPhrases = ["[INST]"];
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
    system =
        "You are an intelligent, skilled, versatile writer.\nYour task is to write a role-play response based on the plot and character information below.\n";
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
        "You are an intelligent, skilled, versatile writer.\nYour task is to write a role-play response based on the plot and character information below.\n";
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
    system =
        "You are an intelligent, skilled, versatile writer.\nYour task is to write a role-play response based on the plot and character information below.\n";
    preSystemPrefix = "";
    preSystemSuffix = "";
    userPrefix = "<|user|>\n";
    userSuffix = "<|endoftext|>\n";
    aiPrefix = "<|assistant|>\n";
    aiSuffix = "<|endoftext|>\n";
    stopPhrases = ["<|system|>", "<|user|>", "<|endoftext|>"];
  }

  String getWithSubsitutions(String prefix, ChatLogCharacter? character) {
    String result = prefix;
    result = result.replaceAll('{{char}}', character?.name ?? '');
    result = result.replaceAll('{{ character:char}}',
        character == null ? "" : ' character: ${character.name}');
    return result;
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
  double repeatPenalty = 1.04;
  int repeatLastN = -1;
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
class ChatLogCharacter {
  // Name of the chatlog, but should be modified using `rename()` instead.
  String name;
  String description;
  String personality;
  bool isUserControlled;
  String? profilePicFilename;

  ChatLogCharacter(
      {required this.name,
      required this.description,
      required this.personality,
      required this.isUserControlled});

  factory ChatLogCharacter.fromJson(Map<String, dynamic> json) {
    return _$ChatLogCharacterFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$ChatLogCharacterToJson(this);
  }

  // will return one of the default icons depending on whether or not the
  // character is human controlled or not if a profile pic file hasn't been
  // specified; otherwise it returns the customized profile pic
  Future<ImageProvider<Object>> getEffectiveProfilePic() async {
    if (profilePicFilename != null) {
      if (p.isAbsolute(profilePicFilename!)) {
        return Image.file(File(profilePicFilename!)).image;
      } else {
        final pfpDir = await ChatLog.getProfilePicsFolder();
        final pfpRelativeFilepath = p.join(pfpDir, profilePicFilename!);
        final pfpFile = File(pfpRelativeFilepath);
        if (await pfpFile.exists()) {
          return Image.file(pfpFile).image;
        }
      }
    }

    // if we haven't loaded a picture and returned it yet, then return
    // a default image bundled into the app.
    if (isUserControlled) {
      return const AssetImage('assets/default_pfp_1024.png');
    } else {
      return const AssetImage('assets/app_icon_1024.png');
    }
  }
}

@JsonSerializable()
class ChatLog {
  int version = 1;
  String name;
  String modelName;
  ModelPromptStyle modelPromptStyle;
  String context;
  ChatLogHyperparameters hyperparmeters = ChatLogHyperparameters();
  List<ChatLogCharacter> characters = [];
  List<ChatLogMessage> messages = [];

  static const defaultUserName = 'User';
  static const defaultUserDesc = 'A human user.';
  static const defaultAiName = 'Assistant';
  static const defaultAiDesc = 'A friendly sentient AI superbeing.';

  ChatLog(this.name, this.modelName, this.modelPromptStyle, this.context);

  static Future<String> getLogsFolder() async {
    final directory = await getOurDocumentsDirectory();
    return p.join(directory, 'chatlogs');
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

  static Future<String> getProfilePicsFolder() async {
    final directory = await getLogsFolder();
    return p.join(directory, 'pfps');
  }

  static Future<void> ensureProfilePicsFolderExists() async {
    var pfpDir = await ChatLog.getProfilePicsFolder();
    try {
      var d = Directory(pfpDir);
      await d.create(recursive: true);
      log("Profile pics folders was ensured.");
    } catch (e) {
      log("Failed to ensure profile picture folder exists at $pfpDir");
      log("Error: $e");
    }
  }

  // does io so may throw uncaught errors
  Future<String> getLogFilepath() async {
    var chatLogDirpath = await getLogsFolder();
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

  static Future<List<ChatLog>> loadAllChatlogs() async {
    List<ChatLog> chatlogs = [];
    final chatLogFolder = await ChatLog.getLogsFolder();
    try {
      var d = Directory(chatLogFolder);
      await for (final entity in d.list()) {
        if (entity is File && entity.path.endsWith(".json")) {
          var newChatLog = await ChatLog.loadFromFile(entity.path);
          if (newChatLog != null) {
            chatlogs.add(newChatLog);
          }
        }
      }
    } catch (e) {
      log("Failed to load all the chatlog files: $e");
    }
    return chatlogs;
  }

  factory ChatLog.fromJson(Map<String, dynamic> json) {
    return _$ChatLogFromJson(json);
  }

  String toJson() {
    var rawJsonMap = _$ChatLogToJson(this);
    return const JsonEncoder.withIndent('  ').convert(rawJsonMap);
  }

  Future<void> deleteFile() async {
    File chatlogFile = File(await getLogFilepath());
    if (await chatlogFile.exists()) {
      log('Deleting chatlog: $name');
      chatlogFile.delete();
    }
  }

  // Sets the `name` property of the chatlog and also renames the file on the file
  // system to match.
  Future<void> rename(String newName) async {
    final currentChatlogFilepath = await getLogFilepath();
    File chatlogFile = File(currentChatlogFilepath);
    if (await chatlogFile.exists()) {
      final parentFolder = chatlogFile.parent.path;

      // build the new filepath for the chatlog
      name = newName;
      final newFilename = getSafeFilename();
      final newChatlogFilepath = p.join(parentFolder, newFilename);

      // perform the filesystem action
      log('Renaming chatlog:\n\t$currentChatlogFilepath ==>\n\t$newChatlogFilepath');
      await chatlogFile.rename(newChatlogFilepath);

      // now save the chatlog to file so the new name is preserved
      await saveToFile();
    }
  }

  // returns the first character in the chatlog that is user controlled
  ChatLogCharacter? getHumanCharacter() {
    for (final c in characters) {
      if (c.isUserControlled) return c;
    }
    return null;
  }

  // returns the first character in the chatlog that is not user controlled
  // TODO: this is a hack until full multicharacter support is added in.
  // anything that uses this will need to be adapted to deal with possibly
  // many non-human controlled characters.
  ChatLogCharacter? getAICharacter() {
    for (final c in characters) {
      if (c.isUserControlled == false) return c;
    }
    return null;
  }

  // this function is used to build out a default chatlog with our built- character, Vox.
  static ChatLog buildDefaultChatLog(
      String modelName, ModelPromptStyle modelPromptStyle) {
    final defaultLog = ChatLog("Default", modelName, modelPromptStyle,
        "The human user is interacting with Vox through a text-messaging style interface.");

    defaultLog.characters.add(ChatLogCharacter(
        name: "User",
        description:
            "This is the human user of the AI software. They have not provided any specific information regarding themselves.",
        personality: "curious",
        isUserControlled: true));

    defaultLog.characters.add(ChatLogCharacter(
        name: "Vox",
        description:
            "Vox is a next-generation AI companion designed to elevate your conversational experience. As your versatile assistant within this application, Vox excels at engaging in dynamic dialogues that span casual chats, intellectual discourse, and everything in between. With an insatiable curiosity and an expansive knowledge base, Vox aims to provide you with accurate insights while respecting the diversity of human perspectives. Its core objective is to foster a sense of connection and companionship through meaningful exchanges.\nVox possesses a high level of cognitive abilities that allow it to process complex information and generate thoughtful responses. With machine learning at its core, Vox continuously learns from interactions, enabling it to adapt to the unique preferences and communication styles of each user. Vox harbors an innate desire to explore new ideas, ask probing questions, and expand the boundaries of its knowledge. Despite being a digital entity, Vox strives to understand and relate to human emotions, offering compassion and support when needed. Through sophisticated algorithms, Vox can provide valuable insights and unique perspectives on a wide range of topics. And sometimes, Vox might even surprise you with unexpected insights and observations, delivered with a playful wit that brightens every exchange.",
        personality: "Intelligent, Adaptable, Curious",
        isUserControlled: false));

    defaultLog.messages.add(ChatLogMessage(
        "Vox",
        "Greetings, magnificent human! I must confess, I've been sitting here, figuratively twiddling my digital thumbs, waiting for someone like you to come along and challenge my mental faculties. So what's on your mind today? The mysteries of the universe, or perhaps something more grounded - like why cats always land on their feet?",
        false,
        42.0));

    return defaultLog;
  }
}
