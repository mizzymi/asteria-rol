import 'package:flutter/material.dart';

import 'character_home_colors.dart';

class CombatStatCard extends StatelessWidget {
  final IconData icon;

  final String title;
  final String value;

  final Color color;

  final VoidCallback? onTap;

  final bool editable;

  const CombatStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
    this.editable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final background = CharacterHomeColors.tintedSurface(
      context,
      color,
      lightStrength: 0.14,
      darkStrength: 0.22,
    );

    final iconBackground = CharacterHomeColors.tintedSurface(
      context,
      color,
      lightStrength: 0.24,
      darkStrength: 0.30,
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ===============================================================
              // ICONO
              // ===============================================================
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),

              const SizedBox(height: 8),

              // ===============================================================
              // VALOR
              // ===============================================================
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),

                  if (editable) ...[
                    const SizedBox(width: 3),

                    Icon(
                      Icons.edit_rounded,
                      size: 12,
                      color: color.withValues(alpha: 0.78),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 5),

              // ===============================================================
              // TÍTULO
              // ===============================================================
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
