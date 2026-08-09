import 'package:flutter/material.dart';

import '../../models/character.dart';
import '../common/app_card.dart';

class StoryHeader extends StatelessWidget {
  final Character character;

  const StoryHeader({super.key, required this.character});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      emphasized: true,
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                character.name.isEmpty ? '?' : character.name[0].toUpperCase(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name.isEmpty ? 'Personaje' : character.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),

                if (character.race.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    character.race,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: 7),

                Row(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      'Historia del personaje',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
