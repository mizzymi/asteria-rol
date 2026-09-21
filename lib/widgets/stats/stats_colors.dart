import 'package:flutter/material.dart';
import '../../models/skill.dart';

class StatsColors {
  const StatsColors._();

  static Color abilityColor(BuildContext context, AbilityType ability) {
    final scheme = Theme.of(context).colorScheme;
    switch (ability) {
      case AbilityType.strength: return scheme.error;
      case AbilityType.dexterity: return scheme.tertiary;
      case AbilityType.constitution: return scheme.secondary;
      case AbilityType.intelligence: return scheme.secondary;
      case AbilityType.wisdom: return scheme.primary;
      case AbilityType.charisma: return scheme.tertiary;
    }
  }

  static Color softBackground(BuildContext context, AbilityType ability, {double strength = 0.12}) {
    final scheme = Theme.of(context).colorScheme;
    return Color.lerp(scheme.surface, abilityColor(context, ability), strength) ?? scheme.surface;
  }

  static IconData abilityIcon(AbilityType ability) {
    switch (ability) {
      case AbilityType.strength: return Icons.fitness_center_rounded;
      case AbilityType.dexterity: return Icons.directions_run_rounded;
      case AbilityType.constitution: return Icons.favorite_rounded;
      case AbilityType.intelligence: return Icons.psychology_rounded;
      case AbilityType.wisdom: return Icons.visibility_rounded;
      case AbilityType.charisma: return Icons.auto_awesome_rounded;
    }
  }
}
