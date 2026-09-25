import 'formulas/character_formula.dart';
import 'passive.dart';
import 'healing_bonus.dart';
import 'skill.dart';
import 'damage_bonus.dart';
import 'critical_damage_bonus.dart';

enum CharacterEffectType { buff, debuff, condition, neutral }

extension CharacterEffectTypeData on CharacterEffectType {
  String get label {
    switch (this) {
      case CharacterEffectType.buff:
        return 'Beneficio';

      case CharacterEffectType.debuff:
        return 'Perjuicio';

      case CharacterEffectType.condition:
        return 'Estado';

      case CharacterEffectType.neutral:
        return 'Neutral';
    }
  }
}

enum CharacterEffectDurationType { permanent, turns, rounds, minutes, custom }

extension CharacterEffectDurationTypeData on CharacterEffectDurationType {
  String get label {
    switch (this) {
      case CharacterEffectDurationType.permanent:
        return 'Permanente';

      case CharacterEffectDurationType.turns:
        return 'Turnos';

      case CharacterEffectDurationType.rounds:
        return 'Rondas';

      case CharacterEffectDurationType.minutes:
        return 'Minutos';

      case CharacterEffectDurationType.custom:
        return 'Personalizada';
    }
  }
}

class CharacterEffect {
  String id;

  String name;

  String description;

  bool enabled;

  CharacterEffectType type;

  List<DamageBonus> damageBonuses;

  List<CriticalDamageBonus> criticalDamageBonuses;

  List<HealingBonus> healingBonuses;

  // ===========================================================================
  // DURACIÓN
  // ===========================================================================

  CharacterEffectDurationType durationType;

  /// Duración inicial/configurada.
  int maxDuration;

  /// Duración restante.
  int currentDuration;

  /// Texto libre:
  ///
  /// "Hasta recibir daño"
  /// "Hasta terminar el combate"
  /// "Hasta descansar"
  String durationNote;

  int minuteRoundProgress;

  // ===========================================================================
  // BONIFICACIONES
  // ===========================================================================

  int armorClassBonus;

  int initiativeBonus;

  int speedBonus;

  int maxHealthBonus;

  int attackBonus;

  int criticalMinimumNaturalRoll;

  /// Si true, mientras este efecto esté activo
  /// los críticos utilizan la regla potenciada.
  bool empoweredCritical;

  int empoweredCriticalMultiplier;

  /// Fórmula del crítico potenciado. Admite TIRADA, MAX, MOD, TURNO, CARGAS, RECURSO() y CONTADOR().
  String empoweredCriticalFormula;

  Map<AbilityType, int> abilityModifierBonuses;

  Map<DndSkill, int> skillBonuses;

  Map<AbilityType, int> savingThrowBonuses;

  // ===========================================================================
  // OTROS
  // ===========================================================================
  final List<CharacterEffectTrigger> triggers;

  String notes;

  CharacterEffect({
    required this.id,
    required this.name,
    this.description = '',
    this.enabled = true,
    this.type = CharacterEffectType.neutral,

    this.durationType = CharacterEffectDurationType.permanent,

    this.maxDuration = 0,
    this.currentDuration = 0,
    this.durationNote = '',
    this.minuteRoundProgress = 0,
    this.armorClassBonus = 0,
    this.initiativeBonus = 0,
    this.speedBonus = 0,
    this.maxHealthBonus = 0,
    this.attackBonus = 0,
    this.criticalMinimumNaturalRoll = 20,
    this.empoweredCritical = false,
    this.empoweredCriticalMultiplier = 2,
    this.empoweredCriticalFormula = '(MAX + MOD) * 2',
    Map<AbilityType, int>? abilityModifierBonuses,
    Map<DndSkill, int>? skillBonuses,
    Map<AbilityType, int>? savingThrowBonuses,

    List<DamageBonus>? damageBonuses,

    List<CriticalDamageBonus>? criticalDamageBonuses,

    List<HealingBonus>? healingBonuses,

    this.notes = '',

    List<CharacterEffectTrigger>? triggers,
  }) : triggers = triggers ?? [],
       abilityModifierBonuses = abilityModifierBonuses ?? {},
       skillBonuses = skillBonuses ?? {},
       savingThrowBonuses = savingThrowBonuses ?? {},
       damageBonuses = damageBonuses ?? [],
       healingBonuses = healingBonuses ?? [],
       criticalDamageBonuses = criticalDamageBonuses ?? [];

  bool get advancesWithTurn {
    return durationType == CharacterEffectDurationType.turns;
  }

  bool get advancesWithRound {
    return durationType == CharacterEffectDurationType.rounds ||
        durationType == CharacterEffectDurationType.minutes;
  }

  bool get expiresWithTurn {
    return durationType == CharacterEffectDurationType.turns;
  }

  bool get expiresWithRound {
    return durationType == CharacterEffectDurationType.rounds ||
        durationType == CharacterEffectDurationType.minutes;
  }

  bool get isExpired {
    if (!hasDuration) {
      return false;
    }

    return currentDuration <= 0;
  }

  bool get expired {
    return isExpired;
  }

  void advanceTurn() {
    if (!enabled) {
      return;
    }

    if (durationType != CharacterEffectDurationType.turns) {
      return;
    }

    if (currentDuration <= 0) {
      enabled = false;
      currentDuration = 0;

      return;
    }

    currentDuration--;

    if (currentDuration <= 0) {
      currentDuration = 0;
      enabled = false;
    }
  }

  void advanceRound() {
    if (!enabled) {
      return;
    }

    switch (durationType) {
      // =========================================================================
      // RONDAS
      // =========================================================================

      case CharacterEffectDurationType.rounds:
        if (currentDuration <= 0) {
          enabled = false;
          currentDuration = 0;

          return;
        }

        currentDuration--;

        if (currentDuration <= 0) {
          currentDuration = 0;
          enabled = false;
        }

        return;

      // =========================================================================
      // MINUTOS
      //
      // D&D:
      // 1 ronda = 6 segundos
      // 10 rondas = 1 minuto
      // =========================================================================

      case CharacterEffectDurationType.minutes:
        if (currentDuration <= 0) {
          enabled = false;
          currentDuration = 0;
          minuteRoundProgress = 0;

          return;
        }

        minuteRoundProgress++;

        // Todavía no ha transcurrido un minuto completo.
        if (minuteRoundProgress < 10) {
          return;
        }

        // Han transcurrido 10 rondas = 1 minuto.
        minuteRoundProgress = 0;

        currentDuration--;

        if (currentDuration <= 0) {
          currentDuration = 0;
          enabled = false;
        }

        return;

      // =========================================================================
      // NO AVANZAN CON RONDA
      // =========================================================================

      case CharacterEffectDurationType.permanent:
      case CharacterEffectDurationType.turns:
      case CharacterEffectDurationType.custom:
        return;
    }
  }

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  bool get hasMechanicalEffects {
    return armorClassBonus != 0 ||
        initiativeBonus != 0 ||
        speedBonus != 0 ||
        maxHealthBonus != 0 ||
        attackBonus != 0 ||
        criticalMinimumNaturalRoll < 20 ||
        empoweredCritical ||
        abilityModifierBonuses.values.any((value) => value != 0) ||
        skillBonuses.values.any((value) => value != 0) ||
        savingThrowBonuses.values.any((value) => value != 0) ||
        damageBonuses.any((damage) => damage.hasDamage) ||
        criticalDamageBonuses.any((damage) => damage.canTrigger) ||
        healingBonuses.any((bonus) => bonus.hasHealing) ||
        triggers.any((trigger) => trigger.hasMechanicalEffects);
  }

  bool get hasDuration {
    switch (durationType) {
      case CharacterEffectDurationType.turns:
      case CharacterEffectDurationType.rounds:
      case CharacterEffectDurationType.minutes:
        return true;

      case CharacterEffectDurationType.permanent:
      case CharacterEffectDurationType.custom:
        return false;
    }
  }

  String get durationText {
    switch (durationType) {
      case CharacterEffectDurationType.permanent:
        return 'Permanente';

      case CharacterEffectDurationType.turns:
        return currentDuration == 1 ? '1 turno' : '$currentDuration turnos';

      case CharacterEffectDurationType.rounds:
        return currentDuration == 1 ? '1 ronda' : '$currentDuration rondas';

      case CharacterEffectDurationType.minutes:
        if (minuteRoundProgress <= 0) {
          return currentDuration == 1 ? '1 minuto' : '$currentDuration minutos';
        }

        final roundsUntilNextMinute = 10 - minuteRoundProgress;

        return '${currentDuration == 1 ? '1 minuto' : '$currentDuration minutos'}'
            ' · $roundsUntilNextMinute '
            '${roundsUntilNextMinute == 1 ? 'ronda' : 'rondas'}';

      case CharacterEffectDurationType.custom:
        final note = durationNote.trim();

        return note.isNotEmpty ? note : 'Duración personalizada';
    }
  }

  // ===========================================================================
  // DURACIÓN
  // ===========================================================================

  void decreaseDuration() {
    if (!hasDuration) {
      return;
    }

    if (currentDuration > 0) {
      currentDuration--;
    }

    if (currentDuration <= 0) {
      currentDuration = 0;
      enabled = false;
    }

    minuteRoundProgress = 0;
  }

  void increaseDuration() {
    if (!hasDuration) {
      return;
    }

    currentDuration++;

    if (maxDuration > 0 && currentDuration > maxDuration) {
      currentDuration = maxDuration;
    }

    if (currentDuration > 0) {
      enabled = true;
    }

    minuteRoundProgress = 0;
  }

  void resetDuration() {
    if (!hasDuration) {
      return;
    }

    currentDuration = maxDuration;
    minuteRoundProgress = 0;
  }

  void normalizeDuration() {
    // ===========================================================================
    // SIN CONTADOR MECÁNICO
    // ===========================================================================

    if (durationType == CharacterEffectDurationType.permanent ||
        durationType == CharacterEffectDurationType.custom) {
      maxDuration = 0;
      currentDuration = 0;
      minuteRoundProgress = 0;

      return;
    }

    // ===========================================================================
    // VALORES NEGATIVOS
    // ===========================================================================

    if (maxDuration < 0) {
      maxDuration = 0;
    }

    if (currentDuration < 0) {
      currentDuration = 0;
    }

    // ===========================================================================
    // MÁXIMO
    // ===========================================================================

    if (maxDuration > 0 && currentDuration > maxDuration) {
      currentDuration = maxDuration;
    }

    // ===========================================================================
    // MINUTOS
    // ===========================================================================

    if (durationType == CharacterEffectDurationType.minutes) {
      if (minuteRoundProgress < 0) {
        minuteRoundProgress = 0;
      }

      if (minuteRoundProgress > 9) {
        minuteRoundProgress %= 10;
      }
    } else {
      minuteRoundProgress = 0;
    }
  }

  CharacterEffect copyWith({
    String? id,
    String? name,
    String? description,
    bool? enabled,
    CharacterEffectType? type,
    CharacterEffectDurationType? durationType,
    int? maxDuration,
    int? currentDuration,
    int? minuteRoundProgress,
    String? durationNote,
    int? armorClassBonus,
    int? initiativeBonus,
    int? speedBonus,
    int? maxHealthBonus,
    int? attackBonus,
    int? criticalMinimumNaturalRoll,
    bool? empoweredCritical,
    int? empoweredCriticalMultiplier,
    String? empoweredCriticalFormula,
    Map<AbilityType, int>? abilityModifierBonuses,
    Map<DndSkill, int>? skillBonuses,
    Map<AbilityType, int>? savingThrowBonuses,
    List<DamageBonus>? damageBonuses,
    List<CriticalDamageBonus>? criticalDamageBonuses,
    List<HealingBonus>? healingBonuses,
    List<CharacterEffectTrigger>? triggers,
    String? notes,
  }) {
    return CharacterEffect(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      type: type ?? this.type,

      durationType: durationType ?? this.durationType,
      maxDuration: maxDuration ?? this.maxDuration,
      currentDuration: currentDuration ?? this.currentDuration,
      durationNote: durationNote ?? this.durationNote,
      minuteRoundProgress: minuteRoundProgress ?? this.minuteRoundProgress,
      armorClassBonus: armorClassBonus ?? this.armorClassBonus,
      initiativeBonus: initiativeBonus ?? this.initiativeBonus,
      speedBonus: speedBonus ?? this.speedBonus,
      maxHealthBonus: maxHealthBonus ?? this.maxHealthBonus,
      attackBonus: attackBonus ?? this.attackBonus,

      criticalMinimumNaturalRoll:
          criticalMinimumNaturalRoll ?? this.criticalMinimumNaturalRoll,

      empoweredCritical: empoweredCritical ?? this.empoweredCritical,
      empoweredCriticalMultiplier:
          empoweredCriticalMultiplier ?? this.empoweredCriticalMultiplier,
      empoweredCriticalFormula:
          empoweredCriticalFormula ?? this.empoweredCriticalFormula,

      abilityModifierBonuses:
          abilityModifierBonuses ??
          Map<AbilityType, int>.from(this.abilityModifierBonuses),

      skillBonuses: skillBonuses ?? Map<DndSkill, int>.from(this.skillBonuses),

      savingThrowBonuses:
          savingThrowBonuses ??
          Map<AbilityType, int>.from(this.savingThrowBonuses),

      damageBonuses:
          damageBonuses ??
          this.damageBonuses
              .map((bonus) => DamageBonus.fromMap(bonus.toMap()))
              .toList(),

      criticalDamageBonuses:
          criticalDamageBonuses ??
          this.criticalDamageBonuses
              .map((bonus) => CriticalDamageBonus.fromMap(bonus.toMap()))
              .toList(),

      healingBonuses:
          healingBonuses ??
          this.healingBonuses
              .map((bonus) => HealingBonus.fromMap(bonus.toMap()))
              .toList(),

      triggers:
          triggers ??
          this.triggers
              .map((trigger) => CharacterEffectTrigger.fromMap(trigger.toMap()))
              .toList(),

      notes: notes ?? this.notes,
    );
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'enabled': enabled,
      'type': type.name,

      'durationType': durationType.name,

      'maxDuration': maxDuration,

      'currentDuration': currentDuration,

      'durationNote': durationNote,

      'minuteRoundProgress': minuteRoundProgress,

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

      'criticalMinimumNaturalRoll': criticalMinimumNaturalRoll,

      'empoweredCritical': empoweredCritical,
      'empoweredCriticalMultiplier': empoweredCriticalMultiplier,
      'empoweredCriticalFormula': empoweredCriticalFormula,

      'criticalDamageBonuses': criticalDamageBonuses
          .map((damage) => damage.toMap())
          .toList(),

      'healingBonuses': healingBonuses.map((bonus) => bonus.toMap()).toList(),

      'triggers': triggers.map((trigger) => trigger.toMap()).toList(),

      'notes': notes,
    };
  }

  factory CharacterEffect.fromMap(Map<dynamic, dynamic> map) {
    final abilityModifierBonuses = <AbilityType, int>{};

    final rawAbilities = map['abilityModifierBonuses'];

    if (rawAbilities is Map) {
      final bonusMap = Map<dynamic, dynamic>.from(rawAbilities);

      for (final ability in AbilityType.values) {
        final value = (bonusMap[ability.name] as num?)?.toInt() ?? 0;

        if (value != 0) {
          abilityModifierBonuses[ability] = value;
        }
      }
    }

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

    final triggers = <CharacterEffectTrigger>[];

    final rawTriggers = map['triggers'];

    if (rawTriggers is List) {
      for (final raw in rawTriggers) {
        if (raw is! Map) {
          continue;
        }

        triggers.add(
          CharacterEffectTrigger.fromMap(Map<dynamic, dynamic>.from(raw)),
        );
      }
    }

    final effect = CharacterEffect(
      id: map['id']?.toString() ?? '',

      name: map['name']?.toString() ?? '',

      description: map['description']?.toString() ?? '',

      enabled: map['enabled'] as bool? ?? true,

      type: CharacterEffectType.values.firstWhere(
        (item) => item.name == map['type']?.toString(),
        orElse: () => CharacterEffectType.neutral,
      ),

      durationType: CharacterEffectDurationType.values.firstWhere(
        (item) => item.name == map['durationType']?.toString(),
        orElse: () => CharacterEffectDurationType.permanent,
      ),

      maxDuration: (map['maxDuration'] as num?)?.toInt() ?? 0,

      currentDuration: (map['currentDuration'] as num?)?.toInt() ?? 0,

      durationNote: map['durationNote']?.toString() ?? '',

      minuteRoundProgress: (map['minuteRoundProgress'] as num?)?.toInt() ?? 0,

      armorClassBonus: (map['armorClassBonus'] as num?)?.toInt() ?? 0,

      initiativeBonus: (map['initiativeBonus'] as num?)?.toInt() ?? 0,

      speedBonus: (map['speedBonus'] as num?)?.toInt() ?? 0,

      maxHealthBonus: (map['maxHealthBonus'] as num?)?.toInt() ?? 0,

      attackBonus: (map['attackBonus'] as num?)?.toInt() ?? 0,

      criticalMinimumNaturalRoll:
          (map['criticalMinimumNaturalRoll'] as num?)?.toInt() ?? 20,

      empoweredCritical: map['empoweredCritical'] as bool? ?? false,
      empoweredCriticalMultiplier:
          ((map['empoweredCriticalMultiplier'] as num?)?.toInt() ?? 2).clamp(2, 10).toInt(),
      empoweredCriticalFormula: map['empoweredCriticalFormula'] as String? ??
          '(MAX + MOD) * ${((map['empoweredCriticalMultiplier'] as num?)?.toInt() ?? 2).clamp(2, 10)}',

      abilityModifierBonuses: abilityModifierBonuses,

      skillBonuses: skillBonuses,

      savingThrowBonuses: savingThrowBonuses,

      damageBonuses: damageBonuses,

      criticalDamageBonuses: criticalDamageBonuses,

      healingBonuses: healingBonuses,

      triggers: triggers,

      notes: map['notes']?.toString() ?? '',
    );

    effect.normalizeDuration();

    return effect;
  }
}

class CharacterEffectTrigger {
  final String id;

  final PassiveTriggerEvent event;

  final PassiveTriggerTarget target;

  final TriggerUsageLimit usageLimit;

  /// Define cómo se comporta el trigger.
  ///
  /// once:
  /// se ejecuta una vez cuando ocurre el evento.
  ///
  /// whileCondition:
  /// mantiene sus efectos vinculados mientras
  /// la condición permanezca verdadera.
  final PassiveTriggerMode mode;

  final CharacterFormula? condition;

  final List<DamageBonus> damageBonuses;
  final List<HealingBonus> healingBonuses;
  final List<HealingBonus> mitigationBonuses;
  final List<CharacterEffect> linkedEffects;

  const CharacterEffectTrigger({
    required this.id,
    required this.event,
    this.target = PassiveTriggerTarget.self,
    this.usageLimit = TriggerUsageLimit.unlimited,
    this.mode = PassiveTriggerMode.once,
    this.condition,
    this.damageBonuses = const [],
    this.healingBonuses = const [],
    this.mitigationBonuses = const [],
    this.linkedEffects = const [],
  });

  bool get targetsSelf {
    return target == PassiveTriggerTarget.self;
  }

  bool get targetsActionTarget {
    return target == PassiveTriggerTarget.actionTarget;
  }

  bool get executesOnce {
    return mode == PassiveTriggerMode.once;
  }

  bool get maintainsWhileCondition {
    return mode == PassiveTriggerMode.whileCondition;
  }

  bool get supportsPersistentMode {
    return linkedEffects.isNotEmpty &&
        damageBonuses.every((bonus) => !bonus.hasDamage) &&
        healingBonuses.every((bonus) => !bonus.hasHealing) &&
        mitigationBonuses.every((bonus) => !bonus.hasHealing);
  }

  String usageKey(String sourceEffectId) {
    return '$sourceEffectId:$id';
  }

  bool get hasCondition {
    return condition != null &&
        condition!.expression.trim().isNotEmpty &&
        condition!.expression.trim() != '0';
  }

  bool get hasMechanicalEffects {
    return damageBonuses.any((bonus) => bonus.hasDamage) ||
        healingBonuses.any((bonus) => bonus.hasHealing) ||
        mitigationBonuses.any((bonus) => bonus.hasHealing) ||
        linkedEffects.isNotEmpty;
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event': event.name,
      'target': target.name,
      'usageLimit': usageLimit.name,
      'mode': mode.name,
      'condition': condition?.toMap(),

      'damageBonuses': damageBonuses.map((bonus) => bonus.toMap()).toList(),

      'healingBonuses': healingBonuses.map((bonus) => bonus.toMap()).toList(),

      'mitigationBonuses': mitigationBonuses
          .map((bonus) => bonus.toMap())
          .toList(),

      'linkedEffects': linkedEffects.map((effect) => effect.toMap()).toList(),
    };
  }

  factory CharacterEffectTrigger.fromMap(Map<dynamic, dynamic> map) {
    // =========================================================================
    // CONDICIÓN
    // =========================================================================

    final rawCondition = map['condition'];

    final condition = rawCondition is Map
        ? CharacterFormula.fromMap(Map<dynamic, dynamic>.from(rawCondition))
        : null;

    // =========================================================================
    // DAÑO
    // =========================================================================

    final damageBonuses = <DamageBonus>[];

    final rawDamageBonuses = map['damageBonuses'];

    if (rawDamageBonuses is List) {
      for (final rawBonus in rawDamageBonuses) {
        if (rawBonus is! Map) {
          continue;
        }

        try {
          damageBonuses.add(
            DamageBonus.fromMap(Map<dynamic, dynamic>.from(rawBonus)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    // =========================================================================
    // CURACIÓN
    // =========================================================================

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
    // MITIGACIÓN
    // =========================================================================

    final mitigationBonuses = <HealingBonus>[];

    final rawMitigationBonuses = map['mitigationBonuses'];

    if (rawMitigationBonuses is List) {
      for (final rawBonus in rawMitigationBonuses) {
        if (rawBonus is! Map) {
          continue;
        }

        try {
          mitigationBonuses.add(
            HealingBonus.fromMap(Map<dynamic, dynamic>.from(rawBonus)),
          );
        } catch (_) {
          continue;
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
    // CREAR TRIGGER
    // =========================================================================

    return CharacterEffectTrigger(
      id: map['id']?.toString() ?? '',

      event: PassiveTriggerEvent.values.firstWhere(
        (value) => value.name == map['event']?.toString(),
        orElse: () => PassiveTriggerEvent.custom,
      ),

      usageLimit: TriggerUsageLimit.values.firstWhere(
        (value) => value.name == map['usageLimit']?.toString(),
        orElse: () => TriggerUsageLimit.unlimited,
      ),

      mode: PassiveTriggerMode.values.firstWhere(
        (value) => value.name == map['mode']?.toString(),
        orElse: () => PassiveTriggerMode.once,
      ),

      target: PassiveTriggerTarget.values.firstWhere(
        (value) => value.name == map['target']?.toString(),
        orElse: () => PassiveTriggerTarget.self,
      ),

      condition: condition,

      damageBonuses: damageBonuses,

      healingBonuses: healingBonuses,

      mitigationBonuses: mitigationBonuses,

      linkedEffects: linkedEffects,
    );
  }
}
