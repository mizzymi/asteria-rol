import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/item.dart';

class ItemImportExportService {
  const ItemImportExportService._();

  static const int formatVersion = 2;

  static const String formatType = 'asteria-item';

  // ===========================================================================
  // EXPORTAR DEFINITION
  // ===========================================================================

  static Future<File> createExportFile(ItemDefinition definition) async {
    final exportDefinition = ItemDefinition.fromMap(definition.toMap());

    String? encodedImage;

    if (definition.imagePath.isNotEmpty) {
      final imageFile = File(definition.imagePath);

      if (await imageFile.exists()) {
        final bytes = await imageFile.readAsBytes();

        encodedImage = base64Encode(bytes);
      }
    }

    // =========================================================================
    // LA RUTA LOCAL NO SE EXPORTA
    // =========================================================================

    exportDefinition.imagePath = '';

    // =========================================================================
    // PAYLOAD
    // =========================================================================

    final payload = {
      'type': formatType,

      'version': formatVersion,

      'definition': exportDefinition.toMap(),

      'image': encodedImage,
    };

    final tempDirectory = await getTemporaryDirectory();

    final safeName = _safeFileName(definition.name);

    final file = File('${tempDirectory.path}/$safeName.asteria-item');

    await file.writeAsString(jsonEncode(payload), flush: true);

    return file;
  }

  // ===========================================================================
  // COMPARTIR
  // ===========================================================================

  static Future<void> shareDefinition(ItemDefinition definition) async {
    final file = await createExportFile(definition);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Objeto de Asteria: ${definition.name}',
        text: 'Importa este objeto en Asteria.',
      ),
    );
  }

  // ===========================================================================
  // COMPATIBILIDAD TEMPORAL
  //
  // Mientras todavía haya callers legacy que trabajen con CharacterItem.
  // ===========================================================================

  static Future<File> createLegacyExportFile(CharacterItem item) {
    return createExportFile(item.toDefinition());
  }

  static Future<void> shareItem(CharacterItem item) {
    return shareDefinition(item.toDefinition());
  }

  // ===========================================================================
  // IMPORTAR
  // ===========================================================================

  static Future<ItemDefinition?> pickAndImportDefinition() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final path = result.files.single.path;

    if (path == null || path.isEmpty) {
      return null;
    }

    return importDefinitionFromFile(File(path));
  }

  // ===========================================================================
  // IMPORTAR DESDE ARCHIVO
  // ===========================================================================

  static Future<ItemDefinition> importDefinitionFromFile(File file) async {
    final raw = await file.readAsString();

    final decoded = jsonDecode(raw);

    if (decoded is! Map) {
      throw const FormatException('El archivo no contiene un objeto válido.');
    }

    final map = Map<String, dynamic>.from(decoded);

    // =========================================================================
    // TYPE
    // =========================================================================

    if (map['type'] != formatType) {
      throw const FormatException('El archivo no es un objeto de Asteria.');
    }

    // =========================================================================
    // VERSION
    // =========================================================================

    final version = (map['version'] as num?)?.toInt() ?? 0;

    if (version <= 0 || version > formatVersion) {
      throw FormatException('Versión de objeto no compatible: $version');
    }

    // =========================================================================
    // VERSION 2+ · ITEM DEFINITION
    // =========================================================================

    if (version >= 2) {
      final rawDefinition = map['definition'];

      if (rawDefinition is! Map) {
        throw const FormatException(
          'La definición del objeto está incompleta.',
        );
      }

      final definition = ItemDefinition.fromMap(
        Map<dynamic, dynamic>.from(rawDefinition),
      );

      return _attachImportedImage(
        definition: definition,
        encodedImage: map['image']?.toString(),
      );
    }

    // =========================================================================
    // VERSION 1 · LEGACY CHARACTER ITEM
    //
    // Compatibilidad con archivos ya exportados por versiones anteriores.
    // =========================================================================

    final rawLegacyItem = map['item'];

    if (rawLegacyItem is! Map) {
      throw const FormatException('El objeto está incompleto.');
    }

    final legacyItem = CharacterItem.fromMap(
      Map<dynamic, dynamic>.from(rawLegacyItem),
    );

    final definition = legacyItem.toDefinition();

    return _attachImportedImage(
      definition: definition,
      encodedImage: map['image']?.toString(),
    );
  }

  // ===========================================================================
  // COMPATIBILIDAD TEMPORAL · IMPORT LEGACY
  //
  // Solo para callers que todavía esperan CharacterItem.
  // ===========================================================================

  static Future<CharacterItem?> pickAndImportItem() async {
    final definition = await pickAndImportDefinition();

    if (definition == null) {
      return null;
    }

    return CharacterItem.fromDefinition(
      definition,
      inventoryId: DateTime.now().microsecondsSinceEpoch.toString(),
      quantity: 1,
      equipped: false,
    );
  }

  static Future<CharacterItem> importFromFile(File file) async {
    final definition = await importDefinitionFromFile(file);

    return CharacterItem.fromDefinition(
      definition,
      inventoryId: DateTime.now().microsecondsSinceEpoch.toString(),
      quantity: 1,
      equipped: false,
    );
  }

  // ===========================================================================
  // IMAGEN
  // ===========================================================================

  static Future<ItemDefinition> _attachImportedImage({
    required ItemDefinition definition,
    required String? encodedImage,
  }) async {
    String imagePath = '';

    if (encodedImage != null && encodedImage.isNotEmpty) {
      try {
        final bytes = base64Decode(encodedImage);

        imagePath = await _saveImportedImage(definition.id, bytes);
      } catch (_) {
        imagePath = '';
      }
    }

    final map = definition.toMap();

    map['imagePath'] = imagePath;

    return ItemDefinition.fromMap(map);
  }

  // ===========================================================================
  // IMAGEN IMPORTADA
  // ===========================================================================

  static Future<String> _saveImportedImage(
    String itemId,
    List<int> bytes,
  ) async {
    final directory = await getApplicationDocumentsDirectory();

    final imageDirectory = Directory('${directory.path}/item_images');

    if (!await imageDirectory.exists()) {
      await imageDirectory.create(recursive: true);
    }

    final safeItemId = _safeFileName(itemId);

    final file = File('${imageDirectory.path}/imported_$safeItemId.jpg');

    await file.writeAsBytes(bytes, flush: true);

    return file.path;
  }

  // ===========================================================================
  // NOMBRE SEGURO
  // ===========================================================================

  static String _safeFileName(String value) {
    var result = value.trim().toLowerCase();

    result = result.replaceAll(RegExp(r'[áàäâ]'), 'a');

    result = result.replaceAll(RegExp(r'[éèëê]'), 'e');

    result = result.replaceAll(RegExp(r'[íìïî]'), 'i');

    result = result.replaceAll(RegExp(r'[óòöô]'), 'o');

    result = result.replaceAll(RegExp(r'[úùüû]'), 'u');

    result = result.replaceAll('ñ', 'n');

    result = result.replaceAll(RegExp(r'[^a-z0-9]+'), '_');

    result = result.replaceAll(RegExp(r'^_+|_+$'), '');

    if (result.isEmpty) {
      return 'asteria_item';
    }

    return result;
  }
}
