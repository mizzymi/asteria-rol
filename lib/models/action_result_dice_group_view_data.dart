import 'dice_pool.dart';

class ActionResultDiceGroupViewData {
  final String notation;

  final List<int> rolls;

  const ActionResultDiceGroupViewData({
    required this.notation,
    required this.rolls,
  });

  factory ActionResultDiceGroupViewData.fromGroup(DiceGroupRoll group) {
    return ActionResultDiceGroupViewData(
      notation: group.pool.notation,
      rolls: List<int>.unmodifiable(group.rolls),
    );
  }

  bool get hasRolls {
    return rolls.isNotEmpty;
  }

  int get rolledTotal {
    return rolls.fold<int>(0, (sum, roll) => sum + roll);
  }

  String get rollsText {
    if (rolls.isEmpty) {
      return '—';
    }

    return rolls.join(', ');
  }
}
