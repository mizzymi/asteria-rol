import 'ability.dart';
import 'action_cost.dart';
import 'action_critical_profile.dart';
import 'action_resolution_context.dart';
import 'action_resolution_plan.dart';
import 'action_source.dart';
import 'action_definition.dart';

class PreparedActionResolution {
  final CharacterAbility ability;

  final ActionResolutionContext context;

  final ActionResolutionPlan plan;

  final ActionCriticalProfile criticalProfile;

  final List<ActionCost> costs;

  final ActionSource source;

  final ActionDefinition definition;

  const PreparedActionResolution({
    required this.source,
    required this.definition,
    required this.ability,
    required this.context,
    required this.plan,
    required this.criticalProfile,
    this.costs = const [],
  });
}
