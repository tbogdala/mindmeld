// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatLogMessage _$ChatLogMessageFromJson(Map<String, dynamic> json) =>
    ChatLogMessage(
      json['senderName'] as String,
      json['message'] as String,
      json['humanSent'] as bool,
      (json['generationSpeedTPS'] as num?)?.toDouble(),
    )..messageCreatedAt = DateTime.parse(json['messageCreatedAt'] as String);

Map<String, dynamic> _$ChatLogMessageToJson(ChatLogMessage instance) =>
    <String, dynamic>{
      'senderName': instance.senderName,
      'message': instance.message,
      'humanSent': instance.humanSent,
      'messageCreatedAt': instance.messageCreatedAt.toIso8601String(),
      'generationSpeedTPS': instance.generationSpeedTPS,
    };

ChatLogHyperparameters _$ChatLogHyperparametersFromJson(
        Map<String, dynamic> json) =>
    ChatLogHyperparameters()
      ..seed = (json['seed'] as num).toInt()
      ..tokens = (json['tokens'] as num).toInt()
      ..topK = (json['topK'] as num).toInt()
      ..topP = (json['topP'] as num).toDouble()
      ..minP = (json['minP'] as num).toDouble()
      ..temp = (json['temp'] as num).toDouble()
      ..repeatPenalty = (json['repeatPenalty'] as num).toDouble()
      ..repeatLastN = (json['repeatLastN'] as num).toInt()
      ..tfsZ = (json['tfsZ'] as num).toDouble()
      ..typicalP = (json['typicalP'] as num).toDouble()
      ..frequencyPenalty = (json['frequencyPenalty'] as num).toDouble()
      ..presencePenalty = (json['presencePenalty'] as num).toDouble()
      ..mirostatType = (json['mirostatType'] as num).toInt()
      ..mirostatEta = (json['mirostatEta'] as num).toDouble()
      ..mirostatTau = (json['mirostatTau'] as num).toDouble();

Map<String, dynamic> _$ChatLogHyperparametersToJson(
        ChatLogHyperparameters instance) =>
    <String, dynamic>{
      'seed': instance.seed,
      'tokens': instance.tokens,
      'topK': instance.topK,
      'topP': instance.topP,
      'minP': instance.minP,
      'temp': instance.temp,
      'repeatPenalty': instance.repeatPenalty,
      'repeatLastN': instance.repeatLastN,
      'tfsZ': instance.tfsZ,
      'typicalP': instance.typicalP,
      'frequencyPenalty': instance.frequencyPenalty,
      'presencePenalty': instance.presencePenalty,
      'mirostatType': instance.mirostatType,
      'mirostatEta': instance.mirostatEta,
      'mirostatTau': instance.mirostatTau,
    };

ChatLogCharacter _$ChatLogCharacterFromJson(Map<String, dynamic> json) =>
    ChatLogCharacter(
      name: json['name'] as String,
      description: json['description'] as String,
      personality: json['personality'] as String,
      isUserControlled: json['isUserControlled'] as bool,
    )..profilePicFilename = json['profilePicFilename'] as String?;

Map<String, dynamic> _$ChatLogCharacterToJson(ChatLogCharacter instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'personality': instance.personality,
      'isUserControlled': instance.isUserControlled,
      'profilePicFilename': instance.profilePicFilename,
    };

ChatLog _$ChatLogFromJson(Map<String, dynamic> json) => ChatLog(
      json['name'] as String,
      json['modelName'] as String,
      $enumDecode(_$ModelPromptStyleEnumMap, json['modelPromptStyle']),
      json['context'] as String,
    )
      ..version = (json['version'] as num).toInt()
      ..hyperparmeters = ChatLogHyperparameters.fromJson(
          json['hyperparmeters'] as Map<String, dynamic>)
      ..characters = (json['characters'] as List<dynamic>)
          .map((e) => ChatLogCharacter.fromJson(e as Map<String, dynamic>))
          .toList()
      ..messages = (json['messages'] as List<dynamic>)
          .map((e) => ChatLogMessage.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$ChatLogToJson(ChatLog instance) => <String, dynamic>{
      'version': instance.version,
      'name': instance.name,
      'modelName': instance.modelName,
      'modelPromptStyle': _$ModelPromptStyleEnumMap[instance.modelPromptStyle]!,
      'context': instance.context,
      'hyperparmeters': instance.hyperparmeters,
      'characters': instance.characters,
      'messages': instance.messages,
    };

const _$ModelPromptStyleEnumMap = {
  ModelPromptStyle.alpaca: 'alpaca',
  ModelPromptStyle.chatml: 'chatml',
  ModelPromptStyle.gemma: 'gemma',
  ModelPromptStyle.llama3: 'llama3',
  ModelPromptStyle.mistralInstruct: 'mistralInstruct',
  ModelPromptStyle.opusV14: 'opusV14',
  ModelPromptStyle.phi3: 'phi3',
  ModelPromptStyle.tinyllama: 'tinyllama',
  ModelPromptStyle.vicuna: 'vicuna',
  ModelPromptStyle.zephyr: 'zephyr',
};
