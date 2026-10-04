import 'package:flutter/material.dart';
import '../../models/passive.dart';

class PassiveColors {
  const PassiveColors._();

  static Color sourceColor(BuildContext context, CharacterPassive passive) =>
      Theme.of(context).colorScheme.primary;
  static Color armorClass(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;
  static Color initiative(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;
  static Color speed(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary;
  static Color health(BuildContext context) =>
      Theme.of(context).colorScheme.error;
  static Color attack(BuildContext context) =>
      Theme.of(context).colorScheme.error;
  static Color skill(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color savingThrow(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;

  static Color softBackground(
    BuildContext context,
    Color color, {
    double strength = 0.12,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Color.lerp(scheme.surface, color, strength) ?? scheme.surface;
  }
}
