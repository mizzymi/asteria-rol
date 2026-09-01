import 'ability.dart';
import 'skill.dart';

class ActionSavingThrowRequest {
  final String id;

  final String targetId;

  final String effectId;

  final String effectName;

  final AbilityType ability;

  final int dc;

  final SaveSuccessEffect successEffect;

  const ActionSavingThrowRequest({
    required this.id,
    required this.targetId,
    required this.effectId,
    required this.effectName,
    required this.ability,
    required this.dc,
    required this.successEffect,
  });
}

class ActionSavingThrowResult {
  final ActionSavingThrowRequest request;

  final int? naturalRoll;

  final int? modifier;

  final int? total;

  final bool saved;

  const ActionSavingThrowResult({
    required this.request,
    this.naturalRoll,
    this.modifier,
    this.total,
    required this.saved,
  });

  const ActionSavingThrowResult.external({
    required ActionSavingThrowRequest request,
    required bool saved,
  }) : this(request: request, saved: saved);

  bool get hasRollDetails {
    return naturalRoll != null && modifier != null && total != null;
  }
}

class ActionPhysicalSavingThrowInput {
  final String requestId;

  final int naturalRoll;

  const ActionPhysicalSavingThrowInput({
    required this.requestId,
    required this.naturalRoll,
  });
}
