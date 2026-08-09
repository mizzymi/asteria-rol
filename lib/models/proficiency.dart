enum ProficiencyLevel { none, proficient, expertise }

extension ProficiencyLevelData on ProficiencyLevel {
  String get label {
    switch (this) {
      case ProficiencyLevel.none:
        return 'Sin competencia';
      case ProficiencyLevel.proficient:
        return 'Competente';
      case ProficiencyLevel.expertise:
        return 'Pericia';
    }
  }

  int bonus(int proficiencyBonus) {
    switch (this) {
      case ProficiencyLevel.none:
        return 0;

      case ProficiencyLevel.proficient:
        return proficiencyBonus;

      case ProficiencyLevel.expertise:
        return proficiencyBonus * 2;
    }
  }
}
