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

  // ---------------------------------------------------------------------------
  // CÁLCULO DE MODIFICADORES
  // ---------------------------------------------------------------------------

  static int modifierFor(int value) {
    return ((value - 10) / 2).floor();
  }

  int get strengthModifier => modifierFor(strength);

  int get dexterityModifier => modifierFor(dexterity);

  int get constitutionModifier => modifierFor(constitution);

  int get intelligenceModifier => modifierFor(intelligence);

  int get wisdomModifier => modifierFor(wisdom);

  int get charismaModifier => modifierFor(charisma);

  // ---------------------------------------------------------------------------
  // OBTENER MODIFICADOR SEGÚN ATRIBUTO
  // ---------------------------------------------------------------------------

  int modifierByType(AbilityType type) {
    switch (type) {
      case AbilityType.strength:
        return strengthModifier;

      case AbilityType.dexterity:
        return dexterityModifier;

      case AbilityType.constitution:
        return constitutionModifier;

      case AbilityType.intelligence:
        return intelligenceModifier;

      case AbilityType.wisdom:
        return wisdomModifier;

      case AbilityType.charisma:
        return charismaModifier;
    }
  }

  // ---------------------------------------------------------------------------
  // SERIALIZACIÓN
  // ---------------------------------------------------------------------------

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
      strength: map['strength'] ?? 10,
      dexterity: map['dexterity'] ?? 10,
      constitution: map['constitution'] ?? 10,
      intelligence: map['intelligence'] ?? 10,
      wisdom: map['wisdom'] ?? 10,
      charisma: map['charisma'] ?? 10,
    );
  }
}
