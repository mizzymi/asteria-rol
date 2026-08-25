import 'package:rol/models/character_effect.dart';

import 'formulas/formula_bonus.dart';
import 'formulas/character_formula.dart';
import 'passive_resource_modifier.dart';
import 'healing_bonus.dart';
import 'skill.dart';
import 'damage_bonus.dart';
import 'critical_damage_bonus.dart';
import 'dice_pool.dart';

enum PassiveTriggerMode { once, whileCondition }

enum PassiveSourceType { race, classFeature, feat, item, background, custom }

enum PassiveTriggerEvent {
  healthChanged,
  resourceChanged,
  chargeChanged,
  counterChanged,

  damageReceived,
  damageDealt,

  healingReceived,
  healingDealt,

  criticalHit,
  enemyKilled,

  turnStarted,
  turnEnded,
  roundStarted,
  roundEnded,

  manual,
  custom,
}

enum PassiveTriggerActionType {
  addResource,
  subtractResource,
  setResource,
  addCharge,
  subtractCharge,
  applyEffect,
  removeEffect,
  dealDamage,
  heal,
  incrementCounter,
  setCounter,
}

class PassiveTrigger {
  String id;

  PassiveTriggerEvent event;

  CharacterFormula? condition;

  PassiveTriggerActionType actionType;

  String? targetId;

  CharacterFormula? valueFormula;

  String? customEvent;

  PassiveTriggerMode mode;

  PassiveTrigger({
    required this.id,
    required this.event,
    required this.actionType,

    this.mode = PassiveTriggerMode.once,

    this.condition,
    this.targetId,
    this.valueFormula,
    this.customEvent,
  });

  bool get hasCondition {
    return condition != null &&
        condition!.expression.trim().isNotEmpty &&
        condition!.expression.trim() != '0';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event': event.name,
      'condition': condition?.toMap(),
      'actionType': actionType.name,
      'targetId': targetId,
      'valueFormula': valueFormula?.toMap(),
      'customEvent': customEvent,
      'mode': mode.name,
    };
  }

  factory PassiveTrigger.fromMap(Map<dynamic, dynamic> map) {
    final rawCondition = map['condition'];
    final rawValueFormula = map['valueFormula'];

    return PassiveTrigger(
      id: map['id']?.toString() ?? '',

      event: PassiveTriggerEvent.values.firstWhere(
        (value) => value.name == map['event']?.toString(),
        orElse: () => PassiveTriggerEvent.custom,
      ),

      actionType: PassiveTriggerActionType.values.firstWhere(
        (value) => value.name == map['actionType']?.toString(),
        orElse: () => PassiveTriggerActionType.incrementCounter,
      ),

      mode: PassiveTriggerMode.values.firstWhere(
        (value) => value.name == map['mode']?.toString(),
        orElse: () => PassiveTriggerMode.once,
      ),

      condition: rawCondition is Map
          ? CharacterFormula.fromMap(Map<dynamic, dynamic>.from(rawCondition))
          : null,

      targetId: map['targetId']?.toString(),

      valueFormula: rawValueFormula is Map
          ? CharacterFormula.fromMap(
              Map<dynamic, dynamic>.from(rawValueFormula),
            )
          : null,

      customEvent: map['customEvent']?.toString(),
    );
  }
}

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

  FormulaBonus armorClassBonus;
  FormulaBonus initiativeBonus;
  FormulaBonus speedBonus;
  FormulaBonus maxHealthBonus;
  FormulaBonus attackBonus;

  Map<AbilityType, FormulaBonus> abilityModifierBonuses;

  Map<AbilityType, FormulaBonus> abilityScoreBonuses;

  Map<DndSkill, FormulaBonus> skillBonuses;

  Map<AbilityType, FormulaBonus> savingThrowBonuses;

  List<DamageBonus> damageBonuses;

  List<CriticalDamageBonus> criticalDamageBonuses;

  List<HealingBonus> healingBonuses;

  List<PassiveResourceModifier> resourceModifiers;

  List<PassiveTrigger> triggers;

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

  List<CharacterEffect> linkedEffects;

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

  bool unlimitedCharges;

  /// Texto libre:
  /// "Descanso largo", "Descanso corto", "Al amanecer", etc.
  String rechargeDescription;

  String notes;

  /// Rango crítico proporcionado por esta pasiva.
  ///
  /// 20 significa que no amplía el rango.
  int criticalMinimumNaturalRoll;

  CharacterPassive({
    required this.id,
    required this.name,
    this.description = '',
    this.sourceType = PassiveSourceType.custom,
    this.enabled = true,
    FormulaBonus? armorClassBonus,
    FormulaBonus? initiativeBonus,
    FormulaBonus? speedBonus,
    FormulaBonus? maxHealthBonus,
    FormulaBonus? attackBonus,
    Map<AbilityType, FormulaBonus>? abilityModifierBonuses,
    Map<AbilityType, FormulaBonus>? abilityScoreBonuses,
    Map<DndSkill, FormulaBonus>? skillBonuses,
    Map<AbilityType, FormulaBonus>? savingThrowBonuses,
    List<DamageBonus>? damageBonuses,
    List<HealingBonus>? healingBonuses,
    List<CriticalDamageBonus>? criticalDamageBonuses,
    List<PassiveResourceModifier>? resourceModifiers,
    List<PassiveTrigger>? triggers,
    List<DicePool>? rollDicePools,
    List<CharacterEffect>? linkedEffects,
    Map<AbilityType, int>? rollAbilityModifierMultipliers,
    this.rollFlatBonus = 0,

    // =======================================================================
    // CARGAS
    // =======================================================================
    this.hasCharges = false,
    this.maxCharges = 0,
    this.currentCharges = 0,
    this.unlimitedCharges = false,
    this.rechargeDescription = '',

    this.notes = '',
    this.criticalMinimumNaturalRoll = 20,
  }) : armorClassBonus = armorClassBonus ?? FormulaBonus(),
       initiativeBonus = initiativeBonus ?? FormulaBonus(),
       speedBonus = speedBonus ?? FormulaBonus(),
       maxHealthBonus = maxHealthBonus ?? FormulaBonus(),
       attackBonus = attackBonus ?? FormulaBonus(),
       skillBonuses = Map<DndSkill, FormulaBonus>.from(skillBonuses ?? {}),

       abilityModifierBonuses = Map<AbilityType, FormulaBonus>.from(
         abilityModifierBonuses ?? {},
       ),

       abilityScoreBonuses = Map<AbilityType, FormulaBonus>.from(
         abilityScoreBonuses ?? {},
       ),

       savingThrowBonuses = Map<AbilityType, FormulaBonus>.from(
         savingThrowBonuses ?? {},
       ),
       damageBonuses = List<DamageBonus>.from(damageBonuses ?? []),
       criticalDamageBonuses = List<CriticalDamageBonus>.from(
         criticalDamageBonuses ?? [],
       ),
       healingBonuses = List<HealingBonus>.from(healingBonuses ?? []),
       resourceModifiers = List<PassiveResourceModifier>.from(
         resourceModifiers ?? [],
       ),
       triggers = triggers ?? [],
       rollDicePools = List<DicePool>.from(rollDicePools ?? []),
       linkedEffects = List<CharacterEffect>.from(linkedEffects ?? []),
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

  bool get hasLinkedEffects {
    return linkedEffects.isNotEmpty;
  }

  bool get hasUnlimitedCharges {
    return hasCharges && unlimitedCharges;
  }

  // ===========================================================================
  // EFECTOS MECÁNICOS
  // ===========================================================================

  bool get hasMechanicalEffects {
    return armorClassBonus.hasValue ||
        initiativeBonus.hasValue ||
        speedBonus.hasValue ||
        maxHealthBonus.hasValue ||
        attackBonus.hasValue ||
        abilityModifierBonuses.values.any((bonus) => bonus.hasValue) ||
        abilityScoreBonuses.values.any((bonus) => bonus.hasValue) ||
        skillBonuses.values.any((bonus) => bonus.hasValue) ||
        savingThrowBonuses.values.any((bonus) => bonus.hasValue) ||
        damageBonuses.any((damage) => damage.hasDamage) ||
        criticalDamageBonuses.any((damage) => damage.canTrigger) ||
        healingBonuses.any((bonus) => bonus.hasHealing) ||
        resourceModifiers.isNotEmpty ||
        hasRoll;
  }

  // ===========================================================================
  // CARGAS
  // ===========================================================================

  bool get usesCharges {
    return hasCharges;
  }

  bool get hasAvailableCharges {
    return !hasCharges || currentCharges > 0;
  }

  bool get chargesEmpty {
    return hasCharges && currentCharges <= 0;
  }

  bool get chargesFull {
    if (!hasCharges || unlimitedCharges) {
      return false;
    }

    return currentCharges >= maxCharges;
  }

  String get chargesText {
    if (!hasCharges) {
      return '';
    }

    if (unlimitedCharges) {
      return '$currentCharges';
    }

    return '$currentCharges/$maxCharges';
  }

  void useCharge() {
    if (!hasCharges) {
      return;
    }

    if (currentCharges <= 0) {
      return;
    }

    currentCharges--;
  }

  void restoreCharge() {
    if (!hasCharges) {
      return;
    }

    if (unlimitedCharges) {
      currentCharges++;
      return;
    }

    if (currentCharges < maxCharges) {
      currentCharges++;
    }
  }

  void restoreCharges() {
    if (!hasCharges) {
      return;
    }

    /*
   * Una pasiva sin máximo no tiene un valor
   * concreto al que pueda "rellenarse".
   */
    if (unlimitedCharges) {
      return;
    }

    currentCharges = maxCharges;
  }

  void normalizeCharges() {
    if (!hasCharges) {
      maxCharges = 0;
      currentCharges = 0;
      unlimitedCharges = false;

      return;
    }

    if (currentCharges < 0) {
      currentCharges = 0;
    }

    /*
   * Las cargas ilimitadas no utilizan máximo.
   */
    if (unlimitedCharges) {
      maxCharges = 0;
      return;
    }

    if (maxCharges < 1) {
      maxCharges = 1;
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

      'armorClassBonus': armorClassBonus.toMap(),
      'initiativeBonus': initiativeBonus.toMap(),
      'speedBonus': speedBonus.toMap(),
      'maxHealthBonus': maxHealthBonus.toMap(),
      'attackBonus': attackBonus.toMap(),

      'abilityModifierBonuses': {
        for (final entry in abilityModifierBonuses.entries)
          entry.key.name: entry.value.toMap(),
      },

      'abilityScoreBonuses': {
        for (final entry in abilityScoreBonuses.entries)
          entry.key.name: entry.value.toMap(),
      },

      'skillBonuses': {
        for (final entry in skillBonuses.entries)
          entry.key.name: entry.value.toMap(),
      },

      'savingThrowBonuses': {
        for (final entry in savingThrowBonuses.entries)
          entry.key.name: entry.value.toMap(),
      },

      'damageBonuses': damageBonuses.map((damage) => damage.toMap()).toList(),

      'criticalDamageBonuses': criticalDamageBonuses
          .map((damage) => damage.toMap())
          .toList(),

      'healingBonuses': healingBonuses.map((bonus) => bonus.toMap()).toList(),

      'resourceModifiers': resourceModifiers
          .map((modifier) => modifier.toMap())
          .toList(),

      'triggers': triggers.map((trigger) => trigger.toMap()).toList(),

      'rollDicePools': rollDicePools.map((pool) => pool.toMap()).toList(),

      'linkedEffects': linkedEffects.map((effect) => effect.toMap()).toList(),

      'rollAbilityModifierMultipliers': {
        for (final entry in rollAbilityModifierMultipliers.entries)
          entry.key.name: entry.value,
      },

      'rollFlatBonus': rollFlatBonus,

      // =======================================================================
      // CARGAS
      // =======================================================================
      'hasCharges': hasCharges,
      'unlimitedCharges': unlimitedCharges,
      'maxCharges': maxCharges,
      'currentCharges': currentCharges,
      'rechargeDescription': rechargeDescription,

      'notes': notes,

      'criticalMinimumNaturalRoll': criticalMinimumNaturalRoll,
    };
  }

  // ===========================================================================
  // FROM MAP
  // ===========================================================================

  factory CharacterPassive.fromMap(Map<dynamic, dynamic> map) {
    FormulaBonus readFormulaBonus(dynamic raw) {
      if (raw is Map) {
        return FormulaBonus.fromMap(Map<dynamic, dynamic>.from(raw));
      }

      if (raw is num) {
        return FormulaBonus(flatValue: raw.toInt());
      }

      return FormulaBonus();
    }

    final triggers = <PassiveTrigger>[];

    final rawTriggers = map['triggers'];

    if (rawTriggers is List) {
      for (final raw in rawTriggers) {
        if (raw is! Map) {
          continue;
        }

        triggers.add(PassiveTrigger.fromMap(Map<dynamic, dynamic>.from(raw)));
      }
    }

    // =========================================================================
    // SKILLS
    // =========================================================================

    final skillBonuses = <DndSkill, FormulaBonus>{};

    final rawSkills = map['skillBonuses'];

    if (rawSkills is Map) {
      final skillMap = Map<dynamic, dynamic>.from(rawSkills);

      for (final skill in DndSkill.values) {
        final bonus = readFormulaBonus(skillMap[skill.name]);

        if (bonus.hasValue) {
          skillBonuses[skill] = bonus;
        }
      }
    }

    // =========================================================================
    // ATRIBUTOS
    // =========================================================================

    final abilityModifierBonuses = <AbilityType, FormulaBonus>{};

    final rawAbilityBonuses = map['abilityModifierBonuses'];

    if (rawAbilityBonuses is Map) {
      final bonusMap = Map<dynamic, dynamic>.from(rawAbilityBonuses);

      for (final ability in AbilityType.values) {
        final bonus = readFormulaBonus(bonusMap[ability.name]);

        if (bonus.hasValue) {
          abilityModifierBonuses[ability] = bonus;
        }
      }
    }

    final abilityScoreBonuses = <AbilityType, FormulaBonus>{};

    final rawAbilityScoreBonuses = map['abilityScoreBonuses'];

    if (rawAbilityScoreBonuses is Map) {
      final bonusMap = Map<dynamic, dynamic>.from(rawAbilityScoreBonuses);

      for (final ability in AbilityType.values) {
        final rawBonus = bonusMap[ability.name];

        if (rawBonus is! Map) {
          continue;
        }

        try {
          final bonus = FormulaBonus.fromMap(
            Map<dynamic, dynamic>.from(rawBonus),
          );

          if (bonus.hasValue) {
            abilityScoreBonuses[ability] = bonus;
          }
        } catch (_) {
          continue;
        }
      }
    }

    // =========================================================================
    // SALVACIONES
    // =========================================================================

    final savingThrowBonuses = <AbilityType, FormulaBonus>{};

    final rawSaves = map['savingThrowBonuses'];

    if (rawSaves is Map) {
      final saveMap = Map<dynamic, dynamic>.from(rawSaves);

      for (final ability in AbilityType.values) {
        final bonus = readFormulaBonus(saveMap[ability.name]);

        if (bonus.hasValue) {
          savingThrowBonuses[ability] = bonus;
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
    // EFECTOS VINCULADOS
    // =========================================================================

    final linkedEffects = <CharacterEffect>[];

    final rawLinkedEffects = map['linkedEffects'];

    if (rawLinkedEffects is List) {
      for (final rawEffect in rawLinkedEffects) {
        if (rawEffect is! Map) {
          continue;
        }

        try {
          linkedEffects.add(
            CharacterEffect.fromMap(Map<dynamic, dynamic>.from(rawEffect)),
          );
        } catch (_) {
          continue;
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

    final unlimitedCharges = map['unlimitedCharges'] as bool? ?? false;

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

    final resourceModifiers = <PassiveResourceModifier>[];

    final rawResourceModifiers = map['resourceModifiers'];

    if (rawResourceModifiers is List) {
      for (final rawModifier in rawResourceModifiers) {
        if (rawModifier is! Map) {
          continue;
        }

        try {
          resourceModifiers.add(
            PassiveResourceModifier.fromMap(
              Map<dynamic, dynamic>.from(rawModifier),
            ),
          );
        } catch (_) {
          continue;
        }
      }
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

      armorClassBonus: readFormulaBonus(map['armorClassBonus']),

      initiativeBonus: readFormulaBonus(map['initiativeBonus']),

      speedBonus: readFormulaBonus(map['speedBonus']),

      maxHealthBonus: readFormulaBonus(map['maxHealthBonus']),

      attackBonus: readFormulaBonus(map['attackBonus']),

      skillBonuses: skillBonuses,

      savingThrowBonuses: savingThrowBonuses,

      abilityModifierBonuses: abilityModifierBonuses,

      abilityScoreBonuses: abilityScoreBonuses,

      damageBonuses: damageBonuses,

      criticalDamageBonuses: criticalDamageBonuses,

      healingBonuses: healingBonuses,

      resourceModifiers: resourceModifiers,

      triggers: triggers,

      rollDicePools: rollDicePools,

      linkedEffects: linkedEffects,

      rollAbilityModifierMultipliers: rollAbilityModifierMultipliers,

      rollFlatBonus: (map['rollFlatBonus'] as num?)?.toInt() ?? 0,

      // =======================================================================
      // CARGAS
      // =======================================================================
      hasCharges: hasCharges,

      unlimitedCharges: hasCharges && unlimitedCharges,

      maxCharges: hasCharges && !unlimitedCharges ? maxCharges : 0,

      currentCharges: currentCharges,

      rechargeDescription: map['rechargeDescription']?.toString() ?? '',

      notes: map['notes']?.toString() ?? '',

      criticalMinimumNaturalRoll:
          (map['criticalMinimumNaturalRoll'] as num?)?.toInt() ?? 20,
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
