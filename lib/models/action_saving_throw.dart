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

  /// Resultado natural del d20.
  ///
  /// Puede ser null en personajes/importaciones antiguas
  /// donde solo se conocía si superó o no.
  final int? naturalRoll;

  /// Modificador utilizado.
  final int? modifier;

  /// Total final de la salvación.
  final int? total;

  /// true = el objetivo superó la salvación.
  final bool saved;

  const ActionSavingThrowResult({
    required this.request,
    required this.saved,
    this.naturalRoll,
    this.modifier,
    this.total,
  });
}
