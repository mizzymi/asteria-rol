import 'package:hive_flutter/hive_flutter.dart';

import '../models/character.dart';

class CharacterStorageService {
  static const String boxName = 'characters';

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  static Box get _box {
    return Hive.box(boxName);
  }

  static List<Character> getCharacters() {
    final characters = <Character>[];

    for (final value in _box.values) {
      if (value == null) {
        continue;
      }

      try {
        final map = Map<dynamic, dynamic>.from(value);

        characters.add(Character.fromMap(map));
      } catch (_) {
        continue;
      }
    }

    return characters;
  }

  static Character? getCharacter(String id) {
    final value = _box.get(id);

    if (value == null) {
      return null;
    }

    try {
      return Character.fromMap(Map<dynamic, dynamic>.from(value));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveCharacter(Character character) async {
    await _box.put(character.id, character.toMap());
  }

  static Future<void> deleteCharacter(String id) async {
    await _box.delete(id);
  }

  static Future<void> clearAll() async {
    await _box.clear();
  }
}
