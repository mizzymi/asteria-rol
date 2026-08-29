import 'action_dice_request.dart';
import 'dice_pool.dart';
import 'ability.dart';

class ActionDiceResult {
  final List<ActionDicePartResult> parts;

  const ActionDiceResult({
    this.parts = const [],
  });

  // ===========================================================================
  // TOTAL
  // ===========================================================================

  int get total {
    return parts.fold<int>(
      0,
          (sum, part) => sum + part.total,
    );
  }

  bool get isEmpty => parts.isEmpty;

  bool get isNotEmpty => parts.isNotEmpty;

  // ===========================================================================
  // LOOKUPS
  // ===========================================================================

  ActionDicePartResult? partById(
      String id,
      ) {
    for (final part in parts) {
      if (part.request.id == id) {
        return part;
      }
    }

    return null;
  }

  List<ActionDicePartResult> partsForEffect(
      String effectId,
      ) {
    return parts
        .where(
          (part) =>
      part.request.effectId ==
          effectId,
    )
        .toList(growable: false);
  }

  List<ActionDicePartResult> partsForSource(
      ActionDiceSourceType sourceType,
      ) {
    return parts
        .where(
          (part) =>
      part.request.sourceType ==
          sourceType,
    )
        .toList(growable: false);
  }

  List<ActionDicePartResult> partsForEffectType(
      AbilityEffectType effectType,
      ) {
    return parts
        .where(
          (part) =>
      part.request.effectType ==
          effectType,
    )
        .toList(growable: false);
  }

  // ===========================================================================
  // TOTALES
  // ===========================================================================

  int totalForEffectType(
      AbilityEffectType effectType,
      ) {
    return parts
        .where(
          (part) =>
      part.request.effectType ==
          effectType,
    )
        .fold<int>(
      0,
          (sum, part) =>
      sum + part.total,
    );
  }

  int totalForEffect(
      String effectId,
      ) {
    return parts
        .where(
          (part) =>
      part.request.effectId ==
          effectId,
    )
        .fold<int>(
      0,
          (sum, part) =>
      sum + part.total,
    );
  }

  int totalForSource(
      ActionDiceSourceType sourceType,
      ) {
    return parts
        .where(
          (part) =>
      part.request.sourceType ==
          sourceType,
    )
        .fold<int>(
      0,
          (sum, part) =>
      sum + part.total,
    );
  }

  int totalForSourceId(
      String sourceId,
      ) {
    return parts
        .where(
          (part) =>
      part.request.sourceId ==
          sourceId,
    )
        .fold<int>(
      0,
          (sum, part) =>
      sum + part.total,
    );
  }

  // ===========================================================================
  // CRÍTICO
  // ===========================================================================

  int get criticalExtraTotal {
    return parts
        .where(
          (part) =>
      part.request.kind ==
          ActionDicePartKind.criticalExtra,
    )
        .fold<int>(
      0,
          (sum, part) =>
      sum + part.total,
    );
  }
}

class ActionDicePartResult {
  final ActionDiceRequestPart request;

  final DiceCalculationResult result;

  const ActionDicePartResult({
    required this.request,
    required this.result,
  });

  // ===========================================================================
  // DESGLOSE
  // ===========================================================================

  int get rolledTotal {
    return result.total;
  }

  int get automaticValue {
    return request.automaticValue;
  }

  int get total {
    return rolledTotal + automaticValue;
  }

  bool get hasAutomaticValue {
    return automaticValue != 0;
  }

  bool get isCriticalExtra {
    return request.kind ==
        ActionDicePartKind.criticalExtra;
  }

  bool get hasValue {
    return total != 0 ||
        request.requiresRoll;
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