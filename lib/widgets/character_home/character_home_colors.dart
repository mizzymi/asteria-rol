import 'package:flutter/material.dart';

class CharacterHomeColors {
  const CharacterHomeColors._();

  // ===========================================================================
  // COLORES SEMÁNTICOS
  //
  // Estos identifican conceptos y pueden mantenerse entre temas.
  // ===========================================================================

  static const Color health = Color(0xFFE84A8A);
  static const Color armor = Color(0xFF934DE8);
  static const Color initiative = Color(0xFF4C68F2);
  static const Color speed = Color(0xFF55B9B6);
  static const Color proficiency = Color(0xFF7BE86F);

  static const Color stats = Color(0xFF9B6CE8);
  static const Color abilities = Color(0xFF6C8CD5);
  static const Color effects = Color(0xFF4D8FE8);
  static const Color counters = Color(0xFF42B8C8);
  static const Color items = Color(0xFF18A6A6);
  static const Color story = Color(0xFF55B96B);
  static const Color journal = Color(0xFFF29E4C);
  static const Color resources = Color(0xFFE85D5D);
  static const Color dice = Color(0xFFE45AA7);

  // ===========================================================================
  // ACCIONES RÁPIDAS
  // ===========================================================================

  static const Color combat = Color(0xFFE85D68);
  static const Color rest = Color(0xFF8B6FE8);
  static const Color notes = Color(0xFF42A879);

  // ===========================================================================
  // SUPERFICIES ADAPTATIVAS
  // ===========================================================================

  static Color panel(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainerLow;
  }

  static Color elevatedPanel(BuildContext context) {
    return Theme.of(context).colorScheme.surfaceContainer;
  }

  static Color border(BuildContext context) {
    return Theme.of(context).colorScheme.outlineVariant;
  }

  // ===========================================================================
  // TINTE SEMÁNTICO ADAPTATIVO
  // ===========================================================================

  static Color tintedSurface(
    BuildContext context,
    Color accent, {
    double lightStrength = 0.10,
    double darkStrength = 0.16,
  }) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    return Color.lerp(
          theme.colorScheme.surface,
          accent,
          isDark ? darkStrength : lightStrength,
        ) ??
        theme.colorScheme.surface;
  }

  static Color tintedBorder(
    BuildContext context,
    Color accent, {
    double lightAlpha = 0.20,
    double darkAlpha = 0.32,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return accent.withValues(alpha: isDark ? darkAlpha : lightAlpha);
  }
}
