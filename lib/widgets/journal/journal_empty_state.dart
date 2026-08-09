import 'package:flutter/material.dart';

import '../common/empty_state.dart';

class JournalEmptyState extends StatelessWidget {
  final bool filtered;

  final VoidCallback onCreate;

  final VoidCallback? onClearFilter;

  const JournalEmptyState({
    super.key,
    required this.filtered,
    required this.onCreate,
    this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    if (!filtered) {
      return EmptyState(
        icon: Icons.history_edu_rounded,
        title: 'El diario está vacío',
        message:
            'Guarda aquí sesiones, descubrimientos, misiones, NPCs y momentos importantes.',
        actionLabel: 'Primera entrada',
        actionIcon: Icons.add_rounded,
        onAction: onCreate,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(
                Icons.filter_alt_off_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'No hay entradas',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 8),

            Text(
              'No hay ninguna entrada que coincida con este filtro.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 22),

            if (onClearFilter != null)
              FilledButton.tonalIcon(
                onPressed: onClearFilter,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Mostrar todo'),
              ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nueva entrada'),
            ),
          ],
        ),
      ),
    );
  }
}
