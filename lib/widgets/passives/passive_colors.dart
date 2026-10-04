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

  static Color sourceColor(BuildContext context, CharacterPassive passive) {
    final semantic = _semantic(context);
    return semantic.isRainbow
        ? semantic.neutral
        : Theme.of(context).colorScheme.primary;
  }

  static Color armorClass(BuildContext context) {
    final semantic = _semantic(context);
    return semantic.isRainbow
        ? semantic.settings
        : Theme.of(context).colorScheme.secondary;
  }

  static Color initiative(BuildContext context) {
    final semantic = _semantic(context);
    return semantic.isRainbow
        ? semantic.condition
        : Theme.of(context).colorScheme.secondary;
  }

  static Color speed(BuildContext context) {
    final semantic = _semantic(context);
    return semantic.isRainbow
        ? semantic.positive
        : Theme.of(context).colorScheme.tertiary;
  }

  static Color health(BuildContext context) {
    final semantic = _semantic(context);
    return semantic.isRainbow
        ? semantic.negative
        : Theme.of(context).colorScheme.error;
  }

  static Color attack(BuildContext context) {
    final semantic = _semantic(context);
    return semantic.isRainbow
        ? semantic.negative
        : Theme.of(context).colorScheme.error;
  }

  static Color skill(BuildContext context) {
    final semantic = _semantic(context);
    return semantic.isRainbow
        ? semantic.abilities
        : Theme.of(context).colorScheme.primary;
  }

  static Color savingThrow(BuildContext context) {
    final semantic = _semantic(context);
    return semantic.isRainbow
        ? semantic.exportAction
        : Theme.of(context).colorScheme.secondary;
  }

  static Color softBackground(
    BuildContext context,
    Color color, {
    double strength = 0.12,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Color.lerp(scheme.surface, color, strength) ?? scheme.surface;
  }
}
