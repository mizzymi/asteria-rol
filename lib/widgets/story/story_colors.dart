import 'package:flutter/material.dart';

import '../../theme/asteria_semantic_colors.dart';

class StoryColors {
  const StoryColors._();

  static AsteriaSemanticColors _semantic(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AsteriaSemanticColors>() ??
        AsteriaSemanticColors.asteria(theme.colorScheme);
  }

  static Color backstory(BuildContext context) {
    final semantic = _semantic(context);
    return semantic.isRainbow
        ? semantic.story
        : Theme.of(context).colorScheme.primary;
  }

  static Color appearance(BuildContext context) {
    final semantic = _semantic(context);
    return semantic.isRainbow
        ? semantic.library
        : Theme.of(context).colorScheme.secondary;
  }

  static Color personality(BuildContext context) {
    final semantic = _semantic(context);
    return semantic.isRainbow
        ? semantic.neutral
        : Theme.of(context).colorScheme.tertiary;
  }

  static Color ideals(BuildContext context) {
    final semantic = _semantic(context);
    return semantic.isRainbow
        ? semantic.condition
        : Theme.of(context).colorScheme.secondary;
  }

  static Color bonds(BuildContext context) {
    final semantic = _semantic(context);
    return semantic.isRainbow
        ? semantic.journal
        : Theme.of(context).colorScheme.tertiary;
  }

  static Color flaws(BuildContext context) {
    final semantic = _semantic(context);
    return semantic.isRainbow
        ? semantic.negative
        : Theme.of(context).colorScheme.error;
  }

  static Color goals(BuildContext context) {
    final semantic = _semantic(context);
    return semantic.isRainbow
        ? semantic.create
        : Theme.of(context).colorScheme.primary;
  }

  static Color notes(BuildContext context) {
    final semantic = _semantic(context);
    return semantic.isRainbow
        ? semantic.notes
        : Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static Color background(
    BuildContext context,
    Color color, {
    double strength = 0.12,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Color.lerp(scheme.surface, color, strength) ?? scheme.surface;
  }
}
