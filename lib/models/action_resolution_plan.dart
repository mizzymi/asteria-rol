import 'ability.dart';
import 'ability_effect_part.dart';
import 'action_cost.dart';
import 'action_external_requirement.dart';

class ActionResolutionPlan {
  final CharacterAbility ability;

  final List<AbilityEffectPart> automaticParts;

  final List<AbilityEffectPart> optionalParts;

  final List<ActionExternalRequirement> externalRequirements;

  final List<ActionCost> costs;

  const ActionResolutionPlan({
    required this.ability,
    this.automaticParts = const [],
    this.optionalParts = const [],
    this.externalRequirements = const [],
    this.costs = const [],
  });

  List<AbilityEffectPart> get allAvailableParts {
    return [...automaticParts, ...optionalParts];
  }

  bool get hasOptionalParts {
    return optionalParts.isNotEmpty;
  }

  bool get needsExternalInformation {
    return externalRequirements.isNotEmpty;
  }

  bool get hasCosts {
    return costs.isNotEmpty;
  }
}
