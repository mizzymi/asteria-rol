import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/character.dart';
import 'portable_image_bundle.dart';
import 'portable_streaming_archive.dart';

class CharacterImportExportService {
  const CharacterImportExportService._();

  static const int formatVersion = 3;
  static const String formatType = 'asteria_character';
  static final _binaryMagic = PortableStreamingArchive.magic(
    'ASTERIA_CHARACTER_V3',
  );

  static Future<File> exportCharacter(Character character) async {
    final directory = await getApplicationDocumentsDirectory();
    final safeName = character.name.trim().replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final fileName = '${safeName.isEmpty ? 'character' : safeName}.asteria';
    final file = File('${directory.path}/$fileName');

    final root = <String, dynamic>{
      'character': Map<String, dynamic>.from(character.toMap()),
    };

    await PortableStreamingArchive.write(
      file: file,
      magicBytes: _binaryMagic,
      root: root,
      header: <String, dynamic>{
        'format': formatType,
        'version': formatVersion,
        'exportedAt': DateTime.now().toIso8601String(),
      },
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
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/octet-stream')],
        subject: '$safeName.asteria',
      ),
    );
  }

  static Future<Character> importFromString(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Archivo de personaje inválido.');
    }
    final map = Map<String, dynamic>.from(decoded);

    if (map['format'] == formatType) {
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

  static Future<Character> _importBinary(File file) async {
    final header = await PortableStreamingArchive.read(
      file: file,
      magicBytes: _binaryMagic,
      namespace: 'character',
    );
    if (header['format'] != formatType ||
        (header['version'] as num?)?.toInt() != formatVersion) {
      throw const FormatException('El archivo no es un personaje de Asteria v3.');
    }
    final root = Map<String, dynamic>.from(header['root'] as Map);
    if (root['character'] is! Map) {
      throw const FormatException('El personaje está incompleto.');
    }
    return Character.fromMap(
      Map<dynamic, dynamic>.from(root['character'] as Map),
    );
  }

  static Future<Character> importFromFile(File file) async {
    if (await PortableStreamingArchive.hasMagic(file, _binaryMagic)) {
      return _importBinary(file);
    }
    return importFromString(await file.readAsString());
  }

  static Character _asCopy(Character imported) {
    final map = imported.toMap();
    map['id'] = DateTime.now().microsecondsSinceEpoch.toString();
    final name = imported.name.trim();
    if (name.isNotEmpty) {
      map['name'] = '$name (copia)';
    }
    return Character.fromMap(Map<dynamic, dynamic>.from(map));
  }

  static Future<Character> importCharacterAsCopy(String raw) async {
    return _asCopy(await importFromString(raw));
  }

  static Future<Character> importFileAsCopy(File file) async {
    return _asCopy(await importFromFile(file));
  }
}
