import 'damage_bonus.dart';
import 'dice_pool.dart';

class DamageBonusResult {
  final DamageBonus bonus;

  final DiceCalculationResult roll;

  DamageBonusResult({required this.bonus, required this.roll});

  int get total {
    return roll.total;
  }
}
