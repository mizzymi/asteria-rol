import 'package:flutter/material.dart';

import '../../models/character_counter.dart';
import '../common/app_card.dart';

class CounterCard extends StatelessWidget {
  final CharacterCounter counter;

  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onTap;
  final VoidCallback onReset;

  const CounterCard({
    super.key,
    required this.counter,
    required this.onDecrease,
    required this.onIncrease,
    required this.onTap,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.tag_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  counter.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              Text(
                '${counter.value}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: counter.value > 0 ? onDecrease : null,
                  icon: const Icon(Icons.remove_rounded),
                  label: const Text('Restar'),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onIncrease,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Añadir'),
                ),
              ),

              const SizedBox(width: 6),

              IconButton(
                tooltip: 'Reiniciar',
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
