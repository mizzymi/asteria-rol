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
          result.saved ? Icons.shield_rounded : Icons.shield_outlined,
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                _resultText(result),
                style: Theme.of(context).textTheme.bodySmall,
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

    return '${request.ability.name} · '
        '${result.naturalRoll} + ${result.modifier} = ${result.total} '
        'vs CD ${request.dc}';
  }
}

String _resultText(ActionSavingThrowResult result) {
  if (!result.saved) {
    return 'Salvación fallida · efecto completo.';
  }

  switch (result.request.successEffect) {
    case SaveSuccessEffect.full:
      return 'Salvación superada · efecto completo.';

    case SaveSuccessEffect.half:
      return 'Salvación superada · efecto reducido a la mitad.';

    case SaveSuccessEffect.none:
      return 'Salvación superada · sin efecto.';
  }
}
