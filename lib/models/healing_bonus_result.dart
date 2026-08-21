import 'dice_pool.dart';
import 'healing_bonus.dart';

class HealingBonusResult {
  final HealingBonus bonus;

  final DiceCalculationResult roll;

  HealingBonusResult({required this.bonus, required this.roll});

  int get total {
    return roll.total;
  }
}
