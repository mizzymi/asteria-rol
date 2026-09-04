import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ability.dart';

class AbilityLibraryService {
  static const String _storageKey = 'ability_library_definitions';

  static Future<List<CharacterAbility>> loadAbilities() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    return raw
        .map((str) {
          try {
            return CharacterAbility.fromMap(jsonDecode(str));
          } catch (_) {
            return null;
          }
        })
        .whereType<CharacterAbility>()
        .toList();
  }

  static Future<CharacterAbility?> getAbilityById(String id) async {
    final abilities = await loadAbilities();
    try {
      return abilities.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveAbility(CharacterAbility ability) async {
    final prefs = await SharedPreferences.getInstance();
    final abilities = await loadAbilities();

    final index = abilities.indexWhere((a) => a.id == ability.id);
    if (index >= 0) {
      abilities[index] = ability;
    } else {
      abilities.add(ability);
    }

    final raw = abilities.map((a) => jsonEncode(a.toMap())).toList();
    await prefs.setStringList(_storageKey, raw);
  }
}
