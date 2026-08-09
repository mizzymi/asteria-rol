import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/item.dart';

class ItemImportExportService {
  const ItemImportExportService._();

  static const int formatVersion = 1;

  static const String formatType = 'asteria-item';

  // ===========================================================================
  // EXPORTAR
  // ===========================================================================

  static Future<File> createExportFile(CharacterItem item) async {
    final exportItem = CharacterItem.fromMap(item.toMap());

    /*
     * No queremos que otro jugador
     * lo importe automáticamente equipado.
     */
    exportItem.equipped = false;

    String? encodedImage;

    if (item.imagePath.isNotEmpty) {
      final imageFile = File(item.imagePath);

      if (await imageFile.exists()) {
        final bytes = await imageFile.readAsBytes();

        encodedImage = base64Encode(bytes);
      }
    }

    /*
     * La ruta local del dispositivo
     * no tiene sentido para otro usuario.
     */
    exportItem.imagePath = '';

    final payload = {
      'type': formatType,
      'version': formatVersion,
      'item': exportItem.toMap(),
      'image': encodedImage,
    };

    final tempDirectory = await getTemporaryDirectory();

    final safeName = _safeFileName(item.name);

    final file = File('${tempDirectory.path}/$safeName.asteria-item');

    await file.writeAsString(jsonEncode(payload), flush: true);

    return file;
  }

  static Future<void> shareItem(CharacterItem item) async {
    final file = await createExportFile(item);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Objeto de Asteria: ${item.name}',
      text: 'Importa este objeto en Asteria.',
    );
  }

  // ===========================================================================
  // IMPORTAR
  // ===========================================================================

  static Future<CharacterItem?> pickAndImportItem() async {
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

    return importFromFile(File(path));
  }

  static Future<CharacterItem> importFromFile(File file) async {
    final raw = await file.readAsString();

    final decoded = jsonDecode(raw);

    if (decoded is! Map) {
      throw const FormatException('El archivo no contiene un objeto válido.');
    }

    final map = Map<String, dynamic>.from(decoded);

    if (map['type'] != formatType) {
      throw const FormatException('El archivo no es un objeto de Asteria.');
    }

    final version = (map['version'] as num?)?.toInt() ?? 0;

    if (version <= 0 || version > formatVersion) {
      throw FormatException('Versión de objeto no compatible: $version');
    }

    final rawItem = map['item'];

    if (rawItem is! Map) {
      throw const FormatException('El objeto está incompleto.');
    }

    final item = CharacterItem.fromMap(Map<dynamic, dynamic>.from(rawItem));

    /*
     * Siempre generamos ID nuevo.
     */
    item.id = DateTime.now().microsecondsSinceEpoch.toString();

    item.equipped = false;

    // =========================================================================
    // IMAGEN
    // =========================================================================

    final encodedImage = map['image']?.toString();

    if (encodedImage != null && encodedImage.isNotEmpty) {
      try {
        final bytes = base64Decode(encodedImage);

        item.imagePath = await _saveImportedImage(item.id, bytes);
      } catch (_) {
        item.imagePath = '';
      }
    } else {
      item.imagePath = '';
    }

    /*
     * Las habilidades y pasivas pueden
     * mantener sus IDs internos porque
     * viven dentro de este nuevo item,
     * pero podemos regenerarlos para
     * evitar cualquier posible choque.
     */
    for (var i = 0; i < item.passives.length; i++) {
      item.passives[i].id = '${item.id}_passive_$i';
    }

    for (var i = 0; i < item.abilities.length; i++) {
      item.abilities[i].id = '${item.id}_ability_$i';
    }

    return item;
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

    final file = File('${imageDirectory.path}/imported_$itemId.jpg');

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
