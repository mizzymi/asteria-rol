import 'dice_pool.dart';
import 'skill.dart';
import 'passive.dart';
import 'formulas/character_formula.dart';
import 'passive_charge_dice_scaling.dart';
import 'action_cost.dart';

class HealingBonus {
  String id;

  String name;

  List<DicePool> dicePools;

  Map<AbilityType, int> abilityModifierMultipliers;

  int flatBonus;

  CharacterFormula? formula;

  PassiveChargeDiceScaling chargeScaling;

  List<ActionCost> costs;

  HealingBonus({
    required this.id,
    this.name = '',
    List<DicePool>? dicePools,
    Map<AbilityType, int>? abilityModifierMultipliers,
    this.flatBonus = 0,
    this.formula,
    this.chargeScaling = const PassiveChargeDiceScaling(),
    List<ActionCost>? costs,
  }) : dicePools = dicePools ?? [],
       abilityModifierMultipliers = abilityModifierMultipliers ?? {},
       costs = costs ?? [];

  bool get hasHealing {
    return dicePools.isNotEmpty ||
        flatBonus != 0 ||
        abilityModifierMultipliers.values.any((value) => value != 0) ||
        hasFormula ||
        chargeScaling.hasScaling;
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

      'formula': formula?.toMap(),

      'chargeScaling': chargeScaling.toMap(),

      'costs': costs.map((cost) => cost.toMap()).toList(),
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

    final rawFormula = map['formula'];

    final costs = <ActionCost>[];

    final rawCosts = map['costs'];

    if (rawCosts is List) {
      for (final rawCost in rawCosts) {
        if (rawCost is! Map) {
          continue;
        }

        final cost = ActionCost.fromMap(Map<dynamic, dynamic>.from(rawCost));

        if (cost.isValid) {
          costs.add(cost);
        }
      }
    }

    return HealingBonus(
      id: map['id']?.toString() ?? '',

      name: map['name']?.toString() ?? '',

      dicePools: dicePools,

      abilityModifierMultipliers: multipliers,

      flatBonus: (map['flatBonus'] as num?)?.toInt() ?? 0,

      formula: rawFormula is Map
          ? CharacterFormula.fromMap(Map<dynamic, dynamic>.from(rawFormula))
          : null,

      chargeScaling: map['chargeScaling'] is Map
          ? PassiveChargeDiceScaling.fromMap(
              Map<dynamic, dynamic>.from(map['chargeScaling']),
            )
          : const PassiveChargeDiceScaling(),

      costs: costs,
    );
  }
}

class ActiveHealingBonus {
  final HealingBonus bonus;
  final CharacterPassive? passive;

  const ActiveHealingBonus({required this.bonus, this.passive});
}
