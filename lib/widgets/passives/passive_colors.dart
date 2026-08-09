import 'package:flutter/material.dart';

import '../../models/passive.dart';

class PassiveColors {
  const PassiveColors._();

  static Color sourceColor(CharacterPassive passive) {
    switch (passive.sourceType) {
      default:
        return const Color(0xFF8B6FE8);
    }
  }

  static Color armorClass = const Color(0xFF4D8FE8);

  static Color initiative = const Color(0xFFF2C94C);

  static Color speed = const Color(0xFF55B96B);

  static Color health = const Color(0xFFE84A8A);

  static Color attack = const Color(0xFFE85D5D);

  static Color skill = const Color(0xFF8B6FE8);

  static Color savingThrow = const Color(0xFF4D8FE8);

  static Color softBackground(
    BuildContext context,
    Color color, {
    double strength = 0.12,
  }) {
    return Color.lerp(Theme.of(context).colorScheme.surface, color, strength) ??
        color;
  }
}
