import 'package:flutter/material.dart';

import '../../models/ability.dart';
import '../../models/character.dart';
import '../../models/item.dart';

import '../character_home/character_home_colors.dart';

class CombatAbilityCard extends StatelessWidget {
  final Character character;
  final CharacterAbility ability;
  final ItemDefinition? sourceItem;

  final VoidCallback onUse;

  const CombatAbilityCard({
    super.key,
    required this.character,
    required this.ability,
    required this.onUse,
    this.sourceItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final color = CharacterHomeColors.abilities;

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

    final canUse = character.canCommitAbilityCosts(ability: ability);

    final resource = character.resourceForAbility(ability);

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
          // ===================================================================
          // CABECERA
          // ===================================================================
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.flash_on_rounded, color: color, size: 21),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ability.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _subtitle(character, ability, sourceItem),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ===================================================================
          // INFO MECÁNICA
          // ===================================================================
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              if (ability.requiresAttackRoll)
                _InfoChip(
                  icon: Icons.gps_fixed_rounded,
                  text:
                      '${_signed(character.characterAbilityAttackBonus(ability))} ataque',
                ),

              if (ability.hasLimitedUses)
                _InfoChip(
                  icon: Icons.battery_charging_full_rounded,
                  text: '${ability.currentUses}/${ability.maxUses} usos',
                ),

              if (ability.usesResource && resource != null)
                _InfoChip(
                  icon: resource.icon,
                  text: '${ability.resourceCost} ${resource.name}',
                ),

              if (ability.hasEffect)
                _InfoChip(
                  icon: Icons.auto_awesome_rounded,
                  text: character.characterAbilityEffectText(ability),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ===================================================================
          // USAR
          // ===================================================================
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canUse ? onUse : null,
              icon: Icon(
                ability.requiresAttackRoll
                    ? Icons.sports_martial_arts_rounded
                    : Icons.play_arrow_rounded,
              ),
              label: Text(ability.requiresAttackRoll ? 'Atacar' : 'Usar'),
            ),
          ),
        ],
      ),
    );
  }

  static String _subtitle(
    Character character,
    CharacterAbility ability,
    ItemDefinition? sourceItem,
  ) {
    if (sourceItem != null) {
      return 'Objeto · ${sourceItem.name}';
    }

    if (ability.requiresAttackRoll) {
      return 'Habilidad de ataque';
    }

    if (ability.heals) {
      return 'Curación';
    }

    if (ability.dealsDamage) {
      return 'Daño';
    }

    return 'Habilidad';
  }

  static String _signed(int value) {
    return value >= 0 ? '+$value' : '$value';
  }
}

// =============================================================================
// INFO CHIP
// =============================================================================

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.onSurfaceVariant),

          const SizedBox(width: 5),

          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
