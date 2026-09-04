import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/passive.dart';

class PassiveLibraryService {
  static const String _storageKey = 'passive_library_definitions';

  static Future<List<CharacterPassive>> loadPassives() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    return raw
        .map((str) {
          try {
            return CharacterPassive.fromMap(jsonDecode(str));
          } catch (_) {
            return null;
          }
        })
        .whereType<CharacterPassive>()
        .toList();
  }

  static Future<CharacterPassive?> getPassiveById(String id) async {
    final passives = await loadPassives();
    try {
      return passives.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> savePassive(CharacterPassive passive) async {
    final prefs = await SharedPreferences.getInstance();
    final passives = await loadPassives();

    final index = passives.indexWhere((p) => p.id == passive.id);
    if (index >= 0) {
      passives[index] = passive;
    } else {
      passives.add(passive);
    }

    final raw = passives.map((p) => jsonEncode(p.toMap())).toList();
    await prefs.setStringList(_storageKey, raw);
  }
}
