import '../models/action_saving_throw.dart';

import 'action_dice_resolver.dart';

class ActionSavingThrowResolver {
  const ActionSavingThrowResolver();

  ActionSavingThrowResult resolve({
    required ActionSavingThrowRequest request,
    required int naturalRoll,
    required int modifier,
  }) {
    if (naturalRoll < 1 || naturalRoll > 20) {
      throw ArgumentError.value(
        naturalRoll,
        'naturalRoll',
        'La tirada natural debe estar entre 1 y 20.',
      );
    }

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
    const diceResolver = ActionDiceResolver();

    final naturalRoll = diceResolver.rollDigitalD20();

    return resolve(
      request: request,
      naturalRoll: naturalRoll,
      modifier: modifier,
    );
  }
}
