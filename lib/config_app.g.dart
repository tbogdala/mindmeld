// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_app.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfigApp _$ConfigAppFromJson(Map<String, dynamic> json) => ConfigApp()
  ..version = (json['version'] as num).toInt()
  ..options = Map<String, String>.from(json['options'] as Map);

Map<String, dynamic> _$ConfigAppToJson(ConfigApp instance) => <String, dynamic>{
      'version': instance.version,
      'options': instance.options,
    };
