import 'package:flutter/material.dart';

import '../models/skill.dart';
import 'accessibility_colors.dart';

/// Semantic ability palette derived from the active Theme.
///
/// Hue identifies each stat while saturation/lightness follow the current
/// theme so the same identity stays readable in both light and dark mode.
class AttributePalette {
  const AttributePalette._();

  static Color of(BuildContext context, AbilityType ability) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primary = HSLColor.fromColor(scheme.primary);

    final hue = switch (ability) {
      AbilityType.strength => 4.0, // rojo
      AbilityType.dexterity => 330.0, // rosa
      AbilityType.constitution => 292.0, // lila
      AbilityType.intelligence => 266.0, // violeta
      AbilityType.wisdom => 218.0, // azul
      AbilityType.charisma => 174.0, // turquesa
    };

    final saturation = (primary.saturation + 0.26).clamp(0.72, 0.96).toDouble();
    final lightness = isDark ? 0.72 : 0.42;

    final candidate = HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
    final strongestSoft = Color.lerp(scheme.surface, candidate, 0.24) ?? scheme.surface;
    return AccessibilityColors.ensureContrastAgainst(
      candidate,
      [
        scheme.surface,
        scheme.surfaceContainerLow,
        scheme.surfaceContainerHigh,
        strongestSoft,
      ],
      minimum: 5.4,
    );
  }

  static Color soft(
    BuildContext context,
    AbilityType ability, {
    double strength = 0.12,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Color.lerp(scheme.surface, of(context, ability), strength) ??
        scheme.surface;
  }
}
