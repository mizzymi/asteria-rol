import 'package:flutter/material.dart';
import '../models/item_definition.dart';
import 'asteria_semantic_colors.dart';

class ItemTypeColors {
  const ItemTypeColors._();

  static Color of(BuildContext context, ItemType type) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final semantic =
        theme.extension<AsteriaSemanticColors>() ??
        AsteriaSemanticColors.asteria(scheme);

    if (!semantic.isRainbow) {
      switch (type) {
        case ItemType.armor:
        case ItemType.shield:
        case ItemType.helmet:
          return scheme.primary;
        case ItemType.gloves:
        case ItemType.ring:
        case ItemType.amulet:
          return scheme.secondary;
        case ItemType.boots:
        case ItemType.cape:
        case ItemType.accessory:
          return scheme.tertiary;
        case ItemType.weapon:
        case ItemType.ammunition:
          return scheme.error;
        case ItemType.consumable:
        case ItemType.potion:
        case ItemType.scroll:
        case ItemType.book:
          return scheme.secondary;
        case ItemType.tool:
        case ItemType.material:
          return scheme.tertiary;
        case ItemType.special:
          return scheme.primary;
        case ItemType.container:
        case ItemType.misc:
          return scheme.onSurfaceVariant;
      }
    }

    switch (type) {
      case ItemType.armor:
      case ItemType.shield:
      case ItemType.helmet:
        return semantic.settings;
      case ItemType.gloves:
      case ItemType.ring:
      case ItemType.amulet:
        return semantic.neutral;
      case ItemType.boots:
      case ItemType.cape:
      case ItemType.accessory:
        return semantic.library;
      case ItemType.weapon:
      case ItemType.ammunition:
        return semantic.negative;
      case ItemType.consumable:
      case ItemType.potion:
        return semantic.positive;
      case ItemType.scroll:
      case ItemType.book:
        return semantic.condition;
      case ItemType.tool:
      case ItemType.material:
        return semantic.edit;
      case ItemType.special:
        return semantic.create;
      case ItemType.container:
      case ItemType.misc:
        return semantic.notes;
    }
  }

  static IconData icon(ItemType type) {
    switch (type) {
      case ItemType.armor:
        return Icons.shield_rounded;
      case ItemType.shield:
        return Icons.security_rounded;
      case ItemType.helmet:
        return Icons.sports_motorsports_rounded;
      case ItemType.gloves:
        return Icons.back_hand_rounded;
      case ItemType.boots:
        return Icons.hiking_rounded;
      case ItemType.cape:
        return Icons.checkroom_rounded;
      case ItemType.ring:
        return Icons.circle_outlined;
      case ItemType.amulet:
        return Icons.diamond_rounded;
      case ItemType.weapon:
        return Icons.sports_martial_arts_rounded;
      case ItemType.accessory:
        return Icons.auto_awesome_rounded;
      case ItemType.consumable:
      case ItemType.potion:
        return Icons.local_drink_rounded;
      case ItemType.scroll:
        return Icons.description_rounded;
      case ItemType.tool:
        return Icons.handyman_rounded;
      case ItemType.material:
        return Icons.category_rounded;
      case ItemType.book:
        return Icons.menu_book_rounded;
      case ItemType.special:
        return Icons.stars_rounded;
      case ItemType.ammunition:
        return Icons.adjust_rounded;
      case ItemType.container:
        return Icons.all_inbox_rounded;
      case ItemType.misc:
        return Icons.inventory_2_rounded;
    }
  }

  static Color soft(
    BuildContext context,
    ItemType type, {
    double alpha = 0.12,
  }) => of(context, type).withValues(alpha: alpha);
  static Color border(
    BuildContext context,
    ItemType type, {
    double alpha = 0.28,
  }) => of(context, type).withValues(alpha: alpha);

  static Color background(
    BuildContext context,
    ItemType type, {
    double strength = 0.14,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Color.lerp(scheme.surface, of(context, type), strength) ??
        scheme.surface;
  }

  static Color foreground(BuildContext context, ItemType type) {
    final scheme = Theme.of(context).colorScheme;
    final color = of(context, type);
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? scheme.onPrimary
        : scheme.onSurface;
  }
}
