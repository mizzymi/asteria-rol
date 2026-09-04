import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/knowledge_definition.dart';

class KnowledgeLibraryService {
  static const String _storageKey = 'knowledge_library_definitions';

  static Future<List<KnowledgeDefinition>> loadDefinitions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    return raw
        .map((str) {
          try {
            return KnowledgeDefinition.fromMap(jsonDecode(str));
          } catch (_) {
            return null;
          }
        })
        .whereType<KnowledgeDefinition>()
        .toList();
  }

  static Future<KnowledgeDefinition?> getDefinitionById(String id) async {
    final defs = await loadDefinitions();
    try {
      return defs.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveDefinition(KnowledgeDefinition definition) async {
    final prefs = await SharedPreferences.getInstance();
    final defs = await loadDefinitions();

    final index = defs.indexWhere((d) => d.id == definition.id);
    if (index >= 0) {
      defs[index] = definition;
    } else {
      defs.add(definition);
    }

    final raw = defs.map((d) => jsonEncode(d.toMap())).toList();
    await prefs.setStringList(_storageKey, raw);
  }
}
