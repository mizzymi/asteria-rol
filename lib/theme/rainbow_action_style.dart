import 'package:flutter/material.dart';

import 'accessibility_colors.dart';
import 'asteria_semantic_colors.dart';

/// Superficies de acción del tema Rainbow.
///
/// En claro usamos fondos pastel con contenido negro.
/// En oscuro usamos fondos profundos con contenido blanco.
/// El fondo se ajusta automáticamente hasta mantener al menos 5:1 de
/// contraste con ese foreground fijo.
class RainbowActionStyle {
  const RainbowActionStyle._();

  static AsteriaSemanticColors _semantic(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AsteriaSemanticColors>() ??
        AsteriaSemanticColors.asteria(theme.colorScheme);
  }

  static bool enabled(BuildContext context) => _semantic(context).isRainbow;

  static Color foreground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  static Color background(BuildContext context, Color accent) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foregroundColor = dark ? Colors.white : Colors.black;

    // Primer intento: pastel visible en light y versión profunda en dark.
    var background = dark
        ? Color.lerp(const Color(0xFF080808), accent, 0.34)!
        : Color.lerp(Colors.white, accent, 0.34)!;

    if (AccessibilityColors.meets(
      foregroundColor,
      background,
      minimum: 5.0,
    )) {
      return background;
    }

    // Mantenemos el foreground negro/blanco pedido y movemos únicamente
    // el fondo hacia blanco/negro hasta garantizar el contraste mínimo.
    final target = dark ? Colors.black : Colors.white;
    var low = 0.0;
    var high = 1.0;

    for (var i = 0; i < 24; i++) {
      final mid = (low + high) / 2;
      final candidate = Color.lerp(background, target, mid)!;

      if (AccessibilityColors.meets(
        foregroundColor,
        candidate,
        minimum: 5.0,
      )) {
        high = mid;
      } else {
        low = mid;
      }
    }

    background = Color.lerp(background, target, high)!;
    return background;
  }

  static ButtonStyle iconButton(
    BuildContext context,
    Color accent,
  ) {
    if (!enabled(context)) {
      return IconButton.styleFrom(foregroundColor: accent);
    }

    return IconButton.styleFrom(
      backgroundColor: background(context, accent),
      foregroundColor: foreground(context),
    );
  }

  static ButtonStyle filledButton(
    BuildContext context,
    Color accent,
  ) {
    if (!enabled(context)) {
      return FilledButton.styleFrom();
    }

    return FilledButton.styleFrom(
      backgroundColor: background(context, accent),
      foregroundColor: foreground(context),
    );
  }

  static ButtonStyle floatingActionButton(
    BuildContext context,
    Color accent,
  ) {
    if (!enabled(context)) {
      return const ButtonStyle();
    }

    return ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(background(context, accent)),
      foregroundColor: WidgetStatePropertyAll(foreground(context)),
    );
  }
}
