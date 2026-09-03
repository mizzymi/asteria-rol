import 'package:flutter/material.dart';

import '../../models/ability.dart';
import '../../models/dice_pool.dart';
import '../../models/skill.dart';
import 'ability_colors.dart';

class EffectResultCard extends StatelessWidget {
  final AbilityEffect effect;
  final DiceCalculationResult result;

  final int total;

  final bool saved;
  final bool critical;

  final int? saveDc;

  final ValueChanged<bool>? onSavedChanged;

  const EffectResultCard({
    super.key,
    required this.effect,
    required this.result,
    required this.total,
    required this.saved,
    required this.critical,
    required this.saveDc,
    required this.onSavedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AbilityColors.effectColor(context, effect);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AbilityColors.strongerBackground(context, color),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(AbilityColors.effectIcon(effect), color: color),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    if (effect.effectTypeName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        effect.effectTypeName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (critical)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 15,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Crítico',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          ...result.groups.map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(
                    group.pool.notation,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),

                  const Spacer(),

                  Text('${group.rolls.join(' + ')} = ${group.total}'),
                ],
              ),
            ),
          ),

          if (result.modifier != 0) ...[
            const SizedBox(height: 3),

            Row(
              children: [
                const Text('Modificador'),
                const Spacer(),
                Text(
                  _bonusText(result.modifier),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],

          if (critical && result.maximumDiceTotal > 0) ...[
            const SizedBox(height: 3),

            Row(
              children: [
                const Text('Bonus crítico'),
                const Spacer(),
                Text(
                  '+${result.maximumDiceTotal}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],

          if (effect.usesSavingThrow) ...[
            const Divider(height: 24),

            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 17,
                  color: theme.colorScheme.primary,
                ),

                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    '${effect.savingThrowAbility.shortLabel} · CD $saveDc',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Expanded(child: Text('¿Superó la salvación?')),

                ChoiceChip(
                  label: const Text('No'),
                  selected: !saved,
                  onSelected: (_) {
                    onSavedChanged?.call(false);
                  },
                ),

                const SizedBox(width: 6),

                ChoiceChip(
                  label: const Text('Sí'),
                  selected: saved,
                  onSelected: (_) {
                    onSavedChanged?.call(true);
                  },
                ),
              ],
            ),

            const SizedBox(height: 7),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _saveText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],

          const Divider(height: 24),

          Row(
            children: [
              Text(
                effect.heals ? 'Curación' : 'Daño',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),

              const Spacer(),

              Text(
                '$total',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _title {
    if (effect.name.isNotEmpty) {
      return effect.name;
    }

    if (effect.effectTypeName.isNotEmpty) {
      return effect.effectTypeName;
    }

    return effect.heals ? 'Curación' : 'Daño';
  }

  String get _saveText {
    if (!saved) {
      return 'Salvación fallida · efecto completo';
    }

    switch (effect.saveSuccessEffect) {
      case SaveSuccessEffect.full:
        return 'Salvación superada · completo';

      case SaveSuccessEffect.half:
        return 'Salvación superada · mitad';

      case SaveSuccessEffect.none:
        return 'Salvación superada · sin efecto';
    }
  }

  String _bonusText(int value) {
    return value >= 0 ? '+$value' : '$value';
  }
}
