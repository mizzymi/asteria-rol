import 'skill.dart';

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

    // =======================================================================
    // CARGAS
    // =======================================================================
    this.hasCharges = false,
    this.maxCharges = 0,
    this.currentCharges = 0,
    this.rechargeDescription = '',

    this.notes = '',
  }) : skillBonuses = skillBonuses ?? {},
       abilityModifierBonuses = abilityModifierBonuses ?? {},
       savingThrowBonuses = savingThrowBonuses ?? {};

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
        savingThrowBonuses.values.any((value) => value != 0);
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
