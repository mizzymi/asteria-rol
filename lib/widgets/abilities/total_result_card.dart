import 'package:flutter/material.dart';

class TotalResultCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  final bool emphasized;

  const TotalResultCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.emphasized = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: emphasized
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 23, color: theme.colorScheme.primary),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          Text(
            '$value',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
