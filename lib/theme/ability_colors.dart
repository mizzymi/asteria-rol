import 'package:flutter/material.dart';
import '../models/skill.dart';

class AbilityColors {
  const AbilityColors._();

  static Color of(BuildContext context, AbilityType ability) {
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

  static Color soft(BuildContext context, AbilityType ability, {double alpha = 0.12}) => of(context, ability).withValues(alpha: alpha);
  static Color border(BuildContext context, AbilityType ability, {double alpha = 0.32}) => of(context, ability).withValues(alpha: alpha);
  static Color foreground(BuildContext context, AbilityType ability) {
    final scheme = Theme.of(context).colorScheme;
    final color = of(context, ability);
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? scheme.onPrimary : scheme.onSurface;
  }
}
