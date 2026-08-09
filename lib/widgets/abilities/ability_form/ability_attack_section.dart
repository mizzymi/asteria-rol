import 'package:flutter/material.dart';

class AbilityAttackSection extends StatelessWidget {
  final bool requiresAttackRoll;
  final bool proficient;

  final TextEditingController attackBonusController;

  final ValueChanged<bool> onRequiresAttackChanged;

  final ValueChanged<bool> onProficientChanged;

  const AbilityAttackSection({
    super.key,
    required this.requiresAttackRoll,
    required this.proficient,
    required this.attackBonusController,
    required this.onRequiresAttackChanged,
    required this.onProficientChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.gps_fixed_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(width: 8),

            Text(
              'Ataque',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        const SizedBox(height: 10),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: requiresAttackRoll,
          title: const Text('Requiere tirada de ataque'),
          subtitle: const Text('Tira d20 para comprobar si impacta'),
          onChanged: onRequiresAttackChanged,
        ),

        if (requiresAttackRoll) ...[
          const SizedBox(height: 8),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: proficient,
            title: const Text('Sumar competencia'),
            subtitle: const Text('Añade el bonus de competencia a la tirada'),
            onChanged: onProficientChanged,
          ),

          const SizedBox(height: 10),

          TextFormField(
            controller: attackBonusController,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            decoration: const InputDecoration(
              labelText: 'Bonus adicional al golpe',
              helperText: 'Ej: arma +1, rasgo +2...',
              prefixIcon: Icon(Icons.add_rounded),
            ),
          ),
        ],
      ],
    );
  }
}
