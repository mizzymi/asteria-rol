import 'package:flutter/material.dart';

import '../../models/skill.dart';
import '../../theme/attribute_palette.dart';

class AbilityAttributeColors {
  const AbilityAttributeColors._();

  static Color color(BuildContext context, AbilityType ability) {
    return AttributePalette.of(context, ability);
  }

  static Color background(
    BuildContext context,
    AbilityType ability, {
    double strength = 0.13,
  }) {
    return AttributePalette.soft(context, ability, strength: strength);
  }

  static Color strongBackground(BuildContext context, AbilityType ability) {
    return AttributePalette.soft(context, ability, strength: 0.24);
  }
}
