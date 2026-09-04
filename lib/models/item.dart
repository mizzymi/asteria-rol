import 'ability.dart';
import 'consumable.dart';
import 'inventory_item.dart';
import 'item_definition.dart';
import 'passive.dart';
import 'weapon.dart';

// =============================================================================
// EXPORTS
//
// Permite que los archivos que históricamente hacían:
//
// import '../../models/item.dart';
//
// sigan viendo ItemType, ArmorCategory, ItemCalculationCost,
// ItemDefinition e InventoryItem.
// =============================================================================

export 'consumable.dart';
export 'inventory_item.dart';
export 'item_definition.dart';

// =============================================================================
// CHARACTER ITEM · LEGACY BRIDGE
//
// TEMPORAL.
//
// Este modelo existe mientras Character, ItemsScreen y widgets antiguos
// todavía trabajan con una entidad que mezcla:
//
// - definición del objeto,
// - cantidad,
// - equipamiento.
//
// El destino final es:
//
// ItemDefinition + InventoryItem.
// =============================================================================

class CharacterItem {
  // ===========================================================================
  // INVENTORY ENTRY ID
  // ===========================================================================

  String id;

  // ===========================================================================
  // DEFINITION ID LEGACY
  //
  // Equivale al futuro InventoryItem.itemId.
  // ===========================================================================

  String templateId;

  // ===========================================================================
  // DEFINITION DATA · LEGACY COPY
  // ===========================================================================

  String name;

  String description;

  String? imagePath;

  ItemType type;

  String notes;

  bool calculable;

  List<ItemCalculationCost> calculationCosts;

  // ===========================================================================
  // EQUIPMENT STATE
  // ===========================================================================

  bool equipped;

  // ===========================================================================
  // ARMOR
  // ===========================================================================

  ArmorCategory? armorCategory;

  int armorBaseClass;

  // ===========================================================================
  // WEAPON
  // ===========================================================================

  Weapon? weapon;

  // ===========================================================================
  // CONTENT
  // ===========================================================================

  List<CharacterPassive> passives;

  List<CharacterAbility> abilities;

  Consumable? consumable;

  // ===========================================================================
  // INVENTORY
  // ===========================================================================

  int quantity;

  CharacterItem({
    required this.id,
    required this.name,
    this.description = '',
    String? templateId,
    this.imagePath = '',
    this.type = ItemType.misc,
    this.notes = '',
    this.calculable = false,
    List<ItemCalculationCost>? calculationCosts,
    this.equipped = false,
    this.armorCategory,
    this.armorBaseClass = 10,
    this.weapon,
    List<CharacterPassive>? passives,
    List<CharacterAbility>? abilities,
    this.consumable,
    this.quantity = 1,
  }) : templateId = templateId?.trim().isNotEmpty == true
           ? templateId!.trim()
           : id,
       calculationCosts = calculationCosts ?? [],
       passives = passives ?? [],
       abilities = abilities ?? [];

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool? get hasImage {
    return imagePath?.trim().isNotEmpty;
  }

  bool get hasPassives {
    return passives.isNotEmpty;
  }

  bool get hasAbilities {
    return abilities.isNotEmpty;
  }

  bool get isWeapon {
    return type == ItemType.weapon && weapon != null;
  }

  bool get isConsumable {
    return type == ItemType.consumable && consumable != null;
  }

  bool get isEquipable {
    return type.isEquipable;
  }

  String get definitionId {
    final value = templateId.trim();

    if (value.isNotEmpty) {
      return value;
    }

    return id;
  }

  // ===========================================================================
  // CHARACTER ITEM → ITEM DEFINITION
  // ===========================================================================

  ItemDefinition toDefinition() {
    return ItemDefinition(
      id: definitionId,

      name: name,

      description: description,

      type: type,

      imagePath: imagePath,

      notes: notes,

      stackable: type.stackableByDefault,

      calculable: calculable,

      calculationCosts: calculationCosts
          .map((cost) => ItemCalculationCost.fromMap(cost.toMap()))
          .toList(),

      equipmentSlotIds: type.defaultEquipmentSlotIds,

      armor: armorCategory == null
          ? null
          : ItemArmorDefinition(
              category: armorCategory!,
              baseArmorClass: armorBaseClass,
            ),

      weapon: weapon == null ? null : Weapon.fromMap(weapon!.toMap()),

      consumable: consumable == null
          ? null
          : Consumable.fromMap(consumable!.toMap()),

      passives: passives
          .map((passive) => CharacterPassive.fromMap(passive.toMap()))
          .toList(),

      abilities: abilities
          .map((ability) => CharacterAbility.fromMap(ability.toMap()))
          .toList(),
    );
  }

  // ===========================================================================
  // CHARACTER ITEM → INVENTORY ITEM
  // ===========================================================================

  InventoryItem toInventoryItem() {
    return InventoryItem(
      id: id,

      itemId: definitionId,

      quantity: quantity < 0 ? 0 : quantity,

      equipped: equipped,

      equippedSlotId: equipped ? type.defaultEquipmentSlotId : null,
    );
  }

  // ===========================================================================
  // ITEM DEFINITION → CHARACTER ITEM
  //
  // Compatibilidad temporal.
  // ===========================================================================

  factory CharacterItem.fromDefinition(
    ItemDefinition definition, {
    String? inventoryId,
    int quantity = 1,
    bool equipped = false,
    String? equippedSlotId,
  }) {
    return CharacterItem(
      id: inventoryId ?? DateTime.now().microsecondsSinceEpoch.toString(),

      templateId: definition.id,

      name: definition.name,

      description: definition.description,

      imagePath: definition.imagePath,

      type: definition.type,

      notes: definition.notes,

      calculable: definition.calculable,

      calculationCosts: definition.calculationCosts
          .map((cost) => ItemCalculationCost.fromMap(cost.toMap()))
          .toList(),

      equipped: equipped,

      armorCategory: definition.armor?.category,

      armorBaseClass: definition.armor?.baseArmorClass ?? 10,

      weapon: definition.weapon == null
          ? null
          : Weapon.fromMap(definition.weapon!.toMap()),

      consumable: definition.consumable == null
          ? null
          : Consumable.fromMap(definition.consumable!.toMap()),

      passives: definition.passives
          .map((passive) => CharacterPassive.fromMap(passive.toMap()))
          .toList(),

      abilities: definition.abilities
          .map((ability) => CharacterAbility.fromMap(ability.toMap()))
          .toList(),

      quantity: quantity < 0 ? 0 : quantity,
    );
  }

  // ===========================================================================
  // ITEM DEFINITION + INVENTORY ITEM → CHARACTER ITEM
  // ===========================================================================

  factory CharacterItem.fromDefinitionAndInventory({
    required ItemDefinition definition,
    required InventoryItem inventory,
  }) {
    if (inventory.itemId != definition.id) {
      throw ArgumentError(
        'InventoryItem "${inventory.id}" referencia '
        '"${inventory.itemId}", pero la definición recibida es '
        '"${definition.id}".',
      );
    }

    return CharacterItem.fromDefinition(
      definition,
      inventoryId: inventory.id,
      quantity: inventory.quantity,
      equipped: inventory.equipped,
      equippedSlotId: inventory.equippedSlotId,
    );
  }

  // ===========================================================================
  // SERIALIZATION · LEGACY
  //
  // Se conserva mientras Character todavía persista CharacterItem.
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,

      'templateId': templateId,

      'name': name,

      'description': description,

      'imagePath': imagePath,

      'type': type.name,

      'notes': notes,

      'calculable': calculable,

      'calculationCosts': calculationCosts.map((cost) => cost.toMap()).toList(),

      'equipped': equipped,

      'armorCategory': armorCategory?.name,

      'armorBaseClass': armorBaseClass,

      'weapon': weapon?.toMap(),

      'passives': passives.map((passive) => passive.toMap()).toList(),

      'abilities': abilities.map((ability) => ability.toMap()).toList(),

      'consumable': consumable?.toMap(),

      'quantity': quantity,
    };
  }

  // ===========================================================================
  // FROM MAP · LEGACY
  // ===========================================================================

  factory CharacterItem.fromMap(Map<dynamic, dynamic> map) {
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
          // Ignorar.
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
    // TYPE
    // =========================================================================

    final type = ItemType.values.firstWhere(
      (value) => value.name == map['type']?.toString(),
      orElse: () => ItemType.misc,
    );

    // =========================================================================
    // ARMOR
    // =========================================================================

    ArmorCategory? armorCategory;

    final rawArmorCategory = map['armorCategory']?.toString();

    if (rawArmorCategory != null && rawArmorCategory.isNotEmpty) {
      armorCategory = ArmorCategory.values.firstWhere(
        (value) => value.name == rawArmorCategory,
        orElse: () => ArmorCategory.light,
      );
    }

    // =========================================================================
    // ID
    // =========================================================================

    final id = map['id']?.toString() ?? '';

    final templateId = map['templateId']?.toString().trim() ?? '';

    // =========================================================================
    // RESULT
    // =========================================================================

    return CharacterItem(
      id: id,

      templateId: templateId.isNotEmpty ? templateId : id,

      name: map['name']?.toString() ?? '',

      description: map['description']?.toString() ?? '',

      imagePath: map['imagePath']?.toString() ?? '',

      type: type,

      notes: map['notes']?.toString() ?? '',

      calculable: map['calculable'] as bool? ?? calculationCosts.isNotEmpty,

      calculationCosts: calculationCosts,

      equipped: map['equipped'] == true,

      armorCategory: armorCategory,

      armorBaseClass: (map['armorBaseClass'] as num?)?.toInt() ?? 10,

      weapon: weapon,

      passives: passives,

      abilities: abilities,

      consumable: consumable,

      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
