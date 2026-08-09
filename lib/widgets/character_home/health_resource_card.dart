import 'package:flutter/material.dart';

import '../common/app_card.dart';

import 'character_home_colors.dart';

class HealthResourceCard extends StatelessWidget {
  final int current;
  final int max;

  final VoidCallback onTap;

  const HealthResourceCard({
    super.key,
    required this.current,
    required this.max,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = CharacterHomeColors.health;

    final progress = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

    return AppCard(
      onTap: onTap,
      accentColor: color,
      emphasized: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CharacterHomeColors.background(
                    context,
                    color,
                    strength: 0.24,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.favorite_rounded, color: color),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Text(
                  'Puntos de golpe',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              Icon(Icons.edit_rounded, size: 18, color: color),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$current',
                style: theme.textTheme.displaySmall?.copyWith(
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),

              const SizedBox(width: 6),

              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ $max',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress.toDouble(),
              minHeight: 10,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
