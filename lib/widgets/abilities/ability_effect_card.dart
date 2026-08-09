import 'package:flutter/material.dart';

import '../../models/ability.dart';
import '../../models/character.dart';
import '../../models/skill.dart';
import 'ability_colors.dart';

import '../common/info_badge.dart';

class AbilityEffectCard extends StatelessWidget {
  final CharacterAbility ability;
  final AbilityEffect effect;
  final Character character;

  const AbilityEffectCard({
    super.key,
    required this.ability,
    required this.effect,
    required this.character,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final modifier = character.abilityEffectModifier(ability, effect);

    final dc = effect.usesSavingThrow
        ? character.abilityEffectSaveDc(ability, effect)
        : null;

    final color = AbilityColors.effectColor(context, effect);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AbilityColors.softBackground(context, color, strength: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AbilityColors.strongerBackground(context, color),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              AbilityColors.effectIcon(effect),
              size: 22,
              color: color,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 7),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (effect.diceNotation.isNotEmpty)
                      InfoBadge(
                        icon: Icons.casino_rounded,
                        text: _diceText(modifier),
                        color: color,
                      ),

                    if (effect.effectTypeName.isNotEmpty)
                      InfoBadge(
                        icon: AbilityColors.effectIcon(effect),
                        text: effect.effectTypeName,
                        color: color,
                      ),

                    if (effect.usesSavingThrow)
                      InfoBadge(
                        icon: Icons.shield_rounded,
                        text:
                            '${effect.savingThrowAbility.shortLabel} · CD $dc',
                        color: const Color(0xFF8B5CF6),
                        highlighted: true,
                      ),

                    if (effect.usesSavingThrow)
                      InfoBadge(
                        icon: Icons.verified_user_outlined,
                        text: _saveText(effect.saveSuccessEffect),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _diceText(int modifier) {
    var result = effect.diceNotation;

    if (modifier > 0) {
      result += ' + $modifier';
    } else if (modifier < 0) {
      result += ' - ${modifier.abs()}';
    }

    return result;
  }

  String get _title {
    if (effect.name.isNotEmpty) {
      return effect.name;
    }

    if (effect.effectTypeName.isNotEmpty) {
      return effect.effectTypeName;
    }

    if (effect.heals) {
      return 'Curación';
    }

    if (effect.dealsDamage) {
      return 'Daño';
    }

    return 'Efecto';
  }

  IconData get _icon {
    if (effect.heals) {
      return Icons.favorite_rounded;
    }

    if (effect.usesSavingThrow) {
      return Icons.shield_rounded;
    }

    if (effect.dealsDamage) {
      return Icons.flash_on_rounded;
    }

    return Icons.auto_awesome_rounded;
  }

  Color _iconBackground(ThemeData theme) {
    if (effect.heals) {
      return theme.colorScheme.tertiaryContainer;
    }

    if (effect.usesSavingThrow) {
      return theme.colorScheme.secondaryContainer;
    }

    return theme.colorScheme.primaryContainer;
  }

  Color _iconColor(ThemeData theme) {
    if (effect.heals) {
      return theme.colorScheme.onTertiaryContainer;
    }

    if (effect.usesSavingThrow) {
      return theme.colorScheme.onSecondaryContainer;
    }

    return theme.colorScheme.primary;
  }

  String _saveText(SaveSuccessEffect value) {
    switch (value) {
      case SaveSuccessEffect.full:
        return 'Éxito: completo';

      case SaveSuccessEffect.half:
        return 'Éxito: mitad';

      case SaveSuccessEffect.none:
        return 'Éxito: sin efecto';
    }
  }
}
