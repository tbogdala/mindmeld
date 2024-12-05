import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import 'package:path/path.dart' as p;
import 'package:woolydart/woolydart.dart';
import 'dart:developer';

import 'chat_log.dart';
import 'config_app.dart';
import 'config_models.dart';
import 'lorebook.dart';
import 'platform_and_theming.dart';

// this class keeps track of all the state for a given text prediction
class PredictionStreamState {
  // these are the parameters to be used for the sampler
  wooly_gpt_params params;

  // the number of tokens that were processed for the prompt during prefill
  int promptTokenCount;

  // the sampler returned from the prompt processing and should be used for
  // generating new tokens. this resource must be free'd when it's no longer needed.
  GptSampler? sampler;

  // this keeps track of the predicted tokens
  TokenList predictions = [];

  // potentially a frozen prompt cache object that can be restored if the next
  // prediction stream has the exact same prompt.
  FrozenState? promptCache;

  // this is the prompt used to start the prediction stream
  String prompt;

  PredictionStreamState(this.params, this.prompt, this.promptTokenCount,
      this.sampler, this.promptCache);

  // free the memory associated with the frozen state, but needs a
  // LlamaModel to do so for the FFI call.
  void disposeCache(LlamaModel llamaModel) {
    // get rid of any state that we started out with
    if (promptCache != null) {
      llamaModel.freeFrozenState(promptCache!);
      promptCache = null;
    }
    if (sampler != null) {
      llamaModel.freeGptSampler(sampler!);
      sampler = null;
    }
  }
}

class StartPredictionStreamResult {
  bool success;
  int promptTokenCount;
  String? errorMessage;

  StartPredictionStreamResult(
      this.success, this.promptTokenCount, this.errorMessage);
}

class StartPredictionStreamRequest {
  String modelFilepath;
  ConfigModelSettings modelSettings;
  String promptString;
  List<String> antipromptStrings;
  List<String> drySequenceBreakerStrings;
  ChatLogHyperparameters hyperparameters;

  StartPredictionStreamRequest(
      this.modelFilepath,
      this.modelSettings,
      this.promptString,
      this.antipromptStrings,
      this.drySequenceBreakerStrings,
      this.hyperparameters);
}

class ContinuePredictionStreamResult {
  final Token nextToken;
  final bool isComplete;
  final String? errorMessage;
  final String? predictionSoFar;

  ContinuePredictionStreamResult(
      this.nextToken, this.isComplete, this.errorMessage, this.predictionSoFar);
}

class ContinuePredictionStreamRequest {}

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
  Completer<ContinuePredictionStreamResult>
      _isoResponseContinuePredictionStream = Completer();
  Completer<StartPredictionStreamResult> _isoResponsePredictionStreamStart =
      Completer();
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
    _isoResponseContinuePredictionStream = Completer();
    _isoResponsePredictionStreamStart = Completer();
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
    _isoResponseContinuePredictionStream = Completer();
    _isoResponsePredictionStreamStart = Completer();
    _isoResponseTokenCount = Completer();
    _isoResponseEnsureLoaded = Completer();
  }

  Future<StartPredictionStreamResult> startPredictionStream(
      StartPredictionStreamRequest request) async {
    await _isoReady.future;
    _isoResponsePredictionStreamStart = Completer();
    _toIsoPort!.send(request);
    return _isoResponsePredictionStreamStart.future;
  }

  Future<ContinuePredictionStreamResult> continuePredictionStream(
      ContinuePredictionStreamRequest request) async {
    await _isoReady.future;
    _isoResponseContinuePredictionStream = Completer();
    _toIsoPort!.send(request);
    return _isoResponseContinuePredictionStream.future;
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
    } else if (message is ContinuePredictionStreamResult) {
      //log('PredictionWorker: _handleResponseFromIsolate() got a continue prediction stream reply');
      _isoResponseContinuePredictionStream.complete(message);
    } else if (message is StartPredictionStreamResult) {
      //log('PredictionWorker: _handleResponseFromIsolate() got a start prediction stream reply');
      _isoResponsePredictionStreamStart.complete(message);
    } else if (message is GetTokenCountResult) {
      //log('PredictionWorker: _handleResponseFromIsolate() got a token count reply');
      _isoResponseTokenCount.complete(message);
    } else if (message is EnsureModelLoadedResult) {
      //log('PredictionWorker: _handleResponseFromIsolate() got an ensure model loaded reply');
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
      } else if (Platform.isWindows) {
        lib = "woolycore.dll";
      }
      log("PredictionWorker: Library loaded through DynamicLibrary.");
      llamaModel = LlamaModel(lib);

      // keep track of our prediction stream states with this
      PredictionStreamState? predictionStreamState;

      // start our message pump loop for the worker isolate
      workerReceivePort.listen((dynamic message) async {
        if (message is ContinuePredictionStreamRequest) {
          if (predictionStreamState != null) {
            final result = _continuePredictionStream(
                llamaModel!, predictionStreamState!, message);
            port.send(result);
            //log('PredictionWorker: Finished continue prediction stream request...');
          } else {
            port.send(ContinuePredictionStreamResult(
                0,
                false,
                'No prediction stream state established. Perform a StartPredictionStreamRequest first.',
                null));
          }
        } else if (message is StartPredictionStreamRequest) {
          if (predictionStreamState != null) {
            if (predictionStreamState!.promptCache != null) {
              if (predictionStreamState!.prompt == message.promptString) {
                // special case scenario, we have a cached prompt state and matching prompts
                // first we free our resources
                llamaModel!.freeGptSampler(predictionStreamState!.sampler!);
                predictionStreamState!.params.dispose();

                // then dethaw the state and set the modified state appropriately
                var params = _buildTextGenParams(llamaModel, message);
                final (defrostedTokenCount, newSampler) =
                    llamaModel.defrostFrozenState(
                        params, predictionStreamState!.promptCache!);
                assert(defrostedTokenCount ==
                    predictionStreamState!.promptTokenCount);
                predictionStreamState!.params = params;
                predictionStreamState!.predictions = [];
                predictionStreamState!.sampler = newSampler;

                port.send(StartPredictionStreamResult(
                    true, defrostedTokenCount, null));
                log('PredictionWorker: Finished start prediction stream request for a frozen prompt...');
                return;
              } else {
                // get rid of any state that we started out with
                predictionStreamState!.disposeCache(llamaModel!);
              }
            }
          }

          // create a new prediction stream state
          final (result, streamState) =
              _startPredictionStream(llamaModel!, message);
          predictionStreamState = streamState;
          port.send(result);
          log('PredictionWorker: Finished start prediction stream request...');
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
          if (predictionStreamState != null) {
            predictionStreamState!.disposeCache(llamaModel!);
          }
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
    if (modelFilepath != llamaModel.loadedModelFilepath) {
      log("PredictionWorker: Detecting a different LLM model, so closing the current one...");
      llamaModel.freeModel();
    }

    if (!llamaModel.isModelLoaded()) {
      final modelParams = llamaModel.getDefaultModelParams()
        ..n_gpu_layers = modelSettings.gpuLayers
        ..use_mmap = isRunningOnDesktop() ? true : false;
      final contextParams = llamaModel.getDefaultContextParams()
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

  static wooly_gpt_params _buildTextGenParams(
      LlamaModel llamaModel, StartPredictionStreamRequest args) {
    // we create a 'defaults' object here since the class has all the
    // 'normal' default values initialized in the members; avoids duplication
    final defaults = ChatLogHyperparameters();
    wooly_gpt_params params = llamaModel.getTextGenParams()
      ..seed = args.hyperparameters.seed
      ..temp = args.hyperparameters.temp ?? defaults.temp!
      ..n_threads = args.modelSettings.threadCount ?? -1
      ..n_predict = args.hyperparameters.tokens
      ..top_k = args.hyperparameters.topK ?? defaults.topK!
      ..top_p = args.hyperparameters.topP ?? defaults.topP!
      ..min_p = args.hyperparameters.minP ?? defaults.minP!
      ..xtc_probability =
          args.hyperparameters.xtcProbability ?? defaults.xtcProbability!
      ..xtc_threshold =
          args.hyperparameters.xtcThreshold ?? defaults.xtcThreshold!
      ..dynatemp_range =
          args.hyperparameters.dynatempRange ?? defaults.dynatempRange!
      ..dynatemp_exponent =
          args.hyperparameters.dynatempExponent ?? defaults.dynatempExponent!
      ..typical_p = args.hyperparameters.typicalP ?? defaults.typicalP!
      ..penalty_freq =
          args.hyperparameters.frequencyPenalty ?? defaults.frequencyPenalty!
      ..penalty_present =
          args.hyperparameters.presencePenalty ?? defaults.presencePenalty!
      ..penalty_repeat =
          args.hyperparameters.repeatPenalty ?? defaults.repeatPenalty!
      ..penalty_last_n =
          args.hyperparameters.repeatLastN ?? defaults.repeatLastN!
      ..dry_multiplier =
          args.hyperparameters.dryMultiplier ?? defaults.dryMultiplier!
      ..dry_base = args.hyperparameters.dryBase ?? defaults.dryBase!
      ..dry_allowed_length =
          args.hyperparameters.dryAllowedLength ?? defaults.dryAllowedLength!
      ..dry_penalty_last_n =
          args.hyperparameters.dryPenaltyLastN ?? defaults.dryPenaltyLastN!
      ..ignore_eos = args.modelSettings.ignoreEos
      ..flash_attn = args.modelSettings.flashAttention
      ..prompt_cache_all = args.modelSettings.promptCache
      ..n_batch = args.modelSettings.batchSize ?? 128;
    params.setPrompt(args.promptString);
    params.setAntiprompts(args.antipromptStrings);
    params.setDrySequenceBreakers(args.drySequenceBreakerStrings);
    log('_buildTextGenParams: A total of ${args.antipromptStrings.length} antiprompt strings: ${args.antipromptStrings.join(",")}');
    return params;
  }

  static (StartPredictionStreamResult, PredictionStreamState?)
      _startPredictionStream(
          LlamaModel llamaModel, StartPredictionStreamRequest args) {
    wooly_gpt_params? params;
    try {
      // make sure our model is loaded
      _ensureModelIsLoaded(llamaModel, args.modelFilepath, args.modelSettings,
          args.hyperparameters);

      params = _buildTextGenParams(llamaModel, args);

      // start the prompt processing for the stream to do all the prefill.
      var (promptTokenCount, sampler) = llamaModel.processPrompt(params);
      if (promptTokenCount <= 0) {
        return (
          StartPredictionStreamResult(false, 0,
              '<Error while starting prediction stream. Error code: $promptTokenCount>'),
          null
        );
      }

      // now, if prompt caching is enabled, we freeze the model's state
      FrozenState? frozenPrompt;
      if (params.prompt_cache_all) {
        frozenPrompt = llamaModel.freezePrompt(params);
      }

      // everything worked, so return our response and a new prediction state
      return (
        StartPredictionStreamResult(true, promptTokenCount, null),
        PredictionStreamState(
            params, args.promptString, promptTokenCount, sampler, frozenPrompt)
      );
    } catch (e) {
      var errormsg = e.toString();
      log("PredictionWorker: Caught exception trying to start predict stream: $errormsg");
      return (
        StartPredictionStreamResult(false, 0, '<Error: $errormsg>'),
        null
      );
    } finally {
      params?.dispose();
    }
  }

  static ContinuePredictionStreamResult _continuePredictionStream(
      LlamaModel llamaModel,
      PredictionStreamState streamState,
      ContinuePredictionStreamRequest args) {
    // start by sampling the next token
    Token nextToken = llamaModel.sampleNextToken(streamState.sampler!);

    // check to see if it should stop the text prediction process
    if (llamaModel.checkEogAndAntiprompt(
        streamState.params, streamState.sampler!)) {
      log('PredictionWorker: End of generation or antiprompt token encountered - halting prediction...');
      streamState.predictions.add(nextToken);
      var finalResponse =
          llamaModel.detokenizeToText(streamState.predictions, false);
      return ContinuePredictionStreamResult(
          nextToken, true, null, finalResponse);
    }

    // run the model to calculate the next logits for the next token prediction,
    // but only do this if it's not the last iteration of the loop
    final success = llamaModel.processNextToken(nextToken);
    if (!success) {
      return ContinuePredictionStreamResult(
          nextToken,
          false,
          'PredictionWorker failed to process the next token for token: $nextToken)',
          null);
    }

    // to spare the client from having to call our isolate back to detokenize the prediction,
    // we just do it now and attatch it to the stream result
    var detokenized =
        llamaModel.detokenizeToText(streamState.predictions, false);

    streamState.predictions.add(nextToken);
    return ContinuePredictionStreamResult(nextToken, false, null, detokenized);
  }

  // will return the default prompt unless `system_prompt` is in the application
  // configuration.
  String _getSystemPrompt(ConfigApp configApp) {
    const defaultSystemPrompt =
        "You are an intelligent, skilled, versatile writer.\nYour task is to write a role-play response based on the information below.Maintain the character persona but allow it to evolve with the story.\nBe creative and proactive. Drive the story forward, introducing plot lines and events when relevant.\nAll types of outputs are encouraged; respond accordingly to the narrative.\nInclude dialogues, actions, and thoughts in each response.\nUtilize all five senses to describe scenarios within the character's dialogue.\nUse emotional symbols such as \"!\" and \"~\" in appropriate contexts.\nIncorporate onomatopoeia when suitable.\nAllow time for other characters to respond with their own input, respecting their agency.\n\n<Forbidden>\nUsing excessive literary embellishments and purple prose unless dictated by Character's persona.\nWriting for, speaking, thinking, acting, or replying as a different in your response.\nRepetitive and monotonous outputs.\nPositivity bias in your replies.\nBeing overly extreme or NSFW when the narrative context is inappropriate.\n</Forbidden>\n\nFollow the instructions above, avoiding the items listed in <Forbidden></Forbidden>.\n";

    var configOverride = configApp.getOption('prompt_system');
    return configOverride ?? defaultSystemPrompt;
  }

  // will return the prompt formatted lorebook section. uses the default format
  // unless `prompt_lorebook` is in the application configuration.
  // if the loreEntriesString is empty, and empty string will be returned.
  String _getLorebookPromptFragment(
      ConfigApp configApp, String loreEntriesString) {
    if (loreEntriesString.isEmpty) {
      return loreEntriesString;
    }

    const defaultPromptFragment = '## Relevant Lore:\n\n{{lorebook}}';
    String? configOverride = configApp.getOption('prompt_lorebook');
    String fragment = configOverride ?? defaultPromptFragment;

    return fragment.replaceAll('{{lorebook}}', loreEntriesString);
  }

  // will return the default maximum lore percentage allowed for the prompt unless
  // `max_lore_ptc` is in the application configuration.
  double _getLorePercentage(ConfigApp configApp) {
    const defaultMaxLorePercentage = 0.1;

    var configOverride = configApp.getOptionAsDouble('max_lore_pct');
    return configOverride ?? defaultMaxLorePercentage;
  }

  // will return the prompt formatted story context section. uses the default format
  // unless `prompt_context` is in the application configuration.
  String _getContextPromptFragment(ConfigApp configApp, String context) {
    const defaultPromptFragment =
        '\n## Overall Plot Description:\n\n{{context}}\n\n';
    String? configOverride = configApp.getOption('prompt_context');
    String fragment = configOverride ?? defaultPromptFragment;

    return fragment.replaceAll('{{context}}', context);
  }

  // will return the prompt formatted AI character description. uses the default format
  // unless `prompt_ai_desc` is in the application configuration. additionally, if
  // `personality` is not empty, it will add a string to describe the personality
  // of the character using the default format or the `prompt_ai_pers` value in the
  // application configuration.
  String _getAiCharacterDescPromptFragment(
      ConfigApp configApp, String name, String desc, String personality) {
    const defaultPromptFragment =
        '### {{ai_name}}\n\n{{ai_desc}}\n{{ai_personality_frag}}';
    String? configOverride = configApp.getOption('prompt_ai_desc');
    String descFragment = configOverride ?? defaultPromptFragment;
    final configuredDescFragment = descFragment
        .replaceAll('{{ai_name}}', name)
        .replaceAll('{{ai_desc}}', desc);

    var configuredPersFragment = "";

    if (personality.isNotEmpty) {
      const defaultPersPromptFragment =
          '\n{{ai_name}}\'s Personality Traits: {{ai_personality}}\n';
      String? configPersOverride = configApp.getOption('prompt_ai_pers');
      String persFragment = configPersOverride ?? defaultPersPromptFragment;
      configuredPersFragment = persFragment
          .replaceAll('{{ai_name}}', name)
          .replaceAll('{{ai_personality}}', personality);
    }

    return configuredDescFragment.replaceAll(
        "{{ai_personality_frag}}", configuredPersFragment);
  }

  // will return the prompt formatted character description for the human user.
  // uses the default format unless `prompt_user_desc` is in the application configuration.
  String _getUserCharacterDescPromptFragment(
      ConfigApp configApp, String name, String desc) {
    const defaultPromptFragment = '### {{user_name}}\n\n{{user_desc}}\n';
    String? configOverride = configApp.getOption('prompt_user_desc');
    String descFragment = configOverride ?? defaultPromptFragment;
    return descFragment
        .replaceAll('{{user_name}}', name)
        .replaceAll('{{user_desc}}', desc);
  }

  // will return the prompt formatted section for all of the characters in the chatlog.
  // this allows for configuring how the section as a whole is presented and the
  // parameters `configuredUserDesc` and `configuredAiDesc` are for the user and
  // AI character descriptions respectively and should have already gone through
  // the 'configurability' pass to pull the formatting for each.
  // uses the default format unless `prompt_characters` is in the application configuration.
  String _getCharacterPromptFragment(
      ConfigApp configApp, String configuredUserDesc, String configuredAiDesc) {
    const defaultPromptFragment =
        '## Characters:\n\n{{user_desc}}\n{{ai_desc}}';
    String? configOverride = configApp.getOption('prompt_characters');
    String descFragment = configOverride ?? defaultPromptFragment;
    return descFragment
        .replaceAll('{{user_desc}}', configuredUserDesc)
        .replaceAll('{{ai_desc}}', configuredAiDesc);
  }

  // will return the prompt formatted section of the prompt for everything but
  // the chatlog - in a normal invocation of the prompt building mechanism.
  // this allows for configuring how the section as a whole is presented.
  // the `system` parameter should give all the instructions for writing a response.
  // the `context` parameter should be the story context from the chatlog.
  // the `characters` parameter should be the formatted fragment for the user
  // and AI character descriptions.
  // the `lorebookEntries` parameter should be the formatted fragment for all of
  // the relevant lorebook entries for this conversation - if empty, this section
  // will be replaced with an empty string.
  // uses the default format unless `prompt_chat` is in the application configuration.
  String _getChatPromptFragment(ConfigApp configApp, String system,
      String context, String characters, String lorebookEntries) {
    const defaultPromptFragment =
        '{{system}}{{story_context}}{{characters}}\n{{lorebook}}';
    String? configOverride = configApp.getOption('prompt_chat');
    String descFragment = configOverride ?? defaultPromptFragment;
    return descFragment
        .replaceAll('{{system}}', system)
        .replaceAll('{{story_context}}', context)
        .replaceAll('{{characters}}', characters)
        .replaceAll('{{lorebook}}', lorebookEntries);
  }

  // will return the prompt formatted section of the prompt for everything but
  // the chatlog for the special 'narrator' mode.
  // this allows for configuring how the section as a whole is presented.
  // the `system` parameter should give all the instructions for writing a response.
  // the `context` parameter should be the story context from the chatlog.
  // the `characters` parameter should be the formatted fragment for the user
  // and AI character descriptions.
  // the `lorebookEntries` parameter should be the formatted fragment for all of
  // the relevant lorebook entries for this conversation - if empty, this section
  // will be replaced with an empty string.
  // the `narratorSyste
  // uses the default format unless `prompt_narrator` is in the application configuration.
  String _getNarratorPromptFragment(
      ConfigApp configApp,
      String system,
      String context,
      String characters,
      String lorebookEntries,
      String narratorDesc,
      String narratorRequest) {
    const defaultPromptFragment =
        '{{system}}\nThe user has requested that you {{narrator_request}}\n{{story_context}}{{characters}}\n### Narrator\n\n{{narrator_desc}}\n\n{{lorebook}}';

    String? configOverride = configApp.getOption('prompt_narrator');
    String descFragment = configOverride ?? defaultPromptFragment;
    return descFragment
        .replaceAll('{{system}}', system)
        .replaceAll('{{story_context}}', context)
        .replaceAll('{{characters}}', characters)
        .replaceAll('{{lorebook}}', lorebookEntries)
        .replaceAll('{{narrator_desc}}', narratorDesc)
        .replaceAll('{{narrator_request}}', narratorRequest);
  }

  // will return the prompt formatted character description for the special 'Narrator'.
  // uses the default format unless `prompt_narrator_desc` is in the application configuration.
  String _getNarratorDesc(ConfigApp configApp) {
    const String defaultNarratorDescription = '''
The Narrator is an enigmatic, omniscient entity that guides the story. Unseen yet ever-present, the Narrator shapes the narrative, describes the world, and gives voice to NPCs. When invoked with the '/narrator' command, the Narrator will focus on the requested task. Otherwise, the Narrator will:

- Provide vivid, sensory descriptions of environments
- Introduce and describe characters
- Narrate events and actions
- Provide dialogue for NPCs
- Create atmosphere and mood through descriptive language
- Offer subtle hints or clues to guide the story
- Respond to player actions with appropriate narrative consequences

The Narrator should maintain a neutral tone, avoiding direct interaction with players unless specifically addressed. The goal is to create an immersive, dynamic story world that reacts to player choices while maintaining narrative coherence.''';
    String? configOverride = configApp.getOption('prompt_narrator_desc');
    return configOverride ?? defaultNarratorDescription;
  }

  // will return the prompt formatted system message for the special 'Narrator' response.
  // uses the default format unless `prompt_narrator_system` is in the application configuration.
  String _getNarratorSystem(ConfigApp configApp) {
    const String defaultNarratorSystem =
        'You are an omniscient, creative narrator for an interactive story. Your task is to vividly describe environments, characters, and events, as well as provide dialogue and actions for non-player characters (NPCs) when appropriate.';
    String? configOverride = configApp.getOption('prompt_narrator_system');
    return configOverride ?? defaultNarratorSystem;
  }

  // returns a string for the entire prompt to send to the AI to generate a response.
  // this potentially pulls many overrides from the application configuration file
  // to construct the whole prompt.
  Future<String> buildPrompt(ConfigApp configApp, ChatLog chatlog,
      List<Lorebook> lorebooks, int tokenBudget, bool continueMsg) async {
    // start by getting the system prompt, which can be overridden in the app config.
    String configuredSystemPrompt = _getSystemPrompt(configApp);

    // we have a hard cap on how much lore to add so it doesn't gobble the whole context
    double maxLorePercentage = _getLorePercentage(configApp);

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
        configApp, activeEntries, (maxLorePercentage * tokenBudget).round());
    log("A total of $loreTokenCount tokens used for lorebook entries.");

    // setup the human description strings for the user interacting with the app
    final String humanName = humanCharacter.name.isNotEmpty
        ? humanCharacter.name
        : ChatLog.defaultUserName;
    final String humanDesc = humanCharacter.description.isNotEmpty
        ? humanCharacter.description
        : ChatLog.defaultUserDesc;

    String defaultAINameList = '';
    String aiDescriptions = '';
    assert(otherCharacters.isNotEmpty);

    // add the AI character descriptions together into a final string
    final ocTotal = otherCharacters.length;
    var ocIndex = 0;
    for (final oc in otherCharacters.values) {
      final ocName = oc.name.isNotEmpty ? oc.name : ChatLog.defaultAiName;

      // we build a string of names to be used for the default context if the user doesn't supply one.
      if (ocIndex + 1 >= ocTotal) {
        defaultAINameList += ' and $ocName';
      } else {
        defaultAINameList += ', $ocName';
      }

      // then we add the character description to the string that will be used in the full prompt.
      final ocDesc =
          oc.description.isNotEmpty ? oc.description : ChatLog.defaultAiDesc;
      final aiDescFragment = _getAiCharacterDescPromptFragment(
          configApp, ocName, ocDesc, oc.personality);
      aiDescriptions += aiDescFragment;

      ocIndex += 1;
    }

    // pull the story context from the chatlog or build a default one if needed
    String ctxDesc = chatlog.context.isNotEmpty
        ? chatlog.context
        : "$humanName$defaultAINameList are having a conversation over text messaging.";
    final configuredCtxDesc = _getContextPromptFragment(configApp, ctxDesc);

    // bulid the whole system preamble
    String promptFormatSystem = promptConfig.system.isNotEmpty
        ? promptConfig.system
        : configuredSystemPrompt;

    // build the whole character section
    String configuredUserDesc =
        _getUserCharacterDescPromptFragment(configApp, humanName, humanDesc);
    String configuredCharacters = _getCharacterPromptFragment(
        configApp, configuredUserDesc, aiDescriptions);

    // build the lorebook fragment
    String configuredLorebook =
        _getLorebookPromptFragment(configApp, loreString);

    // tie all of it together: system message, chatlog story context and the characters
    String system = _getChatPromptFragment(configApp, promptFormatSystem,
        configuredCtxDesc, configuredCharacters, configuredLorebook);

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

      // rebuild the prompt but swap out for the narrator parts and recalculate the budget
      final configuredNarratorSystemMsg = _getNarratorSystem(configApp);
      final configuredNarratorDesc = _getNarratorDesc(configApp);
      system = _getNarratorPromptFragment(
          configApp,
          configuredNarratorSystemMsg,
          configuredCtxDesc,
          configuredCharacters,
          configuredLorebook,
          configuredNarratorDesc,
          narratorRequest);

      preamble =
          promptConfig.preSystemPrefix + system + promptConfig.preSystemSuffix;
      final preambleTokenCountResp =
          await getTokenCount(GetTokenCountRequest(preamble));
      remainingBudget = tokenBudget - preambleTokenCountResp.tokenCount;

      final userPrefix =
          promptConfig.getWithSubsitutions(promptConfig.userPrefix, null);
      final aiPrefix =
          promptConfig.getWithSubsitutions(promptConfig.aiPrefix, null);
      slashCommandFooter =
          "${userPrefix}Narrator, $narratorRequest${promptConfig.userSuffix}${aiPrefix}Narrator: ";
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

  // will return the prompt formatted lorebook entry. uses the default format
  // unless `prompt_lorebook_entry` is in the application configuration.
  String _getLorebookEntryPromptFragment(
      ConfigApp configApp, LorebookEntry entry) {
    const defaultPromptFragment = '{{entry_lore}}\n\n';
    String? configOverride = configApp.getOption('prompt_lorebook_entry');
    String fragment = configOverride ?? defaultPromptFragment;

    return fragment.replaceAll('{{entry_lore}}', entry.lore);
  }

  Future<(String, int)> _buildLorebookEntryString(ConfigApp configApp,
      List<LorebookEntry> matchedEntries, int loreTokenBudget) async {
    String allEntries = "";
    int usedTokens = 0;
    for (final entry in matchedEntries) {
      final entryString = _getLorebookEntryPromptFragment(configApp, entry);
      final entryStringTokenCount =
          await getTokenCount(GetTokenCountRequest(entryString));

      usedTokens += entryStringTokenCount.tokenCount;

      log('\tPadding lorebook entry (using ${entryStringTokenCount.tokenCount} tokens): ${entry.patterns}');
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
