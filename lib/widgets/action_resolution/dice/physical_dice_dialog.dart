import 'package:flutter/material.dart';

import '../../../models/action_dice_request.dart';
import '../../../models/action_dice_result.dart';
import '../../../services/action_dice_resolver.dart';

import '../common/action_dialog_scaffold.dart';
import '../common/action_section_card.dart';
import '../common/numeric_dice_field.dart';

class PhysicalDiceSection {
  final String id;

  final String title;

  final ActionDiceRequest request;

  const PhysicalDiceSection({
    required this.id,
    required this.title,
    required this.request,
  });
}

class _DieBinding {
  final String sectionId;

  final ActionDiceRequestPart part;

  final int poolIndex;

  final int dieIndex;

  final int sides;

  int? value;

  String? error;

  _DieBinding({
    required this.sectionId,
    required this.part,
    required this.poolIndex,
    required this.dieIndex,
    required this.sides,
  });
}

Future<Map<String, ActionDiceResult>?> showPhysicalDiceDialog(
  BuildContext context, {
  required List<PhysicalDiceSection> sections,
}) async {
  if (sections.isEmpty) {
    return const {};
  }

  final bindings = <_DieBinding>[];

  // ===========================================================================
  // BINDINGS
  // ===========================================================================

  for (final section in sections) {
    for (final part in section.request.parts.where(
      (part) => part.requiresRoll,
    )) {
      for (var poolIndex = 0; poolIndex < part.dicePools.length; poolIndex++) {
        final pool = part.dicePools[poolIndex];

        for (var dieIndex = 0; dieIndex < pool.count; dieIndex++) {
          bindings.add(
            _DieBinding(
              sectionId: section.id,
              part: part,
              poolIndex: poolIndex,
              dieIndex: dieIndex,
              sides: pool.sides,
            ),
          );
        }
      }
    }
  }

  // ===========================================================================
  // SIN DADOS FÍSICOS REALES
  //
  // Puede haber partes con modifier / automaticValue,
  // pero ningún dado que introducir.
  //
  // Ejemplo:
  // crítico potenciado completamente automático.
  // ===========================================================================

  if (bindings.isEmpty) {
    const diceResolver = ActionDiceResolver();

    return Map<String, ActionDiceResult>.unmodifiable({
      for (final section in sections)
        section.id: diceResolver.resolvePhysical(
          request: section.request,
          inputs: const [],
        ),
    });
  }

  // ===========================================================================
  // DIÁLOGO
  // ===========================================================================

  return showDialog<Map<String, ActionDiceResult>>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void submit() {
            var valid = true;

            // ===================================================================
            // VALIDAR
            // ===================================================================

            for (final binding in bindings) {
              final value = binding.value;

              if (value == null || value < 1 || value > binding.sides) {
                binding.error = '1-${binding.sides}';

                valid = false;
              } else {
                binding.error = null;
              }
            }

            if (!valid) {
              setDialogState(() {});
              return;
            }

            // ===================================================================
            // CONSTRUIR RESULTADOS
            // ===================================================================

            const diceResolver = ActionDiceResolver();

            final results = <String, ActionDiceResult>{};

            for (final section in sections) {
              final inputs = <ActionPhysicalDiceInput>[];

              for (final part in section.request.parts.where(
                (part) => part.requiresRoll,
              )) {
                final rolls = <List<int>>[];

                for (
                  var poolIndex = 0;
                  poolIndex < part.dicePools.length;
                  poolIndex++
                ) {
                  final pool = part.dicePools[poolIndex];

                  final poolRolls = <int>[];

                  for (var dieIndex = 0; dieIndex < pool.count; dieIndex++) {
                    final binding = bindings.firstWhere(
                      (binding) =>
                          binding.sectionId == section.id &&
                          binding.part.id == part.id &&
                          binding.poolIndex == poolIndex &&
                          binding.dieIndex == dieIndex,
                    );

                    poolRolls.add(binding.value!);
                  }

                  rolls.add(poolRolls);
                }

                inputs.add(
                  ActionPhysicalDiceInput(requestPartId: part.id, rolls: rolls),
                );
              }

              results[section.id] = diceResolver.resolvePhysical(
                request: section.request,
                inputs: inputs,
              );
            }

            Navigator.of(
              dialogContext,
            ).pop(Map<String, ActionDiceResult>.unmodifiable(results));
          }

          return ActionDialogScaffold(
            icon: Icons.casino_rounded,

            title: 'Dados de la acción',

            subtitle: 'Introduce todos los resultados antes de resolver.',

            primaryLabel: 'Resolver',

            maxWidth: 640,

            onSecondary: () {
              Navigator.of(dialogContext).pop();
            },

            onPrimary: submit,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final section in sections) ...[
                  if (sections.length > 1) ...[
                    Text(
                      section.title,
                      style: Theme.of(dialogContext).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),

                    const SizedBox(height: 12),
                  ],

                  for (final part in section.request.parts.where(
                    (part) => part.requiresRoll,
                  )) ...[
                    _PhysicalDicePartCard(
                      sectionId: section.id,
                      part: part,
                      bindings: bindings,
                      onChanged: () {
                        setDialogState(() {});
                      },
                    ),

                    const SizedBox(height: 12),
                  ],

                  if (section != sections.last) ...[
                    const Divider(),

                    const SizedBox(height: 16),
                  ],
                ],
              ],
            ),
          );
        },
      );
    },
  );
}

class _PhysicalDicePartCard extends StatelessWidget {
  final String sectionId;

  final ActionDiceRequestPart part;

  final List<_DieBinding> bindings;

  final VoidCallback onChanged;

  const _PhysicalDicePartCard({
    required this.sectionId,
    required this.part,
    required this.bindings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ActionSectionCard(
      title: part.effectName,

      subtitle: part.damageType.trim().isNotEmpty
          ? part.damageType.trim()
          : null,

      icon: Icons.casino_rounded,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (
            var poolIndex = 0;
            poolIndex < part.dicePools.length;
            poolIndex++
          ) ...[
            Text(
              part.dicePools[poolIndex].notation,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bindings
                  .where(
                    (binding) =>
                        binding.sectionId == sectionId &&
                        binding.part.id == part.id &&
                        binding.poolIndex == poolIndex,
                  )
                  .map(
                    (binding) => SizedBox(
                      width: 92,
                      child: NumericDiceField(
                        sides: binding.sides,

                        value: binding.value,

                        errorText: binding.error,

                        onChanged: (value) {
                          binding.value = value;

                          if (value != null &&
                              value >= 1 &&
                              value <= binding.sides) {
                            binding.error = null;
                          }

                          onChanged();
                        },
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),

            const SizedBox(height: 12),
          ],

          if (part.modifier != 0 || part.automaticValue != 0) ...[
            const Divider(),

            const SizedBox(height: 8),

            if (part.modifier != 0)
              _PhysicalFixedValueRow(
                label: 'Modificador',
                value: part.modifier,
              ),

            if (part.modifier != 0 && part.automaticValue != 0)
              const SizedBox(height: 6),

            if (part.automaticValue != 0)
              _PhysicalFixedValueRow(
                label: 'Valor automático',
                value: part.automaticValue,
              ),
          ],
        ],
      ),
    );
  }
}

class _PhysicalFixedValueRow extends StatelessWidget {
  final String label;

  final int value;

  const _PhysicalFixedValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),

        Text(
          value >= 0 ? '+$value' : '$value',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
