import 'consumable.dart';
import 'ability.dart';
import 'passive.dart';
import 'weapon.dart';

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
  other,
}

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

extension ItemTypeData on ItemType {
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

      case ItemType.other:
        return 'Otro';
    }
  }

  bool get isEquipable {
    return this != ItemType.consumable;
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
      case ItemType.other:
        return false;
    }
  }
}

class CharacterItem {
  String id;

  String name;

  String description;

  bool calculable;

  List<ItemCalculationCost> calculationCosts;

  String templateId;

  // ===========================================================================
  // IMAGEN
  // ===========================================================================

  /// Ruta local persistente de la imagen del objeto.
  ///
  /// Si está vacío, el objeto utilizará su icono por defecto.
  String imagePath;

  // ===========================================================================
  // TIPO / EQUIPAMIENTO
  // ===========================================================================

  ItemType type;

  bool equipped;

  ArmorCategory? armorCategory;

  int armorBaseClass;

  // ===========================================================================
  // ARMA
  // ===========================================================================

  Weapon? weapon;

  // ===========================================================================
  // CONTENIDO
  // ===========================================================================

  List<CharacterPassive> passives;

  List<CharacterAbility> abilities;

  // ===========================================================================
  // INVENTARIO
  // ===========================================================================

  int quantity;

  String notes;

  Consumable? consumable;

  CharacterItem({
    required this.id,
    required this.name,
    this.description = '',
    this.calculable = false,
    List<ItemCalculationCost>? calculationCosts,
    String? templateId,
    // Imagen
    this.imagePath = '',

    // Tipo
    this.type = ItemType.other,
    this.equipped = false,

    // Armadura
    this.armorCategory,
    this.armorBaseClass = 10,

    //Arma
    this.weapon,

    // Contenido
    List<CharacterPassive>? passives,
    List<CharacterAbility>? abilities,

    // Inventario
    this.quantity = 1,
    this.notes = '',
    this.consumable,
  }) : passives = passives ?? [],
       calculationCosts = calculationCosts ?? [],
       templateId = templateId?.trim().isNotEmpty == true ? templateId! : id,
       abilities = abilities ?? [];

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool get hasImage {
    return imagePath.trim().isNotEmpty;
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

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'calculable': calculable,

      'calculationCosts': calculationCosts.map((cost) => cost.toMap()).toList(),
      'templateId': templateId,
      // Imagen
      'imagePath': imagePath,

      // Tipo / equipamiento
      'type': type.name,
      'equipped': equipped,

      // Pasivas
      'passives': passives.map((passive) => passive.toMap()).toList(),

      // Habilidades
      'abilities': abilities.map((ability) => ability.toMap()).toList(),

      // Inventario
      'quantity': quantity,
      'notes': notes,
      'consumable': consumable?.toMap(),

      // Armadura
      'armorCategory': armorCategory?.name,
      'armorBaseClass': armorBaseClass,

      //Arma
      'weapon': weapon?.toMap(),
    };
  }

  factory CharacterItem.fromMap(Map<dynamic, dynamic> map) {
    // =========================================================================
    // PASIVAS
    // =========================================================================

    final passives = <CharacterPassive>[];

    final rawPassives = map['passives'];

    if (rawPassives is List) {
      for (final rawPassive in rawPassives) {
        if (rawPassive == null) {
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

    /*
     * Compatibilidad con el modelo antiguo,
     * donde había una sola pasiva.
     */
    if (passives.isEmpty) {
      final oldPassive = map['passive'];

      if (oldPassive is Map) {
        try {
          passives.add(
            CharacterPassive.fromMap(Map<dynamic, dynamic>.from(oldPassive)),
          );
        } catch (_) {}
      }
    }

    // =========================================================================
    // HABILIDADES
    // =========================================================================

    final abilities = <CharacterAbility>[];

    final rawAbilities = map['abilities'];

    if (rawAbilities is List) {
      for (final rawAbility in rawAbilities) {
        if (rawAbility == null) {
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

    Weapon? weapon;

    final rawWeapon = map['weapon'];

    if (rawWeapon is Map) {
      try {
        weapon = Weapon.fromMap(Map<dynamic, dynamic>.from(rawWeapon));
      } catch (_) {
        weapon = null;
      }
    }

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
    // OBJETO
    // =========================================================================

    return CharacterItem(
      id: map['id']?.toString() ?? '',

      name: map['name']?.toString() ?? '',

      description: map['description']?.toString() ?? '',

      calculable: map['calculable'] as bool? ?? false,

      calculationCosts: calculationCosts,

      templateId: map['templateId']?.toString() ?? map['id']?.toString() ?? '',
      // Imagen
      imagePath: map['imagePath']?.toString() ?? '',

      // Tipo
      type: ItemType.values.firstWhere(
        (item) => item.name == map['type']?.toString(),
        orElse: () => ItemType.other,
      ),

      equipped: map['equipped'] == true,

      // Pasivas
      passives: passives,

      // Habilidades
      abilities: abilities,

      // Inventario
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,

      notes: map['notes']?.toString() ?? '',

      // Armadura
      armorCategory: map['armorCategory'] == null
          ? null
          : ArmorCategory.values.firstWhere(
              (value) => value.name == map['armorCategory']?.toString(),
              orElse: () => ArmorCategory.light,
            ),

      armorBaseClass: (map['armorBaseClass'] as num?)?.toInt() ?? 10,

      weapon: weapon,

      consumable: consumable,
    );
  }
}

class ItemCalculationCost {
  String itemId;

  int quantityPerUnit;

  ItemCalculationCost({required this.itemId, this.quantityPerUnit = 1});

  Map<String, dynamic> toMap() {
    return {'itemId': itemId, 'quantityPerUnit': quantityPerUnit};
  }

  factory ItemCalculationCost.fromMap(Map<dynamic, dynamic> map) {
    return ItemCalculationCost(
      itemId: map['itemId']?.toString() ?? '',
      quantityPerUnit: (map['quantityPerUnit'] as num?)?.toInt() ?? 1,
    );
  }
}
