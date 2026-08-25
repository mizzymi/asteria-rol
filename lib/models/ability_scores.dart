import 'skill.dart';

class AbilityScores {
  int strength;
  int dexterity;
  int constitution;
  int intelligence;
  int wisdom;
  int charisma;

  AbilityScores({
    this.strength = 10,
    this.dexterity = 10,
    this.constitution = 10,
    this.intelligence = 10,
    this.wisdom = 10,
    this.charisma = 10,
  });

  // ===========================================================================
  // CÁLCULO DE MODIFICADORES
  // ===========================================================================

  static int modifierFor(int value) {
    return ((value - 10) / 2).floor();
  }

  int get strengthModifier => modifierFor(strength);

  int get dexterityModifier => modifierFor(dexterity);

  int get constitutionModifier => modifierFor(constitution);

  int get intelligenceModifier => modifierFor(intelligence);

  int get wisdomModifier => modifierFor(wisdom);

  int get charismaModifier => modifierFor(charisma);

  // ===========================================================================
  // OBTENER PUNTUACIÓN SEGÚN ATRIBUTO
  // ===========================================================================

  int valueByType(AbilityType type) {
    switch (type) {
      case AbilityType.strength:
        return strength;

      case AbilityType.dexterity:
        return dexterity;

      case AbilityType.constitution:
        return constitution;

      case AbilityType.intelligence:
        return intelligence;

      case AbilityType.wisdom:
        return wisdom;

      case AbilityType.charisma:
        return charisma;
    }
  }

  // ===========================================================================
  // OBTENER MODIFICADOR SEGÚN ATRIBUTO
  // ===========================================================================

  int modifierByType(AbilityType type) {
    return modifierFor(valueByType(type));
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'strength': strength,
      'dexterity': dexterity,
      'constitution': constitution,
      'intelligence': intelligence,
      'wisdom': wisdom,
      'charisma': charisma,
    };
  }

  factory AbilityScores.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return AbilityScores();
    }

    return AbilityScores(
      strength: (map['strength'] as num?)?.toInt() ?? 10,
      dexterity: (map['dexterity'] as num?)?.toInt() ?? 10,
      constitution: (map['constitution'] as num?)?.toInt() ?? 10,
      intelligence: (map['intelligence'] as num?)?.toInt() ?? 10,
      wisdom: (map['wisdom'] as num?)?.toInt() ?? 10,
      charisma: (map['charisma'] as num?)?.toInt() ?? 10,
    );
  }
}
