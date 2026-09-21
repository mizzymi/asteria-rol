import 'package:flutter/material.dart';

import '../../models/ability.dart';
import '../../models/skill.dart';

import '../abilities/ability_attribute_colors.dart';
import '../common/info_badge.dart';

class ItemAbilityPreview extends StatelessWidget {
  final CharacterAbility ability;

  const ItemAbilityPreview({super.key, required this.ability});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = AbilityAttributeColors.color(context, ability.abilityType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Color.lerp(theme.colorScheme.surface, color, 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Color.lerp(theme.colorScheme.surface, color, 0.24),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  ability.requiresAttackRoll
                      ? Icons.gps_fixed_rounded
                      : Icons.auto_awesome_rounded,
                  size: 18,
                  color: color,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  ability.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              InfoBadge(
                icon: Icons.bolt_rounded,
                text: ability.actionType.label,
                color: color,
              ),
            ],
          ),

          if (ability.description.isNotEmpty) ...[
            const SizedBox(height: 8),

            Text(
              ability.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          const SizedBox(height: 9),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              InfoBadge(
                icon: Icons.psychology_rounded,
                text: ability.abilityType.shortLabel,
                color: color,
                highlighted: true,
              ),

              if (ability.requiresAttackRoll)
                const InfoBadge(icon: Icons.gps_fixed_rounded, text: 'Ataque'),

              if (ability.hasLimitedUses)
                InfoBadge(
                  icon: Icons.repeat_rounded,
                  text: '${ability.currentUses}/${ability.maxUses}',
                ),

              ...ability.effects
                  .where((effect) => effect.hasEffect)
                  .map(
                    (effect) => InfoBadge(
                      icon: effect.heals
                          ? Icons.favorite_rounded
                          : effect.usesSavingThrow
                          ? Icons.shield_rounded
                          : Icons.flash_on_rounded,
                      text: effect.name.isNotEmpty
                          ? effect.name
                          : effect.diceNotation,
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
