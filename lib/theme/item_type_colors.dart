import 'package:flutter/material.dart';

import '../models/item_definition.dart';

class ItemTypeColors {
  const ItemTypeColors._();

  // ===========================================================================
  // COLORES BASE
  // ===========================================================================

  static const Color armor = Color(0xFF4D8FE8);

  static const Color shield = Color(0xFF5C93C4);

  static const Color helmet = Color(0xFF6874E8);

  static const Color gloves = Color(0xFFE58A52);

  static const Color boots = Color(0xFF55B96B);

  static const Color ring = Color(0xFFF2C94C);

  static const Color amulet = Color(0xFF9A6BE8);

  static const Color weapon = Color(0xFFE85D5D);

  static const Color accessory = Color(0xFFE45AA7);

  static const Color consumable = Color(0xFF42B8C8);

  static const Color tool = Color(0xFF8A6D4D);

  static const Color material = Color(0xFF7A8F62);

  static const Color book = Color(0xFF8B6FE8);

  static const Color special = Color(0xFFC56CE8);

  static const Color other = Color(0xFF82909C);

  // ===========================================================================
  // COLOR POR TIPO
  // ===========================================================================

  static Color of(ItemType type) {
    switch (type) {
      case ItemType.armor:
        return armor;

      case ItemType.shield:
        return shield;

      case ItemType.helmet:
        return helmet;

      case ItemType.gloves:
        return gloves;

      case ItemType.boots:
        return boots;

      case ItemType.ring:
        return ring;

      case ItemType.amulet:
        return amulet;

      case ItemType.weapon:
        return weapon;

      case ItemType.accessory:
        return accessory;

      case ItemType.consumable:
      case ItemType.potion:
        return consumable;

      case ItemType.scroll:
        return book;

      case ItemType.tool:
        return tool;

      case ItemType.material:
        return material;

      case ItemType.book:
        return book;

      case ItemType.special:
        return special;

      case ItemType.ammunition:
        return weapon;

      case ItemType.container:
      case ItemType.misc:
        return other;
    }
  }

  // ===========================================================================
  // ICONO POR TIPO
  // ===========================================================================

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

  // ===========================================================================
  // VERSIONES SUAVES
  // ===========================================================================

  static Color soft(ItemType type, {double alpha = 0.12}) {
    return of(type).withValues(alpha: alpha);
  }

  static Color border(ItemType type, {double alpha = 0.28}) {
    return of(type).withValues(alpha: alpha);
  }

  // ===========================================================================
  // FONDO ADAPTADO AL THEME
  // ===========================================================================

  static Color background(
    BuildContext context,
    ItemType type, {
    double strength = 0.14,
  }) {
    return Color.lerp(
          Theme.of(context).colorScheme.surface,
          of(type),
          strength,
        ) ??
        of(type);
  }

  // ===========================================================================
  // CONTRASTE
  // ===========================================================================

  static Color foreground(ItemType type) {
    final color = of(type);

    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}
