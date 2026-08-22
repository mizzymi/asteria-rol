import 'healing_bonus.dart';
import 'skill.dart';
import 'damage_bonus.dart';
import 'critical_damage_bonus.dart';
import 'dice_pool.dart';

enum PassiveSourceType { race, classFeature, feat, item, background, custom }

extension PassiveSourceTypeData on PassiveSourceType {
  String get label {
    switch (this) {
      case PassiveSourceType.race:
        return 'Racial';

      case PassiveSourceType.classFeature:
        return 'Clase';

      case PassiveSourceType.feat:
        return 'Dote';

      case PassiveSourceType.item:
        return 'Objeto';

      case PassiveSourceType.background:
        return 'Trasfondo';

      case PassiveSourceType.custom:
        return 'Personalizada';
    }
  }
}

class CharacterPassive {
  String id;
  String name;
  String description;

  PassiveSourceType sourceType;

  bool enabled;

  int armorClassBonus;
  int initiativeBonus;
  int speedBonus;
  int maxHealthBonus;
  int attackBonus;

  Map<AbilityType, int> abilityModifierBonuses;

  Map<DndSkill, int> skillBonuses;

  Map<AbilityType, int> savingThrowBonuses;

  List<DamageBonus> damageBonuses;

  List<CriticalDamageBonus> criticalDamageBonuses;

  List<HealingBonus> healingBonuses;

  // ===========================================================================
  // TIRADA PROPIA DE LA PASIVA
  // ===========================================================================

  /// Dados que puede tirar manualmente esta pasiva.
  ///
  /// Ejemplos:
  /// 1d6
  /// 2d8
  /// 2d6 + 1d4
  List<DicePool> rollDicePools;

  /// Atributos que se suman a la tirada.
  ///
  /// Ejemplo:
  /// {
  ///   AbilityType.wisdom: 1,
  ///   AbilityType.constitution: 2,
  /// }
  ///
  /// equivale a:
  /// SAB + 2×CON
  Map<AbilityType, int> rollAbilityModifierMultipliers;

  /// Bonus fijo de la tirada.
  ///
  /// Ejemplo:
  /// 2d6 + SAB + 3
  int rollFlatBonus;

  // ===========================================================================
  // CARGAS
  // ===========================================================================

  /// Si false, esta pasiva funciona como una pasiva tradicional.
  bool hasCharges;

  /// Número máximo de cargas.
  int maxCharges;

  /// Cargas disponibles actualmente.
  int currentCharges;

  /// Texto libre:
  /// "Descanso largo", "Descanso corto", "Al amanecer", etc.
  String rechargeDescription;

  String notes;

  CharacterPassive({
    required this.id,
    required this.name,
    this.description = '',
    this.sourceType = PassiveSourceType.custom,
    this.enabled = true,
    this.armorClassBonus = 0,
    this.initiativeBonus = 0,
    this.speedBonus = 0,
    this.maxHealthBonus = 0,
    this.attackBonus = 0,
    Map<AbilityType, int>? abilityModifierBonuses,
    Map<DndSkill, int>? skillBonuses,
    Map<AbilityType, int>? savingThrowBonuses,
    List<DamageBonus>? damageBonuses,
    List<HealingBonus>? healingBonuses,
    List<CriticalDamageBonus>? criticalDamageBonuses,
    List<DicePool>? rollDicePools,
    Map<AbilityType, int>? rollAbilityModifierMultipliers,
    this.rollFlatBonus = 0,

    // =======================================================================
    // CARGAS
    // =======================================================================
    this.hasCharges = false,
    this.maxCharges = 0,
    this.currentCharges = 0,
    this.rechargeDescription = '',

    this.notes = '',
  }) : skillBonuses = Map<DndSkill, int>.from(skillBonuses ?? {}),
       abilityModifierBonuses = Map<AbilityType, int>.from(
         abilityModifierBonuses ?? {},
       ),
       savingThrowBonuses = Map<AbilityType, int>.from(
         savingThrowBonuses ?? {},
       ),
       damageBonuses = List<DamageBonus>.from(damageBonuses ?? []),
       criticalDamageBonuses = List<CriticalDamageBonus>.from(
         criticalDamageBonuses ?? [],
       ),
       healingBonuses = List<HealingBonus>.from(healingBonuses ?? []),
       rollDicePools = List<DicePool>.from(rollDicePools ?? []),
       rollAbilityModifierMultipliers = Map<AbilityType, int>.from(
         rollAbilityModifierMultipliers ?? {},
       );

  bool get hasRoll {
    return rollDicePools.isNotEmpty ||
        rollAbilityModifierMultipliers.values.any((value) => value != 0) ||
        rollFlatBonus != 0;
  }

  String get rollDiceNotation {
    return rollDicePools.map((pool) => pool.notation).join(' + ');
  }

  // ===========================================================================
  // EFECTOS MECÁNICOS
  // ===========================================================================

  bool get hasMechanicalEffects {
    return armorClassBonus != 0 ||
        initiativeBonus != 0 ||
        speedBonus != 0 ||
        maxHealthBonus != 0 ||
        attackBonus != 0 ||
        abilityModifierBonuses.values.any((value) => value != 0) ||
        skillBonuses.values.any((value) => value != 0) ||
        savingThrowBonuses.values.any((value) => value != 0) ||
        damageBonuses.any((damage) => damage.hasDamage) ||
        criticalDamageBonuses.any((damage) => damage.canTrigger) ||
        healingBonuses.any((bonus) => bonus.hasHealing) ||
        hasRoll;
  }

  // ===========================================================================
  // CARGAS
  // ===========================================================================

  bool get usesCharges {
    return hasCharges && maxCharges > 0;
  }

  bool get hasAvailableCharges {
    return !usesCharges || currentCharges > 0;
  }

  bool get chargesEmpty {
    return usesCharges && currentCharges <= 0;
  }

  String get chargesText {
    if (!usesCharges) {
      return '';
    }

    return '$currentCharges/$maxCharges';
  }

  void useCharge() {
    if (!usesCharges) {
      return;
    }

    if (currentCharges <= 0) {
      return;
    }

    currentCharges--;
  }

  void restoreCharge() {
    if (!usesCharges) {
      return;
    }

    if (currentCharges < maxCharges) {
      currentCharges++;
    }
  }

  void restoreCharges() {
    if (!usesCharges) {
      return;
    }

    currentCharges = maxCharges;
  }

  void normalizeCharges() {
    if (!hasCharges) {
      maxCharges = 0;
      currentCharges = 0;

      return;
    }

    if (maxCharges < 1) {
      maxCharges = 1;
    }

    if (currentCharges < 0) {
      currentCharges = 0;
    }

    if (currentCharges > maxCharges) {
      currentCharges = maxCharges;
    }
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sourceType': sourceType.name,
      'enabled': enabled,

      'armorClassBonus': armorClassBonus,
      'initiativeBonus': initiativeBonus,
      'speedBonus': speedBonus,
      'maxHealthBonus': maxHealthBonus,
      'attackBonus': attackBonus,

      'abilityModifierBonuses': {
        for (final entry in abilityModifierBonuses.entries)
          entry.key.name: entry.value,
      },

      'skillBonuses': {
        for (final entry in skillBonuses.entries) entry.key.name: entry.value,
      },

      'savingThrowBonuses': {
        for (final entry in savingThrowBonuses.entries)
          entry.key.name: entry.value,
      },

      'damageBonuses': damageBonuses.map((damage) => damage.toMap()).toList(),

      'criticalDamageBonuses': criticalDamageBonuses
          .map((damage) => damage.toMap())
          .toList(),

      'healingBonuses': healingBonuses.map((bonus) => bonus.toMap()).toList(),

      'rollDicePools': rollDicePools.map((pool) => pool.toMap()).toList(),

      'rollAbilityModifierMultipliers': {
        for (final entry in rollAbilityModifierMultipliers.entries)
          entry.key.name: entry.value,
      },

      'rollFlatBonus': rollFlatBonus,
      // =======================================================================
      // CARGAS
      // =======================================================================
      'hasCharges': hasCharges,
      'maxCharges': maxCharges,
      'currentCharges': currentCharges,
      'rechargeDescription': rechargeDescription,

      'notes': notes,
    };
  }

  // ===========================================================================
  // FROM MAP
  // ===========================================================================

  factory CharacterPassive.fromMap(Map<dynamic, dynamic> map) {
    // =========================================================================
    // SKILLS
    // =========================================================================

    final skillBonuses = <DndSkill, int>{};

    final rawSkills = map['skillBonuses'];

    if (rawSkills is Map) {
      final skillMap = Map<dynamic, dynamic>.from(rawSkills);

      for (final skill in DndSkill.values) {
        final value = (skillMap[skill.name] as num?)?.toInt() ?? 0;

        if (value != 0) {
          skillBonuses[skill] = value;
        }
      }
    }

    // =========================================================================
    // ATRIBUTOS
    // =========================================================================

    final abilityModifierBonuses = <AbilityType, int>{};

    final rawAbilityBonuses = map['abilityModifierBonuses'];

    if (rawAbilityBonuses is Map) {
      final bonusMap = Map<dynamic, dynamic>.from(rawAbilityBonuses);

      for (final ability in AbilityType.values) {
        final value = (bonusMap[ability.name] as num?)?.toInt() ?? 0;

        if (value != 0) {
          abilityModifierBonuses[ability] = value;
        }
      }
    }

    // =========================================================================
    // SALVACIONES
    // =========================================================================

    final savingThrowBonuses = <AbilityType, int>{};

    final rawSaves = map['savingThrowBonuses'];

    if (rawSaves is Map) {
      final saveMap = Map<dynamic, dynamic>.from(rawSaves);

      for (final ability in AbilityType.values) {
        final value = (saveMap[ability.name] as num?)?.toInt() ?? 0;

        if (value != 0) {
          savingThrowBonuses[ability] = value;
        }
      }
    }

    final damageBonuses = <DamageBonus>[];

    final rawDamageBonuses = map['damageBonuses'];

    if (rawDamageBonuses is List) {
      for (final rawDamage in rawDamageBonuses) {
        if (rawDamage is! Map) {
          continue;
        }

        try {
          damageBonuses.add(
            DamageBonus.fromMap(Map<dynamic, dynamic>.from(rawDamage)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    final criticalDamageBonuses = <CriticalDamageBonus>[];

    final rawCriticalDamageBonuses = map['criticalDamageBonuses'];

    if (rawCriticalDamageBonuses is List) {
      for (final rawDamage in rawCriticalDamageBonuses) {
        if (rawDamage is! Map) {
          continue;
        }

        try {
          criticalDamageBonuses.add(
            CriticalDamageBonus.fromMap(Map<dynamic, dynamic>.from(rawDamage)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    final healingBonuses = <HealingBonus>[];

    final rawHealingBonuses = map['healingBonuses'];

    if (rawHealingBonuses is List) {
      for (final rawBonus in rawHealingBonuses) {
        if (rawBonus is! Map) {
          continue;
        }

        try {
          healingBonuses.add(
            HealingBonus.fromMap(Map<dynamic, dynamic>.from(rawBonus)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    // =========================================================================
    // TIRADA PROPIA
    // =========================================================================

    final rollDicePools = <DicePool>[];

    final rawRollDicePools = map['rollDicePools'];

    if (rawRollDicePools is List) {
      for (final rawPool in rawRollDicePools) {
        if (rawPool is! Map) {
          continue;
        }

        try {
          rollDicePools.add(
            DicePool.fromMap(Map<dynamic, dynamic>.from(rawPool)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    final rollAbilityModifierMultipliers = <AbilityType, int>{};

    final rawRollMultipliers = map['rollAbilityModifierMultipliers'];

    if (rawRollMultipliers is Map) {
      final multiplierMap = Map<dynamic, dynamic>.from(rawRollMultipliers);

      for (final ability in AbilityType.values) {
        final value = (multiplierMap[ability.name] as num?)?.toInt() ?? 0;

        if (value != 0) {
          rollAbilityModifierMultipliers[ability] = value;
        }
      }
    }

    // =========================================================================
    // CARGAS
    // =========================================================================

    /*
     * Compatibilidad con pasivas antiguas:
     *
     * Si no existe hasCharges:
     * false
     *
     * Por tanto funciona exactamente
     * como antes de introducir las cargas.
     */
    final hasCharges = map['hasCharges'] as bool? ?? false;

    final maxCharges = (map['maxCharges'] as num?)?.toInt() ?? 0;

    int currentCharges;

    if (map.containsKey('currentCharges')) {
      currentCharges = (map['currentCharges'] as num?)?.toInt() ?? 0;
    } else {
      /*
       * Compatibilidad intermedia:
       *
       * Si una versión guardó hasCharges
       * y maxCharges pero todavía no tenía
       * currentCharges, empieza llena.
       */
      currentCharges = hasCharges ? maxCharges : 0;
    }

    // =========================================================================
    // CREAR PASIVA
    // =========================================================================

    final passive = CharacterPassive(
      id: map['id']?.toString() ?? '',

      name: map['name']?.toString() ?? '',

      description: map['description']?.toString() ?? '',

      sourceType: PassiveSourceType.values.firstWhere(
        (item) => item.name == map['sourceType'],
        orElse: () => PassiveSourceType.custom,
      ),

      enabled: map['enabled'] as bool? ?? true,

      armorClassBonus: (map['armorClassBonus'] as num?)?.toInt() ?? 0,

      initiativeBonus: (map['initiativeBonus'] as num?)?.toInt() ?? 0,

      speedBonus: (map['speedBonus'] as num?)?.toInt() ?? 0,

      maxHealthBonus: (map['maxHealthBonus'] as num?)?.toInt() ?? 0,

      attackBonus: (map['attackBonus'] as num?)?.toInt() ?? 0,

      skillBonuses: skillBonuses,

      savingThrowBonuses: savingThrowBonuses,

      abilityModifierBonuses: abilityModifierBonuses,

      damageBonuses: damageBonuses,

      criticalDamageBonuses: criticalDamageBonuses,

      healingBonuses: healingBonuses,

      rollDicePools: rollDicePools,

      rollAbilityModifierMultipliers: rollAbilityModifierMultipliers,

      rollFlatBonus: (map['rollFlatBonus'] as num?)?.toInt() ?? 0,
      // =======================================================================
      // CARGAS
      // =======================================================================
      hasCharges: hasCharges,

      maxCharges: maxCharges,

      currentCharges: currentCharges,

      rechargeDescription: map['rechargeDescription']?.toString() ?? '',

      notes: map['notes']?.toString() ?? '',
    );

    /*
     * Corrige posibles datos inconsistentes:
     *
     * - 6/3 cargas → 3/3
     * - -1 cargas → 0
     * - hasCharges false → 0/0
     */
    passive.normalizeCharges();

    return passive;
  }
}
