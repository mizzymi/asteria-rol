import 'package:flutter/material.dart';

import '../../models/item.dart';

class ItemTypeColors {
  const ItemTypeColors._();

  static Color color(ItemType type) {
    switch (type) {
      case ItemType.armor:
        return const Color(0xFF4D8FE8);

      case ItemType.helmet:
        return const Color(0xFF6874E8);

      case ItemType.gloves:
        return const Color(0xFFE58A52);

      case ItemType.boots:
        return const Color(0xFF55B96B);

      case ItemType.ring:
        return const Color(0xFFF2C94C);

      case ItemType.amulet:
        return const Color(0xFF9A6BE8);

      case ItemType.weapon:
        return const Color(0xFFE85D5D);

      case ItemType.accessory:
        return const Color(0xFFE45AA7);

      case ItemType.consumable:
        return const Color(0xFF42B8C8);

      case ItemType.other:
        return const Color(0xFF82909C);
    }
  }

  static IconData icon(ItemType type) {
    switch (type) {
      case ItemType.armor:
        return Icons.shield_rounded;

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
        return Icons.local_drink_rounded;

      case ItemType.other:
        return Icons.inventory_2_rounded;
    }
  }

  static Color background(
    BuildContext context,
    ItemType type, {
    double strength = 0.14,
  }) {
    return Color.lerp(
          Theme.of(context).colorScheme.surface,
          color(type),
          strength,
        ) ??
        color(type);
  }
}
