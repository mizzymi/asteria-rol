import 'ability.dart';
import 'consumable.dart';
import 'passive.dart';
import 'weapon.dart';

// =============================================================================
// ITEM TYPE
// =============================================================================

enum ItemType {
  armor,
  helmet,
  gloves,
  boots,

  ring,
  amulet,

  weapon,
  accessory,

  consumable,

  tool,
  material,
  book,

  special,
  other,
}

extension ItemTypeData on ItemType {
  // ===========================================================================
  // LABEL
  // ===========================================================================

  String get label {
    switch (this) {
      case ItemType.armor:
        return 'Armadura';

      case ItemType.helmet:
        return 'Casco';

      case ItemType.gloves:
        return 'Guantes';

      case ItemType.boots:
        return 'Botas';

      case ItemType.ring:
        return 'Anillo';

      case ItemType.amulet:
        return 'Amuleto';

      case ItemType.weapon:
        return 'Arma';

      case ItemType.accessory:
        return 'Accesorio';

      case ItemType.consumable:
        return 'Consumible';

      case ItemType.tool:
        return 'Herramienta';

      case ItemType.material:
        return 'Material';

      case ItemType.book:
        return 'Libro';

      case ItemType.special:
        return 'Especial';

      case ItemType.other:
        return 'Otro';
    }
  }

  // ===========================================================================
  // STACK
  // ===========================================================================

  bool get stackableByDefault {
    switch (this) {
      case ItemType.consumable:
      case ItemType.material:
        return true;

      case ItemType.armor:
      case ItemType.helmet:
      case ItemType.gloves:
      case ItemType.boots:
      case ItemType.ring:
      case ItemType.amulet:
      case ItemType.weapon:
      case ItemType.accessory:
      case ItemType.tool:
      case ItemType.book:
      case ItemType.special:
      case ItemType.other:
        return false;
    }
  }

  // ===========================================================================
  // EQUIPMENT
  // ===========================================================================

  bool get isEquipable {
    switch (this) {
      case ItemType.armor:
      case ItemType.helmet:
      case ItemType.gloves:
      case ItemType.boots:
      case ItemType.ring:
      case ItemType.amulet:
      case ItemType.weapon:
      case ItemType.accessory:
        return true;

      case ItemType.consumable:
      case ItemType.tool:
      case ItemType.material:
      case ItemType.book:
      case ItemType.special:
      case ItemType.other:
        return false;
    }
  }

  bool get exclusiveSlot {
    switch (this) {
      case ItemType.armor:
      case ItemType.helmet:
      case ItemType.gloves:
      case ItemType.boots:
      case ItemType.amulet:
        return true;

      case ItemType.ring:
      case ItemType.weapon:
      case ItemType.accessory:
      case ItemType.consumable:
      case ItemType.tool:
      case ItemType.material:
      case ItemType.book:
      case ItemType.special:
      case ItemType.other:
        return false;
    }
  }

  String? get defaultEquipmentSlotId {
    switch (this) {
      case ItemType.armor:
        return 'armor';

      case ItemType.helmet:
        return 'head';

      case ItemType.gloves:
        return 'hands';

      case ItemType.boots:
        return 'feet';

      case ItemType.ring:
        return 'ring';

      case ItemType.amulet:
        return 'neck';

      case ItemType.weapon:
        return 'weapon';

      case ItemType.accessory:
        return 'accessory';

      case ItemType.consumable:
      case ItemType.tool:
      case ItemType.material:
      case ItemType.book:
      case ItemType.special:
      case ItemType.other:
        return null;
    }
  }

  List<String> get defaultEquipmentSlotIds {
    final slotId = defaultEquipmentSlotId;

    if (slotId == null) {
      return const [];
    }

    return [slotId];
  }

  // ===========================================================================
  // TYPE HELPERS
  // ===========================================================================

  bool get isArmorLike {
    switch (this) {
      case ItemType.armor:
      case ItemType.helmet:
      case ItemType.gloves:
      case ItemType.boots:
        return true;

      case ItemType.ring:
      case ItemType.amulet:
      case ItemType.weapon:
      case ItemType.accessory:
      case ItemType.consumable:
      case ItemType.tool:
      case ItemType.material:
      case ItemType.book:
      case ItemType.special:
      case ItemType.other:
        return false;
    }
  }
}

// =============================================================================
// ARMOR
// =============================================================================

enum ArmorCategory { light, medium, heavy }

extension ArmorCategoryData on ArmorCategory {
  String get label {
    switch (this) {
      case ArmorCategory.light:
        return 'Ligera';

      case ArmorCategory.medium:
        return 'Media';

      case ArmorCategory.heavy:
        return 'Pesada';
    }
  }
}

class ItemArmorDefinition {
  final ArmorCategory category;

  final int baseArmorClass;

  const ItemArmorDefinition({
    required this.category,
    required this.baseArmorClass,
  });

  // ===========================================================================
  // SERIALIZATION
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {'category': category.name, 'baseArmorClass': baseArmorClass};
  }

  factory ItemArmorDefinition.fromMap(Map<dynamic, dynamic> map) {
    return ItemArmorDefinition(
      category: ArmorCategory.values.firstWhere(
        (value) => value.name == map['category']?.toString(),
        orElse: () => ArmorCategory.light,
      ),
      baseArmorClass: (map['baseArmorClass'] as num?)?.toInt() ?? 10,
    );
  }
}

// =============================================================================
// ITEM DEFINITION
// =============================================================================

class ItemDefinition {
  /// Identidad real del objeto.
  ///
  /// Biblioteca, inventario, tiendas, recetas y paquetes deben utilizar
  /// este ID para referenciar el mismo objeto.
  final String id;

  String name;

  String description;

  ItemType type;

  String imagePath;

  String notes;

  // ===========================================================================
  // STACK / CALCULATOR
  // ===========================================================================

  bool stackable;

  bool calculable;

  List<ItemCalculationCost> calculationCosts;

  // ===========================================================================
  // EQUIPMENT
  // ===========================================================================

  /// Slots en los que puede equiparse.
  ///
  /// Vacío = no equipable.
  List<String> equipmentSlotIds;

  // ===========================================================================
  // CONTENT
  // ===========================================================================

  ItemArmorDefinition? armor;

  Weapon? weapon;

  Consumable? consumable;

  List<CharacterPassive> passives;

  List<CharacterAbility> abilities;

  ItemDefinition({
    required this.id,
    required this.name,
    this.description = '',
    this.type = ItemType.other,
    this.imagePath = '',
    this.notes = '',
    bool? stackable,
    this.calculable = false,
    List<ItemCalculationCost>? calculationCosts,
    List<String>? equipmentSlotIds,
    this.armor,
    this.weapon,
    this.consumable,
    List<CharacterPassive>? passives,
    List<CharacterAbility>? abilities,
  }) : stackable = stackable ?? type.stackableByDefault,
       calculationCosts = calculationCosts ?? [],
       equipmentSlotIds = equipmentSlotIds ?? type.defaultEquipmentSlotIds,
       passives = passives ?? [],
       abilities = abilities ?? [];

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool get hasImage {
    return imagePath.trim().isNotEmpty;
  }

  bool get equipable {
    return equipmentSlotIds.isNotEmpty;
  }

  bool get hasArmor {
    return armor != null;
  }

  bool get hasWeapon {
    return weapon != null;
  }

  bool get hasConsumable {
    return consumable != null;
  }

  bool get hasPassives {
    return passives.isNotEmpty;
  }

  bool get hasAbilities {
    return abilities.isNotEmpty;
  }

  bool get hasCalculationCosts {
    return calculationCosts.isNotEmpty;
  }

  bool get isWeapon {
    return type == ItemType.weapon && weapon != null;
  }

  bool get isConsumable {
    return type == ItemType.consumable && consumable != null;
  }

  // ===========================================================================
  // COPY
  // ===========================================================================

  ItemDefinition copy() {
    return ItemDefinition.fromMap(toMap());
  }

  // ===========================================================================
  // SERIALIZATION
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,

      'name': name,

      'description': description,

      'type': type.name,

      'imagePath': imagePath,

      'notes': notes,

      'stackable': stackable,

      'calculable': calculable,

      'calculationCosts': calculationCosts.map((cost) => cost.toMap()).toList(),

      'equipmentSlotIds': List<String>.from(equipmentSlotIds),

      'armor': armor?.toMap(),

      'weapon': weapon?.toMap(),

      'consumable': consumable?.toMap(),

      'passives': passives.map((passive) => passive.toMap()).toList(),

      'abilities': abilities.map((ability) => ability.toMap()).toList(),
    };
  }

  // ===========================================================================
  // FROM MAP
  // ===========================================================================

  factory ItemDefinition.fromMap(Map<dynamic, dynamic> map) {
    // =========================================================================
    // TYPE
    // =========================================================================

    final type = ItemType.values.firstWhere(
      (value) => value.name == map['type']?.toString(),
      orElse: () => ItemType.other,
    );

    // =========================================================================
    // PASSIVES
    // =========================================================================

    final passives = <CharacterPassive>[];

    final rawPassives = map['passives'];

    if (rawPassives is List) {
      for (final rawPassive in rawPassives) {
        if (rawPassive is! Map) {
          continue;
        }

        try {
          passives.add(
            CharacterPassive.fromMap(Map<dynamic, dynamic>.from(rawPassive)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    // =========================================================================
    // LEGACY SINGLE PASSIVE
    // =========================================================================

    if (passives.isEmpty) {
      final rawPassive = map['passive'];

      if (rawPassive is Map) {
        try {
          passives.add(
            CharacterPassive.fromMap(Map<dynamic, dynamic>.from(rawPassive)),
          );
        } catch (_) {
          // Ignorar contenido legacy inválido.
        }
      }
    }

    // =========================================================================
    // ABILITIES
    // =========================================================================

    final abilities = <CharacterAbility>[];

    final rawAbilities = map['abilities'];

    if (rawAbilities is List) {
      for (final rawAbility in rawAbilities) {
        if (rawAbility is! Map) {
          continue;
        }

        try {
          abilities.add(
            CharacterAbility.fromMap(Map<dynamic, dynamic>.from(rawAbility)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    // =========================================================================
    // WEAPON
    // =========================================================================

    Weapon? weapon;

    final rawWeapon = map['weapon'];

    if (rawWeapon is Map) {
      try {
        weapon = Weapon.fromMap(Map<dynamic, dynamic>.from(rawWeapon));
      } catch (_) {
        weapon = null;
      }
    }

    // =========================================================================
    // CONSUMABLE
    // =========================================================================

    Consumable? consumable;

    final rawConsumable = map['consumable'];

    if (rawConsumable is Map) {
      try {
        consumable = Consumable.fromMap(
          Map<dynamic, dynamic>.from(rawConsumable),
        );
      } catch (_) {
        consumable = null;
      }
    }

    // =========================================================================
    // ARMOR
    // =========================================================================

    ItemArmorDefinition? armor;

    final rawArmor = map['armor'];

    if (rawArmor is Map) {
      try {
        armor = ItemArmorDefinition.fromMap(
          Map<dynamic, dynamic>.from(rawArmor),
        );
      } catch (_) {
        armor = null;
      }
    }

    // =========================================================================
    // LEGACY ARMOR
    //
    // El CharacterItem antiguo guardaba:
    //
    // armorCategory
    // armorBaseClass
    // =========================================================================

    if (armor == null) {
      final legacyArmorCategory = map['armorCategory']?.toString();

      if (legacyArmorCategory != null && legacyArmorCategory.isNotEmpty) {
        final category = ArmorCategory.values.firstWhere(
          (value) => value.name == legacyArmorCategory,
          orElse: () => ArmorCategory.light,
        );

        armor = ItemArmorDefinition(
          category: category,
          baseArmorClass: (map['armorBaseClass'] as num?)?.toInt() ?? 10,
        );
      }
    }

    // =========================================================================
    // CALCULATION COSTS
    // =========================================================================

    final calculationCosts = <ItemCalculationCost>[];

    final rawCalculationCosts = map['calculationCosts'];

    if (rawCalculationCosts is List) {
      for (final rawCost in rawCalculationCosts) {
        if (rawCost is! Map) {
          continue;
        }

        try {
          calculationCosts.add(
            ItemCalculationCost.fromMap(Map<dynamic, dynamic>.from(rawCost)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    // =========================================================================
    // EQUIPMENT SLOTS
    // =========================================================================

    final equipmentSlotIds = <String>[];

    final rawSlots = map['equipmentSlotIds'];

    if (rawSlots is List) {
      for (final rawSlot in rawSlots) {
        final slotId = rawSlot?.toString().trim() ?? '';

        if (slotId.isEmpty) {
          continue;
        }

        if (!equipmentSlotIds.contains(slotId)) {
          equipmentSlotIds.add(slotId);
        }
      }
    }

    // =========================================================================
    // LEGACY EQUIPMENT
    // =========================================================================

    if (equipmentSlotIds.isEmpty && type.isEquipable) {
      equipmentSlotIds.addAll(type.defaultEquipmentSlotIds);
    }

    // =========================================================================
    // ID
    //
    // templateId era la identidad de definición legacy.
    // =========================================================================

    final rawId = map['id']?.toString().trim() ?? '';

    final rawTemplateId = map['templateId']?.toString().trim() ?? '';

    final id = rawTemplateId.isNotEmpty ? rawTemplateId : rawId;

    // =========================================================================
    // RESULT
    // =========================================================================

    return ItemDefinition(
      id: id,

      name: map['name']?.toString() ?? '',

      description: map['description']?.toString() ?? '',

      type: type,

      imagePath: map['imagePath']?.toString() ?? '',

      notes: map['notes']?.toString() ?? '',

      stackable: map['stackable'] as bool? ?? type.stackableByDefault,

      calculable: map['calculable'] as bool? ?? calculationCosts.isNotEmpty,

      calculationCosts: calculationCosts,

      equipmentSlotIds: equipmentSlotIds,

      armor: armor,

      weapon: weapon,

      consumable: consumable,

      passives: passives,

      abilities: abilities,
    );
  }
}

// =============================================================================
// CALCULATION COST
// =============================================================================

class ItemCalculationCost {
  /// Referencia siempre ItemDefinition.id.
  String itemId;

  int quantityPerUnit;

  ItemCalculationCost({required this.itemId, this.quantityPerUnit = 1});

  // ===========================================================================
  // SERIALIZATION
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {'itemId': itemId, 'quantityPerUnit': quantityPerUnit};
  }

  factory ItemCalculationCost.fromMap(Map<dynamic, dynamic> map) {
    final quantity = (map['quantityPerUnit'] as num?)?.toInt() ?? 1;

    return ItemCalculationCost(
      itemId: map['itemId']?.toString() ?? '',

      quantityPerUnit: quantity < 1 ? 1 : quantity,
    );
  }
}
