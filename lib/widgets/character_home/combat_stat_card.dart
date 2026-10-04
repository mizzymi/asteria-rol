import 'package:flutter/material.dart';

import '../../theme/asteria_semantic_colors.dart';
import '../../theme/rainbow_action_style.dart';
import 'character_home_colors.dart';

class CombatStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const CombatStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final semantic =
        theme.extension<AsteriaSemanticColors>() ??
        AsteriaSemanticColors.asteria(colors);

    final rainbow = semantic.isRainbow;
    final foreground = rainbow
        ? RainbowActionStyle.foreground(context)
        : color;

    final background = rainbow
        ? RainbowActionStyle.background(context, color)
        : CharacterHomeColors.tintedSurface(
            context,
            color,
            lightStrength: 0.16,
            darkStrength: 0.13,
          );

    final iconBackground = rainbow
        ? foreground.withValues(alpha: 0.10)
        : CharacterHomeColors.tintedSurface(
            context,
            color,
            lightStrength: 0.26,
            darkStrength: 0.20,
          );

    final borderColor = rainbow
        ? foreground.withValues(alpha: 0.24)
        : CharacterHomeColors.tintedBorder(
            context,
            color,
            lightAlpha: 0.22,
            darkAlpha: 0.36,
          );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.08 : 0.05,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: foreground),
              ),
              const SizedBox(height: 8),
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
                        color: foreground,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: rainbow
                      ? foreground.withValues(alpha: 0.82)
                      : colors.onSurfaceVariant,
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
