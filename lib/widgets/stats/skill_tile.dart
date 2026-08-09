import 'package:flutter/material.dart';

import '../../models/character.dart';
import '../../models/proficiency.dart';
import '../../models/skill.dart';

import '../common/info_badge.dart';
import 'stats_colors.dart';

class SkillTile extends StatelessWidget {
  final DndSkill skill;
  final Character character;

  final VoidCallback onChangeProficiency;
  final VoidCallback onRoll;

  const SkillTile({
    super.key,
    required this.skill,
    required this.character,
    required this.onChangeProficiency,
    required this.onRoll,
  });

  String bonusText(int value) {
    return value >= 0 ? '+$value' : '$value';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ability = skill.ability;

    final color = StatsColors.abilityColor(ability);

    final proficiency = character.skillProficiency(skill);

    final bonus = character.skillBonus(skill);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StatsColors.softBackground(context, ability, strength: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: onChangeProficiency,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: StatsColors.softBackground(
                  context,
                  ability,
                  strength: 0.20,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _proficiencyIcon(proficiency),
                color: color,
                size: 21,
              ),
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.label,
                  style: TextStyle(
                    fontWeight: proficiency == ProficiencyLevel.none
                        ? FontWeight.w600
                        : FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    InfoBadge(
                      icon: StatsColors.abilityIcon(ability),
                      text: ability.shortLabel,
                      color: color,
                    ),

                    InfoBadge(
                      icon: _proficiencyIcon(proficiency),
                      text: proficiency.label,
                      color: proficiency == ProficiencyLevel.none
                          ? null
                          : color,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onRoll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: StatsColors.softBackground(
                  context,
                  ability,
                  strength: 0.17,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.casino_rounded, size: 17, color: color),

                  const SizedBox(width: 5),

                  Text(
                    bonusText(bonus),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _proficiencyIcon(ProficiencyLevel level) {
    switch (level) {
      case ProficiencyLevel.none:
        return Icons.circle_outlined;

      case ProficiencyLevel.proficient:
        return Icons.check_circle_rounded;

      case ProficiencyLevel.expertise:
        return Icons.star_rounded;
    }
  }
}
