import 'package:flutter/material.dart';

import '../common/info_badge.dart';

class PassiveEffectBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const PassiveEffectBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InfoBadge(icon: icon, text: label, color: color, highlighted: true);
  }
}
