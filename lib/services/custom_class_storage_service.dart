import 'package:hive_flutter/hive_flutter.dart';

import '../models/custom_class_definition.dart';

class CustomClassStorageService {
  static const String boxName = 'custom_classes';

  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  static Box get _box => Hive.box(boxName);

  static List<CustomClassDefinition> getClasses(String campaignId) {
    final result = <CustomClassDefinition>[];
    for (final value in _box.values) {
      if (value is! Map) continue;
      try {
        final definition = CustomClassDefinition.fromMap(
          Map<dynamic, dynamic>.from(value),
        );
        if (definition.classId.trim().isNotEmpty &&
            definition.campaignId == campaignId) {
          result.add(definition);
        }
      } catch (_) {
        continue;
      }
    }
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  static String _key(String campaignId, String classId) =>
      '$campaignId::$classId';

  static CustomClassDefinition? getClass(String campaignId, String classId) {
    final value = _box.get(_key(campaignId, classId));
    if (value is! Map) return null;
    try {
      final definition = CustomClassDefinition.fromMap(
        Map<dynamic, dynamic>.from(value),
      );
      return definition.campaignId == campaignId ? definition : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveClass(CustomClassDefinition definition) async {
    if (definition.campaignId.trim().isEmpty ||
        definition.classId.trim().isEmpty) {
      throw const FormatException('La clase requiere campaignId y classId.');
    }
    await _box.put(
      _key(definition.campaignId, definition.classId),
      definition.toMap(),
    );
  }

  static Future<void> deleteClass(String campaignId, String classId) async {
    await _box.delete(_key(campaignId, classId));
  }
}
