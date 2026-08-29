import 'package:flutter/material.dart';

import '../../../models/action_dice_mode.dart';

Future<ActionDiceMode?> showActionDiceModeSheet(BuildContext context) {
  return showModalBottomSheet<ActionDiceMode>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¿Cómo quieres tirar?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 14),

              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.casino_rounded),

                  title: const Text(
                    'Dados digitales',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),

                  subtitle: const Text(
                    'Asteria realiza las tiradas automáticamente.',
                  ),

                  trailing: const Icon(Icons.chevron_right_rounded),

                  onTap: () {
                    Navigator.pop(sheetContext, ActionDiceMode.digital);
                  },
                ),
              ),

              const SizedBox(height: 10),

              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.back_hand_rounded),

                  title: const Text(
                    'Dados físicos',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),

                  subtitle: const Text(
                    'Tiras los dados reales y escribes los resultados.',
                  ),

                  trailing: const Icon(Icons.chevron_right_rounded),

                  onTap: () {
                    Navigator.pop(sheetContext, ActionDiceMode.physical);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
