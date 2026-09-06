import 'skill.dart';
import 'ability.dart';
import 'passive.dart';
import 'ability_scores.dart';
import 'weapon.dart';

class Pet {
  String id;
  String name;
  String species;
  String avatarPath;

  // Estadísticas vitales base
  int currentHealth;
  int maxHealth;
  int armorClass;
  int speed;
  int proficiencyBonus; // <--- Bono de competencia de la mascota

  // Atributos (Fuerza, Destreza, Constitución, Inteligencia, Sabiduría, Carisma)
  AbilityScores abilities;

  // Componentes mecánicos del compañero
  List<CharacterAbility> characterAbilities;
  List<CharacterPassive> passives;
  List<Weapon> weapons; // <--- Ataques básicos / armas de la mascota
  Map<String, int> statModifiers;

  String notes;

  Pet({
    required this.id,
    required this.name,
    this.species = '',
    this.avatarPath = '',
    this.currentHealth = 10,
    this.maxHealth = 10,
    this.armorClass = 12,
    this.speed = 30,
    this.proficiencyBonus = 2,
    AbilityScores? abilities,
    List<CharacterAbility>? characterAbilities,
    List<CharacterPassive>? passives,
    List<Weapon>? weapons,
    Map<String, int>? statModifiers,
    this.notes = '',
  }) : abilities = abilities ?? AbilityScores(),
       characterAbilities = characterAbilities ?? [],
       passives = passives ?? [],
       weapons = weapons ?? [],
       statModifiers = statModifiers ?? {};

  // Helpers de atributos y modificadores
  int get strengthScore => abilities.strength;
  int get dexterityScore => abilities.dexterity;
  int get constitutionScore => abilities.constitution;
  int get intelligenceScore => abilities.intelligence;
  int get wisdomScore => abilities.wisdom;
  int get charismaScore => abilities.charisma;

  int get strengthModifier => AbilityScores.modifierFor(strengthScore);
  int get dexterityModifier => AbilityScores.modifierFor(dexterityScore);
  int get constitutionModifier => AbilityScores.modifierFor(constitutionScore);
  int get intelligenceModifier => AbilityScores.modifierFor(intelligenceScore);
  int get wisdomModifier => AbilityScores.modifierFor(wisdomScore);
  int get charismaModifier => AbilityScores.modifierFor(charismaScore);

  // Cálculo de ataque básico para un arma de la mascota
  int weaponAttackBonus(Weapon weapon) {
    final mod = weapon.attackAbility == AbilityType.strength
        ? strengthModifier
        : dexterityModifier;
    final prof = weapon.proficient ? proficiencyBonus : 0;
    return mod + prof + weapon.magicBonus;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'avatarPath': avatarPath,
      'currentHealth': currentHealth,
      'maxHealth': maxHealth,
      'armorClass': armorClass,
      'speed': speed,
      'proficiencyBonus': proficiencyBonus,
      'abilities': abilities.toMap(),
      'characterAbilities': characterAbilities.map((a) => a.toMap()).toList(),
      'passives': passives.map((p) => p.toMap()).toList(),
      'weapons': weapons.map((w) => w.toMap()).toList(),
      'statModifiers': statModifiers,
      'notes': notes,
    };
  }

  factory Pet.fromMap(Map<dynamic, dynamic> map) {
    final rawAbilities = map['abilities'];
    final abilities = rawAbilities is Map
        ? AbilityScores.fromMap(Map<dynamic, dynamic>.from(rawAbilities))
        : AbilityScores();

    final rawAbilitiesList = map['characterAbilities'] ?? map['abilities'];
    final characterAbilities = <CharacterAbility>[];
    if (rawAbilitiesList is List) {
      for (final raw in rawAbilitiesList) {
        if (raw is Map) {
          try {
            characterAbilities.add(
              CharacterAbility.fromMap(Map<dynamic, dynamic>.from(raw)),
            );
          } catch (_) {}
        }
      }
    }

    final rawPassives = map['passives'];
    final passives = <CharacterPassive>[];
    if (rawPassives is List) {
      for (final raw in rawPassives) {
        if (raw is Map) {
          try {
            passives.add(
              CharacterPassive.fromMap(Map<dynamic, dynamic>.from(raw)),
            );
          } catch (_) {}
        }
      }
    }

    final rawWeapons = map['weapons'];
    final weapons = <Weapon>[];
    if (rawWeapons is List) {
      for (final raw in rawWeapons) {
        if (raw is Map) {
          try {
            weapons.add(Weapon.fromMap(Map<dynamic, dynamic>.from(raw)));
          } catch (_) {}
        }
      }
    }

    final rawModifiers = map['statModifiers'];
    final statModifiers = <String, int>{};
    if (rawModifiers is Map) {
      rawModifiers.forEach((key, value) {
        if (value is num) {
          statModifiers[key.toString()] = value.toInt();
        }
      });
    }

    return Pet(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      species: map['species']?.toString() ?? '',
      avatarPath: map['avatarPath']?.toString() ?? '',
      currentHealth: (map['currentHealth'] as num?)?.toInt() ?? 10,
      maxHealth: (map['maxHealth'] as num?)?.toInt() ?? 10,
      armorClass: (map['armorClass'] as num?)?.toInt() ?? 12,
      speed: (map['speed'] as num?)?.toInt() ?? 30,
      proficiencyBonus: (map['proficiencyBonus'] as num?)?.toInt() ?? 2,
      abilities: abilities,
      characterAbilities: characterAbilities,
      passives: passives,
      weapons: weapons,
      statModifiers: statModifiers,
      notes: map['notes']?.toString() ?? '',
    );
  }
}
