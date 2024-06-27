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

ChatLog _$ChatLogFromJson(Map<String, dynamic> json) => ChatLog(
      json['name'] as String,
      json['humanName'] as String,
      json['aiName'] as String,
      json['modelName'] as String,
      $enumDecode(_$ModelPromptStyleEnumMap, json['modelPromptStyle']),
    )
      ..version = (json['version'] as num).toInt()
      ..humanDescription = json['humanDescription'] as String?
      ..aiDescription = json['aiDescription'] as String?
      ..aiPersonality = json['aiPersonality'] as String?
      ..context = json['context'] as String?
      ..hyperparmeters = ChatLogHyperparameters.fromJson(
          json['hyperparmeters'] as Map<String, dynamic>)
      ..messages = (json['messages'] as List<dynamic>)
          .map((e) => ChatLogMessage.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$ChatLogToJson(ChatLog instance) => <String, dynamic>{
      'version': instance.version,
      'name': instance.name,
      'humanName': instance.humanName,
      'humanDescription': instance.humanDescription,
      'aiName': instance.aiName,
      'aiDescription': instance.aiDescription,
      'aiPersonality': instance.aiPersonality,
      'context': instance.context,
      'modelName': instance.modelName,
      'modelPromptStyle': _$ModelPromptStyleEnumMap[instance.modelPromptStyle]!,
      'hyperparmeters': instance.hyperparmeters,
      'messages': instance.messages,
    };

const _$ModelPromptStyleEnumMap = {
  ModelPromptStyle.alpaca: 'alpaca',
  ModelPromptStyle.chatml: 'chatml',
  ModelPromptStyle.llama3: 'llama3',
  ModelPromptStyle.opusV12: 'opusV12',
  ModelPromptStyle.phi3: 'phi3',
  ModelPromptStyle.tinyllama: 'tinyllama',
  ModelPromptStyle.vicuna: 'vicuna',
  ModelPromptStyle.zephyr: 'zephyr',
};
