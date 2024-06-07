// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatLogMessage _$ChatLogMessageFromJson(Map<String, dynamic> json) =>
    ChatLogMessage(
      json['senderName'] as String,
      json['message'] as String,
      (json['generationSpeedTPS'] as num?)?.toDouble(),
    )..messageCreatedAt = DateTime.parse(json['messageCreatedAt'] as String);

Map<String, dynamic> _$ChatLogMessageToJson(ChatLogMessage instance) =>
    <String, dynamic>{
      'senderName': instance.senderName,
      'message': instance.message,
      'messageCreatedAt': instance.messageCreatedAt.toIso8601String(),
      'generationSpeedTPS': instance.generationSpeedTPS,
    };

ChatLog _$ChatLogFromJson(Map<String, dynamic> json) => ChatLog(
      json['name'] as String,
      json['modelFilepath'] as String,
      $enumDecode(_$ModelPromptStyleEnumMap, json['modelPromptStyle']),
    )..messages = (json['messages'] as List<dynamic>)
        .map((e) => ChatLogMessage.fromJson(e as Map<String, dynamic>))
        .toList();

Map<String, dynamic> _$ChatLogToJson(ChatLog instance) => <String, dynamic>{
      'name': instance.name,
      'modelFilepath': instance.modelFilepath,
      'modelPromptStyle': _$ModelPromptStyleEnumMap[instance.modelPromptStyle]!,
      'messages': instance.messages,
    };

const _$ModelPromptStyleEnumMap = {
  ModelPromptStyle.alpaca: 'alpaca',
  ModelPromptStyle.chatml: 'chatml',
  ModelPromptStyle.phi3: 'phi3',
  ModelPromptStyle.tinychat: 'tinychat',
  ModelPromptStyle.vicuna: 'vicuna',
  ModelPromptStyle.zephyr: 'zephyr',
};
