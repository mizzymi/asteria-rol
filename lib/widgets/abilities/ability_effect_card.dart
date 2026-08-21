import 'package:flutter/material.dart';
import 'package:rol/models/character_resource.dart';

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
                ...effect.parts.map((part) {
                  final pieces = <String>[];

                  if (part.diceNotation.isNotEmpty) {
                    pieces.add(part.diceNotation);
                  }

                  for (final entry in part.abilityModifierMultipliers.entries) {
                    if (entry.value == 0) {
                      continue;
                    }

                    if (entry.value == 1) {
                      pieces.add(entry.key.shortLabel);
                    } else {
                      pieces.add('${entry.value}×${entry.key.shortLabel}');
                    }
                  }

                  for (final entry in part.resourceValueMultipliers.entries) {
                    final resource = character.resources
                        .where((resource) => resource.id == entry.key)
                        .cast<CharacterResource?>()
                        .firstOrNull;

                    if (resource == null) {
                      continue;
                    }

                    if (entry.value == 1) {
                      pieces.add(resource.name);
                    } else {
                      pieces.add('${entry.value}×${resource.name}');
                    }
                  }

                  if (part.flatBonus != 0) {
                    pieces.add(
                      part.flatBonus > 0
                          ? '+${part.flatBonus}'
                          : '${part.flatBonus}',
                    );
                  }

                  final formula = pieces.isEmpty
                      ? 'Sin fórmula'
                      : pieces.join(' + ').replaceAll('+ -', '- ');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            effect.heals
                                ? Icons.favorite_rounded
                                : Icons.flash_on_rounded,
                            size: 18,
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  part.typeName.trim().isNotEmpty
                                      ? part.typeName
                                      : effect.effectType.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),

                                const SizedBox(height: 2),

                                Text(formula),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
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
