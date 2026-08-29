import 'package:flutter/material.dart';

import '../../../models/action_saving_throw.dart';

import '../common/action_dialog_scaffold.dart';
import '../common/action_section_card.dart';

Future<void> showSavingThrowResultsDialog(
  BuildContext context, {
  required List<ActionSavingThrowResult> results,
}) {
  if (results.isEmpty) {
    return Future.value();
  }

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return ActionDialogScaffold(
        icon: Icons.security_rounded,

        title: 'Salvaciones',

        subtitle: 'Resultados de las tiradas.',

        primaryLabel: 'Continuar',

        secondaryLabel: 'Cerrar',

        onSecondary: () {
          Navigator.pop(dialogContext);
        },

        onPrimary: () {
          Navigator.pop(dialogContext);
        },

        child: Column(
          children: [
            for (final result in results) ...[
              ActionSectionCard(
                title: result.request.effectName,

                subtitle:
                    '${result.request.ability.name} · '
                    'CD ${result.request.dc}',

                icon: result.saved
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,

                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        result.saved
                            ? 'Salvación superada'
                            : 'Salvación fallida',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),

                    if (result.total != null)
                      Text(
                        '${result.total}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
            ],
          ],
        ),
      );
    },
  );
}
