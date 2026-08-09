import 'package:flutter/material.dart';

import '../../models/skill.dart';

class StatsColors {
  const StatsColors._();

  static Color abilityColor(AbilityType ability) {
    switch (ability) {
      case AbilityType.strength:
        return const Color(0xFFE85D5D);

      case AbilityType.dexterity:
        return const Color(0xFF55B96B);

      case AbilityType.constitution:
        return const Color(0xFFF29E4C);

      case AbilityType.intelligence:
        return const Color(0xFF4D8FE8);

      case AbilityType.wisdom:
        return const Color(0xFF8B6FE8);

      case AbilityType.charisma:
        return const Color(0xFFE45AA7);
    }
  }

  static Color softBackground(
    BuildContext context,
    AbilityType ability, {
    double strength = 0.12,
  }) {
    return Color.lerp(
          Theme.of(context).colorScheme.surface,
          abilityColor(ability),
          strength,
        ) ??
        abilityColor(ability);
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
