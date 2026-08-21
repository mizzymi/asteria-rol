import 'critical_damage_bonus.dart';
import 'dice_pool.dart';

class CriticalDamageBonusResult {
  final CriticalDamageBonus bonus;

  final int chanceRoll;

  final bool triggered;

  final DiceCalculationResult? roll;

  CriticalDamageBonusResult({
    required this.bonus,
    required this.chanceRoll,
    required this.triggered,
    this.roll,
  });

  int get total {
    if (!triggered || roll == null) {
      return 0;
    }

    return roll!.total;
  }
}
