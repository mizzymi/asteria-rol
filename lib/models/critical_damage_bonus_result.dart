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

  bool get failed => !triggered;

  bool get hasResult {
    return triggered && roll != null;
  }

  int get total {
    if (!hasResult) {
      return 0;
    }

    return roll!.total;
  }
}
