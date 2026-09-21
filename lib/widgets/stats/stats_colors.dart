import 'package:flutter/material.dart';

import '../../models/skill.dart';
import '../../theme/attribute_palette.dart';

class StatsColors {
  const StatsColors._();

  static Color abilityColor(BuildContext context, AbilityType ability) {
    return AttributePalette.of(context, ability);
  }

  static Color softBackground(
    BuildContext context,
    AbilityType ability, {
    double strength = 0.12,
  }) {
    return AttributePalette.soft(context, ability, strength: strength);
  }

  static IconData abilityIcon(AbilityType ability) {
    switch (ability) {
      case AbilityType.strength:
        return Icons.fitness_center_rounded;
      case AbilityType.dexterity:
        return Icons.directions_run_rounded;
      case AbilityType.constitution:
        return Icons.favorite_rounded;
      case AbilityType.intelligence:
        return Icons.psychology_rounded;
      case AbilityType.wisdom:
        return Icons.visibility_rounded;
      case AbilityType.charisma:
        return Icons.auto_awesome_rounded;
    }
  }
}
