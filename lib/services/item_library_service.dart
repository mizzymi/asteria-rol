import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/item.dart';
import '../models/item_library_entry.dart';

class ItemLibraryService {
  const ItemLibraryService._();

  static const String _fileName = 'item_library.json';

  // ===========================================================================
  // ARCHIVO
  // ===========================================================================

  static Future<File> _libraryFile() async {
    final directory = await getApplicationDocumentsDirectory();

    return File('${directory.path}/$_fileName');
  }

  // ===========================================================================
  // CARGAR
  // ===========================================================================

  static Future<List<ItemLibraryEntry>> loadLibrary() async {
    final file = await _libraryFile();

    if (!await file.exists()) {
      return [];
    }

    try {
      final raw = await file.readAsString();

      if (raw.trim().isEmpty) {
        return [];
      }

      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (entry) =>
                ItemLibraryEntry.fromMap(Map<dynamic, dynamic>.from(entry)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ===========================================================================
  // GUARDAR
  // ===========================================================================

  static Future<void> saveLibrary(List<ItemLibraryEntry> entries) async {
    final file = await _libraryFile();

    final encoded = jsonEncode(entries.map((entry) => entry.toMap()).toList());

    await file.writeAsString(encoded, flush: true);
  }

  // ===========================================================================
  // AÑADIR
  // ===========================================================================

  static Future<ItemLibraryEntry> addItem(CharacterItem item) async {
    final library = await loadLibrary();

    final now = DateTime.now();

    final copy = CharacterItem.fromMap(item.toMap());

    /*
     * Una plantilla de biblioteca nunca
     * debería guardarse como equipada.
     */
    copy.equipped = false;

    final entry = ItemLibraryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      item: copy,
      createdAt: now,
      updatedAt: now,
    );

    library.add(entry);

    await saveLibrary(library);

    return entry;
  }

  // ===========================================================================
  // ACTUALIZAR
  // ===========================================================================

  static Future<void> updateItem(ItemLibraryEntry entry) async {
    final library = await loadLibrary();

    final index = library.indexWhere((value) => value.id == entry.id);

    if (index < 0) {
      return;
    }

    /*
     * Copiamos también el item para
     * mantener la biblioteca aislada
     * de referencias externas.
     */
    final updatedItem = CharacterItem.fromMap(entry.item.toMap());

    updatedItem.equipped = false;

    final updatedEntry = ItemLibraryEntry(
      id: entry.id,
      item: updatedItem,
      createdAt: entry.createdAt,
      updatedAt: DateTime.now(),
    );

    library[index] = updatedEntry;

    await saveLibrary(library);
  }

  // ===========================================================================
  // ELIMINAR
  // ===========================================================================

  static Future<void> removeItem(String entryId) async {
    final library = await loadLibrary();

    library.removeWhere((entry) => entry.id == entryId);

    await saveLibrary(library);
  }

  // ===========================================================================
  // CREAR COPIA PARA INVENTARIO
  // ===========================================================================

  static Future<CharacterItem> createInventoryCopy(
    ItemLibraryEntry entry,
  ) async {
    final copy = CharacterItem.fromMap(entry.item.toMap());

    /*
     * El objeto importado debe ser
     * una instancia nueva.
     */
    copy.id = DateTime.now().microsecondsSinceEpoch.toString();

    copy.equipped = false;

    /*
     * Regeneramos IDs internos para
     * evitar colisiones si el mismo objeto
     * se añade varias veces.
     */
    for (var i = 0; i < copy.passives.length; i++) {
      copy.passives[i].id = '${copy.id}_passive_$i';
    }

    for (var i = 0; i < copy.abilities.length; i++) {
      copy.abilities[i].id = '${copy.id}_ability_$i';
    }

    return copy;
  }
}
