import 'skill.dart';

enum DndClass {
  barbarian,
  bard,
  cleric,
  druid,
  fighter,
  monk,
  paladin,
  ranger,
  rogue,
  sorcerer,
  warlock,
  wizard,
}

extension DndClassData on DndClass {
  // ---------------------------------------------------------------------------
  // NOMBRE
  // ---------------------------------------------------------------------------

  String get label {
    switch (this) {
      case DndClass.barbarian:
        return 'Bárbaro';

      case DndClass.bard:
        return 'Bardo';

      case DndClass.cleric:
        return 'Clérigo';

      case DndClass.druid:
        return 'Druida';

      case DndClass.fighter:
        return 'Guerrero';

      case DndClass.monk:
        return 'Monje';

      case DndClass.paladin:
        return 'Paladín';

      case DndClass.ranger:
        return 'Explorador';

      case DndClass.rogue:
        return 'Pícaro';

      case DndClass.sorcerer:
        return 'Hechicero';

      case DndClass.warlock:
        return 'Brujo';

      case DndClass.wizard:
        return 'Mago';
    }
  }

  // ---------------------------------------------------------------------------
  // DADO DE GOLPE
  // ---------------------------------------------------------------------------

  int get hitDie {
    switch (this) {
      case DndClass.barbarian:
        return 12;

      case DndClass.fighter:
      case DndClass.paladin:
      case DndClass.ranger:
        return 10;

      case DndClass.bard:
      case DndClass.cleric:
      case DndClass.druid:
      case DndClass.monk:
      case DndClass.rogue:
      case DndClass.warlock:
        return 8;

      case DndClass.sorcerer:
      case DndClass.wizard:
        return 6;
    }
  }

  // ---------------------------------------------------------------------------
  // PG MEDIOS POR NIVEL
  // ---------------------------------------------------------------------------

  int get averageHitPoints {
    return (hitDie ~/ 2) + 1;
  }

  // ---------------------------------------------------------------------------
  // SALVACIONES CON COMPETENCIA
  // ---------------------------------------------------------------------------

  Set<AbilityType> get savingThrowProficiencies {
    switch (this) {
      case DndClass.barbarian:
        return {AbilityType.strength, AbilityType.constitution};

      case DndClass.bard:
        return {AbilityType.dexterity, AbilityType.charisma};

      case DndClass.cleric:
        return {AbilityType.wisdom, AbilityType.charisma};

      case DndClass.druid:
        return {AbilityType.intelligence, AbilityType.wisdom};

      case DndClass.fighter:
        return {AbilityType.strength, AbilityType.constitution};

      case DndClass.monk:
        return {AbilityType.strength, AbilityType.dexterity};

      case DndClass.paladin:
        return {AbilityType.wisdom, AbilityType.charisma};

      case DndClass.ranger:
        return {AbilityType.strength, AbilityType.dexterity};

      case DndClass.rogue:
        return {AbilityType.dexterity, AbilityType.intelligence};

      case DndClass.sorcerer:
        return {AbilityType.constitution, AbilityType.charisma};

      case DndClass.warlock:
        return {AbilityType.wisdom, AbilityType.charisma};

      case DndClass.wizard:
        return {AbilityType.intelligence, AbilityType.wisdom};
    }
  }

  // ---------------------------------------------------------------------------
  // DESERIALIZACIÓN
  // ---------------------------------------------------------------------------

  static DndClass fromString(String? value) {
    if (value == null || value.isEmpty) {
      return DndClass.fighter;
    }

    for (final dndClass in DndClass.values) {
      if (dndClass.name == value) {
        return dndClass;
      }

      if (dndClass.label.toLowerCase() == value.toLowerCase()) {
        return dndClass;
      }
    }

    return DndClass.fighter;
  }
}
