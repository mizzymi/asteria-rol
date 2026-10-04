import 'package:flutter/material.dart';

import 'accessibility_colors.dart';

class ResourcePalette {
  const ResourcePalette._();

  static const List<String> labels = [
    'Rosa',
    'Rojo',
    'Naranja',
    'Amarillo',
    'Verde',
    'Turquesa',
    'Azul',
    'Morado',
    'Lila',
  ];

  static List<Color> colors(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primaryHsl = HSLColor.fromColor(scheme.primary);

    Color themedHue(double hue, {double saturationBoost = 0}) {
      final saturation = (primaryHsl.saturation + 0.28 + saturationBoost)
          .clamp(0.68, 0.96)
          .toDouble();
      final lightness = isDark ? 0.72 : 0.42;

      final candidate = HSLColor.fromAHSL(
        1,
        hue,
        saturation,
        lightness,
      ).toColor();
      final soft =
          Color.lerp(scheme.surface, candidate, 0.18) ?? scheme.surface;
      return AccessibilityColors.ensureContrastAgainst(candidate, [
        scheme.surface,
        scheme.surfaceContainerLow,
        soft,
      ], minimum: 5.4);
    }

    final lilacBase = HSLColor.fromColor(scheme.primary);
    final lilac = HSLColor.fromAHSL(
      1,
      lilacBase.hue,
      (lilacBase.saturation + 0.22).clamp(0.72, 0.96).toDouble(),
      isDark ? 0.74 : 0.44,
    ).toColor();
    final readableLilac = AccessibilityColors.ensureContrastAgainst(lilac, [
      scheme.surface,
      scheme.surfaceContainerLow,
      Color.lerp(scheme.surface, lilac, 0.18) ?? scheme.surface,
    ], minimum: 5.4);

    return [
      themedHue(330),
      themedHue(4),
      themedHue(28),
      themedHue(49, saturationBoost: 0.04),
      themedHue(132),
      themedHue(174),
      themedHue(218),
      themedHue(278),
      readableLilac,
    ];
  }

  static Color colorFor(BuildContext context, int value) {
    final palette = colors(context);
    return palette[value.abs() % palette.length];
  }
}
