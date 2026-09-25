import 'package:flutter/material.dart';

import '../../models/character_resource.dart';
import 'character_home_colors.dart';

class QuickResourceCard extends StatelessWidget {
  final CharacterResource resource;
  final int effectiveCurrent;
  final int? effectiveMax;
  final VoidCallback onTap;

  const QuickResourceCard({
    super.key,
    required this.resource,
    required this.effectiveCurrent,
    required this.effectiveMax,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = resource.colorFor(context);

    final shownMax = effectiveMax ?? resource.maxValue;
    final hasMaximum = resource.hasMaximum && shownMax > 0;
    final progress = hasMaximum
        ? (effectiveCurrent / shownMax).clamp(0.0, 1.0)
        : 0.0;

    final valueText = resource.hasMaximum
        ? '$effectiveCurrent/$shownMax'
        : '$effectiveCurrent';

    final background = CharacterHomeColors.tintedSurface(
      context,
      accent,
      lightStrength: 0.16,
      darkStrength: 0.13,
    );

    final iconBackground = CharacterHomeColors.tintedSurface(
      context,
      accent,
      lightStrength: 0.26,
      darkStrength: 0.20,
    );

    final borderColor = CharacterHomeColors.tintedBorder(
      context,
      accent,
      lightAlpha: 0.22,
      darkAlpha: 0.36,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
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
          borderRadius: BorderRadius.circular(17),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(resource.icon, size: 20, color: accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resource.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            valueText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: accent.withValues(
                          alpha: theme.brightness == Brightness.dark ? 0.16 : 0.10,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 13,
                        color: accent,
                      ),
                    ),
                  ],
                ),
                if (hasMaximum) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress.toDouble(),
                      minHeight: 5,
                      color: accent,
                      backgroundColor: colors.surfaceContainerHighest,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
