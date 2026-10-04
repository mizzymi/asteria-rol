import 'package:flutter/material.dart';

import '../../models/ability.dart';
import '../../theme/asteria_semantic_colors.dart';

class AbilityColors {
  const AbilityColors._();

  static Color effectColor(BuildContext context, AbilityEffect effect) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final semantic =
        theme.extension<AsteriaSemanticColors>() ??
        AsteriaSemanticColors.asteria(scheme);
    final damageType = effect.effectTypeName.toLowerCase();

    if (effect.mitigatesDamage) {
      return semantic.settings;
    }
    if (effect.heals) {
      return semantic.positive;
    }

    if (damageType.contains('fuego') || damageType.contains('fire')) {
      return semantic.negative;
    }
    if (damageType.contains('hielo') ||
        damageType.contains('frío') ||
        damageType.contains('frio') ||
        damageType.contains('ice') ||
        damageType.contains('cold')) {
      return semantic.settings;
    }
    if (damageType.contains('veneno') || damageType.contains('poison')) {
      return semantic.negative;
    }
    if (damageType.contains('ácido') ||
        damageType.contains('acido') ||
        damageType.contains('acid')) {
      return semantic.condition;
    }
    if (damageType.contains('rayo') ||
        damageType.contains('eléctrico') ||
        damageType.contains('electrico') ||
        damageType.contains('lightning')) {
      return semantic.condition;
    }
    if (damageType.contains('necrótico') ||
        damageType.contains('necrotico') ||
        damageType.contains('necrotic')) {
      return semantic.neutral;
    }
    if (damageType.contains('radiante') || damageType.contains('radiant')) {
      return semantic.condition;
    }
    if (damageType.contains('psíquico') ||
        damageType.contains('psiquico') ||
        damageType.contains('psychic')) {
      return semantic.neutral;
    }
    if (effect.usesSavingThrow) {
      return semantic.settings;
    }
    if (effect.dealsDamage) {
      return semantic.negative;
    }
    return semantic.abilities;
  }

  static Color softBackground(
    BuildContext context,
    Color color, {
    double strength = 0.16,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Color.lerp(scheme.surface, color, strength) ?? scheme.surface;
  }

  static Color strongerBackground(BuildContext context, Color color) {
    final scheme = Theme.of(context).colorScheme;
    return Color.lerp(scheme.surface, color, 0.26) ?? scheme.surface;
  }

  static IconData effectIcon(AbilityEffect effect) {
    final damageType = effect.effectTypeName.toLowerCase();
    if (effect.mitigatesDamage) {
      return Icons.shield_rounded;
    }
    if (effect.heals) {
      return Icons.favorite_rounded;
    }
    if (damageType.contains('fuego')) {
      return Icons.local_fire_department_rounded;
    }
    if (damageType.contains('hielo') ||
        damageType.contains('frío') ||
        damageType.contains('frio')) {
      return Icons.ac_unit_rounded;
    }
    if (damageType.contains('veneno')) {
      return Icons.coronavirus_rounded;
    }
    if (damageType.contains('rayo') ||
        damageType.contains('eléctrico') ||
        damageType.contains('electrico')) {
      return Icons.bolt_rounded;
    }
    if (damageType.contains('necrótico') || damageType.contains('necrotico')) {
      return Icons.dark_mode_rounded;
    }
    if (damageType.contains('radiante')) {
      return Icons.wb_sunny_rounded;
    }
    if (damageType.contains('psíquico') || damageType.contains('psiquico')) {
      return Icons.psychology_alt_rounded;
    }
    if (effect.usesSavingThrow) {
      return Icons.shield_rounded;
    }
    return Icons.flash_on_rounded;
  }
}
