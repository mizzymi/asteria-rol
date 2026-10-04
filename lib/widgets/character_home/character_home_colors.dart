import 'package:flutter/material.dart';

import '../../theme/asteria_semantic_colors.dart';

class CharacterHomeColors {
  const CharacterHomeColors._();

  static Color health(BuildContext context) =>
      Theme.of(context).colorScheme.error;
  static Color armor(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color initiative(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;
  static Color speed(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary;
  static Color proficiency(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static AsteriaSemanticColors _semantic(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AsteriaSemanticColors>() ??
        AsteriaSemanticColors.asteria(theme.colorScheme);
  }

  static Color stats(BuildContext context) => _semantic(context).stats;
  static Color abilities(BuildContext context) => _semantic(context).abilities;
  static Color effects(BuildContext context) => _semantic(context).effects;
  static Color counters(BuildContext context) => _semantic(context).counters;
  static Color items(BuildContext context) => _semantic(context).items;
  static Color story(BuildContext context) => _semantic(context).story;
  static Color journal(BuildContext context) => _semantic(context).journal;

  // Los recursos conservan su paleta actual en todos los temas.
  static Color resources(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  static Color dice(BuildContext context) => _semantic(context).dice;
  static Color knowledge(BuildContext context) => _semantic(context).knowledge;

  static Color combat(BuildContext context) => _semantic(context).combat;
  static Color rest(BuildContext context) => _semantic(context).rest;
  static Color notes(BuildContext context) => _semantic(context).notes;

  static Color panel(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).colorScheme.surfaceContainerLow
      : Theme.of(context).colorScheme.surface;
  static Color elevatedPanel(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).colorScheme.surfaceContainer
      : Theme.of(context).colorScheme.surfaceContainerLow;
  static Color border(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;

  static Color tintedSurface(
    BuildContext context,
    Color accent, {
    double lightStrength = 0.10,
    double darkStrength = 0.10,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = isDark
        ? theme.colorScheme.surfaceContainerLow
        : theme.colorScheme.surface;
    final strength = isDark ? darkStrength : lightStrength;
    return Color.lerp(base, accent, strength) ?? base;
  }

  static Color tintedBorder(
    BuildContext context,
    Color accent, {
    double lightAlpha = 0.20,
    double darkAlpha = 0.32,
  }) {
    final theme = Theme.of(context);
    return accent.withValues(
      alpha: theme.brightness == Brightness.dark ? darkAlpha : lightAlpha,
    );
  }
}
