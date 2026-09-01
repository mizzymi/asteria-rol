import 'package:flutter/material.dart';

import '../character_home/character_home_colors.dart';

class CombatContentFolderCard extends StatelessWidget {
  final String name;

  final int count;

  final bool automatic;

  final VoidCallback onTap;

  const CombatContentFolderCard({
    super.key,
    required this.name,
    required this.count,
    required this.onTap,
    this.automatic = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final color = CharacterHomeColors.abilities;

    final background = CharacterHomeColors.tintedSurface(
      context,
      color,
      lightStrength: 0.08,
      darkStrength: 0.15,
    );

    final iconBackground = CharacterHomeColors.tintedSurface(
      context,
      color,
      lightStrength: 0.20,
      darkStrength: 0.28,
    );

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(
          color: CharacterHomeColors.tintedBorder(
            context,
            color,
            lightAlpha: 0.18,
            darkAlpha: 0.30,
          ),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  automatic ? Icons.inventory_2_rounded : Icons.folder_rounded,
                  color: color,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      '$count '
                      '${count == 1 ? 'elemento' : 'elementos'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              if (automatic) ...[
                Icon(
                  Icons.lock_outline_rounded,
                  size: 15,
                  color: colors.onSurfaceVariant,
                ),

                const SizedBox(width: 5),
              ],

              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
