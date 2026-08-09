import 'skill.dart';

class Weapon {
  String id;
  String name;

  AbilityType attackAbility;

  bool proficient;

  int magicBonus;

  String damageDice;

  String damageType;

  Weapon({
    required this.id,
    required this.name,
    this.attackAbility = AbilityType.strength,
    this.proficient = true,
    this.magicBonus = 0,
    this.damageDice = '1d6',
    this.damageType = 'Cortante',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'attackAbility': attackAbility.name,
      'proficient': proficient,
      'magicBonus': magicBonus,
      'damageDice': damageDice,
      'damageType': damageType,
    };
  }

  factory Weapon.fromMap(Map<dynamic, dynamic> map) {
    return Weapon(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      attackAbility: AbilityType.values.firstWhere(
        (value) => value.name == map['attackAbility'],
        orElse: () => AbilityType.strength,
      ),
      proficient: map['proficient'] ?? true,
      magicBonus: map['magicBonus'] ?? 0,
      damageDice: map['damageDice'] ?? '1d6',
      damageType: map['damageType'] ?? 'Cortante',
    );
  }
}
