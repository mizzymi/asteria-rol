import 'package:flutter/material.dart';

import '../../models/ability.dart';

class AbilityActionBadge extends StatelessWidget {
  final AbilityActionType type;

  const AbilityActionBadge({super.key, required this.type});

  Color _color(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (type) {
      case AbilityActionType.action:
        return scheme.secondary;

      case AbilityActionType.bonusAction:
        return scheme.secondary;

      case AbilityActionType.reaction:
        return scheme.tertiary;

      case AbilityActionType.passive:
        return scheme.primary;
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
    final color = _color(context);

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
