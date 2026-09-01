import 'dice_pool.dart';
import 'skill.dart';
import 'formulas/character_formula.dart';
import 'action_hit_behavior.dart';
import 'passive_charge_dice_scaling.dart';
import 'action_cost.dart';

class DamageBonus {
  String id;

  String name;

  List<DicePool> dicePools;

  Map<AbilityType, int> abilityModifierMultipliers;

  int flatBonus;

  String damageType;

  CharacterFormula? formula;

  CharacterFormula? condition;

  bool optional;

  String optionalGroupId;

  String optionalLabel;

  ActionHitBehavior hitBehavior;

  /// Si true, este daño adicional participa en la transformación crítica.
  ///
  /// false permite representar daño que se aplica con el ataque
  /// pero no se duplica/maximiza por crítico.
  bool participatesInCritical;

  PassiveChargeDiceScaling chargeScaling;

  List<ActionCost> costs;

  DamageBonus({
    required this.id,
    this.name = '',
    List<DicePool>? dicePools,
    Map<AbilityType, int>? abilityModifierMultipliers,
    this.flatBonus = 0,
    this.damageType = '',
    this.formula,
    this.condition,
    this.optional = false,
    this.optionalGroupId = '',
    this.optionalLabel = '',
    this.hitBehavior = ActionHitBehavior.requireHit,
    this.participatesInCritical = true,
    this.chargeScaling = const PassiveChargeDiceScaling(),
    List<ActionCost>? costs,
  }) : dicePools = dicePools ?? [],
       abilityModifierMultipliers = abilityModifierMultipliers ?? {},
       costs = costs ?? [];

  bool get hasCondition {
    return condition != null &&
        condition!.expression.trim().isNotEmpty &&
        condition!.expression.trim() != '0';
  }

  String get effectiveOptionalGroupId {
    final explicit = optionalGroupId.trim();

    if (explicit.isNotEmpty) {
      return explicit;
    }

    return id;
  }

  String get effectiveOptionalLabel {
    final explicit = optionalLabel.trim();

    if (explicit.isNotEmpty) {
      return explicit;
    }

    if (name.trim().isNotEmpty) {
      return name.trim();
    }

    return 'Daño adicional';
  }

  bool get hasDamage {
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

      'damageType': damageType,

      'formula': formula?.toMap(),

      'condition': condition?.toMap(),

      'optional': optional,

      'optionalGroupId': optionalGroupId,

      'optionalLabel': optionalLabel,

      'hitBehavior': hitBehavior.name,

      'participatesInCritical': participatesInCritical,

      'chargeScaling': chargeScaling.toMap(),

      'costs': costs.map((cost) => cost.toMap()).toList(),
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
        ? CharacterFormula.fromMap(Map<dynamic, dynamic>.from(rawFormula))
        : null;

    final rawCondition = map['condition'];

    final condition = rawCondition is Map
        ? CharacterFormula.fromMap(Map<dynamic, dynamic>.from(rawCondition))
        : null;

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

    return DamageBonus(
      id: map['id']?.toString() ?? '',

      name: map['name']?.toString() ?? '',

      dicePools: dicePools,

      abilityModifierMultipliers: multipliers,

      flatBonus: (map['flatBonus'] as num?)?.toInt() ?? 0,

      damageType: map['damageType']?.toString() ?? '',

      formula: formula,

      condition: condition,

      optional: map['optional'] as bool? ?? false,

      optionalGroupId: map['optionalGroupId']?.toString() ?? '',

      optionalLabel: map['optionalLabel']?.toString() ?? '',

      hitBehavior: ActionHitBehavior.values.firstWhere(
        (value) => value.name == map['hitBehavior']?.toString(),
        orElse: () => ActionHitBehavior.requireHit,
      ),

      participatesInCritical: map['participatesInCritical'] as bool? ?? true,

      chargeScaling: map['chargeScaling'] is Map
          ? PassiveChargeDiceScaling.fromMap(
              Map<dynamic, dynamic>.from(map['chargeScaling']),
            )
          : const PassiveChargeDiceScaling(),

      costs: costs,
    );
  }
}
