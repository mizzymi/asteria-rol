import 'action_dice_result.dart';

class PassiveRollResolution {
  final ActionDiceResult diceResult;

  final String calculationText;

  const PassiveRollResolution({
    required this.diceResult,
    required this.calculationText,
  });

  int get total => diceResult.total;
}
