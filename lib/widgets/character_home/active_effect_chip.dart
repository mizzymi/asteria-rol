import 'package:flutter/material.dart';

import '../../models/character_effect.dart';
import 'character_home_colors.dart';

class ActiveEffectChip extends StatelessWidget {
  final CharacterEffect effect;
  final int count;
  final VoidCallback onTap;

  const ActiveEffectChip({
    super.key,
    required this.effect,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = _effectColor(context, effect);

    final background = CharacterHomeColors.tintedSurface(
      context,
      accent,
      lightStrength: 0.15,
      darkStrength: 0.12,
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
      lightAlpha: 0.20,
      darkAlpha: 0.34,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_effectIcon(effect), size: 17, color: accent),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 145),
                          child: Text(
                            effect.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (count > 1) ...[
                          const SizedBox(width: 6),
                          _StackBadge(count: count, color: accent),
                        ],
                      ],
                    ),
                    if (_durationText(effect) case final duration? when duration.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            duration,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _durationText(CharacterEffect effect) {
    if (!effect.hasDuration) {
      return null;
    }

    final text = effect.durationText.trim();
    if (text.isEmpty) {
      return null;
    }
    return text;
  }

  Color _effectColor(BuildContext context, CharacterEffect effect) {
    final colors = Theme.of(context).colorScheme;

    if (!effect.enabled || effect.expired) {
      return colors.onSurfaceVariant;
    }

    switch (effect.type) {
      case CharacterEffectType.buff:
        return Theme.of(context).colorScheme.tertiary;
      case CharacterEffectType.debuff:
        return Theme.of(context).colorScheme.error;
      case CharacterEffectType.condition:
        return Theme.of(context).colorScheme.primary;
      case CharacterEffectType.neutral:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  IconData _effectIcon(CharacterEffect effect) {
    if (effect.expired) {
      return Icons.timer_off_rounded;
    }
    if (!effect.enabled) {
      return Icons.visibility_off_rounded;
    }

    switch (effect.type) {
      case CharacterEffectType.buff:
        return Icons.arrow_upward_rounded;
      case CharacterEffectType.debuff:
        return Icons.arrow_downward_rounded;
      case CharacterEffectType.condition:
        return Icons.warning_amber_rounded;
      case CharacterEffectType.neutral:
        return Icons.auto_awesome_rounded;
    }
  }
}

class _StackBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _StackBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = CharacterHomeColors.tintedSurface(
      context,
      color,
      lightStrength: 0.22,
      darkStrength: 0.18,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '×$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
      ),
    );
  }
}
