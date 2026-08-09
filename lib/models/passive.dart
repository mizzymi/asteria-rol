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
    this.notes = '',
  }) : skillBonuses = skillBonuses ?? {},
       abilityModifierBonuses = abilityModifierBonuses ?? {},
       savingThrowBonuses = savingThrowBonuses ?? {};

  bool get hasMechanicalEffects {
    return armorClassBonus != 0 ||
        initiativeBonus != 0 ||
        speedBonus != 0 ||
        maxHealthBonus != 0 ||
        attackBonus != 0 ||
        skillBonuses.values.any((value) => value != 0) ||
        savingThrowBonuses.values.any((value) => value != 0);
  }

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
      'notes': notes,
    };
  }

  factory CharacterPassive.fromMap(Map<dynamic, dynamic> map) {
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

    return CharacterPassive(
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
      notes: map['notes']?.toString() ?? '',
    );
  }
}
