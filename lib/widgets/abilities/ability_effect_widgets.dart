import 'package:flutter/material.dart';

import '../../models/ability.dart';
import '../../models/dice_pool.dart';
import '../../models/skill.dart';

// =============================================================================
// SALVACIÓN
// =============================================================================

Future<bool?> showEffectSavingThrowSheet({
  required BuildContext context,
  required CharacterAbility ability,
  required AbilityEffect effect,
  required int dc,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                effect.name.isNotEmpty ? effect.name : ability.name,
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  const Icon(Icons.shield_rounded, size: 18),

                  const SizedBox(width: 6),

                  Text(
                    'Salvación de '
                    '${effect.savingThrowAbility.label}'
                    ' · CD $dc',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.close_rounded),
                  title: const Text(
                    'Salvación fallida',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Aplicar el efecto completo'),
                  onTap: () {
                    Navigator.pop(sheetContext, false);
                  },
                ),
              ),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.shield_rounded),
                  title: const Text(
                    'Salvación superada',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(_saveSuccessText(effect.saveSuccessEffect)),
                  onTap: () {
                    Navigator.pop(sheetContext, true);
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

String _saveSuccessText(SaveSuccessEffect effect) {
  switch (effect) {
    case SaveSuccessEffect.full:
      return 'Recibe el efecto completo';

    case SaveSuccessEffect.half:
      return 'Recibe la mitad';

    case SaveSuccessEffect.none:
      return 'No recibe el efecto';
  }
}

// =============================================================================
// RESULTADO
// =============================================================================

class AbilityEffectResultDialog extends StatelessWidget {
  final CharacterAbility ability;
  final AbilityEffect effect;

  final DiceCalculationResult result;

  final int total;

  final bool saved;
  final bool critical;

  final String Function(int) bonusText;

  final VoidCallback onRepeat;

  const AbilityEffectResultDialog({
    super.key,
    required this.ability,
    required this.effect,
    required this.result,
    required this.total,
    required this.saved,
    required this.critical,
    required this.bonusText,
    required this.onRepeat,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(effect.name.isNotEmpty ? effect.name : ability.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...result.groups.map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      group.pool.notation,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  Text('${group.rolls.join(' + ')} = ${group.total}'),
                ],
              ),
            ),
          ),

          if (critical) ...[
            const Divider(),

            Row(
              children: [
                const Expanded(child: Text('Bonus crítico')),

                Text(
                  '+${result.maximumDiceTotal}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],

          if (result.modifier != 0) ...[
            const SizedBox(height: 6),

            Row(
              children: [
                const Expanded(child: Text('Modificador')),

                Text(
                  bonusText(result.modifier),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],

          const Divider(height: 28),

          if (saved) ...[
            _SavedResultBanner(effect: effect),

            const SizedBox(height: 12),
          ],

          Text(
            effect.heals
                ? 'CURACIÓN'
                : critical
                ? 'DAÑO CRÍTICO'
                : 'DAÑO',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 4),

          Text(
            '$total',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
          ),

          if (effect.effectTypeName.isNotEmpty)
            Text(effect.effectTypeName, textAlign: TextAlign.center),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cerrar'),
        ),

        FilledButton.icon(
          onPressed: onRepeat,
          icon: const Icon(Icons.casino_rounded),
          label: const Text('Repetir'),
        ),
      ],
    );
  }
}

class _SavedResultBanner extends StatelessWidget {
  final AbilityEffect effect;

  const _SavedResultBanner({required this.effect});

  @override
  Widget build(BuildContext context) {
    final text = switch (effect.saveSuccessEffect) {
      SaveSuccessEffect.full => 'Salvación superada · efecto completo',

      SaveSuccessEffect.half => 'Salvación superada · mitad',

      SaveSuccessEffect.none => 'Salvación superada · sin efecto',
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shield_rounded, size: 18),

          const SizedBox(width: 6),

          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
