import 'package:flutter/material.dart';

import '../../theme/rainbow_action_style.dart';
import 'character_home_colors.dart';

class CharacterQuickActions extends StatelessWidget {
  final VoidCallback onCombat;
  final VoidCallback onRest;
  final VoidCallback onPets;
  final int petCount;

  const CharacterQuickActions({
    super.key,
    required this.onCombat,
    required this.onRest,
    required this.onPets,
    this.petCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: CharacterHomeColors.elevatedPanel(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.78),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.10 : 0.06,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acceso rápido',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.sports_martial_arts_rounded,
                  label: 'Combate',
                  color: CharacterHomeColors.combat(context),
                  onTap: onCombat,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Descansar',
                  color: CharacterHomeColors.rest(context),
                  onTap: onRest,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.pets_rounded,
                  label: petCount > 0 ? 'Mascotas ($petCount)' : 'Mascotas',
                  color: CharacterHomeColors.effects(context),
                  onTap: onPets,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final rainbow = RainbowActionStyle.enabled(context);
    final background = rainbow
        ? RainbowActionStyle.background(context, color)
        : CharacterHomeColors.tintedSurface(
            context,
            color,
            lightStrength: 0.14,
            darkStrength: 0.12,
          );
    final foreground = rainbow
        ? RainbowActionStyle.foreground(context)
        : color;

    final iconBackground = rainbow
        ? foreground.withValues(alpha: 0.10)
        : CharacterHomeColors.tintedSurface(
            context,
            color,
            lightStrength: 0.26,
            darkStrength: 0.18,
          );

    final borderColor = CharacterHomeColors.tintedBorder(
      context,
      color,
      lightAlpha: 0.18,
      darkAlpha: 0.30,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
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
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 21, color: foreground),
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: rainbow ? foreground : colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
