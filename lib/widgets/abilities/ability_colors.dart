import 'package:flutter/material.dart';

import '../../models/ability.dart';

class AbilityColors {
  const AbilityColors._();

  // ===========================================================================
  // EFECTOS
  // ===========================================================================

  static Color effectColor(BuildContext context, AbilityEffect effect) {
    final damageType = effect.effectTypeName.toLowerCase();

    if (effect.heals) {
      return const Color(0xFF00A504);
    }

    if (damageType.contains('fuego') || damageType.contains('fire')) {
      return const Color(0xFFF97316);
    }

    if (damageType.contains('hielo') ||
        damageType.contains('frío') ||
        damageType.contains('frio') ||
        damageType.contains('ice') ||
        damageType.contains('cold')) {
      return const Color(0xFF32BFE8);
    }

    if (damageType.contains('veneno') || damageType.contains('poison')) {
      return const Color(0xFF4A1483);
    }

    if (damageType.contains('ácido') ||
        damageType.contains('acido') ||
        damageType.contains('acid')) {
      return const Color(0xFF9BC53D);
    }

    if (damageType.contains('rayo') ||
        damageType.contains('eléctrico') ||
        damageType.contains('electrico') ||
        damageType.contains('lightning')) {
      return const Color(0xFFF2C94C);
    }

    if (damageType.contains('necrótico') ||
        damageType.contains('necrotico') ||
        damageType.contains('necrotic')) {
      return const Color(0xFF2E0370);
    }

    if (damageType.contains('radiante') || damageType.contains('radiant')) {
      return const Color(0xFFFFB74D);
    }

    if (damageType.contains('psíquico') ||
        damageType.contains('psiquico') ||
        damageType.contains('psychic')) {
      return const Color(0xFFE35DBF);
    }

    if (effect.usesSavingThrow) {
      return const Color(0xFF8B5CF6);
    }

    if (effect.dealsDamage) {
      return const Color(0xFFEF5D6C);
    }

    return Theme.of(context).colorScheme.primary;
  }

  // ===========================================================================
  // FONDOS SUAVES
  // ===========================================================================

  static Color softBackground(
    BuildContext context,
    Color color, {
    double strength = 0.16,
  }) {
    return Color.lerp(Theme.of(context).colorScheme.surface, color, strength) ??
        color;
  }

  static Color strongerBackground(BuildContext context, Color color) {
    return Color.lerp(Theme.of(context).colorScheme.surface, color, 0.26) ??
        color;
  }

  // ===========================================================================
  // ICONOS
  // ===========================================================================

  static IconData effectIcon(AbilityEffect effect) {
    final damageType = effect.effectTypeName.toLowerCase();

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
