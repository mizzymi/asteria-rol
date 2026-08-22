import 'damage_bonus_result.dart';
import 'critical_damage_bonus_result.dart';
import 'dice_pool.dart';
import 'weapon_damage.dart';

class WeaponDamagePartResult {
  final WeaponDamage damage;

  final DiceCalculationResult roll;

  final DiceCalculationResult? criticalExtraRoll;

  WeaponDamagePartResult({
    required this.damage,
    required this.roll,
    this.criticalExtraRoll,
  });

  int get baseTotal {
    return roll.total;
  }

  int get criticalExtraTotal {
    return criticalExtraRoll?.total ?? 0;
  }

  int get total {
    return baseTotal + criticalExtraTotal;
  }
}

class WeaponDamageResult {
  final List<WeaponDamagePartResult> parts;

  final List<DamageBonusResult> bonusDamageParts;

  final List<CriticalDamageBonusResult> criticalBonusParts;

  final bool critical;

  WeaponDamageResult({
    required this.parts,
    List<DamageBonusResult>? bonusDamageParts,
    List<CriticalDamageBonusResult>? criticalBonusParts,
    required this.critical,
  }) : bonusDamageParts = bonusDamageParts ?? [],
       criticalBonusParts = criticalBonusParts ?? [];

  int get weaponDamageTotal {
    return parts.fold<int>(0, (sum, part) => sum + part.total);
  }

  int get bonusDamageTotal {
    return bonusDamageParts.fold<int>(0, (sum, part) => sum + part.total);
  }

  int get criticalBonusTotal {
    return criticalBonusParts.fold<int>(0, (sum, part) => sum + part.total);
  }

  int get total {
    return weaponDamageTotal + bonusDamageTotal + criticalBonusTotal;
  }
}
