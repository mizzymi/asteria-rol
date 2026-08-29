import 'package:flutter/material.dart';

import '../../../models/action_cost.dart';
import '../../../models/action_optional_group.dart';
import '../../../models/action_resolution_context.dart';

import '../common/action_dialog_scaffold.dart';
import '../common/action_section_card.dart';

class OptionalChoiceEntry {
  final ActionOptionalGroup group;

  final ActionTarget? target;

  final ActionCostValidationResult validation;

  const OptionalChoiceEntry({
    required this.group,
    required this.validation,
    this.target,
  });

  String get key {
    return '${target?.id ?? 'shared'}::${group.id}';
  }
}

Future<Map<String, bool>?> showOptionalChoicesDialog(
  BuildContext context, {
  required List<OptionalChoiceEntry> entries,
  required String selfLabel,
}) {
  if (entries.isEmpty) {
    return Future.value(const {});
  }

  final selected = <String, bool>{
    for (final entry in entries) entry.key: false,
  };

  return showDialog<Map<String, bool>>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return ActionDialogScaffold(
            icon: Icons.tune_rounded,

            title: 'Componentes opcionales',

            subtitle: 'Elige qué partes quieres utilizar.',

            primaryLabel: 'Continuar',

            onSecondary: () {
              Navigator.pop(dialogContext);
            },

            onPrimary: () {
              Navigator.pop(
                dialogContext,
                Map<String, bool>.unmodifiable(selected),
              );
            },

            child: Column(
              children: [
                for (final entry in entries) ...[
                  _OptionalCard(
                    entry: entry,

                    selfLabel: selfLabel,

                    selected: selected[entry.key] ?? false,

                    onChanged: (value) {
                      setDialogState(() {
                        selected[entry.key] = value;
                      });
                    },
                  ),

                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      );
    },
  );
}

class _OptionalCard extends StatelessWidget {
  final OptionalChoiceEntry entry;

  final String selfLabel;

  final bool selected;

  final ValueChanged<bool> onChanged;

  const _OptionalCard({
    required this.entry,
    required this.selfLabel,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final target = entry.target;

    final targetLabel = target == null
        ? null
        : target.isSelf
        ? selfLabel
        : target.label ?? 'Objetivo';

    final enabled = entry.validation.valid;

    return ActionSectionCard(
      title: targetLabel,

      icon: Icons.tune_rounded,

      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,

        value: enabled ? selected : false,

        onChanged: enabled ? onChanged : null,

        title: Text(
          entry.group.label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.group.costs.isEmpty)
              const Text('Sin coste adicional')
            else ...[
              const SizedBox(height: 4),

              ...entry.group.costs.map((cost) => Text(_costLabel(cost))),
            ],

            if (!enabled) ...[
              const SizedBox(height: 5),

              Text(
                entry.validation.error ?? 'No disponible.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _costLabel(ActionCost cost) {
  final explicit = cost.label?.trim();

  final name = explicit?.isNotEmpty == true
      ? explicit!
      : switch (cost.type) {
          ActionCostType.resource => 'Recurso',

          ActionCostType.passiveCharge => 'Carga',

          ActionCostType.abilityUse => 'Uso',
        };

  return '• ${cost.amount} × $name';
}
