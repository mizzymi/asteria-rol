import 'package:flutter/material.dart';

import '../models/skill.dart';
import 'attribute_palette.dart';
import 'accessibility_colors.dart';

class AbilityColors {
  const AbilityColors._();

  static Color of(BuildContext context, AbilityType ability) {
    return AttributePalette.of(context, ability);
  }

  static Color soft(
    BuildContext context,
    AbilityType ability, {
    double alpha = 0.12,
  }) =>
      of(context, ability).withValues(alpha: alpha);

  static Color border(
    BuildContext context,
    AbilityType ability, {
    double alpha = 0.32,
  }) =>
      of(context, ability).withValues(alpha: alpha);

  static Color foreground(BuildContext context, AbilityType ability) {
    final scheme = Theme.of(context).colorScheme;
    final color = of(context, ability);
    return AccessibilityColors.ensureContrast(
      scheme.onSurface,
      color,
      minimum: 5.0,
    );
  }
}
