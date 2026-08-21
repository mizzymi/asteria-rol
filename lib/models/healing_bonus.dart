import 'dice_pool.dart';
import 'skill.dart';

class HealingBonus {
  String id;

  String name;

  List<DicePool> dicePools;

  Map<AbilityType, int> abilityModifierMultipliers;

  int flatBonus;

  HealingBonus({
    required this.id,
    this.name = '',
    List<DicePool>? dicePools,
    Map<AbilityType, int>? abilityModifierMultipliers,
    this.flatBonus = 0,
  }) : dicePools = dicePools ?? [],
       abilityModifierMultipliers = abilityModifierMultipliers ?? {};

  bool get hasHealing {
    return dicePools.isNotEmpty ||
        abilityModifierMultipliers.values.any((value) => value != 0) ||
        flatBonus != 0;
  }

  String get diceNotation {
    return dicePools.map((pool) => pool.notation).join(' + ');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,

      'dicePools': dicePools.map((pool) => pool.toMap()).toList(),

      'abilityModifierMultipliers': {
        for (final entry in abilityModifierMultipliers.entries)
          entry.key.name: entry.value,
      },

      'flatBonus': flatBonus,
    };
  }

  factory HealingBonus.fromMap(Map<dynamic, dynamic> map) {
    final dicePools = <DicePool>[];

    final rawPools = map['dicePools'];

    if (rawPools is List) {
      for (final rawPool in rawPools) {
        if (rawPool is! Map) {
          continue;
        }

        try {
          dicePools.add(DicePool.fromMap(Map<dynamic, dynamic>.from(rawPool)));
        } catch (_) {
          continue;
        }
      }
    }

    final multipliers = <AbilityType, int>{};

    final rawMultipliers = map['abilityModifierMultipliers'];

    if (rawMultipliers is Map) {
      final multiplierMap = Map<dynamic, dynamic>.from(rawMultipliers);

      for (final ability in AbilityType.values) {
        final value = (multiplierMap[ability.name] as num?)?.toInt() ?? 0;

        if (value != 0) {
          multipliers[ability] = value;
        }
      }
    }

    return HealingBonus(
      id: map['id']?.toString() ?? '',

      name: map['name']?.toString() ?? '',

      dicePools: dicePools,

      abilityModifierMultipliers: multipliers,

      flatBonus: (map['flatBonus'] as num?)?.toInt() ?? 0,
    );
  }
}
