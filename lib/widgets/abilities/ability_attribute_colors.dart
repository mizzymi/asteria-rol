import 'package:flutter/material.dart';

import '../../models/skill.dart';

class AbilityAttributeColors {
  const AbilityAttributeColors._();

  static Color color(AbilityType ability) {
    switch (ability) {
      case AbilityType.strength:
        return const Color(0xFFE85D5D);

      case AbilityType.dexterity:
        return const Color(0xFF55B96B);

      case AbilityType.constitution:
        return const Color(0xFFF29E4C);

      case AbilityType.intelligence:
        return const Color(0xFF4D8FE8);

      case AbilityType.wisdom:
        return const Color(0xFF8B6FE8);

      case AbilityType.charisma:
        return const Color(0xFFE45AA7);
    }
  }

  static Color background(
    BuildContext context,
    AbilityType ability, {
    double strength = 0.13,
  }) {
    return Color.lerp(
          Theme.of(context).colorScheme.surface,
          color(ability),
          strength,
        ) ??
        color(ability);
  }

  static Color strongBackground(BuildContext context, AbilityType ability) {
    return Color.lerp(
          Theme.of(context).colorScheme.surface,
          color(ability),
          0.24,
        ) ??
        color(ability);
  }
}
