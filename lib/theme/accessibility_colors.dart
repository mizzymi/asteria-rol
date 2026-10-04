import 'package:flutter/material.dart';

/// Helpers para mantener contraste legible entre primer plano y fondo.
///
/// La app usa 5.0:1 como mínimo, algo más exigente que WCAG AA para texto
/// normal. Los acentos se suelen preparar con margen extra para que sigan
/// siendo legibles incluso sobre superficies ligeramente tintadas.
class AccessibilityColors {
  const AccessibilityColors._();

  static double contrastRatio(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static bool meets(
    Color foreground,
    Color background, {
    double minimum = 5.0,
  }) => contrastRatio(foreground, background) >= minimum;

  static Color ensureContrast(
    Color foreground,
    Color background, {
    double minimum = 5.0,
  }) {
    return ensureContrastAgainst(foreground, [background], minimum: minimum);
  }

  static Color ensureContrastAgainst(
    Color foreground,
    Iterable<Color> backgrounds, {
    double minimum = 5.0,
  }) {
    final values = backgrounds.toList(growable: false);
    if (values.isEmpty) return foreground;

    double worst(Color candidate) => values
        .map((background) => contrastRatio(candidate, background))
        .reduce((a, b) => a < b ? a : b);

    if (worst(foreground) >= minimum) return foreground;

    const black = Color(0xFF000000);
    const white = Color(0xFFFFFFFF);
    final blackScore = worst(black);
    final whiteScore = worst(white);
    final target = blackScore >= whiteScore ? black : white;

    // Si ni blanco ni negro alcanzaran el objetivo, devolvemos el mejor.
    if (worst(target) < minimum) return target;

    var low = 0.0;
    var high = 1.0;
    for (var i = 0; i < 24; i++) {
      final mid = (low + high) / 2;
      final candidate = Color.lerp(foreground, target, mid)!;
      if (worst(candidate) >= minimum) {
        high = mid;
      } else {
        low = mid;
      }
    }

    return Color.lerp(foreground, target, high)!;
  }
}
