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

  static List<CustomClassDefinition> getClasses() {
    final result = <CustomClassDefinition>[];
    for (final value in _box.values) {
      if (value is! Map) continue;
      try {
        final definition = CustomClassDefinition.fromMap(
          Map<dynamic, dynamic>.from(value),
        );
        if (definition.classId.trim().isNotEmpty) {
          result.add(definition);
        }
      } catch (_) {
        continue;
      }
    }
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  static CustomClassDefinition? getClass(String classId) {
    final value = _box.get(classId);
    if (value is! Map) return null;
    try {
      return CustomClassDefinition.fromMap(Map<dynamic, dynamic>.from(value));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveClass(CustomClassDefinition definition) async {
    await _box.put(definition.classId, definition.toMap());
  }

  static Future<void> deleteClass(String classId) async {
    await _box.delete(classId);
  }
}
