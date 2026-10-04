import 'package:flutter/material.dart';

import '../../models/character_resource.dart';

import '../character_home/character_home_colors.dart';

class CombatResourceCard extends StatelessWidget {
  final CharacterResource resource;

  final int effectiveCurrent;
  final int? effectiveMax;

  final VoidCallback onTap;

  const CombatResourceCard({
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

    final shownMax = effectiveMax ?? resource.maxValue;

    final hasMaximum = resource.hasMaximum && shownMax > 0;

    final progress = hasMaximum
        ? (effectiveCurrent / shownMax).clamp(0.0, 1.0)
        : 0.0;

    final valueText = hasMaximum
        ? '$effectiveCurrent / $shownMax'
        : '$effectiveCurrent';

    final background = CharacterHomeColors.tintedSurface(
      context,
      resource.colorFor(context),
      lightStrength: 0.12,
      darkStrength: 0.20,
    );

    final iconBackground = CharacterHomeColors.tintedSurface(
      context,
      resource.colorFor(context),
      lightStrength: 0.24,
      darkStrength: 0.30,
    );

    final borderColor = CharacterHomeColors.tintedBorder(
      context,
      resource.colorFor(context),
      lightAlpha: 0.20,
      darkAlpha: 0.34,
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
          padding: const EdgeInsets.all(13),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      resource.icon,
                      size: 20,
                      color: resource.colorFor(context),
                    ),
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
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          valueText,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: resource.colorFor(context),
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: resource
                          .colorFor(context)
                          .withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.16
                                : 0.10,
                          ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: resource.colorFor(context),
                    ),
                  ),
                ],
              ),

              if (hasMaximum) ...[
                const SizedBox(height: 11),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress.toDouble(),
                    minHeight: 6,
                    color: resource.colorFor(context),
                    backgroundColor: colors.surfaceContainerHighest,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
