import 'dart:math';

import '../models/action_chance_check.dart';

class ActionChanceResolver {
  final Random _random;

  ActionChanceResolver({Random? random}) : _random = random ?? Random();

  ActionChanceResult rollDigital(ActionChanceCheck check) {
    if (check.alwaysSucceeds) {
      return ActionChanceResult(check: check, roll: 100, success: true);
    }

    if (check.impossible) {
      return ActionChanceResult(check: check, roll: 1, success: false);
    }

    final roll = _random.nextInt(100) + 1;

    return ActionChanceResult(
      check: check,
      roll: roll,
      success: roll <= check.normalizedChance,
    );
  }

  ActionChanceResult resolvePhysical({
    required ActionChanceCheck check,
    required int roll,
  }) {
    if (roll < 1 || roll > 100) {
      throw ArgumentError.value(
        roll,
        'roll',
        'La tirada debe estar entre 1 y 100.',
      );
    }

    return ActionChanceResult(
      check: check,
      roll: roll,
      success: roll <= check.normalizedChance,
    );
  }
}
