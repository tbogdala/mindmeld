// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfigModelSettings _$ConfigModelSettingsFromJson(Map<String, dynamic> json) =>
    ConfigModelSettings(
      json['modelFilepath'] as String,
      (json['gpuLayers'] as num).toInt(),
      (json['contextSize'] as num?)?.toInt(),
      (json['threadCount'] as num?)?.toInt(),
      (json['batchSize'] as num?)?.toInt(),
      json['promptCache'] as bool,
      json['ignoreEos'] as bool,
      json['flashAttention'] as bool,
      json['promptFormat'] as String?,
    )..version = (json['version'] as num).toInt();

Map<String, dynamic> _$ConfigModelSettingsToJson(
        ConfigModelSettings instance) =>
    <String, dynamic>{
      'version': instance.version,
      'modelFilepath': instance.modelFilepath,
      'gpuLayers': instance.gpuLayers,
      'contextSize': instance.contextSize,
      'threadCount': instance.threadCount,
      'batchSize': instance.batchSize,
      'promptCache': instance.promptCache,
      'ignoreEos': instance.ignoreEos,
      'flashAttention': instance.flashAttention,
      'promptFormat': instance.promptFormat,
    };

ConfigModelFiles _$ConfigModelFilesFromJson(Map<String, dynamic> json) =>
    ConfigModelFiles(
      modelFiles: (json['modelFiles'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k, ConfigModelSettings.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$ConfigModelFilesToJson(ConfigModelFiles instance) =>
    <String, dynamic>{
      'modelFiles': instance.modelFiles,
    };
