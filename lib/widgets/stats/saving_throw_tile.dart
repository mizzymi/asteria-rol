import 'package:flutter/material.dart';

import '../../models/character.dart';
import '../../models/skill.dart';

import '../common/app_card.dart';
import '../common/info_badge.dart';
import 'stats_colors.dart';

class SavingThrowTile extends StatelessWidget {
  final AbilityType ability;
  final Character character;

  final VoidCallback onToggle;
  final VoidCallback onRoll;

  const SavingThrowTile({
    super.key,
    required this.ability,
    required this.character,
    required this.onToggle,
    required this.onRoll,
  });

  String bonusText(int value) {
    return value >= 0 ? '+$value' : '$value';
  }

  @override
  Widget build(BuildContext context) {
    final color = StatsColors.abilityColor(ability);

    final proficient = character.isSavingThrowProficient(ability);

    final bonus = character.savingThrowBonus(ability);

    return AppCard(
      accentColor: color,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onToggle,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: StatsColors.softBackground(
                  context,
                  ability,
                  strength: proficient ? 0.24 : 0.10,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                proficient ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: color,
              ),
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ability.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 5),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    InfoBadge(
                      icon: Icons.shield_outlined,
                      text: ability.shortLabel,
                      color: color,
                    ),

                    InfoBadge(
                      icon: proficient
                          ? Icons.verified_rounded
                          : Icons.remove_circle_outline_rounded,
                      text: proficient ? 'Competente' : 'Normal',
                      color: proficient ? color : null,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onRoll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: StatsColors.softBackground(
                    context,
                    ability,
                    strength: 0.18,
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
          ),
        ],
      ),
    );
  }
}
