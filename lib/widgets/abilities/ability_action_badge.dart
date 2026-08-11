import 'package:flutter/material.dart';

import '../../models/ability.dart';

class AbilityActionBadge extends StatelessWidget {
  final AbilityActionType type;

  const AbilityActionBadge({super.key, required this.type});

  Color _color() {
    switch (type) {
      case AbilityActionType.action:
        return const Color(0xFF4D8FE8);

      case AbilityActionType.bonusAction:
        return const Color(0xFFF29E4C);

      case AbilityActionType.reaction:
        return const Color(0xFFE45AA7);

      case AbilityActionType.passive:
        return const Color(0xFF8B6FE8);
    }
  }

  IconData _icon() {
    switch (type) {
      case AbilityActionType.action:
        return Icons.flash_on_rounded;

      case AbilityActionType.bonusAction:
        return Icons.add_circle_rounded;

      case AbilityActionType.reaction:
        return Icons.sync_rounded;

      case AbilityActionType.passive:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), size: 13, color: color),

          const SizedBox(width: 4),

          Text(
            type.label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.45,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
