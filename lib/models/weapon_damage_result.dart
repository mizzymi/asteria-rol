import 'damage_bonus_result.dart';
import 'critical_damage_bonus_result.dart';
import 'dice_pool.dart';
import 'weapon_damage.dart';

class WeaponDamagePartResult {
  final WeaponDamage damage;

  final DiceCalculationResult roll;

  WeaponDamagePartResult({required this.damage, required this.roll});

  int get total {
    return roll.total;
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
