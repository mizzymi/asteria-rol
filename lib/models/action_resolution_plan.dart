import 'ability.dart';
import 'ability_effect_part.dart';
import 'action_cost.dart';
import 'action_definition.dart';
import 'action_external_requirement.dart';
import 'action_content.dart';

class ActionResolutionPlan {
  /// TEMPORAL.
  ///
  /// Lo conservamos mientras queden APIs antiguas que
  /// necesitan CharacterAbility completa.
  final CharacterAbility? ability;

  final ActionDefinition definition;

  final ActionContent content;

  final List<AbilityEffectPart> automaticParts;

  final List<AbilityEffectPart> optionalParts;

  final List<ActionExternalRequirement> externalRequirements;

  final List<ActionCost> costs;

  const ActionResolutionPlan({
    this.ability,
    required this.definition,
    required this.content,
    this.automaticParts = const [],
    this.optionalParts = const [],
    this.externalRequirements = const [],
    this.costs = const [],
  });

  bool get hasAbility => ability != null;

  CharacterAbility get requireAbility {
    final value = ability;

    if (value == null) {
      throw StateError('Este plan no procede de una habilidad.');
    }

    return value;
  }
}
