import 'package:flutter/material.dart';

class PassiveChargesSection extends StatelessWidget {
  final bool hasCharges;

  final bool unlimitedCharges;

  final TextEditingController maxChargesController;

  final TextEditingController rechargeController;

  final ValueChanged<bool> onHasChargesChanged;

  final ValueChanged<bool> onUnlimitedChanged;

  const PassiveChargesSection({
    super.key,
    required this.hasCharges,
    required this.unlimitedCharges,
    required this.maxChargesController,
    required this.rechargeController,
    required this.onHasChargesChanged,
    required this.onUnlimitedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,

          value: hasCharges,

          title: const Text('Usa cargas'),

          subtitle: const Text('Permite gastar y recuperar cargas'),

          onChanged: onHasChargesChanged,
        ),

        if (hasCharges) ...[
          const SizedBox(height: 4),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,

            value: unlimitedCharges,

            title: const Text('Sin máximo'),

            subtitle: const Text(
              'Las cargas pueden aumentar sin un límite máximo',
            ),

            secondary: const Icon(Icons.all_inclusive_rounded),

            onChanged: onUnlimitedChanged,
          ),

          if (!unlimitedCharges) ...[
            const SizedBox(height: 12),

            TextFormField(
              controller: maxChargesController,

              keyboardType: TextInputType.number,

              decoration: const InputDecoration(
                labelText: 'Cargas máximas',
                prefixIcon: Icon(Icons.battery_full_rounded),
              ),

              validator: (value) {
                final parsed = int.tryParse(value?.trim() ?? '');

                if (parsed == null || parsed <= 0) {
                  return 'Introduce un máximo válido';
                }

                return null;
              },
            ),
          ],

          const SizedBox(height: 12),

          TextFormField(
            controller: rechargeController,

            decoration: const InputDecoration(
              labelText: 'Recuperación',
              hintText: 'Descanso largo, amanecer...',
              prefixIcon: Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ],
    );
  }
}
