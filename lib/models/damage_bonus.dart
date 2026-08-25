import 'dice_pool.dart';
import 'skill.dart';
import 'formulas/character_formula.dart';

class DamageBonus {
  String id;

  String name;

  List<DicePool> dicePools;

  Map<AbilityType, int> abilityModifierMultipliers;

  int flatBonus;

  String damageType;

  CharacterFormula? formula;

  DamageBonus({
    required this.id,
    this.name = '',
    List<DicePool>? dicePools,
    Map<AbilityType, int>? abilityModifierMultipliers,
    this.flatBonus = 0,
    this.damageType = '',
    this.formula,
  }) : dicePools = dicePools ?? [],
       abilityModifierMultipliers = abilityModifierMultipliers ?? {};

  bool get hasDamage {
    return dicePools.isNotEmpty ||
        flatBonus != 0 ||
        abilityModifierMultipliers.values.any(
              (value) => value != 0,
        );
  }

  bool get hasFormula {
    return formula != null &&
        formula!.expression.trim().isNotEmpty &&
        formula!.expression.trim() != '0';
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

      'damageType': damageType,

      'formula': formula?.toMap(),
    };
  }

  factory DamageBonus.fromMap(Map<dynamic, dynamic> map) {
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

    final rawFormula = map['formula'];

    final formula = rawFormula is Map
        ? CharacterFormula.fromMap(
      Map<dynamic, dynamic>.from(rawFormula),
    )
        : null;

    return DamageBonus(
      id: map['id']?.toString() ?? '',

      name: map['name']?.toString() ?? '',

      dicePools: dicePools,

      abilityModifierMultipliers: multipliers,

      flatBonus: (map['flatBonus'] as num?)?.toInt() ?? 0,

      damageType: map['damageType']?.toString() ?? '',

      formula: formula,
    );
  }
}
