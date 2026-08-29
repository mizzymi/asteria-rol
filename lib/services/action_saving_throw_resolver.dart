import '../models/action_saving_throw.dart';
import '../models/dice_pool.dart';

class ActionSavingThrowResolver {
  const ActionSavingThrowResolver();

  ActionSavingThrowResult resolve({
    required ActionSavingThrowRequest request,
    required int naturalRoll,
    required int modifier,
  }) {
    final total = naturalRoll + modifier;

    return ActionSavingThrowResult(
      request: request,
      naturalRoll: naturalRoll,
      modifier: modifier,
      total: total,
      saved: total >= request.dc,
    );
  }

  ActionSavingThrowResult rollDigital({
    required ActionSavingThrowRequest request,
    required int modifier,
  }) {
    final result = DicePoolRoller.roll(
      pools: [DicePool(count: 1, sides: 20)],
    );

    final naturalRoll = result.groups.first.rolls.first;

    return resolve(
      request: request,
      naturalRoll: naturalRoll,
      modifier: modifier,
    );
  }
}
