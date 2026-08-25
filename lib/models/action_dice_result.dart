import 'action_dice_request.dart';
import 'dice_pool.dart';
import 'ability.dart';

class ActionDiceResult {
  final List<ActionDicePartResult> parts;

  const ActionDiceResult({this.parts = const []});

  int get total {
    return parts.fold<int>(0, (sum, part) => sum + part.total);
  }

  ActionDicePartResult? partById(String id) {
    for (final part in parts) {
      if (part.request.id == id) {
        return part;
      }
    }

    return null;
  }

  int totalForEffectType(AbilityEffectType effectType) {
    return parts
        .where((part) => part.request.effectType == effectType)
        .fold<int>(0, (sum, part) => sum + part.total);
  }
}

class ActionDicePartResult {
  final ActionDiceRequestPart request;

  final DiceCalculationResult result;

  const ActionDicePartResult({required this.request, required this.result});

  int get total {
    return result.total + request.automaticValue;
  }
}

class ActionPhysicalDiceInput {
  final String requestPartId;

  final List<List<int>> rolls;

  const ActionPhysicalDiceInput({
    required this.requestPartId,
    required this.rolls,
  });
}
