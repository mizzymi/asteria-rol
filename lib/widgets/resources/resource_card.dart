import 'package:flutter/material.dart';

import '../../utils/number_format.dart';

import '../../models/character_resource.dart';

import '../common/app_card.dart';

class ResourceCard extends StatelessWidget {
  final CharacterResource resource;

  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onCalculator;
  final VoidCallback onTap;

  final int? effectiveCurrentValue;
  final int? effectiveMaxValue;

  const ResourceCard({
    super.key,
    required this.resource,
    required this.onDecrease,
    required this.onIncrease,
    required this.onCalculator,
    required this.onTap,
    this.effectiveCurrentValue,
    this.effectiveMaxValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = resource.colorFor(context);

    final shownCurrent = effectiveCurrentValue ?? resource.currentValue;

    final shownMax = effectiveMaxValue ?? resource.maxValue;

    final progress = resource.isUnlimited
        ? 0.0
        : shownMax <= 0
        ? 0.0
        : (shownCurrent / shownMax).clamp(0.0, 1.0);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      accentColor: color,
      showAccentBar: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(resource.icon, color: color),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  resource.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              Text(
                resource.hasMaximum
                    ? '${formatThousands(shownCurrent)}/${formatThousands(shownMax)}'
                    : formatThousands(shownCurrent),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),

          if (resource.hasMaximum) ...[
            const SizedBox(height: 14),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                color: color,
                backgroundColor: color.withValues(alpha: 0.12),
              ),
            ),
          ],

          const SizedBox(height: 14),

          Row(
            children: [
              if (resource.spendable) ...[
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: resource.currentValue > 0 ? onDecrease : null,
                    icon: const Icon(Icons.remove_rounded),
                    label: const Text('Gastar'),
                  ),
                ),
                const SizedBox(width: 10),
              ],

              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      !resource.hasMaximum || resource.currentValue < shownMax
                      ? onIncrease
                      : null,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(resource.hasMaximum ? 'Recuperar' : 'Añadir'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCalculator,
              icon: const Icon(Icons.calculate_rounded),
              label: const Text('Calculadora'),
            ),
          ),
        ],
      ),
    );
  }
}
