import 'dice_pool.dart';
import 'skill.dart';
import 'formulas/character_formula.dart';

class CriticalDamageBonus {
  String id;

  String name;

  List<DicePool> dicePools;

  Map<AbilityType, int> abilityModifierMultipliers;

  int flatBonus;

  CharacterFormula? formula;

  /// 0 - 100
  int chancePercent;

  String damageType;

  String description;

  CriticalDamageBonus({
    required this.id,
    this.name = '',
    List<DicePool>? dicePools,
    Map<AbilityType, int>? abilityModifierMultipliers,
    this.flatBonus = 0,
    this.formula,
    this.chancePercent = 100,
    this.damageType = '',
    this.description = '',
  }) : dicePools = dicePools ?? [],
        abilityModifierMultipliers = abilityModifierMultipliers ?? {} {
    normalize();
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool get alwaysTriggers {
    return chancePercent >= 100;
  }

  bool get hasFormula {
    return formula != null &&
        formula!.expression.trim().isNotEmpty &&
        formula!.expression.trim() != '0';
  }

  bool get hasDamage {
    return dicePools.isNotEmpty ||
        abilityModifierMultipliers.values.any((value) => value != 0) ||
        flatBonus != 0 ||
        hasFormula;
  }

  bool get canTrigger {
    return chancePercent > 0 && hasDamage;
  }

  String get diceNotation {
    return dicePools.map((pool) => pool.notation).join(' + ');
  }

  void normalize() {
    if (chancePercent < 0) {
      chancePercent = 0;
    }

    if (chancePercent > 100) {
      chancePercent = 100;
    }
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

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

      'chancePercent': chancePercent,

      'damageType': damageType,

      'description': description,
    };
  }

  factory CriticalDamageBonus.fromMap(Map<dynamic, dynamic> map) {
    final dicePools = <DicePool>[];

    final rawPools = map['dicePools'];

    if (rawPools is List) {
      for (final rawPool in rawPools) {
        if (rawPool is! Map) {
          continue;
        }

        try {
          dicePools.add(
            DicePool.fromMap(
              Map<dynamic, dynamic>.from(rawPool),
            ),
          );
        } catch (_) {
          continue;
        }
      }
    }

    final multipliers = <AbilityType, int>{};

    final rawMultipliers = map['abilityModifierMultipliers'];

    if (rawMultipliers is Map) {
      final multiplierMap =
      Map<dynamic, dynamic>.from(rawMultipliers);

      for (final ability in AbilityType.values) {
        final value =
            (multiplierMap[ability.name] as num?)?.toInt() ?? 0;

        if (value != 0) {
          multipliers[ability] = value;
        }
      }
    }

    final rawFormula = map['formula'];

    return CriticalDamageBonus(
      id: map['id']?.toString() ?? '',

      name: map['name']?.toString() ?? '',

      dicePools: dicePools,

      abilityModifierMultipliers: multipliers,

      flatBonus:
      (map['flatBonus'] as num?)?.toInt() ?? 0,

      formula: rawFormula is Map
          ? CharacterFormula.fromMap(
        Map<dynamic, dynamic>.from(rawFormula),
      )
          : null,

      chancePercent:
      (map['chancePercent'] as num?)?.toInt() ?? 100,

      damageType:
      map['damageType']?.toString() ?? '',

      description:
      map['description']?.toString() ?? '',
    );
  }
}