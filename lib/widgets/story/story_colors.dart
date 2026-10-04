import 'package:flutter/material.dart';

import '../../theme/asteria_semantic_colors.dart';

class StoryColors {
  const StoryColors._();

  static AsteriaSemanticColors _semantic(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AsteriaSemanticColors>() ??
        AsteriaSemanticColors.asteria(theme.colorScheme);
  }

  static Color backstory(BuildContext context) => _semantic(context).story;
  static Color appearance(BuildContext context) => _semantic(context).library;
  static Color personality(BuildContext context) => _semantic(context).neutral;
  static Color ideals(BuildContext context) => _semantic(context).condition;
  static Color bonds(BuildContext context) => _semantic(context).journal;
  static Color flaws(BuildContext context) => _semantic(context).negative;
  static Color goals(BuildContext context) => _semantic(context).create;
  static Color notes(BuildContext context) => _semantic(context).notes;

  static Color background(
    BuildContext context,
    Color color, {
    double strength = 0.12,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Color.lerp(scheme.surface, color, strength) ?? scheme.surface;
  }
}
