import 'skill.dart';
import 'dice_pool.dart';

class WeaponDamage {
  String id;

  String name;

  List<DicePool> dicePools;

  bool addAbilityModifier;

  AbilityType abilityType;

  int bonus;

  String damageType;

  WeaponDamage({
    required this.id,
    this.name = '',
    List<DicePool>? dicePools,
    this.addAbilityModifier = false,
    this.abilityType = AbilityType.strength,
    this.bonus = 0,
    this.damageType = '',
  }) : dicePools = dicePools ?? [DicePool(count: 1, sides: 6)];

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool get hasDamage {
    return dicePools.isNotEmpty || bonus != 0 || addAbilityModifier;
  }

  String get diceNotation {
    if (dicePools.isEmpty) {
      return '';
    }

    return dicePools.map((pool) => '${pool.count}d${pool.sides}').join(' + ');
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dicePools': dicePools
          .map((pool) => {'count': pool.count, 'sides': pool.sides})
          .toList(),
      'addAbilityModifier': addAbilityModifier,
      'abilityType': abilityType.name,
      'bonus': bonus,
      'damageType': damageType,
    };
  }

  factory WeaponDamage.fromMap(Map<dynamic, dynamic> map) {
    final dicePools = <DicePool>[];

    final rawDicePools = map['dicePools'];

    if (rawDicePools is List) {
      for (final rawPool in rawDicePools) {
        if (rawPool == null) {
          continue;
        }

        try {
          final poolMap = Map<dynamic, dynamic>.from(rawPool);

          dicePools.add(
            DicePool(
              count: (poolMap['count'] as num?)?.toInt() ?? 1,
              sides: (poolMap['sides'] as num?)?.toInt() ?? 6,
            ),
          );
        } catch (_) {
          continue;
        }
      }
    }

    return WeaponDamage(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      dicePools: dicePools,
      addAbilityModifier: map['addAbilityModifier'] as bool? ?? false,
      abilityType: AbilityType.values.firstWhere(
        (value) => value.name == map['abilityType']?.toString(),
        orElse: () => AbilityType.strength,
      ),
      bonus: (map['bonus'] as num?)?.toInt() ?? 0,
      damageType: map['damageType']?.toString() ?? '',
    );
  }
}
