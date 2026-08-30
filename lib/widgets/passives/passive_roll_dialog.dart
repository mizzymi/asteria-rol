import 'package:flutter/material.dart';

import '../../models/character.dart';
import '../../models/passive.dart';

import '../../services/action_resolution_flow.dart';

Future<void> showPassiveRollDialog(
  BuildContext context, {
  required Character character,
  required CharacterPassive passive,
}) async {
  final flow = ActionResolutionFlow(character: character);

  final result = await flow.resolvePassiveRoll(context, passive: passive);

  if (result == null || !context.mounted) {
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
              result.calculationText,
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
              Navigator.of(dialogContext).pop();

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
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}
