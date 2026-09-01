import 'package:flutter/material.dart';

import '../../models/character.dart';

import '../character_home/character_home_colors.dart';

class CombatHealthCard extends StatelessWidget {
  final Character character;

  final VoidCallback onTap;

  const CombatHealthCard({
    super.key,
    required this.character,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final color = CharacterHomeColors.health;

    final progress = character.maxHealth > 0
        ? (character.currentHealth / character.maxHealth).clamp(0.0, 1.0)
        : 0.0;

    final background = CharacterHomeColors.tintedSurface(
      context,
      color,
      lightStrength: 0.14,
      darkStrength: 0.22,
    );

    final iconBackground = CharacterHomeColors.tintedSurface(
      context,
      color,
      lightStrength: 0.26,
      darkStrength: 0.32,
    );

    final borderColor = CharacterHomeColors.tintedBorder(
      context,
      color,
      lightAlpha: 0.22,
      darkAlpha: 0.36,
    );

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // ===============================================================
              // CABECERA
              // ===============================================================
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(Icons.favorite_rounded, color: color, size: 22),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Puntos de golpe',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          'Toca para aplicar daño o curación',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(Icons.edit_rounded, size: 18, color: color),
                ],
              ),

              const SizedBox(height: 14),

              // ===============================================================
              // VIDA
              // ===============================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${character.currentHealth}',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),

                  const SizedBox(width: 5),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '/ ${character.maxHealth}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const Spacer(),

                  Text(
                    '${(progress * 100).round()}%',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress.toDouble(),
                  minHeight: 7,
                  color: color,
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
