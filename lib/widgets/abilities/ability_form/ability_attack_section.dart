import 'package:flutter/material.dart';

class AbilityAttackSection extends StatelessWidget {
  final bool requiresAttackRoll;
  final bool proficient;

  final TextEditingController attackBonusController;

  final ValueChanged<bool> onRequiresAttackChanged;

  final ValueChanged<bool> onProficientChanged;

  final int criticalMinimumNaturalRoll;

  final bool empoweredCritical;

  final int empoweredCriticalMultiplier;

  final TextEditingController empoweredCriticalFormulaController;

  final ValueChanged<int> onCriticalMinimumNaturalRollChanged;

  final ValueChanged<bool> onEmpoweredCriticalChanged;

  final ValueChanged<int> onEmpoweredCriticalMultiplierChanged;

  const AbilityAttackSection({
    super.key,
    required this.requiresAttackRoll,
    required this.proficient,
    required this.attackBonusController,
    required this.onRequiresAttackChanged,
    required this.onProficientChanged,
    required this.criticalMinimumNaturalRoll,
    required this.empoweredCritical,
    required this.empoweredCriticalMultiplier,
    required this.empoweredCriticalFormulaController,
    required this.onCriticalMinimumNaturalRollChanged,
    required this.onEmpoweredCriticalChanged,
    required this.onEmpoweredCriticalMultiplierChanged,
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
          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            initialValue: criticalMinimumNaturalRoll,
            decoration: const InputDecoration(
              labelText: 'Rango crítico',
              helperText: 'Valor natural mínimo del d20 que produce crítico',
              prefixIcon: Icon(Icons.auto_awesome_rounded),
            ),
            items: List.generate(20, (index) {
              final value = 20 - index;

              final label = value == 20 ? '20' : '$value–20';

              return DropdownMenuItem(value: value, child: Text(label));
            }),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              onCriticalMinimumNaturalRollChanged(value);
            },
          ),

          const SizedBox(height: 8),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: empoweredCritical,
            title: const Text('Crítico potenciado'),
            subtitle: const Text(
              'Los críticos de esta habilidad usan la regla potenciada',
            ),
            onChanged: onEmpoweredCriticalChanged,
          ),

          if (empoweredCritical) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: empoweredCriticalFormulaController,
              decoration: const InputDecoration(
                labelText: 'Fórmula de crítico',
                helperText:
                    'TIRADA, MAX, MOD, TURNO, CARGAS, RECURSO("Ki"), CONTADOR("Combo")',
                prefixIcon: Icon(Icons.functions_rounded),
              ),
            ),
          ],

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
