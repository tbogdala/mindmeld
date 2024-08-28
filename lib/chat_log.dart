import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mindmeld/platform_and_theming.dart';
import 'dart:developer';
import 'package:path/path.dart' as p;

import 'lorebook.dart';
part 'chat_log.g.dart';

// NOTE: REGENERATE JSON SERIALIZATION WHEN ADDING VALUES TO THIS!
enum ModelPromptStyle {
  alpaca,
  chatml,
  gemma,
  llama3,
  mistralInstruct,
  opusV12,
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
      case ModelPromptStyle.opusV12:
        return ModelPromptConfig.opusV12();
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

  ModelPromptConfig.opusV12() {
    name = "Llama3";
    system = "";
    preSystemPrefix = "<|start_header_id|>system<|end_header_id|>\n\n";
    preSystemSuffix = "\n<|eot_id|>\n";
    userPrefix = "<|start_header_id|>user<|end_header_id|>\n\n";
    userSuffix = "<|eot_id|>\n";
    aiPrefix = "<|start_header_id|>writer<|end_header_id|>\n\n";
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

  List<Lorebook> _getActiveLorebooks(
      List<ChatLogCharacter> characters, List<Lorebook> lorebooks) {
    final matchingBooks = lorebooks.where((book) {
      final lorebookNames = book.characterNames.split(',');
      return characters.any((char) {
        return lorebookNames
            .any((bookNameFragment) => bookNameFragment.contains(char.name));
      });
    });
    log('The following ${matchingBooks.length} lorebook(s) match:');
    for (final matched in matchingBooks) {
      log('\t${matched.name}');
    }

    return matchingBooks.toList();
  }

  // does a case-insensitive match to see if any of the comma-separated patterns
  // appear in the relevant text of the chatlog. if so, the LorebookEntry is considered
  // active and returned in the list.
  List<LorebookEntry> _getActiveEntries(List<Lorebook> lorebooks) {
    // build up the text that get's pattern matched. the formatting of this
    // text doesn't matter, so just jam it all together.
    const depthToSearch = 2;
    String relevantText = context;
    for (final msg in messages.reversed.take(depthToSearch)) {
      relevantText += msg.message;
    }

    List<LorebookEntry> matchedEntries = [];
    for (final book in lorebooks) {
      final entries = book.entries.where((entry) {
        return entry.patterns.split(',').map((s) => s.trim()).any((pattern) {
          return relevantText.toLowerCase().contains(pattern.toLowerCase());
        });
      });
      matchedEntries.addAll(entries);
    }

    log('matched ${matchedEntries.length} entries in total:');
    return matchedEntries;
  }

  String _buildLorebookEntryString(
      List<LorebookEntry> matchedEntries, int loreCharBudget) {
    String allEntries = "";
    int remainingBudget = loreCharBudget as int;
    for (final entry in matchedEntries) {
      final entryString = '${entry.lore}\n\n';
      remainingBudget -= entryString.length;

      log('\tadding lorebook entry: ${entry.patterns}');
      allEntries += entryString;

      // if we've filled our budget, make sure to stop here; yes this can
      // overflow the budget by the length of the last entry by design.
      if (remainingBudget < 0) {
        log('Lorebook entries have filled the budget of ${loreCharBudget} characters; stopping...');
        return allEntries;
      }
    }
    return allEntries;
  }

  String buildPrompt(
      List<Lorebook> lorebooks, int tokenBudget, bool continueMsg) {
    // NOTE: eventually make this customizable in an app configuration file.
    const defaultSystemPrompt =
        "You are an intelligent, skilled, versatile writer.\nYour task is to write a role-play response based on the information below.Maintain the character persona but allow it to evolve with the story.\nBe creative and proactive. Drive the story forward, introducing plotlines and events when relevant.\nAll types of outputs are encouraged; respond accordingly to the narrative.\nInclude dialogues, actions, and thoughts in each response.\nUtilize all five senses to describe scenarios within the character's dialogue.\nUse emotional symbols such as \"!\" and \"~\" in appropriate contexts.\nIncorporate onomatopoeia when suitable.\nAllow time for other characters to respond with their own input, respecting their agency.\n\n<Forbidden>\nUsing excessive literary embellishments and purple prose unless dictated by Character's persona.\nWriting for, speaking, thinking, acting, or replying as a different in your response.\nRepetitive and monotonous outputs.\nPositivity bias in your replies.\nBeing overly extreme or NSFW when the narrative context is inappropriate.\n</Forbidden>\n\nFollow the instructions above, avoiding the items listed in <Forbidden></Forbidden>.\n";

    // ballpark esimating for building up a prompt
    // conservative... raising it much above 3.5 trips up verboase prompt formats
    // on log chatlogs with a lot of long tokens like llama3
    const charsPerToken = 3.5;
    final estCharBudget = tokenBudget * charsPerToken;

    // we have a hard cap on how much lore to add so it doesn't gobble the whole context
    const maxLorePercentage = 0.1;

    var promptConfig = modelPromptStyle.getPromptConfig();

    // sort out the human and 'other' characters
    assert(characters.isNotEmpty);
    late ChatLogCharacter humanCharacter;
    List<ChatLogCharacter> otherCharacters = [];
    for (final c in characters) {
      if (c.isUserControlled) {
        humanCharacter = c;
      } else {
        otherCharacters.add(c);
      }
    }

    // figure out what lorebooks are active and then get the entries that are relevant
    List<ChatLogCharacter> allCharacters = [humanCharacter];
    allCharacters.addAll(otherCharacters);
    final activeLorebooks = _getActiveLorebooks(allCharacters, lorebooks);
    final activeEntries = _getActiveEntries(activeLorebooks);
    final loreString = _buildLorebookEntryString(
        activeEntries, (maxLorePercentage * estCharBudget).round());

    final String humanName =
        humanCharacter.name.isNotEmpty ? humanCharacter.name : defaultUserName;
    final String humanDesc = humanCharacter.description.isNotEmpty
        ? humanCharacter.description
        : defaultUserDesc;

    //TODO: provide better defaults for when the strings are empty in the characters
    String aiNames = '';
    String aiDescriptions = '';
    assert(otherCharacters.isNotEmpty);
    for (var i = 0; i < otherCharacters.length; i++) {
      final oc = otherCharacters.elementAt(i);
      final ocName = oc.name.isNotEmpty ? oc.name : defaultAiName;

      // we build a string of names to be used for the context if the user doesn't supply one.
      if (i == otherCharacters.length - 1) {
        aiNames += ' and $ocName';
      } else {
        aiNames += ', $ocName';
      }
      // then we add the character description to the string that will be used in the full prompt.
      aiDescriptions += '### $ocName\n\n';
      aiDescriptions +=
          oc.description.isNotEmpty ? oc.description : defaultAiDesc;
      if (oc.personality.isNotEmpty) {
        aiDescriptions +=
            '\n\n$ocName\'s Personality Traits: ${oc.personality}\n';
      }
    }
    String ctxDesc = context.isNotEmpty
        ? context
        : "$humanName$aiNames are having a conversation over text messaging.";

    // bulid the whole system preamble
    String promptFormatSystem = promptConfig.system.isNotEmpty
        ? promptConfig.system
        : defaultSystemPrompt;

    String system =
        '$promptFormatSystem## Overall plot description:\n\n$ctxDesc\n\n## Characters:\n\n### $humanName\n\n$humanDesc\n\n$aiDescriptions\n';
    if (loreString.isNotEmpty) {
      system += '\n## Relevant Lore\n\n$loreString\n';
    }

    String preamble =
        promptConfig.preSystemPrefix + system + promptConfig.preSystemSuffix;

    // start keeping a running estimate of how many characters we have left to use
    var remainingBudget = estCharBudget - preamble.length;

    // messages are added in reverse order
    var reversedMessages = messages.reversed;
    final firstMessage = reversedMessages.first;
    String? slashCommandFooter;

    // check for any slash commands, of which we currently support one: /narrator
    if (firstMessage.message.startsWith('/narrator ')) {
      // take it out of circulation
      reversedMessages = reversedMessages.skip(1);

      // get the narrator command from the slash command
      final narratorRequest =
          firstMessage.message.replaceFirst('/narrator ', '');

      const narratorSystemMsg =
          'You are an omniscient, creative narrator for an interactive story. Your task is to vividly describe environments, characters, and events, as well as provide dialogue and actions for non-player characters (NPCs) when appropriate.';
      const String narratorDescription = '''
The Narrator is an enigmatic, omniscient entity that guides the story. Unseen yet ever-present, the Narrator shapes the narrative, describes the world, and gives voice to NPCs. When invoked with the '/narrator' command, the Narrator will focus on the requested task. Otherwise, the Narrator will:

- Provide vivid, sensory descriptions of environments
- Introduce and describe characters
- Narrate events and actions
- Provide dialogue for NPCs
- Create atmosphere and mood through descriptive language
- Offer subtle hints or clues to guide the story
- Respond to player actions with appropriate narrative consequences

The Narrator should maintain a neutral tone, avoiding direct interaction with players unless specifically addressed. The goal is to create an immersive, dynamic story world that reacts to player choices while maintaining narrative coherence.
''';

      // rebuild the prompt but swap out for the narrator parts and recalculate the budget
      system =
          '$narratorSystemMsg\nThe user has requested that you $narratorRequest\n\n## Overall plot description:\n\n$ctxDesc\n\n## Characters:\n\n### $humanName\n\n$humanDesc\n\n$aiDescriptions\n\n### Narrator\n\n$narratorDescription\n';
      if (loreString.isNotEmpty) {
        system += '\n## Relevant Lore\n\n$loreString\n';
      }
      preamble =
          promptConfig.preSystemPrefix + system + promptConfig.preSystemSuffix;
      remainingBudget = estCharBudget - preamble.length;

      // we put the Narrator's name in parens here because it also gets added as an antiprompt,
      // which will halt all generation if included as is. This is the compromise. May have
      // to adjust it later if results are poor.
      slashCommandFooter =
          "${promptConfig.userPrefix}Narrator, $narratorRequest${promptConfig.userSuffix}${promptConfig.aiPrefix}(Narrator): ";
    }

    List<String> msgBuffer = [];
    for (final m in reversedMessages) {
      var formattedMsg = "";

      if (m.humanSent) {
        formattedMsg =
            "${promptConfig.userPrefix}$humanName: ${m.message}${promptConfig.userSuffix}";
      } else {
        formattedMsg = "${promptConfig.aiPrefix}${m.senderName}: ${m.message}";
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
    // FIXME: once proper multi-character support is in, this will have to be updated.
    // it assumes one character and takes the first non-human. eventually, will
    // need to supply the character getting gnerated.
    if (!continueMsg) {
      // if we don't have a special override due to a slash command, then build
      // the AI character prompt normally
      if (slashCommandFooter == null) {
        final firstOther = otherCharacters.first;
        final ocName =
            firstOther.name.isNotEmpty ? firstOther.name : defaultAiName;
        budgettedChatlog += "${promptConfig.aiPrefix}$ocName:";
      } else {
        budgettedChatlog += slashCommandFooter;
      }
    }

    final prompt = preamble + budgettedChatlog;

    return prompt;
  }
}
