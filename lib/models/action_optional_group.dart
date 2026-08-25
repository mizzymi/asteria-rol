import 'ability_effect_part.dart';
import 'action_cost.dart';

class ActionOptionalGroup {
  final String id;

  final String label;

  final List<AbilityEffectPart> parts;

  final List<ActionCost> costs;

  const ActionOptionalGroup({
    required this.id,
    required this.label,
    required this.parts,
    required this.costs,
  });

  bool get hasCosts => costs.isNotEmpty;
}
