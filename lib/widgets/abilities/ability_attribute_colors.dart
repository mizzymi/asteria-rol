import 'package:flutter/material.dart';
import '../../models/skill.dart';

class AbilityAttributeColors {
  const AbilityAttributeColors._();

  static Color color(BuildContext context, AbilityType ability) {
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

  static Color background(BuildContext context, AbilityType ability, {double strength = 0.13}) {
    final scheme = Theme.of(context).colorScheme;
    return Color.lerp(scheme.surface, color(context, ability), strength) ?? scheme.surface;
  }

  static Color strongBackground(BuildContext context, AbilityType ability) {
    final scheme = Theme.of(context).colorScheme;
    return Color.lerp(scheme.surface, color(context, ability), 0.24) ?? scheme.surface;
  }
}
