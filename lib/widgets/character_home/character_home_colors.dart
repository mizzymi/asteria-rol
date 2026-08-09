import 'package:flutter/material.dart';

class CharacterHomeColors {
  const CharacterHomeColors._();

  static const Color health = Color(0xFFE84A8A);

  static const Color armor = Color(0xFF4D8FE8);

  static const Color initiative = Color(0xFFF2A94C);

  static const Color proficiency = Color(0xFF8B6FE8);

  static const Color speed = Color(0xFF55B96B);

  static const Color stats = Color(0xFF4D8FE8);

  static const Color abilities = Color(0xFFE85D5D);

  static const Color passives = Color(0xFF8B6FE8);

  static const Color items = Color(0xFFF29E4C);

  static const Color story = Color(0xFFE45AA7);

  static const Color journal = Color(0xFF55B96B);

  static const Color dice = Color(0xFF42B8C8);

  static Color background(
    BuildContext context,
    Color color, {
    double strength = 0.12,
  }) {
    return Color.lerp(Theme.of(context).colorScheme.surface, color, strength) ??
        color;
  }
}
