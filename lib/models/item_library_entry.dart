import 'item_definition.dart';

class ItemLibraryEntry {
  final String id;

  final ItemDefinition definition;

  final DateTime createdAt;

  final DateTime updatedAt;

  const ItemLibraryEntry({
    required this.id,
    required this.definition,
    required this.createdAt,
    required this.updatedAt,
  });

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  String get itemId {
    return definition.id;
  }

  String get name {
    return definition.name;
  }

  String get description {
    return definition.description;
  }

  ItemType get type {
    return definition.type;
  }

  bool get hasImage {
    return definition.imagePath.trim().isNotEmpty;
  }

  // ===========================================================================
  // COPY
  // ===========================================================================

  ItemLibraryEntry copyWith({
    String? id,
    ItemDefinition? definition,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItemLibraryEntry(
      id: id ?? this.id,
      definition: definition ?? this.definition,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'definition': definition.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ItemLibraryEntry.fromMap(Map<dynamic, dynamic> map) {
    final now = DateTime.now();

    // =========================================================================
    // FORMATO ACTUAL
    // =========================================================================

    final rawDefinition = map['definition'];

    if (rawDefinition is Map) {
      final definition = ItemDefinition.fromMap(
        Map<dynamic, dynamic>.from(rawDefinition),
      );

      return ItemLibraryEntry(
        id: _readEntryId(map, fallbackDefinitionId: definition.id),
        definition: definition,
        createdAt: _readDate(map['createdAt'], fallback: now),
        updatedAt: _readDate(map['updatedAt'], fallback: now),
      );
    }

    // =========================================================================
    // COMPATIBILIDAD CON BIBLIOTECA ANTERIOR
    // =========================================================================
    //
    // El formato anterior guardaba:
    //
    // {
    //   "id": "...",
    //   "item": {
    //      ...
    //   },
    //   "createdAt": "...",
    //   "updatedAt": "..."
    // }
    //
    // Intentamos migrarlo directamente a ItemDefinition.
    // ===========================================================================

    final rawLegacyItem = map['item'];

    if (rawLegacyItem is Map) {
      final definition = _definitionFromLegacyItem(
        Map<dynamic, dynamic>.from(rawLegacyItem),
      );

      return ItemLibraryEntry(
        id: _readEntryId(map, fallbackDefinitionId: definition.id),
        definition: definition,
        createdAt: _readDate(map['createdAt'], fallback: now),
        updatedAt: _readDate(map['updatedAt'], fallback: now),
      );
    }

    throw const FormatException(
      'La entrada de biblioteca no contiene una definición válida.',
    );
  }

  // ===========================================================================
  // MIGRACIÓN LEGACY
  // ===========================================================================

  static ItemDefinition _definitionFromLegacyItem(Map<dynamic, dynamic> map) {
    final migrated = <dynamic, dynamic>{...map};

    // -------------------------------------------------------------------------
    // ID
    // -------------------------------------------------------------------------

    final legacyId = map['id']?.toString() ?? '';

    final templateId = map['templateId']?.toString() ?? '';

    migrated['id'] = templateId.trim().isNotEmpty ? templateId : legacyId;

    // -------------------------------------------------------------------------
    // TIPO
    // -------------------------------------------------------------------------
    //
    // Los nombres actuales de ItemType conservan los tipos antiguos:
    //
    // armor
    // helmet
    // gloves
    // boots
    // ring
    // amulet
    // weapon
    // accessory
    // consumable
    // other
    //
    // Por tanto podemos conservar directamente el valor serializado.
    // -------------------------------------------------------------------------

    migrated['type'] = map['type']?.toString() ?? ItemType.other.name;

    // -------------------------------------------------------------------------
    // ARMADURA
    // -------------------------------------------------------------------------
    //
    // Legacy:
    //
    // armorCategory
    // armorBaseClass
    //
    // Actual:
    //
    // armor: {
    //   category,
    //   baseArmorClass
    // }
    // -------------------------------------------------------------------------

    final armorCategory = map['armorCategory']?.toString();

    if (armorCategory != null && armorCategory.isNotEmpty) {
      migrated['armor'] = {
        'category': armorCategory,
        'baseArmorClass': (map['armorBaseClass'] as num?)?.toInt() ?? 10,
      };
    }

    // -------------------------------------------------------------------------
    // SLOTS DE EQUIPAMIENTO
    // -------------------------------------------------------------------------

    migrated['equipmentSlotIds'] = _legacyEquipmentSlots(
      map['type']?.toString(),
    );

    // -------------------------------------------------------------------------
    // STACKABLE
    // -------------------------------------------------------------------------

    final type = map['type']?.toString();

    migrated['stackable'] =
        type == ItemType.consumable.name || type == ItemType.other.name;

    // -------------------------------------------------------------------------
    // DATOS QUE YA TIENEN FORMATO COMPATIBLE
    // -------------------------------------------------------------------------

    migrated['name'] = map['name']?.toString() ?? '';

    migrated['description'] = map['description']?.toString() ?? '';

    migrated['imagePath'] = map['imagePath']?.toString() ?? '';

    migrated['notes'] = map['notes']?.toString() ?? '';

    migrated['weapon'] = map['weapon'];

    migrated['consumable'] = map['consumable'];

    migrated['passives'] = map['passives'] ?? const [];

    migrated['abilities'] = map['abilities'] ?? const [];

    migrated['calculationCosts'] = map['calculationCosts'] ?? const [];

    return ItemDefinition.fromMap(migrated);
  }

  static List<String> _legacyEquipmentSlots(String? type) {
    switch (type) {
      case 'armor':
        return const ['armor'];

      case 'helmet':
        return const ['head'];

      case 'gloves':
        return const ['hands'];

      case 'boots':
        return const ['feet'];

      case 'ring':
        return const ['ring'];

      case 'amulet':
        return const ['neck'];

      case 'weapon':
        return const ['weapon'];

      case 'accessory':
        return const ['accessory'];

      case 'consumable':
      case 'other':
      default:
        return const [];
    }
  }

  // ===========================================================================
  // HELPERS DE SERIALIZACIÓN
  // ===========================================================================

  static String _readEntryId(
    Map<dynamic, dynamic> map, {
    required String fallbackDefinitionId,
  }) {
    final id = map['id']?.toString().trim() ?? '';

    if (id.isNotEmpty) {
      return id;
    }

    if (fallbackDefinitionId.trim().isNotEmpty) {
      return fallbackDefinitionId;
    }

    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  static DateTime _readDate(dynamic value, {required DateTime fallback}) {
    if (value is DateTime) {
      return value;
    }

    final parsed = DateTime.tryParse(value?.toString() ?? '');

    return parsed ?? fallback;
  }
}
