import 'package:flutter/material.dart';

import '../common/app_card.dart';

import 'character_home_colors.dart';

class CharacterMenuCard extends StatelessWidget {
  final IconData icon;

  final String title;
  final String subtitle;

  final Color color;

  final VoidCallback onTap;

  const CharacterMenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onTap,
      accentColor: color,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: CharacterHomeColors.background(
                context,
                color,
                strength: 0.24,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chevron_right_rounded, size: 21, color: color),
          ),
        ],
      ),
    );
  }
}
