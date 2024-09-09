import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import 'dart:ffi';
import 'package:path/path.dart' as p;
import 'package:woolydart/woolydart.dart';
import 'dart:developer';
import 'package:format/format.dart';

import 'chat_log.dart';
import 'config_models.dart';
import 'lorebook.dart';
import 'platform_and_theming.dart';

class PredictReplyResult {
  bool success;
  String message;
  double generationSpeedTPS;

  PredictReplyResult(this.success, this.message, this.generationSpeedTPS);
}

class PredictReplyRequest {
  String modelFilepath;
  ConfigModelSettings modelSettings;
  String promptString;
  List<String> antipromptStrings;
  ChatLogHyperparameters hyperparameters;

  PredictReplyRequest(this.modelFilepath, this.modelSettings, this.promptString,
      this.antipromptStrings, this.hyperparameters);
}

class GetTokenCountRequest {
  String promptString;

  GetTokenCountRequest(this.promptString);
}

class GetTokenCountResult {
  String promptString;
  int tokenCount;

  GetTokenCountResult(this.promptString, this.tokenCount);
}

class EnsureModelLoadedRequest {
  String modelFilepath;
  ConfigModelSettings modelSettings;
  ChatLogHyperparameters hyperparameters;

  EnsureModelLoadedRequest(
      this.modelFilepath, this.modelSettings, this.hyperparameters);
}

class EnsureModelLoadedResult {
  bool success;

  EnsureModelLoadedResult(this.success);
}

class CloseModelRequest {}

class PredictionWorker {
  late Isolate _workerIsolate;
  late ReceivePort _fromIsoPort;
  SendPort? _toIsoPort;
  Completer<void> _isoReady = Completer.sync();
  Completer<PredictReplyResult> _isoResponsePrediction = Completer();
  Completer<GetTokenCountResult> _isoResponseTokenCount = Completer();
  Completer<EnsureModelLoadedResult> _isoResponseEnsureLoaded = Completer();

  static Future<PredictionWorker> spawn() async {
    log('PredictionWorker: spawning...');
    PredictionWorker obj = PredictionWorker();
    obj._fromIsoPort = ReceivePort();
    obj._fromIsoPort.listen(obj._handleResponsesFromIsolate);
    obj._workerIsolate =
        await Isolate.spawn(_isolateWorker, obj._fromIsoPort.sendPort);
    return obj;
  }

  Future<void> closeModel() async {
    log('PredictionWorker: close model...');
    await _isoReady.future;
    _isoResponsePrediction = Completer();
    _isoResponseTokenCount = Completer();
    _isoResponseEnsureLoaded = Completer();
    _toIsoPort!.send(CloseModelRequest());
  }

  void killWorker() {
    log('PredictionWorker: killing worker...');
    _workerIsolate.kill(priority: Isolate.immediate);
    _fromIsoPort.close();
    _toIsoPort = null;
    _isoReady = Completer.sync();
    _isoResponsePrediction = Completer();
    _isoResponseTokenCount = Completer();
    _isoResponseEnsureLoaded = Completer();
  }

  Future<PredictReplyResult> predictText(PredictReplyRequest request) async {
    await _isoReady.future;
    _isoResponsePrediction = Completer();
    _toIsoPort!.send(request);
    return _isoResponsePrediction.future;
  }

  Future<GetTokenCountResult> getTokenCount(
      GetTokenCountRequest request) async {
    await _isoReady.future;
    _isoResponseTokenCount = Completer();
    _toIsoPort!.send(request);
    return _isoResponseTokenCount.future;
  }

  Future<EnsureModelLoadedResult> ensureModelLoaded(
      EnsureModelLoadedRequest request) async {
    await _isoReady.future;
    _isoResponseEnsureLoaded = Completer();
    _toIsoPort!.send(request);
    return _isoResponseEnsureLoaded.future;
  }

  void _handleResponsesFromIsolate(dynamic message) {
    if (message is SendPort) {
      log('PredictionWorker: _handleResponseFromIsolate() got a ready notification');
      _toIsoPort = message;
      _isoReady.complete();
    } else if (message is PredictReplyResult) {
      log('PredictionWorker: _handleResponseFromIsolate() got a prediction reply');
      _isoResponsePrediction.complete(message);
    } else if (message is GetTokenCountResult) {
      log('PredictionWorker: _handleResponseFromIsolate() got a token count reply');
      _isoResponseTokenCount.complete(message);
    } else if (message is EnsureModelLoadedResult) {
      log('PredictionWorker: _handleResponseFromIsolate() got an ensure model loaded reply');
      _isoResponseEnsureLoaded.complete(message);
    } else {
      log("PredictionWorker: _handleResponseFromIsolate() got an unknown message: $message");
    }
  }

  static void _isolateWorker(SendPort port) {
    LlamaModel? llamaModel;

    try {
      // send the communication's port back right away
      final workerReceivePort = ReceivePort();
      port.send(workerReceivePort.sendPort);

      // an empty string for iOS to use the current process instead of a library file.
      String lib = "";
      if (Platform.isAndroid) {
        lib = "libwoolycore.so";
      } else if (Platform.isLinux) {
        final woolycorePath = p.joinAll(
            ["packages", "woolydart", "src", "build-linux", "libwoolycore.so"]);
        if (File(woolycorePath).existsSync()) {
          lib = woolycorePath;
        } else {
          lib = "libwoolycore.so";
        }
      }
      log("PredictionWorker: Library loaded through DynamicLibrary.");
      llamaModel = LlamaModel(lib);

      workerReceivePort.listen((dynamic message) async {
        if (message is PredictReplyRequest) {
          final result = _predictReply(llamaModel!, message);
          port.send(result);
          log('PredictionWorker: Finished reply prediction request...');
        } else if (message is GetTokenCountRequest) {
          final result = _getTokenCount(llamaModel!, message);
          port.send(result);
          log('PredictionWorker: Finished get token count request...');
        } else if (message is EnsureModelLoadedRequest) {
          final result = _ensureModelIsLoaded(
              llamaModel!,
              message.modelFilepath,
              message.modelSettings,
              message.hyperparameters);
          port.send(result);
          log('PredictionWorker: Finished ensure model loaded request...');
        } else if (message is CloseModelRequest) {
          if (llamaModel!.isModelLoaded()) {
            log("PredictionWorker: Worker is closing the loaded model...");
            llamaModel.freeModel();
          }
        }
      });
    } catch (e) {
      var errormsg = e.toString();
      log("PredictionWorker: _isolateWorker caught exception: $errormsg");
      log("... closing model.");
      try {
        llamaModel?.freeModel();
      } finally {}
    }
  }

  static EnsureModelLoadedResult _ensureModelIsLoaded(
    LlamaModel llamaModel,
    String modelFilepath,
    ConfigModelSettings modelSettings,
    ChatLogHyperparameters hyperparameters,
  ) {
    if (!llamaModel.isModelLoaded()) {
      final modelParams = llamaModel.getDefaultModelParams()
        ..n_gpu_layers = modelSettings.gpuLayers
        ..use_mmap = isRunningOnDesktop() ? true : false;
      final contextParams = llamaModel.getDefaultContextParams()
        ..seed = hyperparameters.seed
        ..n_threads = modelSettings.threadCount ?? -1
        ..flash_attn = modelSettings.flashAttention
        ..n_ctx = modelSettings.contextSize ?? 2048;

      log("PredictionWorker: Attempting to load model: $modelFilepath");

      // we make the upstream llamacpp code 'chatty' in the log for debug builds
      final bool loadedResult = llamaModel.loadModel(
          modelFilepath, modelParams, contextParams, !kDebugMode);

      return EnsureModelLoadedResult(loadedResult);
    }
    return EnsureModelLoadedResult(true);
  }

  static GetTokenCountResult _getTokenCount(
      LlamaModel llamaModel, GetTokenCountRequest args) {
    final count = llamaModel.getTokenCount(args.promptString, false, true);
    return GetTokenCountResult(args.promptString, count);
  }

  static PredictReplyResult _predictReply(
      LlamaModel llamaModel, PredictReplyRequest args) {
    wooly_gpt_params? params;
    try {
      // make sure our model is loaded
      _ensureModelIsLoaded(llamaModel, args.modelFilepath, args.modelSettings,
          args.hyperparameters);

      params = llamaModel.getTextGenParams()
        ..seed = args.hyperparameters.seed
        ..n_threads = args.modelSettings.threadCount ?? -1
        ..n_predict = args.hyperparameters.tokens
        ..top_k = args.hyperparameters.topK
        ..top_p = args.hyperparameters.topP
        ..min_p = args.hyperparameters.minP
        ..tfs_z = args.hyperparameters.tfsZ
        ..typical_p = args.hyperparameters.typicalP
        ..penalty_repeat = args.hyperparameters.repeatPenalty
        ..penalty_last_n = args.hyperparameters.repeatLastN
        ..ignore_eos = args.modelSettings.ignoreEos
        ..flash_attn = args.modelSettings.flashAttention
        ..prompt_cache_all = args.modelSettings.promptCache
        ..n_batch = args.modelSettings.batchSize ?? 128;
      params.setPrompt(args.promptString);
      params.setAntiprompts(args.antipromptStrings);
      log('PredictionWorker: A total of ${args.antipromptStrings.length} antiprompt strings: ${args.antipromptStrings.join(",")}');

      final (predictResult, outputString) =
          llamaModel.predictText(params, nullptr);
      if (predictResult.result != 0) {
        return PredictReplyResult(
            false,
            '<Error: LlamaModel.predictText() returned ${predictResult.result}>',
            0.0);
      }
      var generationSpeed = 1e3 /
          (predictResult.t_end_ms - predictResult.t_start_ms) *
          predictResult.n_eval;

      log('Generated text:\n$outputString');
      log(format(
          '\nTiming Data: {} tokens total in {:.2f} ms ({:.2f} T/s) ; {} prompt tokens in {:.2f} ms ({:.2f} T/s)\n\n',
          predictResult.n_eval,
          (predictResult.t_end_ms - predictResult.t_start_ms),
          1e3 /
              (predictResult.t_end_ms - predictResult.t_start_ms) *
              predictResult.n_eval,
          predictResult.n_p_eval,
          predictResult.t_p_eval_ms,
          1e3 / predictResult.t_p_eval_ms * predictResult.n_p_eval));

      return PredictReplyResult((outputString != null ? true : false),
          outputString ?? "<Error: No response generated.>", generationSpeed);
    } catch (e) {
      var errormsg = e.toString();
      log("PredictionWorker: Caught exception trying to predict reply: $errormsg");
      return PredictReplyResult(false, '<Error: $errormsg>', 0.0);
    } finally {
      params?.dispose();
    }
  }

  Future<String> buildPrompt(ChatLog chatlog, List<Lorebook> lorebooks,
      int tokenBudget, bool continueMsg) async {
    // NOTE: eventually make this customizable in an app configuration file.
    const defaultSystemPrompt =
        "You are an intelligent, skilled, versatile writer.\nYour task is to write a role-play response based on the information below.Maintain the character persona but allow it to evolve with the story.\nBe creative and proactive. Drive the story forward, introducing plotlines and events when relevant.\nAll types of outputs are encouraged; respond accordingly to the narrative.\nInclude dialogues, actions, and thoughts in each response.\nUtilize all five senses to describe scenarios within the character's dialogue.\nUse emotional symbols such as \"!\" and \"~\" in appropriate contexts.\nIncorporate onomatopoeia when suitable.\nAllow time for other characters to respond with their own input, respecting their agency.\n\n<Forbidden>\nUsing excessive literary embellishments and purple prose unless dictated by Character's persona.\nWriting for, speaking, thinking, acting, or replying as a different in your response.\nRepetitive and monotonous outputs.\nPositivity bias in your replies.\nBeing overly extreme or NSFW when the narrative context is inappropriate.\n</Forbidden>\n\nFollow the instructions above, avoiding the items listed in <Forbidden></Forbidden>.\n";

    // we have a hard cap on how much lore to add so it doesn't gobble the whole context
    const maxLorePercentage = 0.1;

    var promptConfig = chatlog.modelPromptStyle.getPromptConfig();

    // sort out the human and 'other' characters
    assert(chatlog.characters.isNotEmpty);
    late ChatLogCharacter humanCharacter;
    Map<String, ChatLogCharacter> otherCharacters = {};
    for (final c in chatlog.characters) {
      if (c.isUserControlled) {
        humanCharacter = c;
      } else {
        otherCharacters[c.name] = c;
      }
    }

    // figure out what lorebooks are active and then get the entries that are relevant
    List<ChatLogCharacter> allCharacters = [humanCharacter];
    allCharacters.addAll(otherCharacters.values);
    final activeLorebooks = _getActiveLorebooks(allCharacters, lorebooks);
    final activeEntries = _getActiveEntries(chatlog, activeLorebooks);
    final (loreString, loreTokenCount) = await _buildLorebookEntryString(
        activeEntries, (maxLorePercentage * tokenBudget).round());
    log("A total of $loreTokenCount tokens used for lorebook entries.");

    final String humanName = humanCharacter.name.isNotEmpty
        ? humanCharacter.name
        : ChatLog.defaultUserName;
    final String humanDesc = humanCharacter.description.isNotEmpty
        ? humanCharacter.description
        : ChatLog.defaultUserDesc;

    String aiNames = '';
    String aiDescriptions = '';
    assert(otherCharacters.isNotEmpty);
    for (final oc in otherCharacters.values) {
      final ocName = oc.name.isNotEmpty ? oc.name : ChatLog.defaultAiName;

      // we build a string of names to be used for the context if the user doesn't supply one.
      if (aiNames.isNotEmpty) {
        aiNames += ' and $ocName';
      } else {
        aiNames += ', $ocName';
      }
      // then we add the character description to the string that will be used in the full prompt.
      aiDescriptions += '### $ocName\n\n';
      aiDescriptions +=
          oc.description.isNotEmpty ? oc.description : ChatLog.defaultAiDesc;
      if (oc.personality.isNotEmpty) {
        aiDescriptions +=
            '\n\n$ocName\'s Personality Traits: ${oc.personality}\n';
      }
    }
    String ctxDesc = chatlog.context.isNotEmpty
        ? chatlog.context
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
    final preambleTokenCountResp =
        await getTokenCount(GetTokenCountRequest(preamble));
    var remainingBudget = tokenBudget - preambleTokenCountResp.tokenCount;

    // messages are added in reverse order
    var reversedMessages = chatlog.messages.reversed;
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
      final preambleTokenCountResp =
          await getTokenCount(GetTokenCountRequest(preamble));
      remainingBudget = tokenBudget - preambleTokenCountResp.tokenCount;

      // we put the Narrator's name in parens here because it also gets added as an antiprompt,
      // which will halt all generation if included as is. This is the compromise. May have
      // to adjust it later if results are poor.
      final userPrefix =
          promptConfig.getWithSubsitutions(promptConfig.userPrefix, null);
      final aiPrefix =
          promptConfig.getWithSubsitutions(promptConfig.aiPrefix, null);
      slashCommandFooter =
          "${userPrefix}Narrator, $narratorRequest${promptConfig.userSuffix}$aiPrefix(Narrator): ";
      final footerTokenCountResp =
          await getTokenCount(GetTokenCountRequest(slashCommandFooter));
      remainingBudget -= footerTokenCountResp.tokenCount;
    }

    List<String> msgBuffer = [];
    for (final m in reversedMessages) {
      var formattedMsg = "";

      if (m.humanSent) {
        final userPrefix = promptConfig.getWithSubsitutions(
            promptConfig.userPrefix, humanCharacter);
        formattedMsg =
            "$userPrefix$humanName: ${m.message}${promptConfig.userSuffix}";
      } else {
        final aiPrefix = promptConfig.getWithSubsitutions(
            promptConfig.aiPrefix, otherCharacters[m.senderName]);
        formattedMsg = "$aiPrefix${m.senderName}: ${m.message}";
        // if we're trying to continue the chatlog, then for the first message we
        // encounter here, make sure not to include the suffix because it's been
        // deemed incomplete by the user and we want _moar_ ...
        if (msgBuffer.isNotEmpty) {
          formattedMsg += promptConfig.aiSuffix;
        }
      }

      final msgTokenCountResp =
          await getTokenCount(GetTokenCountRequest(formattedMsg));

      if (remainingBudget - msgTokenCountResp.tokenCount < 0) {
        break;
      }

      // update our remaining budget
      remainingBudget -= msgTokenCountResp.tokenCount;

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
        final firstOther = otherCharacters.values.first;
        final ocName = firstOther.name.isNotEmpty
            ? firstOther.name
            : ChatLog.defaultAiName;
        final aiPrefix =
            promptConfig.getWithSubsitutions(promptConfig.aiPrefix, firstOther);
        budgettedChatlog += "$aiPrefix$ocName:";
      } else {
        budgettedChatlog += slashCommandFooter;
      }
    }

    final prompt = preamble + budgettedChatlog;

    log("Remaining token budget: $remainingBudget (max of $tokenBudget)");
    return prompt;
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
  List<LorebookEntry> _getActiveEntries(
      ChatLog chatlog, List<Lorebook> lorebooks) {
    // build up the text that get's pattern matched. the formatting of this
    // text doesn't matter, so just jam it all together.
    const depthToSearch = 2;
    String relevantText = chatlog.context;
    for (final msg in chatlog.messages.reversed.take(depthToSearch)) {
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

  Future<(String, int)> _buildLorebookEntryString(
      List<LorebookEntry> matchedEntries, int loreTokenBudget) async {
    String allEntries = "";
    int usedTokens = 0;
    for (final entry in matchedEntries) {
      final entryString = '${entry.lore}\n\n';
      final entryStringTokenCount =
          await getTokenCount(GetTokenCountRequest(entryString));

      usedTokens += entryStringTokenCount.tokenCount;

      log('\tadding lorebook entry (using ${entryStringTokenCount.tokenCount} tokens): ${entry.patterns}');
      allEntries += entryString;

      // if we've filled our budget, make sure to stop here; yes this can
      // overflow the budget by the length of the last entry by design.
      if (usedTokens >= loreTokenBudget) {
        log('Lorebook entries have filled the budget of $loreTokenBudget tokens; stopping...');
        return (allEntries, usedTokens);
      }
    }
    return (allEntries, usedTokens);
  }
}
