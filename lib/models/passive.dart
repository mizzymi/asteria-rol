import 'character_effect.dart';
import 'formulas/formula_bonus.dart';
import 'formulas/character_formula.dart';
import 'passive_resource_modifier.dart';
import 'healing_bonus.dart';
import 'skill.dart';
import 'damage_bonus.dart';
import 'critical_damage_bonus.dart';
import 'dice_pool.dart';

enum PassiveTriggerMode { once, whileCondition }

enum PassiveTriggerTarget {
  self,

  /// El objetivo actual de la acción que provocó el trigger.
  actionTarget,
}

enum TriggerSaveBehavior {
  none,

  /// Si supera la salvación, no ocurre nada.
  negate,
}

enum TriggerUsageLimit { unlimited, oncePerTurn, oncePerRound }

enum PassiveSourceType { race, classFeature, feat, item, background, custom }

enum PassiveTriggerEvent {
  healthChanged,
  resourceChanged,
  chargeChanged,
  counterChanged,

  damageReceived,
  damageDealt,
  healingDealt,
  healingReceived,

  effectApplied,
  effectReceived,

  attackHit,
  attackMiss,
  criticalHit,

  // ===========================================================================
  // MUERTE
  // ===========================================================================

  /// El propio personaje acaba de pasar de > 0 PG a 0 PG.
  characterDied,

  /// El personaje ha provocado la muerte de un objetivo externo.
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
  mitigateDamage,
  incrementCounter,
  setCounter,
}

class TriggerSavingThrow {
  final AbilityType ability;

  final int dc;

  final TriggerSaveBehavior behavior;

  const TriggerSavingThrow({
    required this.ability,
    required this.dc,
    this.behavior = TriggerSaveBehavior.negate,
  });

  Map<String, dynamic> toMap() {
    return {'ability': ability.name, 'dc': dc, 'behavior': behavior.name};
  }

  factory TriggerSavingThrow.fromMap(Map<dynamic, dynamic> map) {
    return TriggerSavingThrow(
      ability: AbilityType.values.firstWhere(
        (value) => value.name == map['ability']?.toString(),
        orElse: () => AbilityType.constitution,
      ),

      dc: (map['dc'] as num?)?.toInt() ?? 0,

      behavior: TriggerSaveBehavior.values.firstWhere(
        (value) => value.name == map['behavior']?.toString(),
        orElse: () => TriggerSaveBehavior.negate,
      ),
    );
  }
}

class PassiveTrigger {
  String id;

  PassiveTriggerEvent event;

  CharacterFormula? condition;

  PassiveTriggerMode mode;

  PassiveTriggerTarget target;

  TriggerUsageLimit usageLimit;

  TriggerSavingThrow? savingThrow;

  List<PassiveTriggerAction> actions;

  String? customEvent;

  PassiveTrigger({
    required this.id,
    required this.event,
    this.mode = PassiveTriggerMode.once,
    this.target = PassiveTriggerTarget.self,
    this.usageLimit = TriggerUsageLimit.unlimited,
    this.savingThrow,
    this.condition,
    List<PassiveTriggerAction>? actions,
    this.customEvent,
  }) : actions = List<PassiveTriggerAction>.from(actions ?? const []);

  bool get hasCondition {
    return condition != null &&
        condition!.expression.trim().isNotEmpty &&
        condition!.expression.trim() != '0';
  }

  bool get targetsSelf {
    return target == PassiveTriggerTarget.self;
  }

  bool get targetsActionTarget {
    return target == PassiveTriggerTarget.actionTarget;
  }

  bool get hasSavingThrow {
    return savingThrow != null && savingThrow!.dc > 0;
  }

  bool get isOncePerTurn {
    return usageLimit == TriggerUsageLimit.oncePerTurn;
  }

  bool get isOncePerRound {
    return usageLimit == TriggerUsageLimit.oncePerRound;
  }

  bool get hasUsageLimit {
    return usageLimit != TriggerUsageLimit.unlimited;
  }

  bool get isCustomEvent {
    return event == PassiveTriggerEvent.custom;
  }

  bool get hasValidCustomEvent {
    return !isCustomEvent || customEvent?.trim().isNotEmpty == true;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event': event.name,
      'condition': condition?.toMap(),
      'mode': mode.name,

      'target': target.name,

      'usageLimit': usageLimit.name,

      'savingThrow': savingThrow?.toMap(),

      'actions': actions.map((action) => action.toMap()).toList(),

      'customEvent': customEvent,
    };
  }

  factory PassiveTrigger.fromMap(Map<dynamic, dynamic> map) {
    final rawCondition = map['condition'];

    final rawSavingThrow = map['savingThrow'];

    final actions = <PassiveTriggerAction>[];

    // =========================================================================
    // FORMATO NUEVO
    // =========================================================================

    final rawActions = map['actions'];

    if (rawActions is List) {
      for (final rawAction in rawActions) {
        if (rawAction is! Map) {
          continue;
        }

        try {
          actions.add(
            PassiveTriggerAction.fromMap(Map<dynamic, dynamic>.from(rawAction)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    // =========================================================================
    // COMPATIBILIDAD CON FORMATO ANTIGUO
    // =========================================================================

    if (actions.isEmpty && map['actionType'] != null) {
      final rawValueFormula = map['valueFormula'];

      actions.add(
        PassiveTriggerAction(
          type: PassiveTriggerActionType.values.firstWhere(
            (value) => value.name == map['actionType']?.toString(),
            orElse: () => PassiveTriggerActionType.incrementCounter,
          ),

          targetId: map['targetId']?.toString(),

          valueFormula: rawValueFormula is Map
              ? CharacterFormula.fromMap(
                  Map<dynamic, dynamic>.from(rawValueFormula),
                )
              : null,
        ),
      );
    }

    // =========================================================================
    // CREAR
    // =========================================================================

    return PassiveTrigger(
      id: map['id']?.toString() ?? '',

      event: PassiveTriggerEvent.values.firstWhere(
        (value) => value.name == map['event']?.toString(),
        orElse: () => PassiveTriggerEvent.custom,
      ),

      mode: PassiveTriggerMode.values.firstWhere(
        (value) => value.name == map['mode']?.toString(),
        orElse: () => PassiveTriggerMode.once,
      ),

      target: PassiveTriggerTarget.values.firstWhere(
        (value) => value.name == map['target']?.toString(),
        orElse: () => PassiveTriggerTarget.self,
      ),

      usageLimit: TriggerUsageLimit.values.firstWhere(
        (value) => value.name == map['usageLimit']?.toString(),
        orElse: () => TriggerUsageLimit.unlimited,
      ),

      savingThrow: rawSavingThrow is Map
          ? TriggerSavingThrow.fromMap(
              Map<dynamic, dynamic>.from(rawSavingThrow),
            )
          : null,

      condition: rawCondition is Map
          ? CharacterFormula.fromMap(Map<dynamic, dynamic>.from(rawCondition))
          : null,

      actions: actions,

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

  /// Ruta local de la imagen representativa de la pasiva.
  String? imagePath;

  /// Encuadre visual de la imagen (-1..1). No recorta el archivo original.
  double imageAlignmentX;
  double imageAlignmentY;
  String? folderId;
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

  /// Si true, los críticos realizados mientras esta pasiva
  /// esté activa se consideran críticos potenciados.
  bool empoweredCritical;

  CharacterPassive({
    required this.id,
    required this.name,
    this.description = '',
    this.imagePath,
    this.imageAlignmentX = 0,
    this.imageAlignmentY = 0,
    this.folderId,
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
    this.empoweredCritical = false,
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

  bool get hasAutomaticLinkedEffectTriggers {
    return triggers.any(
      (trigger) => trigger.actions.any(
        (action) =>
            action.type == PassiveTriggerActionType.applyEffect ||
            action.type == PassiveTriggerActionType.removeEffect,
      ),
    );
  }

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
        triggers.isNotEmpty ||
        linkedEffects.isNotEmpty ||
        criticalMinimumNaturalRoll < 20 ||
        empoweredCritical ||
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
      'imagePath': imagePath,
      'imageAlignmentX': imageAlignmentX,
      'imageAlignmentY': imageAlignmentY,
      'folderId': folderId,
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
      'empoweredCritical': empoweredCritical,
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

      imagePath: map['imagePath']?.toString(),

      imageAlignmentX: (map['imageAlignmentX'] as num?)?.toDouble() ?? 0,
      imageAlignmentY: (map['imageAlignmentY'] as num?)?.toDouble() ?? 0,

      folderId: map['folderId']?.toString(),

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

      empoweredCritical: map['empoweredCritical'] as bool? ?? false,
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

class PassiveTriggerAction {
  PassiveTriggerActionType type;

  /// ID específico usado por la acción.
  ///
  /// Ejemplos:
  /// - recurso -> CharacterResource.id
  /// - contador -> CharacterCounter.id
  /// - efecto -> CharacterEffect.id dentro de linkedEffects
  String? targetId;

  /// Valor numérico de la acción.
  ///
  /// Ejemplos:
  /// - daño
  /// - curación
  /// - recurso
  /// - cargas
  /// - contador
  CharacterFormula? valueFormula;

  /// Dados propios de esta acción.
  ///
  /// Principalmente para daño/curación disparados por triggers.
  List<DicePool> dicePools;

  /// Tipo de daño cuando corresponda.
  String damageType;

  PassiveTriggerAction({
    required this.type,
    this.targetId,
    this.valueFormula,
    List<DicePool>? dicePools,
    this.damageType = '',
  }) : dicePools = List<DicePool>.from(dicePools ?? const []);

  // ===========================================================================
  // ESTADO
  // ===========================================================================

  bool get hasDice {
    return dicePools.any((pool) => pool.count > 0);
  }

  bool get hasFormula {
    return valueFormula != null &&
        valueFormula!.expression.trim().isNotEmpty &&
        valueFormula!.expression.trim() != '0';
  }

  bool get hasDamageType {
    return damageType.trim().isNotEmpty;
  }

  bool get requiresTargetId {
    switch (type) {
      case PassiveTriggerActionType.addResource:
      case PassiveTriggerActionType.subtractResource:
      case PassiveTriggerActionType.setResource:
      case PassiveTriggerActionType.applyEffect:
      case PassiveTriggerActionType.removeEffect:
      case PassiveTriggerActionType.incrementCounter:
      case PassiveTriggerActionType.setCounter:
        return true;

      case PassiveTriggerActionType.addCharge:
      case PassiveTriggerActionType.subtractCharge:
      case PassiveTriggerActionType.dealDamage:
      case PassiveTriggerActionType.heal:
      case PassiveTriggerActionType.mitigateDamage:
        return false;
    }
  }

  bool get requiresNumericValue {
    switch (type) {
      case PassiveTriggerActionType.addResource:
      case PassiveTriggerActionType.subtractResource:
      case PassiveTriggerActionType.setResource:
      case PassiveTriggerActionType.addCharge:
      case PassiveTriggerActionType.subtractCharge:
      case PassiveTriggerActionType.incrementCounter:
      case PassiveTriggerActionType.setCounter:
        return true;

      case PassiveTriggerActionType.dealDamage:
      case PassiveTriggerActionType.heal:
      case PassiveTriggerActionType.mitigateDamage:
        return !hasDice;

      case PassiveTriggerActionType.applyEffect:
      case PassiveTriggerActionType.removeEffect:
        return false;
    }
  }

  bool get hasValidTargetId {
    return !requiresTargetId || targetId?.trim().isNotEmpty == true;
  }

  String? get resourceId {
    switch (type) {
      case PassiveTriggerActionType.addResource:
      case PassiveTriggerActionType.subtractResource:
      case PassiveTriggerActionType.setResource:
        return targetId;

      default:
        return null;
    }
  }

  String? get counterId {
    switch (type) {
      case PassiveTriggerActionType.incrementCounter:
      case PassiveTriggerActionType.setCounter:
        return targetId;

      default:
        return null;
    }
  }

  String? get effectId {
    switch (type) {
      case PassiveTriggerActionType.applyEffect:
      case PassiveTriggerActionType.removeEffect:
        return targetId;

      default:
        return null;
    }
  }

  String get diceNotation {
    return dicePools
        .where((pool) => pool.count > 0)
        .map((pool) => pool.notation)
        .join(' + ');
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'targetId': targetId,
      'valueFormula': valueFormula?.toMap(),

      'dicePools': dicePools.map((pool) => pool.toMap()).toList(),

      'damageType': damageType,
    };
  }

  factory PassiveTriggerAction.fromMap(Map<dynamic, dynamic> map) {
    final rawFormula = map['valueFormula'];

    final dicePools = <DicePool>[];

    final rawDicePools = map['dicePools'];

    if (rawDicePools is List) {
      for (final rawPool in rawDicePools) {
        if (rawPool is! Map) {
          continue;
        }

        try {
          dicePools.add(DicePool.fromMap(Map<dynamic, dynamic>.from(rawPool)));
        } catch (_) {
          continue;
        }
      }
    }

    return PassiveTriggerAction(
      type: PassiveTriggerActionType.values.firstWhere(
        (value) => value.name == map['type']?.toString(),
        orElse: () => PassiveTriggerActionType.incrementCounter,
      ),

      targetId: map['targetId']?.toString(),

      valueFormula: rawFormula is Map
          ? CharacterFormula.fromMap(Map<dynamic, dynamic>.from(rawFormula))
          : null,

      dicePools: dicePools,

      damageType: map['damageType']?.toString() ?? '',
    );
  }
}
