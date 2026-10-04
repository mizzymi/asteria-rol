import 'package:flutter/material.dart';

class StoryColors {
  const StoryColors._();

  static Color backstory(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color appearance(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;
  static Color personality(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary;
  static Color ideals(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;
  static Color bonds(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary;
  static Color flaws(BuildContext context) =>
      Theme.of(context).colorScheme.error;
  static Color goals(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color notes(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static Color background(
    BuildContext context,
    Color color, {
    double strength = 0.12,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Color.lerp(scheme.surface, color, strength) ?? scheme.surface;
  }
}
