import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/custom_class_definition.dart';

class CustomClassImportExportService {
  const CustomClassImportExportService._();

  static const String formatType = 'asteria-class';
  static const int formatVersion = 1;

  static Future<File> createExportFile(CustomClassDefinition definition) async {
    final dir = await getTemporaryDirectory();
    final safe = definition.name.trim().replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]+'),
      '_',
    );
    final file = File(
      '${dir.path}/${safe.isEmpty ? 'clase' : safe}.asteria-class',
    );
    await file.writeAsString(
      jsonEncode({
        'type': formatType,
        'formatVersion': formatVersion,
        'definition': definition.toMap(),
      }),
      flush: true,
    );
    return file;
  }

  static Future<void> shareClass(CustomClassDefinition definition) async {
    final file = await createExportFile(definition);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Clase de Asteria: ${definition.name}',
        text: 'Clase personalizada de Asteria.',
      ),
    );
  }

  static CustomClassDefinition decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Archivo de clase inválido.');
    }
    final map = Map<dynamic, dynamic>.from(decoded);
    if (map['type']?.toString() != formatType || map['definition'] is! Map) {
      throw const FormatException('El archivo no es una clase de Asteria.');
    }
    final version = (map['formatVersion'] as num?)?.toInt() ?? 0;
    if (version != formatVersion) {
      throw FormatException('Versión de clase no compatible: $version');
    }
    return CustomClassDefinition.fromMap(
      Map<dynamic, dynamic>.from(map['definition'] as Map),
    );
  }

  static Future<CustomClassDefinition> importFile(File file) async {
    return decode(await file.readAsString());
  }
}
