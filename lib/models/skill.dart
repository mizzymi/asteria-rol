enum DndSkill {
  acrobatics,
  animalHandling,
  arcana,
  athletics,
  deception,
  history,
  insight,
  intimidation,
  investigation,
  medicine,
  nature,
  perception,
  performance,
  persuasion,
  religion,
  sleightOfHand,
  stealth,
  survival,
}

enum AbilityType {
  strength,
  dexterity,
  constitution,
  intelligence,
  wisdom,
  charisma,
}

extension DndSkillData on DndSkill {
  String get label {
    switch (this) {
      case DndSkill.acrobatics:
        return 'Acrobacias';

      case DndSkill.animalHandling:
        return 'Trato con animales';

      case DndSkill.arcana:
        return 'Arcano';

      case DndSkill.athletics:
        return 'Atletismo';

      case DndSkill.deception:
        return 'Engaño';

      case DndSkill.history:
        return 'Historia';

      case DndSkill.insight:
        return 'Perspicacia';

      case DndSkill.intimidation:
        return 'Intimidación';

      case DndSkill.investigation:
        return 'Investigación';

      case DndSkill.medicine:
        return 'Medicina';

      case DndSkill.nature:
        return 'Naturaleza';

      case DndSkill.perception:
        return 'Percepción';

      case DndSkill.performance:
        return 'Interpretación';

      case DndSkill.persuasion:
        return 'Persuasión';

      case DndSkill.religion:
        return 'Religión';

      case DndSkill.sleightOfHand:
        return 'Juego de manos';

      case DndSkill.stealth:
        return 'Sigilo';

      case DndSkill.survival:
        return 'Supervivencia';
    }
  }

  AbilityType get ability {
    switch (this) {
      // Destreza
      case DndSkill.acrobatics:
      case DndSkill.sleightOfHand:
      case DndSkill.stealth:
        return AbilityType.dexterity;

      // Sabiduría
      case DndSkill.animalHandling:
      case DndSkill.insight:
      case DndSkill.medicine:
      case DndSkill.perception:
      case DndSkill.survival:
        return AbilityType.wisdom;

      // Inteligencia
      case DndSkill.arcana:
      case DndSkill.history:
      case DndSkill.investigation:
      case DndSkill.nature:
      case DndSkill.religion:
        return AbilityType.intelligence;

      // Fuerza
      case DndSkill.athletics:
        return AbilityType.strength;

      // Carisma
      case DndSkill.deception:
      case DndSkill.intimidation:
      case DndSkill.performance:
      case DndSkill.persuasion:
        return AbilityType.charisma;
    }
  }
}

extension AbilityTypeData on AbilityType {
  String get label {
    switch (this) {
      case AbilityType.strength:
        return 'Fuerza';

      case AbilityType.dexterity:
        return 'Destreza';

      case AbilityType.constitution:
        return 'Constitución';

      case AbilityType.intelligence:
        return 'Inteligencia';

      case AbilityType.wisdom:
        return 'Sabiduría';

      case AbilityType.charisma:
        return 'Carisma';
    }
  }

  String get shortLabel {
    switch (this) {
      case AbilityType.strength:
        return 'FUE';

      case AbilityType.dexterity:
        return 'DES';

      case AbilityType.constitution:
        return 'CON';

      case AbilityType.intelligence:
        return 'INT';

      case AbilityType.wisdom:
        return 'SAB';

      case AbilityType.charisma:
        return 'CAR';
    }
  }
}
