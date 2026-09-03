import 'package:flutter/material.dart';

import '../../models/character_resource.dart';
import '../../models/ability.dart';
import '../../models/character.dart';
import '../../models/skill.dart';
import 'ability_colors.dart';

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
                        color: Theme
                            .of(context)
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
                                  part.typeName
                                      .trim()
                                      .isNotEmpty
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
}
