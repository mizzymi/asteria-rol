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

  // ===========================================================================
  // BONIFICACIONES
  // ===========================================================================

  int armorClassBonus;

  int initiativeBonus;

  int speedBonus;

  int maxHealthBonus;

  int attackBonus;

  int criticalMinimumNaturalRoll;

  Map<AbilityType, int> abilityModifierBonuses;

  Map<DndSkill, int> skillBonuses;

  Map<AbilityType, int> savingThrowBonuses;

  // ===========================================================================
  // OTROS
  // ===========================================================================

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

    this.armorClassBonus = 0,
    this.initiativeBonus = 0,
    this.speedBonus = 0,
    this.maxHealthBonus = 0,
    this.attackBonus = 0,
    this.criticalMinimumNaturalRoll = 20,
    Map<AbilityType, int>? abilityModifierBonuses,
    Map<DndSkill, int>? skillBonuses,
    Map<AbilityType, int>? savingThrowBonuses,

    List<DamageBonus>? damageBonuses,

    List<CriticalDamageBonus>? criticalDamageBonuses,

    List<HealingBonus>? healingBonuses,

    this.notes = '',
  }) : abilityModifierBonuses = abilityModifierBonuses ?? {},
       skillBonuses = skillBonuses ?? {},
       savingThrowBonuses = savingThrowBonuses ?? {},
       damageBonuses = damageBonuses ?? [],
       healingBonuses = healingBonuses ?? [],
       criticalDamageBonuses = criticalDamageBonuses ?? [];

  // ===========================================================================
  // GETTERS
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
        healingBonuses.any((bonus) => bonus.hasHealing);
  }

  bool get hasDuration {
    return durationType != CharacterEffectDurationType.permanent;
  }

  bool get expired {
    return hasDuration && currentDuration <= 0;
  }

  String get durationText {
    if (!hasDuration) {
      return 'Permanente';
    }

    switch (durationType) {
      case CharacterEffectDurationType.permanent:
        return 'Permanente';

      case CharacterEffectDurationType.turns:
        return '$currentDuration turnos';

      case CharacterEffectDurationType.rounds:
        return '$currentDuration rondas';

      case CharacterEffectDurationType.minutes:
        return '$currentDuration min';

      case CharacterEffectDurationType.custom:
        return durationNote.isNotEmpty
            ? durationNote
            : 'Duración personalizada';
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
  }

  void increaseDuration() {
    if (!hasDuration) {
      return;
    }

    currentDuration++;

    if (maxDuration > 0 && currentDuration > maxDuration) {
      currentDuration = maxDuration;
    }
  }

  void resetDuration() {
    if (!hasDuration) {
      return;
    }

    currentDuration = maxDuration;
  }

  void normalizeDuration() {
    if (!hasDuration) {
      maxDuration = 0;
      currentDuration = 0;

      return;
    }

    if (maxDuration < 0) {
      maxDuration = 0;
    }

    if (currentDuration < 0) {
      currentDuration = 0;
    }

    if (maxDuration > 0 && currentDuration > maxDuration) {
      currentDuration = maxDuration;
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
    String? durationNote,
    int? armorClassBonus,
    int? initiativeBonus,
    int? speedBonus,
    int? maxHealthBonus,
    int? attackBonus,
    Map<AbilityType, int>? abilityModifierBonuses,
    Map<DndSkill, int>? skillBonuses,
    Map<AbilityType, int>? savingThrowBonuses,
    List<DamageBonus>? damageBonuses,
    List<CriticalDamageBonus>? criticalDamageBonuses,
    List<HealingBonus>? healingBonuses,
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

      armorClassBonus: armorClassBonus ?? this.armorClassBonus,
      initiativeBonus: initiativeBonus ?? this.initiativeBonus,
      speedBonus: speedBonus ?? this.speedBonus,
      maxHealthBonus: maxHealthBonus ?? this.maxHealthBonus,
      attackBonus: attackBonus ?? this.attackBonus,

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

      'criticalDamageBonuses': criticalDamageBonuses
          .map((damage) => damage.toMap())
          .toList(),

      'healingBonuses': healingBonuses.map((bonus) => bonus.toMap()).toList(),

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

      armorClassBonus: (map['armorClassBonus'] as num?)?.toInt() ?? 0,

      initiativeBonus: (map['initiativeBonus'] as num?)?.toInt() ?? 0,

      speedBonus: (map['speedBonus'] as num?)?.toInt() ?? 0,

      maxHealthBonus: (map['maxHealthBonus'] as num?)?.toInt() ?? 0,

      attackBonus: (map['attackBonus'] as num?)?.toInt() ?? 0,

      criticalMinimumNaturalRoll:
          (map['criticalMinimumNaturalRoll'] as num?)?.toInt() ?? 20,

      abilityModifierBonuses: abilityModifierBonuses,

      skillBonuses: skillBonuses,

      savingThrowBonuses: savingThrowBonuses,

      damageBonuses: damageBonuses,

      criticalDamageBonuses: criticalDamageBonuses,

      healingBonuses: healingBonuses,

      notes: map['notes']?.toString() ?? '',
    );

    effect.normalizeDuration();

    return effect;
  }
}
