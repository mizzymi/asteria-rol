import 'skill.dart';

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

    Map<AbilityType, int>? abilityModifierBonuses,
    Map<DndSkill, int>? skillBonuses,
    Map<AbilityType, int>? savingThrowBonuses,

    this.notes = '',
  }) : abilityModifierBonuses = abilityModifierBonuses ?? {},
       skillBonuses = skillBonuses ?? {},
       savingThrowBonuses = savingThrowBonuses ?? {};

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
        savingThrowBonuses.values.any((value) => value != 0);
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

      abilityModifierBonuses: abilityModifierBonuses,

      skillBonuses: skillBonuses,

      savingThrowBonuses: savingThrowBonuses,

      notes: map['notes']?.toString() ?? '',
    );

    effect.normalizeDuration();

    return effect;
  }
}
