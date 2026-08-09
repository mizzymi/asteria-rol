import 'package:flutter/material.dart';

import '../../models/passive.dart';
import '../../models/skill.dart';

import '../common/info_badge.dart';

class ItemPassivePreview extends StatelessWidget {
  final CharacterPassive passive;

  const ItemPassivePreview({super.key, required this.passive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final badges = <Widget>[];

    if (passive.armorClassBonus != 0) {
      badges.add(
        InfoBadge(
          icon: Icons.shield_rounded,
          text: '${_bonus(passive.armorClassBonus)} CA',
          color: const Color(0xFF4D8FE8),
          highlighted: true,
        ),
      );
    }

    if (passive.initiativeBonus != 0) {
      badges.add(
        InfoBadge(
          icon: Icons.bolt_rounded,
          text: '${_bonus(passive.initiativeBonus)} iniciativa',
          color: const Color(0xFFF2C94C),
          highlighted: true,
        ),
      );
    }

    if (passive.speedBonus != 0) {
      badges.add(
        InfoBadge(
          icon: Icons.directions_run_rounded,
          text: '${_bonus(passive.speedBonus)} pies',
          color: const Color(0xFF55B96B),
          highlighted: true,
        ),
      );
    }

    if (passive.maxHealthBonus != 0) {
      badges.add(
        InfoBadge(
          icon: Icons.favorite_rounded,
          text: '${_bonus(passive.maxHealthBonus)} PG máx.',
          color: const Color(0xFFE84A8A),
          highlighted: true,
        ),
      );
    }

    if (passive.attackBonus != 0) {
      badges.add(
        InfoBadge(
          icon: Icons.gps_fixed_rounded,
          text: '${_bonus(passive.attackBonus)} al golpe',
          color: const Color(0xFFE85D5D),
          highlighted: true,
        ),
      );
    }

    for (final entry in passive.skillBonuses.entries) {
      if (entry.value == 0) {
        continue;
      }

      badges.add(
        InfoBadge(
          icon: Icons.bar_chart_rounded,
          text: '${_bonus(entry.value)} ${entry.key.label}',
          color: const Color(0xFF8B6FE8),
        ),
      );
    }

    for (final entry in passive.savingThrowBonuses.entries) {
      if (entry.value == 0) {
        continue;
      }

      badges.add(
        InfoBadge(
          icon: Icons.security_rounded,
          text: '${_bonus(entry.value)} Salv. ${entry.key.shortLabel}',
          color: const Color(0xFF4D8FE8),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(16),
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
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  passive.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          if (passive.description.isNotEmpty) ...[
            const SizedBox(height: 8),

            Text(
              passive.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          if (badges.isNotEmpty) ...[
            const SizedBox(height: 10),

            Wrap(spacing: 6, runSpacing: 6, children: badges),
          ],
        ],
      ),
    );
  }

  static String _bonus(int value) {
    return value >= 0 ? '+$value' : '$value';
  }
}
