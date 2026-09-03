import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/item_definition.dart';
import '../models/item_library_entry.dart';
import '../models/inventory_item.dart';

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

      final entries = <ItemLibraryEntry>[];

      var migratedLegacyEntry = false;

      for (final rawEntry in decoded) {
        if (rawEntry is! Map) {
          continue;
        }

        final map = Map<dynamic, dynamic>.from(rawEntry);

        // =====================================================================
        // DETECTAR FORMATO LEGACY
        //
        // Antes:
        //
        // {
        //   "item": CharacterItem
        // }
        //
        // Ahora:
        //
        // {
        //   "definition": ItemDefinition
        // }
        // =====================================================================

        if (map['definition'] == null && map['item'] is Map) {
          migratedLegacyEntry = true;
        }

        try {
          entries.add(ItemLibraryEntry.fromMap(map));
        } catch (_) {
          // Una entrada corrupta no debe impedir
          // cargar toda la biblioteca.
          continue;
        }
      }

      // =======================================================================
      // MIGRACIÓN AUTOMÁTICA
      //
      // Si hemos leído entradas antiguas correctamente,
      // las persistimos ya con el formato nuevo.
      // =======================================================================

      if (migratedLegacyEntry) {
        await saveLibrary(entries);
      }

      return entries;
    } catch (_) {
      return [];
    }
  }

  // ===========================================================================
  // GUARDAR
  // ===========================================================================

  static Future<void> saveLibrary(List<ItemLibraryEntry> entries) async {
    final file = await _libraryFile();

    final payload = entries.map((entry) => entry.toMap()).toList();

    final encoded = jsonEncode(payload);

    await file.writeAsString(encoded, flush: true);
  }

  // ===========================================================================
  // AÑADIR DEFINITION
  // ===========================================================================

  static Future<ItemLibraryEntry> addDefinition(
    ItemDefinition definition,
  ) async {
    final library = await loadLibrary();

    final now = DateTime.now();

    // =======================================================================
    // COPIA PROFUNDA
    //
    // La biblioteca no comparte referencias mutables
    // con formularios ni otras capas.
    // =======================================================================

    final definitionCopy = ItemDefinition.fromMap(definition.toMap());

    final entry = ItemLibraryEntry(
      id: _newEntryId(),

      definition: definitionCopy,

      createdAt: now,

      updatedAt: now,
    );

    library.add(entry);

    await saveLibrary(library);

    return entry;
  }

  // ===========================================================================
  // ACTUALIZAR DEFINITION
  // ===========================================================================

  static Future<ItemLibraryEntry?> updateDefinition({
    required String entryId,
    required ItemDefinition definition,
  }) async {
    final library = await loadLibrary();

    final index = library.indexWhere((entry) => entry.id == entryId);

    if (index < 0) {
      return null;
    }

    final previous = library[index];

    final updated = ItemLibraryEntry(
      id: previous.id,

      definition: ItemDefinition.fromMap(definition.toMap()),

      createdAt: previous.createdAt,

      updatedAt: DateTime.now(),
    );

    library[index] = updated;

    await saveLibrary(library);

    return updated;
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
  // BUSCAR POR ENTRY ID
  // ===========================================================================

  static Future<ItemLibraryEntry?> findEntry(String entryId) async {
    final library = await loadLibrary();

    for (final entry in library) {
      if (entry.id == entryId) {
        return entry;
      }
    }

    return null;
  }

  // ===========================================================================
  // BUSCAR POR ITEM ID
  //
  // Importante:
  // ItemLibraryEntry.id identifica la entrada de biblioteca.
  // ItemDefinition.id identifica el objeto real.
  // ===========================================================================

  static Future<ItemLibraryEntry?> findByItemId(String itemId) async {
    final normalized = itemId.trim();

    if (normalized.isEmpty) {
      return null;
    }

    final library = await loadLibrary();

    for (final entry in library) {
      if (entry.definition.id == normalized) {
        return entry;
      }
    }

    return null;
  }

  // ===========================================================================
  // CREAR INVENTORY ITEM NUEVO
  //
  // Este será el camino definitivo cuando Character abandone CharacterItem.
  // ===========================================================================

  static InventoryItem createInventoryEntry(
    ItemLibraryEntry entry, {
    int quantity = 1,
  }) {
    final safeQuantity = quantity < 1 ? 1 : quantity;

    return InventoryItem(
      id: _newInventoryId(),

      itemId: entry.definition.id,

      quantity: safeQuantity,

      equipped: false,

      equippedSlotId: null,
    );
  }

  // ===========================================================================
  // CLONAR DEFINITION
  //
  // Útil para formularios de edición.
  // ===========================================================================

  static ItemDefinition copyDefinition(ItemLibraryEntry entry) {
    return ItemDefinition.fromMap(entry.definition.toMap());
  }

  // ===========================================================================
  // IDS
  // ===========================================================================

  static String _newEntryId() {
    return 'item_library_'
        '${DateTime.now().microsecondsSinceEpoch}';
  }

  static String _newInventoryId() {
    return 'inventory_item_'
        '${DateTime.now().microsecondsSinceEpoch}';
  }
}
