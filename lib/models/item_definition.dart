import 'package:flutter/foundation.dart';
import 'equipment_slot.dart';
import 'ability.dart';
import 'action_definition.dart';
import 'consumable.dart';
import 'passive.dart';
import 'weapon.dart';

enum ItemType {
  weapon,
  armor,
  shield,
  helmet,
  gloves,
  boots,
  cape,
  ring,
  amulet,
  consumable,
  material,
  tool,
  book,
  special,
  misc,
  potion,
  scroll,
  accessory,
  ammunition,
  container;

  String get label {
    switch (this) {
      case ItemType.weapon:
        return 'Arma';
      case ItemType.armor:
        return 'Armadura';
      case ItemType.shield:
        return 'Escudo';
      case ItemType.helmet:
        return 'Casco';
      case ItemType.gloves:
        return 'Guantes';
      case ItemType.boots:
        return 'Botas';
      case ItemType.cape:
        return 'Capa';
      case ItemType.ring:
        return 'Anillo';
      case ItemType.amulet:
        return 'Amuleto';
      case ItemType.consumable:
        return 'Consumible';
      case ItemType.material:
        return 'Material';
      case ItemType.tool:
        return 'Herramienta';
      case ItemType.book:
        return 'Libro';
      case ItemType.special:
        return 'Especial';
      case ItemType.misc:
        return 'Varios';
      case ItemType.potion:
        return 'Poción';
      case ItemType.scroll:
        return 'Pergamino';
      case ItemType.accessory:
        return 'Accesorio';
      case ItemType.ammunition:
        return 'Munición';
      case ItemType.container:
        return 'Contenedor';
    }
  }

  bool get isEquipable {
    switch (this) {
      case ItemType.weapon:
      case ItemType.armor:
      case ItemType.shield:
      case ItemType.helmet:
      case ItemType.gloves:
      case ItemType.boots:
      case ItemType.cape:
      case ItemType.ring:
      case ItemType.amulet:
      case ItemType.accessory:
        return true;
      default:
        return false;
    }
  }

  bool get stackableByDefault {
    switch (this) {
      case ItemType.weapon:
      case ItemType.armor:
      case ItemType.shield:
      case ItemType.helmet:
      case ItemType.gloves:
      case ItemType.boots:
      case ItemType.cape:
      case ItemType.ring:
      case ItemType.amulet:
      case ItemType.accessory:
      case ItemType.container:
        return false;
      default:
        return true;
    }
  }

  bool get exclusiveSlot {
    switch (this) {
      case ItemType.armor:
      case ItemType.helmet:
      case ItemType.gloves:
      case ItemType.boots:
      case ItemType.cape:
      case ItemType.amulet:
        return true;

      default:
        return false;
    }
  }

  String? get defaultEquipmentSlotId {
    switch (this) {
      case ItemType.weapon:
        return 'main_hand';
      case ItemType.shield:
        return 'off_hand';
      case ItemType.armor:
        return 'chest';
      case ItemType.helmet:
        return 'head';
      case ItemType.gloves:
        return 'hands';
      case ItemType.boots:
        return 'feet';
      case ItemType.cape:
        return 'back';
      case ItemType.ring:
        return 'ring_1';
      case ItemType.amulet:
        return 'neck';
      default:
        return null;
    }
  }

  List<String> get defaultEquipmentSlotIds {
    final slot = defaultEquipmentSlotId;
    return slot != null ? [slot] : const [];
  }
}

enum ArmorCategory {
  light,
  medium,
  heavy,
  shield,
  custom;

  String get label {
    switch (this) {
      case ArmorCategory.light:
        return 'Ligera';
      case ArmorCategory.medium:
        return 'Media';
      case ArmorCategory.heavy:
        return 'Pesada';
      case ArmorCategory.shield:
        return 'Escudo';
      case ArmorCategory.custom:
        return 'Personalizada';
    }
  }
}

extension ItemTypeSlotCompatibility on ItemType {
  Set<EquipmentSlotCategory> get compatibleSlotCategories {
    switch (this) {
      case ItemType.armor:
        return {
          EquipmentSlotCategory.chest,
          EquipmentSlotCategory.head,
          EquipmentSlotCategory.legs,
          EquipmentSlotCategory.feet,
          EquipmentSlotCategory.hands,
          EquipmentSlotCategory.waist,
        };
      case ItemType.helmet:
        return {EquipmentSlotCategory.head};
      case ItemType.gloves:
        return {EquipmentSlotCategory.hands};
      case ItemType.boots:
        return {EquipmentSlotCategory.feet};
      case ItemType.cape:
        return {EquipmentSlotCategory.back};
      case ItemType.amulet:
        return {EquipmentSlotCategory.neck};
      case ItemType.ring:
        return {EquipmentSlotCategory.ring};
      case ItemType.weapon:
      case ItemType.shield:
        return {EquipmentSlotCategory.mainHand, EquipmentSlotCategory.offHand};
      case ItemType.accessory:
        return {
          EquipmentSlotCategory.neck,
          EquipmentSlotCategory.ring,
          EquipmentSlotCategory.waist,
          EquipmentSlotCategory.custom,
        };
      case ItemType.tool:
        return {
          EquipmentSlotCategory.mainHand,
          EquipmentSlotCategory.offHand,
          EquipmentSlotCategory.custom,
        };
      default:
        return {};
    }
  }
}

@immutable
class ItemArmorDefinition {
  final int baseArmorClass;
  final ArmorCategory category;
  final int? maxDexBonus;
  final int minStrength;
  final bool stealthDisadvantage;
  final String? customFormula; // <-- NUEVO

  const ItemArmorDefinition({
    this.baseArmorClass = 10,
    this.category = ArmorCategory.light,
    this.maxDexBonus,
    this.minStrength = 0,
    this.stealthDisadvantage = false,
    this.customFormula,
  });

  int get armorClass => baseArmorClass;

  Map<String, dynamic> toMap() => {
    'baseArmorClass': baseArmorClass,
    'armorClass': baseArmorClass,
    'category': category.name,
    'maxDexBonus': maxDexBonus,
    'minStrength': minStrength,
    'stealthDisadvantage': stealthDisadvantage,
    if (customFormula != null) 'customFormula': customFormula,
  };

  factory ItemArmorDefinition.fromMap(Map<dynamic, dynamic> map) {
    return ItemArmorDefinition(
      baseArmorClass:
          (map['baseArmorClass'] ?? map['armorClass'] as num?)?.toInt() ?? 10,
      category: ArmorCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ArmorCategory.light,
      ),
      maxDexBonus: (map['maxDexBonus'] as num?)?.toInt(),
      minStrength: (map['minStrength'] as num?)?.toInt() ?? 0,
      stealthDisadvantage: map['stealthDisadvantage'] as bool? ?? false,
      customFormula: map['customFormula']?.toString(),
    );
  }
}

@immutable
class ItemDefinition {
  final String id;
  final String name;
  final String description;
  final ItemType type;
  final String? imagePath;
  final double weight;
  final int priceValue;
  final String currencyName;
  final bool stackable;
  final int maxStackSize;
  final String notes;
  final bool calculable;
  final List<ItemCalculationCost> calculationCosts;
  final List<String> equipmentSlotIds;
  final ItemArmorDefinition? armor;
  final Weapon? weapon;
  final Consumable? consumable;
  final List<CharacterPassive> passives;
  final List<CharacterAbility> abilities;
  final ActionDefinition? actionDefinition;
  final Map<String, dynamic> customProperties;

  /// ID del conocimiento que contiene o enseña este objeto (libros, pergaminos, etc.)
  final String? relatedKnowledgeId;

  const ItemDefinition({
    required this.id,
    required this.name,
    this.description = '',
    this.type = ItemType.misc,
    this.imagePath,
    this.weight = 0.0,
    this.priceValue = 0,
    this.currencyName = 'Oro',
    this.stackable = true,
    this.maxStackSize = 999,
    this.notes = '',
    this.calculable = false,
    this.calculationCosts = const [],
    this.equipmentSlotIds = const [],
    this.armor,
    this.weapon,
    this.consumable,
    this.passives = const [],
    this.abilities = const [],
    this.actionDefinition,
    this.customProperties = const {},
    this.relatedKnowledgeId,
  });

  bool get isWeapon => type == ItemType.weapon || weapon != null;
  bool get hasImage => imagePath != null && imagePath!.trim().isNotEmpty;
  bool get isEquippable => equipmentSlotIds.isNotEmpty || type.isEquipable;
  bool get hasPassives => passives.isNotEmpty;
  bool get hasAbilities => abilities.isNotEmpty;
  bool get hasAction => actionDefinition != null;

  ItemDefinition copyWith({
    String? id,
    String? name,
    String? description,
    ItemType? type,
    String? imagePath,
    double? weight,
    int? priceValue,
    String? currencyName,
    bool? stackable,
    int? maxStackSize,
    String? notes,
    bool? calculable,
    List<ItemCalculationCost>? calculationCosts,
    List<String>? equipmentSlotIds,
    ItemArmorDefinition? armor,
    Weapon? weapon,
    Consumable? consumable,
    List<CharacterPassive>? passives,
    List<CharacterAbility>? abilities,
    ActionDefinition? actionDefinition,
    Map<String, dynamic>? customProperties,
    String? relatedKnowledgeId,
  }) {
    return ItemDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      imagePath: imagePath ?? this.imagePath,
      weight: weight ?? this.weight,
      priceValue: priceValue ?? this.priceValue,
      currencyName: currencyName ?? this.currencyName,
      stackable: stackable ?? this.stackable,
      maxStackSize: maxStackSize ?? this.maxStackSize,
      notes: notes ?? this.notes,
      calculable: calculable ?? this.calculable,
      calculationCosts: calculationCosts ?? this.calculationCosts,
      equipmentSlotIds: equipmentSlotIds ?? this.equipmentSlotIds,
      armor: armor ?? this.armor,
      weapon: weapon ?? this.weapon,
      consumable: consumable ?? this.consumable,
      passives: passives ?? this.passives,
      abilities: abilities ?? this.abilities,
      actionDefinition: actionDefinition ?? this.actionDefinition,
      customProperties: customProperties ?? this.customProperties,
      relatedKnowledgeId: relatedKnowledgeId ?? this.relatedKnowledgeId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.name,
    'imagePath': imagePath,
    'weight': weight,
    'priceValue': priceValue,
    'currencyName': currencyName,
    'stackable': stackable,
    'maxStackSize': maxStackSize,
    'notes': notes,
    'calculable': calculable,
    'calculationCosts': calculationCosts.map((c) => c.toMap()).toList(),
    'equipmentSlotIds': equipmentSlotIds,
    'armor': armor?.toMap(),
    'weapon': weapon?.toMap(),
    'consumable': consumable?.toMap(),
    'passives': passives.map((p) => p.toMap()).toList(),
    'abilities': abilities.map((a) => a.toMap()).toList(),
    'actionDefinition': actionDefinition != null
        ? {'id': actionDefinition!.id}
        : null,
    'customProperties': customProperties,
    if (relatedKnowledgeId != null) 'relatedKnowledgeId': relatedKnowledgeId,
  };

  Map<String, dynamic> toJson() => toMap();

  factory ItemDefinition.fromMap(Map<dynamic, dynamic> map) {
    return ItemDefinition(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      type: ItemType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ItemType.misc,
      ),
      imagePath: map['imagePath'] as String?,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      priceValue: (map['priceValue'] as num?)?.toInt() ?? 0,
      currencyName: map['currencyName'] as String? ?? 'Oro',
      stackable: map['stackable'] as bool? ?? true,
      maxStackSize: (map['maxStackSize'] as num?)?.toInt() ?? 999,
      notes: map['notes'] as String? ?? '',
      calculable: map['calculable'] as bool? ?? false,
      calculationCosts:
          (map['calculationCosts'] as List<dynamic>?)
              ?.map(
                (e) => ItemCalculationCost.fromMap(e as Map<dynamic, dynamic>),
              )
              .toList() ??
          const [],
      equipmentSlotIds:
          (map['equipmentSlotIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      armor: map['armor'] != null
          ? ItemArmorDefinition.fromMap(map['armor'] as Map<dynamic, dynamic>)
          : null,
      weapon: map['weapon'] != null
          ? Weapon.fromMap(Map<String, dynamic>.from(map['weapon'] as Map))
          : null,
      consumable: map['consumable'] != null
          ? Consumable.fromMap(
              Map<String, dynamic>.from(map['consumable'] as Map),
            )
          : null,
      passives:
          (map['passives'] as List<dynamic>?)
              ?.map(
                (e) => CharacterPassive.fromMap(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const [],
      abilities:
          (map['abilities'] as List<dynamic>?)
              ?.map(
                (e) => CharacterAbility.fromMap(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const [],
      customProperties: map['customProperties'] != null
          ? Map<String, dynamic>.from(map['customProperties'] as Map)
          : const {},
      relatedKnowledgeId: map['relatedKnowledgeId']?.toString(),
    );
  }

  factory ItemDefinition.fromJson(Map<String, dynamic> json) =>
      ItemDefinition.fromMap(json);
}

class ItemCalculationCost {
  String itemId;
  int quantityPerUnit;

  ItemCalculationCost({required this.itemId, required this.quantityPerUnit});

  // Alias compatibles
  String get resourceId => itemId;
  set resourceId(String val) => itemId = val;
  int get amount => quantityPerUnit;
  set amount(int val) => quantityPerUnit = val;

  Map<String, dynamic> toMap() => {
    'itemId': itemId,
    'quantityPerUnit': quantityPerUnit,
  };

  factory ItemCalculationCost.fromMap(Map<dynamic, dynamic> map) {
    return ItemCalculationCost(
      itemId: (map['itemId'] ?? map['resourceId']) as String? ?? '',
      quantityPerUnit:
      (map['quantityPerUnit'] ?? map['amount'] as num?)?.toInt() ?? 1,
    );
  }
}

