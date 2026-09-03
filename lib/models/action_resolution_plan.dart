import 'ability_effect_part.dart';
import 'action_cost.dart';
import 'action_definition.dart';
import 'action_external_requirement.dart';
import 'action_content.dart';
import 'action_source.dart';

class ActionResolutionPlan {
  /// Fuente real de la acción.
  ///
  /// El plan ya no necesita almacenar CharacterAbility.
  /// Si alguna compatibilidad legacy necesita acceder a la habilidad,
  /// puede hacerlo a través de [source.ability].
  final ActionSource source;

  final ActionDefinition definition;

  final ActionContent content;

  final List<AbilityEffectPart> automaticParts;

  final List<AbilityEffectPart> optionalParts;

  final List<ActionExternalRequirement> externalRequirements;

  final List<ActionCost> costs;

  const ActionResolutionPlan({
    required this.source,
    required this.definition,
    required this.content,
    this.automaticParts = const [],
    this.optionalParts = const [],
    this.externalRequirements = const [],
    this.costs = const [],
  });

  bool get isAbility => source.isAbility;

  bool get isWeapon => source.isWeapon;
}
