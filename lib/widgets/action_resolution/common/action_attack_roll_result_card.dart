import 'package:flutter/material.dart';

import '../../../models/action_attack_result.dart';
import '../../../models/skill.dart';
import '../../../theme/ability_colors.dart';

class ActionAttackRollResultCard extends StatelessWidget {
  final ActionAttackResult attackResult;

  final AbilityType? ability;

  final String? criticalLabel;

  const ActionAttackRollResultCard({
    super.key,
    required this.attackResult,
    this.ability,
    this.criticalLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final accentColor = ability == null
        ? theme.colorScheme.primary
        : AbilityColors.of(context, ability!);

    final backgroundColor = ability == null
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
        : AbilityColors.soft(context, ability!, alpha: 0.10);

    final borderColor = ability == null
        ? theme.colorScheme.primary.withValues(alpha: 0.28)
        : AbilityColors.border(context, ability!, alpha: 0.32);

    final modifier = attackResult.modifier;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        children: [
          if (ability != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accentColor.withValues(alpha: 0.25)),
              ),
              child: Text(
                ability!.shortLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AttackMathValue(
                value: '${attackResult.naturalRoll}',
                label: 'd20',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 1, 16, 0),
                child: Text(
                  modifier >= 0 ? '+' : '−',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _AttackMathValue(value: '${modifier.abs()}', label: 'Mod.'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${attackResult.total}',
            textAlign: TextAlign.center,
            style: theme.textTheme.displayLarge?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            attackResult.critical
                ? (criticalLabel?.trim().isNotEmpty == true
                      ? criticalLabel!.trim().toUpperCase()
                      : 'CRÍTICO')
                : 'RESULTADO TOTAL',
            style: theme.textTheme.labelLarge?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          if (attackResult.critical) ...[
            const SizedBox(height: 8),
            Icon(
              Icons.local_fire_department_rounded,
              color: accentColor,
              size: 25,
            ),
          ],
        ],
      ),
    );
  }
}

class _AttackMathValue extends StatelessWidget {
  final String value;

  final String label;

  const _AttackMathValue({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
