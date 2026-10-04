import 'ability.dart';
import 'skill.dart';
import 'saving_throw_roll_mode.dart';

class ActionSavingThrowRequest {
  final String id;

  final String targetId;

  final String effectId;

  final String effectName;

  final AbilityType ability;

  final int dc;

  final SaveSuccessEffect successEffect;

  /// Modo de la tirada cuando la salvación corresponde al propio personaje.
  final SavingThrowRollMode rollMode;

  const ActionSavingThrowRequest({
    required this.id,
    required this.targetId,
    required this.effectId,
    required this.effectName,
    required this.ability,
    required this.dc,
    required this.successEffect,
    this.rollMode = SavingThrowRollMode.normal,
  });
}

class ActionSavingThrowResult {
  final ActionSavingThrowRequest request;

  /// Dado finalmente utilizado.
  final int? naturalRoll;

  /// Segundo d20 cuando existe ventaja/desventaja.
  final int? secondNaturalRoll;

  final int? modifier;

  final int? total;

  final bool saved;

  const ActionSavingThrowResult({
    required this.request,
    this.naturalRoll,
    this.secondNaturalRoll,
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

  final int? secondNaturalRoll;

  const ActionPhysicalSavingThrowInput({
    required this.requestId,
    required this.naturalRoll,
    this.secondNaturalRoll,
  });
}
