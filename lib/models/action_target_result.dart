import 'ability.dart';
import 'action_dice_result.dart';
import 'action_resolution_context.dart';
import 'action_saving_throw.dart';
import 'action_effect_result.dart';

class ActionTargetResult {
  final ActionTarget target;

  final ActionDiceResult diceResult;

  final List<ActionSavingThrowResult> savingThrows;

  final List<ActionEffectResult> effects;

  const ActionTargetResult({
    required this.target,
    required this.diceResult,
    this.savingThrows = const [],
    this.effects = const [],
  });

  bool get hasEffects => effects.isNotEmpty;

  int _totalForEffectType(AbilityEffectType effectType) {
    final relevantParts = diceResult.parts.where(
      (part) => part.request.effectType == effectType,
    );

    final grouped = <String, int>{};

    var independentBonuses = 0;

    for (final part in relevantParts) {
      final effectId = part.request.effectId;

      final belongsToAbilityEffect =
          effectId != 'damage_bonus' &&
          effectId != 'healing_bonus' &&
          effectId != 'critical_extra';

      if (!belongsToAbilityEffect) {
        independentBonuses += part.total;
        continue;
      }

      grouped[effectId] = (grouped[effectId] ?? 0) + part.total;
    }

    var total = independentBonuses;

    for (final entry in grouped.entries) {
      total += _applySavingThrow(effectId: entry.key, total: entry.value);
    }

    return total;
  }

  int _applySavingThrow({required String effectId, required int total}) {
    ActionSavingThrowResult? save;

    for (final result in savingThrows) {
      if (result.request.effectId == effectId &&
          result.request.targetId == target.id) {
        save = result;
        break;
      }
    }

    if (save == null || !save.saved) {
      return total;
    }

    switch (save.request.successEffect) {
      case SaveSuccessEffect.full:
        return total;

      case SaveSuccessEffect.half:
        return total ~/ 2;

      case SaveSuccessEffect.none:
        return 0;
    }
  }

  int get damage {
    return _totalForEffectType(AbilityEffectType.damage);
  }

  int get healing {
    return _totalForEffectType(AbilityEffectType.healing);
  }

  bool get dealtDamage => damage > 0;

  bool get healed => healing > 0;
}
