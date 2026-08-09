import 'package:flutter/material.dart';

class StoryColors {
  const StoryColors._();

  static const Color backstory = Color(0xFF8B6FE8);

  static const Color appearance = Color(0xFF4D8FE8);

  static const Color personality = Color(0xFFE45AA7);

  static const Color ideals = Color(0xFFF2C94C);

  static const Color bonds = Color(0xFF55B96B);

  static const Color flaws = Color(0xFFE85D5D);

  static const Color goals = Color(0xFF4F80E8);

  static const Color notes = Color(0xFF8E7CC3);

  static Color background(
    BuildContext context,
    Color color, {
    double strength = 0.12,
  }) {
    return Color.lerp(Theme.of(context).colorScheme.surface, color, strength) ??
        color;
  }
}
