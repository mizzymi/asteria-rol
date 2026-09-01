import 'package:flutter/material.dart';

import '../../models/character.dart';
import '../../models/item.dart';

import '../character_home/character_home_colors.dart';

class CombatWeaponCard extends StatelessWidget {
  final Character character;
  final CharacterItem item;

  final VoidCallback onAttack;

  const CombatWeaponCard({
    super.key,
    required this.character,
    required this.item,
    required this.onAttack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final weapon = item.weapon;

    if (weapon == null) {
      return const SizedBox.shrink();
    }

    final color = CharacterHomeColors.combat;

    final background = CharacterHomeColors.tintedSurface(
      context,
      color,
      lightStrength: 0.09,
      darkStrength: 0.16,
    );

    final iconBackground = CharacterHomeColors.tintedSurface(
      context,
      color,
      lightStrength: 0.20,
      darkStrength: 0.28,
    );

    final borderColor = CharacterHomeColors.tintedBorder(
      context,
      color,
      lightAlpha: 0.18,
      darkAlpha: 0.30,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.gavel_rounded,
                  color: color,
                  size: 21,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${character.attackBonusText(weapon)} ataque',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              if (item.equipped)
                const Chip(
                  avatar: Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                  ),
                  label: Text('Equipado'),
                ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow.withValues(
                alpha: 0.75,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flash_on_rounded,
                  size: 18,
                  color: color,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    character.damageText(weapon),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: item.equipped
                  ? onAttack
                  : null,
              icon: const Icon(
                Icons.sports_martial_arts_rounded,
              ),
              label: const Text(
                'Atacar',
              ),
            ),
          ),
        ],
      ),
    );
  }
}