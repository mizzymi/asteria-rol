import 'package:flutter/material.dart';

import '../../models/character_resource.dart';
import '../common/app_card.dart';

class ResourceCard extends StatelessWidget {
  final CharacterResource resource;

  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onTap;

  const ResourceCard({
    super.key,
    required this.resource,
    required this.onDecrease,
    required this.onIncrease,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = resource.color;

    final progress = resource.maxValue <= 0
        ? 0.0
        : (resource.currentValue / resource.maxValue).clamp(0.0, 1.0);

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
                '${resource.currentValue}/${resource.maxValue}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),

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

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: resource.currentValue > 0 ? onDecrease : null,
                  icon: const Icon(Icons.remove_rounded),
                  label: const Text('Gastar'),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: resource.currentValue < resource.maxValue
                      ? onIncrease
                      : null,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Recuperar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
