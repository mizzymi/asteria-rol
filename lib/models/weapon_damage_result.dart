import 'dice_pool.dart';
import 'weapon_damage.dart';

class WeaponDamagePartResult {
  final WeaponDamage damage;

  final DiceCalculationResult roll;

  WeaponDamagePartResult({required this.damage, required this.roll});

  int get total => roll.total;
}

class WeaponDamageResult {
  final List<WeaponDamagePartResult> parts;

  final bool critical;

  WeaponDamageResult({required this.parts, required this.critical});

  int get total {
    return parts.fold<int>(0, (sum, part) => sum + part.total);
  }
}
