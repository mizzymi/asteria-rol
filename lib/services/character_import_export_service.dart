import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/character.dart';
import 'portable_image_bundle.dart';

class CharacterImportExportService {
  const CharacterImportExportService._();

  static const int formatVersion = 2;

  static Future<File> exportCharacter(Character character) async {
    final directory = await getApplicationDocumentsDirectory();
    final safeName = character.name.trim().replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final fileName = '${safeName.isEmpty ? 'character' : safeName}.asteria';
    final file = File('${directory.path}/$fileName');

    final characterMap = Map<String, dynamic>.from(character.toMap());
    final images = await PortableImageBundle.extractFrom(characterMap);

    final payload = {
      'format': 'asteria_character',
      'version': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'character': characterMap,
      'images': images,
    };

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    return file;
  }

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

  static Future<Character> importFromString(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Archivo de personaje inválido.');
    }
    final map = Map<String, dynamic>.from(decoded);

    if (map['format'] == 'asteria_character') {
      final characterData = map['character'];
      if (characterData is! Map) {
        throw const FormatException(
          'El archivo no contiene un personaje válido.',
        );
      }
      final characterMap = Map<String, dynamic>.from(characterData);
      final images = map['images'];
      if (images is Map) {
        await PortableImageBundle.restoreInto(
          characterMap,
          Map<String, dynamic>.from(images),
          namespace: 'character',
        );
      }
      return Character.fromMap(Map<dynamic, dynamic>.from(characterMap));
    }

    if (map.containsKey('id') && map.containsKey('name')) {
      return Character.fromMap(Map<dynamic, dynamic>.from(map));
    }
    throw const FormatException('Formato de personaje no reconocido.');
  }

  static Future<Character> importFromFile(File file) async {
    return importFromString(await file.readAsString());
  }

  static Future<Character> importCharacterAsCopy(String raw) async {
    final imported = await importFromString(raw);
    final map = imported.toMap();
    map['id'] = DateTime.now().microsecondsSinceEpoch.toString();
    final name = imported.name.trim();
    if (name.isNotEmpty) map['name'] = '$name (copia)';
    return Character.fromMap(Map<dynamic, dynamic>.from(map));
  }

  static Future<Character> importFileAsCopy(File file) async {
    return importCharacterAsCopy(await file.readAsString());
  }
}
