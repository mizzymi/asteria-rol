import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/character.dart';

class CharacterImportExportService {
  const CharacterImportExportService._();

  // ===========================================================================
  // EXPORTAR ARCHIVO
  // ===========================================================================

  static Future<File> exportCharacter(Character character) async {
    final directory = await getApplicationDocumentsDirectory();

    final safeName = character.name.trim().replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );

    final fileName = '${safeName.isEmpty ? 'character' : safeName}.asteria';

    final file = File('${directory.path}/$fileName');

    final payload = {
      'format': 'asteria_character',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'character': character.toMap(),
    };

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );

    return file;
  }

  // ===========================================================================
  // EXPORTAR Y COMPARTIR
  // ===========================================================================

  static Future<void> shareCharacter(Character character) async {
    final file = await exportCharacter(character);

    final safeName = character.name.trim().replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: '$safeName.asteria'),
    );
  }

  // ===========================================================================
  // IMPORTAR DESDE TEXTO
  // ===========================================================================

  static Character importFromString(String raw) {
    final decoded = jsonDecode(raw);

    if (decoded is! Map) {
      throw const FormatException('Archivo de personaje inválido.');
    }

    final map = Map<dynamic, dynamic>.from(decoded);

    // -------------------------------------------------------------------------
    // FORMATO NUEVO
    // -------------------------------------------------------------------------

    if (map['format'] == 'asteria_character') {
      final characterData = map['character'];

      if (characterData is! Map) {
        throw const FormatException(
          'El archivo no contiene un personaje válido.',
        );
      }

      return Character.fromMap(Map<dynamic, dynamic>.from(characterData));
    }

    // -------------------------------------------------------------------------
    // COMPATIBILIDAD CON EXPORTACIONES ANTIGUAS
    // -------------------------------------------------------------------------

    if (map.containsKey('id') && map.containsKey('name')) {
      return Character.fromMap(map);
    }

    throw const FormatException('Formato de personaje no reconocido.');
  }

  // ===========================================================================
  // IMPORTAR DESDE ARCHIVO
  // ===========================================================================

  static Future<Character> importFromFile(File file) async {
    final raw = await file.readAsString();

    return importFromString(raw);
  }

  static Character importCharacterAsCopy(String raw) {
    final imported = importFromString(raw);

    final map = imported.toMap();

    map['id'] = DateTime.now().microsecondsSinceEpoch.toString();

    final name = imported.name.trim();

    if (name.isNotEmpty) {
      map['name'] = '$name (copia)';
    }

    return Character.fromMap(Map<dynamic, dynamic>.from(map));
  }

  static Future<Character> importFileAsCopy(File file) async {
    final raw = await file.readAsString();

    return importCharacterAsCopy(raw);
  }
}
