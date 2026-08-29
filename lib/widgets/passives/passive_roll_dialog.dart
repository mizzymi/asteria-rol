import 'package:flutter/material.dart';

import '../../models/character.dart';
import '../../models/passive.dart';

Future<void> showPassiveRollDialog(
  BuildContext context, {
  required Character character,
  required CharacterPassive passive,
}) async {
  final result = character.rollPassive(passive);

  if (!context.mounted) {
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.casino_rounded),

            const SizedBox(width: 10),

            Expanded(child: Text(passive.name)),
          ],
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              character.passiveRollText(passive),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 16),

            Text(
              '${result.total}',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),

        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);

              showPassiveRollDialog(
                context,
                character: character,
                passive: passive,
              );
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Repetir'),
          ),

          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}
