import 'package:flutter/material.dart';

import '../../../models/ability.dart';
import '../../../models/action_saving_throw.dart';

class ActionSavingThrowBreakdown extends StatelessWidget {
  final List<ActionSavingThrowResult> savingThrows;

  const ActionSavingThrowBreakdown({super.key, required this.savingThrows});

  @override
  Widget build(BuildContext context) {
    if (savingThrows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < savingThrows.length; i++) ...[
          _SavingThrowResultRow(result: savingThrows[i]),

          if (i < savingThrows.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SavingThrowResultRow extends StatelessWidget {
  final ActionSavingThrowResult result;

  const _SavingThrowResultRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final request = result.request;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          result.saved ? Icons.shield_outlined : Icons.warning_amber_rounded,
          size: 18,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.effectName.trim().isEmpty
                    ? 'Salvación'
                    : request.effectName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 2),

              Text(
                _rollText(result),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 2),

              Text(
                _resultText(result),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _rollText(ActionSavingThrowResult result) {
    final request = result.request;

    if (!result.hasRollDetails) {
      return result.saved
          ? '${request.ability.name} · CD ${request.dc}'
          : '${request.ability.name} · CD ${request.dc} · fallida';
    }

    final naturalRoll = result.naturalRoll!;

    final modifier = result.modifier!;

    final total = result.total!;

    final modifierText = modifier >= 0 ? '+ $modifier' : '- ${modifier.abs()}';

    return '${request.ability.name} · '
        '$naturalRoll $modifierText = $total '
        'vs CD ${request.dc}';
  }
}

String _resultText(ActionSavingThrowResult result) {
  if (!result.saved) {
    return 'Salvación fallida · efecto completo.';
  }

  switch (result.request.successEffect) {
    case SaveSuccessEffect.full:
      return 'Efecto completo.';

    case SaveSuccessEffect.half:
      return 'Efecto reducido a la mitad.';

    case SaveSuccessEffect.none:
      return 'Sin efecto.';
  }
}
