import 'package:flutter/material.dart';
import '../../models/passive.dart';
import '../../theme/asteria_semantic_colors.dart';

class PassiveColors {
  const PassiveColors._();

  static AsteriaSemanticColors _semantic(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AsteriaSemanticColors>() ??
        AsteriaSemanticColors.asteria(theme.colorScheme);
  }

  static Color sourceColor(BuildContext context, CharacterPassive passive) =>
      _semantic(context).neutral;
  static Color armorClass(BuildContext context) => _semantic(context).settings;
  static Color initiative(BuildContext context) => _semantic(context).condition;
  static Color speed(BuildContext context) => _semantic(context).positive;
  static Color health(BuildContext context) => _semantic(context).negative;
  static Color attack(BuildContext context) => _semantic(context).negative;
  static Color skill(BuildContext context) => _semantic(context).abilities;
  static Color savingThrow(BuildContext context) =>
      _semantic(context).exportAction;

  static Color softBackground(
    BuildContext context,
    Color color, {
    double strength = 0.12,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Color.lerp(scheme.surface, color, strength) ?? scheme.surface;
  }
}
