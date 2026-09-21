import 'package:flutter/material.dart';

import '../../models/skill.dart';
import '../common/app_card.dart';
import 'stats_colors.dart';

class AttributeCard extends StatelessWidget {
  final AbilityType ability;

  final int score;
  final int modifier;

  final VoidCallback onTap;

  const AttributeCard({
    super.key,
    required this.ability,
    required this.score,
    required this.modifier,
    required this.onTap,
  });

  String _bonusText(int value) {
    return value >= 0 ? '+$value' : '$value';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = StatsColors.abilityColor(context, ability);

    return AppCard(
      onTap: onTap,
      accentColor: color,
      showAccentBar: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ===============================================================
          // ICONO
          // ===============================================================
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: StatsColors.softBackground(
                context,
                ability,
                strength: 0.24,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              StatsColors.abilityIcon(ability),
              size: 19,
              color: color,
            ),
          ),

          const Spacer(),

          // ===============================================================
          // MODIFICADOR
          // ===============================================================
          Text(
            _bonusText(modifier),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),

          const SizedBox(height: 5),

          // ===============================================================
          // ATRIBUTO
          // ===============================================================
          Text(
            ability.shortLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 2),

          // ===============================================================
          // VALOR
          // ===============================================================
          Text(
            '${ability.label} · $score',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
