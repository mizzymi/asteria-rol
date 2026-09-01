import 'package:flutter/material.dart';

import '../../../models/ability.dart';
import '../../../models/action_resolution_context.dart';

Future<List<ActionTarget>?> showActionTargetSelector(
  BuildContext context, {
  required AbilityTargetType targetType,
  required String selfLabel,
}) async {
  switch (targetType) {
    case AbilityTargetType.self:
      return const [ActionTarget.self()];

    case AbilityTargetType.external:
      return const [
        ActionTarget(
          id: 'target_1',
          kind: ActionTargetKind.external,
          label: 'Objetivo',
        ),
      ];

    case AbilityTargetType.selfOrExternal:
      final target = await showDialog<ActionTarget>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Seleccionar objetivo'),

            content: const Text('¿A quién quieres dirigir esta acción?'),

            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    const ActionTarget(
                      id: 'target_1',
                      kind: ActionTargetKind.external,
                      label: 'Objetivo',
                    ),
                  );
                },
                icon: const Icon(Icons.gps_fixed_rounded),
                label: const Text('Otro objetivo'),
              ),

              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext, const ActionTarget.self());
                },
                icon: const Icon(Icons.person_rounded),
                label: Text(selfLabel),
              ),
            ],
          );
        },
      );

      return target == null ? null : [target];

    case AbilityTargetType.multipleExternal:
      final count = await _askTargetCount(
        context,
        title: 'Número de objetivos',
        message: '¿A cuántos objetivos afecta la acción?',
      );

      return count == null ? null : _buildExternalTargets(count);

    case AbilityTargetType.areaIncludingSelf:
      final totalCount = await _askTargetCount(
        context,
        title: 'Objetivos del área',
        message:
            '¿A cuántos objetivos afecta el área en total, incluyéndote a ti?',
      );

      if (totalCount == null) {
        return null;
      }

      // Self ya ocupa uno de los objetivos.
      final externalCount = totalCount - 1;

      return [
        const ActionTarget.self(participatesInAttackRoll: false),
        ..._buildExternalTargets(externalCount),
      ];

    case AbilityTargetType.areaExcludingSelf:
      final count = await _askTargetCount(
        context,
        title: 'Objetivos del área',
        message: '¿A cuántos objetivos externos afecta?',
      );

      return count == null ? null : _buildExternalTargets(count);
  }
}

List<ActionTarget> _buildExternalTargets(int count) {
  return List<ActionTarget>.generate(count, (index) {
    final number = index + 1;

    return ActionTarget(
      id: 'target_$number',
      kind: ActionTargetKind.external,
      label: count == 1 ? 'Objetivo' : 'Objetivo $number',
    );
  }, growable: false);
}

class _TargetCountDialog extends StatefulWidget {
  final String title;

  final String message;

  final bool allowZero;

  const _TargetCountDialog({
    required this.title,
    required this.message,
    required this.allowZero,
  });

  @override
  State<_TargetCountDialog> createState() => _TargetCountDialogState();
}

class _TargetCountDialogState extends State<_TargetCountDialog> {
  late final TextEditingController controller;

  String? error;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(text: widget.allowZero ? '0' : '1');
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(controller.text.trim());

    final minimum = widget.allowZero ? 0 : 1;

    if (value == null || value < minimum) {
      setState(() {
        error = widget.allowZero
            ? 'Introduce 0 o más.'
            : 'Introduce al menos 1.';
      });

      return;
    }

    Navigator.of(context).pop(value);
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.message),

          const SizedBox(height: 16),

          TextField(
            controller: controller,

            keyboardType: TextInputType.number,

            // De momento quitamos autofocus.
            //
            // Así tampoco mantenemos una transición de foco/teclado
            // mientras el diálogo está cerrándose.
            autofocus: false,

            decoration: InputDecoration(
              labelText: 'Cantidad de objetivos',
              errorText: error,
            ),

            onSubmitted: (_) {
              _submit();
            },
          ),
        ],
      ),

      actions: [
        TextButton(onPressed: _cancel, child: const Text('Cancelar')),

        FilledButton(onPressed: _submit, child: const Text('Continuar')),
      ],
    );
  }
}

Future<int?> _askTargetCount(
  BuildContext context, {
  required String title,
  required String message,
  bool allowZero = false,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) {
      return _TargetCountDialog(
        title: title,
        message: message,
        allowZero: allowZero,
      );
    },
  );
}
