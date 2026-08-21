import 'dice_pool.dart';
import 'skill.dart';
import 'ability_effect_part.dart';

enum AbilityActionType { action, bonusAction, reaction, passive }

extension AbilityActionTypeData on AbilityActionType {
  String get label {
    switch (this) {
      case AbilityActionType.action:
        return 'Acción';

      case AbilityActionType.bonusAction:
        return 'Acción adicional';

      case AbilityActionType.reaction:
        return 'Reacción';

      case AbilityActionType.passive:
        return 'Pasiva';
    }
  }
}

enum AbilityEffectType { damage, healing, none }

extension AbilityEffectTypeData on AbilityEffectType {
  String get label {
    switch (this) {
      case AbilityEffectType.damage:
        return 'Daño';

      case AbilityEffectType.healing:
        return 'Curación';

      case AbilityEffectType.none:
        return 'Sin daño/curación';
    }
  }
}

enum SaveSuccessEffect { full, half, none }

extension SaveSuccessEffectData on SaveSuccessEffect {
  String get label {
    switch (this) {
      case SaveSuccessEffect.full:
        return 'Daño completo';
      case SaveSuccessEffect.half:
        return 'Mitad';
      case SaveSuccessEffect.none:
        return 'Sin daño';
    }
  }
}

class AbilityEffect {
  String id;
  String name;

  AbilityEffectType effectType;

  List<DicePool> dicePools;

  Map<AbilityType, int> abilityModifierMultipliers;

  int effectBonus;

  String effectTypeName;

  List<AbilityEffectPart> parts;

  bool usesSavingThrow;
  AbilityType savingThrowAbility;
  int saveDcBonus;

  SaveSuccessEffect saveSuccessEffect;

  bool legacyAddAbilityModifier;

  AbilityEffect({
    required this.id,
    this.name = '',
    this.effectType = AbilityEffectType.damage,
    List<DicePool>? dicePools,
    Map<AbilityType, int>? abilityModifierMultipliers,
    this.legacyAddAbilityModifier = false,
    this.effectBonus = 0,
    this.effectTypeName = '',
    this.usesSavingThrow = false,
    this.savingThrowAbility = AbilityType.dexterity,
    this.saveDcBonus = 0,
    this.saveSuccessEffect = SaveSuccessEffect.half,
    List<AbilityEffectPart>? parts,
  }) : dicePools = dicePools ?? [],
       parts = parts ?? [],
       abilityModifierMultipliers = abilityModifierMultipliers ?? {};

  bool get hasEffect {
    return effectType != AbilityEffectType.none &&
        (parts.any((part) => part.hasValue) ||
            dicePools.isNotEmpty ||
            abilityModifierMultipliers.values.any((value) => value != 0) ||
            effectBonus != 0 ||
            legacyAddAbilityModifier);
  }

  bool get dealsDamage => effectType == AbilityEffectType.damage;

  bool get heals => effectType == AbilityEffectType.healing;

  String get diceNotation {
    if (dicePools.isEmpty) {
      return '';
    }

    return dicePools.map((pool) => pool.notation).join(' + ');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'effectType': effectType.name,
      'dicePools': dicePools.map((pool) => pool.toMap()).toList(),
      'abilityModifierMultipliers': {
        for (final entry in abilityModifierMultipliers.entries)
          entry.key.name: entry.value,
      },
      'parts': parts.map((part) => part.toMap()).toList(),
      'effectBonus': effectBonus,
      'effectTypeName': effectTypeName,
      'usesSavingThrow': usesSavingThrow,
      'savingThrowAbility': savingThrowAbility.name,
      'saveDcBonus': saveDcBonus,
      'saveSuccessEffect': saveSuccessEffect.name,
    };
  }

  factory AbilityEffect.fromMap(Map<dynamic, dynamic> map) {
    final pools = <DicePool>[];

    final rawPools = map['dicePools'];

    if (rawPools is List) {
      for (final rawPool in rawPools) {
        if (rawPool == null) {
          continue;
        }

        try {
          pools.add(DicePool.fromMap(Map<dynamic, dynamic>.from(rawPool)));
        } catch (_) {
          continue;
        }
      }
    }

    final parts = <AbilityEffectPart>[];

    final rawParts = map['parts'];

    if (rawParts is List) {
      for (final rawPart in rawParts) {
        if (rawPart is! Map) {
          continue;
        }

        try {
          parts.add(
            AbilityEffectPart.fromMap(Map<dynamic, dynamic>.from(rawPart)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    final abilityModifierMultipliers = <AbilityType, int>{};

    final rawMultipliers = map['abilityModifierMultipliers'];

    if (rawMultipliers is Map) {
      final multiplierMap = Map<dynamic, dynamic>.from(rawMultipliers);

      for (final ability in AbilityType.values) {
        final value = (multiplierMap[ability.name] as num?)?.toInt() ?? 0;

        if (value != 0) {
          abilityModifierMultipliers[ability] = value;
        }
      }
    }

    if (parts.isEmpty &&
        (pools.isNotEmpty ||
            abilityModifierMultipliers.isNotEmpty ||
            (map['effectBonus'] as num?)?.toInt() != 0)) {
      parts.add(
        AbilityEffectPart(
          id: '${map['id']}_part_0',

          dicePools: pools,

          abilityModifierMultipliers: abilityModifierMultipliers,

          flatBonus: (map['effectBonus'] as num?)?.toInt() ?? 0,

          typeName: map['effectTypeName']?.toString() ?? '',
        ),
      );
    }

    return AbilityEffect(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      effectType: AbilityEffectType.values.firstWhere(
        (item) => item.name == map['effectType'],
        orElse: () => AbilityEffectType.damage,
      ),
      dicePools: pools,
      legacyAddAbilityModifier:
          map['addAbilityModifierToEffect'] as bool? ?? false,
      effectBonus: (map['effectBonus'] as num?)?.toInt() ?? 0,
      effectTypeName: map['effectTypeName']?.toString() ?? '',
      usesSavingThrow: map['usesSavingThrow'] as bool? ?? false,
      savingThrowAbility: AbilityType.values.firstWhere(
        (item) => item.name == map['savingThrowAbility'],
        orElse: () => AbilityType.dexterity,
      ),
      saveDcBonus: (map['saveDcBonus'] as num?)?.toInt() ?? 0,
      saveSuccessEffect: SaveSuccessEffect.values.firstWhere(
        (item) => item.name == map['saveSuccessEffect'],
        orElse: () => SaveSuccessEffect.half,
      ),
      parts: parts,
    );
  }
}

class CharacterAbility {
  String id;
  String name;
  String description;

  AbilityActionType actionType;

  bool requiresAttackRoll;

  AbilityType abilityType;

  bool proficient;

  /// Bonus plano adicional a la tirada de ataque.
  int attackBonus;

  AbilityEffectType effectType;

  /// ID del recurso del personaje que consume.
  ///
  /// null o vacío = no consume recursos.
  String? resourceId;

  /// Cantidad consumida al utilizar la habilidad.
  int resourceCost;

  /// Permite cosas como:
  /// 2d6 + 1d8
  List<DicePool> dicePools;
  List<AbilityEffect> effects;

  /// Suma el modificador del atributo al daño/curación.
  bool addAbilityModifierToEffect;

  /// Bonus plano adicional.
  int effectBonus;

  /// Fuego, cortante, radiante...
  /// Para curación se puede dejar vacío.
  String effectTypeName;

  bool usesSavingThrow;

  AbilityType savingThrowAbility;

  int saveDcBonus;

  /// 0 = usos ilimitados.
  int maxUses;

  int currentUses;

  String notes;

  CharacterAbility({
    required this.id,
    required this.name,
    this.description = '',
    this.actionType = AbilityActionType.action,
    this.requiresAttackRoll = false,
    this.abilityType = AbilityType.strength,
    this.proficient = true,
    this.attackBonus = 0,
    this.effectType = AbilityEffectType.none,
    List<DicePool>? dicePools,
    this.addAbilityModifierToEffect = true,
    this.effectBonus = 0,
    this.effectTypeName = '',
    this.usesSavingThrow = false,
    this.savingThrowAbility = AbilityType.dexterity,
    this.saveDcBonus = 0,
    this.maxUses = 0,
    this.currentUses = 0,
    this.resourceId,
    this.resourceCost = 0,
    List<AbilityEffect>? effects,
    this.notes = '',
  }) : dicePools = dicePools ?? [],
       effects = effects ?? [];

  bool get hasLimitedUses => maxUses > 0;

  bool get hasEffect {
    return effectType != AbilityEffectType.none && dicePools.isNotEmpty;
  }

  bool get dealsDamage {
    return effectType == AbilityEffectType.damage;
  }

  bool get heals {
    return effectType == AbilityEffectType.healing;
  }

  String get diceNotation {
    if (dicePools.isEmpty) {
      return '';
    }

    return dicePools.map((pool) => pool.notation).join(' + ');
  }

  bool get usesResource {
    return resourceId != null &&
        resourceId!.trim().isNotEmpty &&
        resourceCost > 0;
  }

  int get maximumDiceValue {
    return dicePools.fold(0, (sum, pool) => sum + pool.maximum);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'actionType': actionType.name,
      'requiresAttackRoll': requiresAttackRoll,
      'abilityType': abilityType.name,
      'proficient': proficient,
      'attackBonus': attackBonus,
      'effectType': effectType.name,
      'dicePools': dicePools.map((pool) => pool.toMap()).toList(),
      'addAbilityModifierToEffect': addAbilityModifierToEffect,
      'effectBonus': effectBonus,
      'effectTypeName': effectTypeName,
      'usesSavingThrow': usesSavingThrow,
      'savingThrowAbility': savingThrowAbility.name,
      'saveDcBonus': saveDcBonus,
      'maxUses': maxUses,
      'effects': effects.map((effect) => effect.toMap()).toList(),
      'currentUses': currentUses,
      'notes': notes,
      'resourceId': resourceId,
      'resourceCost': resourceCost,
    };
  }

  factory CharacterAbility.fromMap(Map<dynamic, dynamic> map) {
    final pools = <DicePool>[];

    final rawPools = map['dicePools'];

    if (rawPools is List) {
      for (final rawPool in rawPools) {
        if (rawPool == null) {
          continue;
        }

        try {
          pools.add(DicePool.fromMap(Map<dynamic, dynamic>.from(rawPool)));
        } catch (_) {
          continue;
        }
      }
    }
    final effects = <AbilityEffect>[];

    final rawEffects = map['effects'];

    if (rawEffects is List) {
      for (final rawEffect in rawEffects) {
        if (rawEffect == null) {
          continue;
        }

        try {
          effects.add(
            AbilityEffect.fromMap(Map<dynamic, dynamic>.from(rawEffect)),
          );
        } catch (_) {
          continue;
        }
      }
    }
    /*
     * Compatibilidad con habilidades antiguas que tenían
     * damageDice = "2d6".
     */
    if (pools.isEmpty) {
      final oldDice = map['damageDice']?.toString() ?? '';

      final parsed = _parseLegacyDice(oldDice);

      if (parsed != null) {
        pools.add(parsed);
      }
    }

    final storedEffect = map['effectType']?.toString();

    AbilityEffectType effect;

    if (storedEffect != null) {
      effect = AbilityEffectType.values.firstWhere(
        (item) => item.name == storedEffect,
        orElse: () => AbilityEffectType.none,
      );
    } else {
      // Datos antiguos.
      effect = pools.isNotEmpty
          ? AbilityEffectType.damage
          : AbilityEffectType.none;
    }
    if (effects.isEmpty && pools.isNotEmpty) {
      final legacyAddModifier =
          map['addAbilityModifierToEffect'] as bool? ??
          map['addAbilityToDamage'] as bool? ??
          true;

      effects.add(
        AbilityEffect(
          id: '${map['id']}_effect_0',

          name: '',

          effectType: effect,

          dicePools: List<DicePool>.from(pools),

          // ===============================================================
          // MIGRACIÓN DEL MODIFICADOR ANTIGUO
          //
          // Antes:
          // addAbilityModifierToEffect = true
          //
          // Ahora:
          // { atributo: 1 }
          // ===============================================================
          abilityModifierMultipliers: legacyAddModifier
              ? {
                  AbilityType.values.firstWhere(
                    (item) => item.name == map['abilityType'],
                    orElse: () => AbilityType.strength,
                  ): 1,
                }
              : {},

          legacyAddAbilityModifier: false,

          effectBonus:
              (map['effectBonus'] as num?)?.toInt() ??
              (map['damageBonus'] as num?)?.toInt() ??
              0,

          effectTypeName:
              map['effectTypeName']?.toString() ??
              map['damageType']?.toString() ??
              '',

          usesSavingThrow: map['usesSavingThrow'] as bool? ?? false,

          savingThrowAbility: AbilityType.values.firstWhere(
            (item) => item.name == map['savingThrowAbility'],
            orElse: () => AbilityType.dexterity,
          ),

          saveDcBonus: (map['saveDcBonus'] as num?)?.toInt() ?? 0,

          saveSuccessEffect: SaveSuccessEffect.half,
        ),
      );
    }
    return CharacterAbility(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      actionType: AbilityActionType.values.firstWhere(
        (item) => item.name == map['actionType'],
        orElse: () => AbilityActionType.action,
      ),
      effects: effects,
      requiresAttackRoll: map['requiresAttackRoll'] as bool? ?? false,
      abilityType: AbilityType.values.firstWhere(
        (item) => item.name == map['abilityType'],
        orElse: () => AbilityType.strength,
      ),
      proficient: map['proficient'] as bool? ?? true,
      attackBonus: (map['attackBonus'] as num?)?.toInt() ?? 0,
      effectType: effect,
      dicePools: pools,
      addAbilityModifierToEffect:
          map['addAbilityModifierToEffect'] as bool? ??
          map['addAbilityToDamage'] as bool? ??
          true,
      effectBonus:
          (map['effectBonus'] as num?)?.toInt() ??
          (map['damageBonus'] as num?)?.toInt() ??
          0,
      effectTypeName:
          map['effectTypeName']?.toString() ??
          map['damageType']?.toString() ??
          '',
      usesSavingThrow: map['usesSavingThrow'] as bool? ?? false,
      savingThrowAbility: AbilityType.values.firstWhere(
        (item) => item.name == map['savingThrowAbility'],
        orElse: () => AbilityType.dexterity,
      ),
      saveDcBonus: (map['saveDcBonus'] as num?)?.toInt() ?? 0,
      maxUses: (map['maxUses'] as num?)?.toInt() ?? 0,
      currentUses: (map['currentUses'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString() ?? '',
      resourceId: map['resourceId']?.toString(),

      resourceCost: (map['resourceCost'] as num?)?.toInt() ?? 0,
    );
  }

  static DicePool? _parseLegacyDice(String value) {
    final clean = value.trim().toLowerCase();

    final match = RegExp(r'^(\d+)d(\d+)$').firstMatch(clean);

    if (match == null) {
      return null;
    }

    final count = int.tryParse(match.group(1) ?? '');

    final sides = int.tryParse(match.group(2) ?? '');

    if (count == null || sides == null || count <= 0 || sides <= 0) {
      return null;
    }

    return DicePool(count: count, sides: sides);
  }
}
