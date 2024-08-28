// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lorebook.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LorebookEntry _$LorebookEntryFromJson(Map<String, dynamic> json) =>
    LorebookEntry(
      patterns: json['patterns'] as String,
      lore: json['lore'] as String,
    );

Map<String, dynamic> _$LorebookEntryToJson(LorebookEntry instance) =>
    <String, dynamic>{
      'patterns': instance.patterns,
      'lore': instance.lore,
    };

Lorebook _$LorebookFromJson(Map<String, dynamic> json) => Lorebook(
      name: json['name'] as String,
      characterNames: json['characterNames'] as String,
      entries: (json['entries'] as List<dynamic>)
          .map((e) => LorebookEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    )..version = (json['version'] as num).toInt();

Map<String, dynamic> _$LorebookToJson(Lorebook instance) => <String, dynamic>{
      'version': instance.version,
      'name': instance.name,
      'characterNames': instance.characterNames,
      'entries': instance.entries,
    };
