import 'action_attack_result.dart';
import 'action_attack_roll_mode.dart';
import 'action_dice_mode.dart';

class WeaponAttackResolution {
  final AttackRollMode mode;

  final ActionDiceMode diceMode;

  final int firstRoll;

  final int? secondRoll;

  final ActionAttackResult attackResult;

  const WeaponAttackResolution({
    required this.mode,
    required this.diceMode,
    required this.firstRoll,
    required this.attackResult,
    this.secondRoll,
  });

  int get naturalRoll => attackResult.naturalRoll;

  int get total => attackResult.total;

  bool get critical => attackResult.critical;

  bool get criticalFail => naturalRoll == 1;

  bool get hasSecondRoll => secondRoll != null;
}
