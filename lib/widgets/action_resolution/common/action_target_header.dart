import 'package:flutter/material.dart';

class ActionTargetHeader extends StatelessWidget {
  final String label;

  final bool self;

  const ActionTargetHeader({super.key, required this.label, this.self = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Icon(
            self ? Icons.person_rounded : Icons.gps_fixed_rounded,
            size: 19,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
