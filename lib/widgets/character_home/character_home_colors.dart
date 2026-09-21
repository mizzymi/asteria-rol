import 'package:flutter/material.dart';

class CharacterHomeColors {
  const CharacterHomeColors._();

  static Color health(BuildContext context) => Theme.of(context).colorScheme.error;
  static Color armor(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color initiative(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color speed(BuildContext context) => Theme.of(context).colorScheme.tertiary;
  static Color proficiency(BuildContext context) => Theme.of(context).colorScheme.primary;

  static Color stats(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color abilities(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color effects(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color counters(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color items(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color story(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color journal(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color resources(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color dice(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color knowledge(BuildContext context) => Theme.of(context).colorScheme.primary;

  static Color combat(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color rest(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color notes(BuildContext context) => Theme.of(context).colorScheme.primary;

  static Color panel(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerLow;
  static Color elevatedPanel(BuildContext context) => Theme.of(context).colorScheme.surfaceContainer;
  static Color border(BuildContext context) => Theme.of(context).colorScheme.outlineVariant;

  static Color tintedSurface(
    BuildContext context,
    Color accent, {
    double lightStrength = 0.10,
    double darkStrength = 0.16,
  }) {
    final theme = Theme.of(context);
    final strength = theme.brightness == Brightness.dark ? darkStrength : lightStrength;
    return Color.lerp(theme.colorScheme.surface, accent, strength) ?? theme.colorScheme.surface;
  }

  static Color tintedBorder(
    BuildContext context,
    Color accent, {
    double lightAlpha = 0.20,
    double darkAlpha = 0.32,
  }) {
    final theme = Theme.of(context);
    return accent.withValues(alpha: theme.brightness == Brightness.dark ? darkAlpha : lightAlpha);
  }
}
