import '../models/action_saving_throw.dart';
import '../models/saving_throw_roll_mode.dart';

import 'action_dice_resolver.dart';

class ActionSavingThrowResolver {
  const ActionSavingThrowResolver();

  ActionSavingThrowResult resolve({
    required ActionSavingThrowRequest request,
    required int naturalRoll,
    int? secondNaturalRoll,
    required int modifier,
  }) {
    void validateRoll(int value, String name) {
      if (value < 1 || value > 20) {
        throw ArgumentError.value(
          value,
          name,
          'La tirada natural debe estar entre 1 y 20.',
        );
      }
    }

    validateRoll(naturalRoll, 'naturalRoll');
    if (secondNaturalRoll != null) {
      validateRoll(secondNaturalRoll, 'secondNaturalRoll');
    }

    var selectedRoll = naturalRoll;

    if (secondNaturalRoll != null) {
      switch (request.rollMode) {
        case SavingThrowRollMode.normal:
          break;
        case SavingThrowRollMode.advantage:
          if (secondNaturalRoll > selectedRoll) {
            selectedRoll = secondNaturalRoll;
          }
          break;
        case SavingThrowRollMode.disadvantage:
          if (secondNaturalRoll < selectedRoll) {
            selectedRoll = secondNaturalRoll;
          }
          break;
      }
    }

    final total = selectedRoll + modifier;

    return ActionSavingThrowResult(
      request: request,
      naturalRoll: selectedRoll,
      secondNaturalRoll: secondNaturalRoll,
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
    final secondNaturalRoll = request.rollMode == SavingThrowRollMode.normal
        ? null
        : diceResolver.rollDigitalD20();

    return resolve(
      request: request,
      naturalRoll: naturalRoll,
      secondNaturalRoll: secondNaturalRoll,
      modifier: modifier,
    );
  }
}
