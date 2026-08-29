import 'package:flutter/material.dart';

import '../models/skill.dart';

class AbilityColors {
  const AbilityColors._();

  // ===========================================================================
  // COLORES PRINCIPALES
  // ===========================================================================

  static const Color strength = Color(0xFFE35D6A);

  static const Color dexterity = Color(0xFF49B878);

  static const Color constitution = Color(0xFFE39A4A);

  static const Color intelligence = Color(0xFF4F8DEB);

  static const Color wisdom = Color(0xFF9B6CE8);

  static const Color charisma = Color(0xFFE96AAE);

  // ===========================================================================
  // COLOR POR ATRIBUTO
  // ===========================================================================

  static Color of(AbilityType ability) {
    switch (ability) {
      case AbilityType.strength:
        return strength;

      case AbilityType.dexterity:
        return dexterity;

      case AbilityType.constitution:
        return constitution;

      case AbilityType.intelligence:
        return intelligence;

      case AbilityType.wisdom:
        return wisdom;

      case AbilityType.charisma:
        return charisma;
    }
  }

  // ===========================================================================
  // VERSIONES CON ALPHA
  // ===========================================================================

  static Color soft(AbilityType ability, {double alpha = 0.12}) {
    return of(ability).withValues(alpha: alpha);
  }

  static Color border(AbilityType ability, {double alpha = 0.32}) {
    return of(ability).withValues(alpha: alpha);
  }

  // ===========================================================================
  // CONTRASTE
  // ===========================================================================

  static Color foreground(AbilityType ability) {
    final color = of(ability);

    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}
