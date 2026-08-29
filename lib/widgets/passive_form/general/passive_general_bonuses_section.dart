import 'package:flutter/material.dart';

import '../../../models/character.dart';

import '../../forms/common/formula_input_section.dart';

class PassiveGeneralBonusesSection extends StatelessWidget {
  final Character? character;

  final TextEditingController armorClassController;

  final TextEditingController initiativeController;

  final TextEditingController speedController;

  final TextEditingController maxHealthController;

  final TextEditingController attackController;

  final TextEditingController armorClassFormulaController;

  final TextEditingController initiativeFormulaController;

  final TextEditingController speedFormulaController;

  final TextEditingController maxHealthFormulaController;

  final TextEditingController attackFormulaController;

  const PassiveGeneralBonusesSection({
    super.key,
    required this.character,
    required this.armorClassController,
    required this.initiativeController,
    required this.speedController,
    required this.maxHealthController,
    required this.attackController,
    required this.armorClassFormulaController,
    required this.initiativeFormulaController,
    required this.speedFormulaController,
    required this.maxHealthFormulaController,
    required this.attackFormulaController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bonificaciones fijas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _SignedNumberField(
                        controller: armorClassController,
                        label: 'CA fija',
                        icon: Icons.shield_rounded,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _SignedNumberField(
                        controller: initiativeController,
                        label: 'Iniciativa fija',
                        icon: Icons.bolt_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _SignedNumberField(
                        controller: maxHealthController,
                        label: 'PG máximos fijos',
                        icon: Icons.favorite_rounded,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _SignedNumberField(
                        controller: attackController,
                        label: 'Al golpe fijo',
                        icon: Icons.gps_fixed_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _SignedNumberField(
                  controller: speedController,
                  label: 'Velocidad fija',
                  icon: Icons.directions_run_rounded,
                  suffixText: 'pies',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Fórmulas de bonificación',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Estas fórmulas se suman a las bonificaciones fijas.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: 16),

                FormulaInputSection(
                  controller: armorClassFormulaController,
                  character: character,
                  title: 'CA',
                  label: 'Fórmula · CA',
                  hint: 'rounddown(level / 5)',
                ),

                const SizedBox(height: 16),

                FormulaInputSection(
                  controller: initiativeFormulaController,
                  character: character,
                  title: 'Iniciativa',
                  label: 'Fórmula · Iniciativa',
                  hint: 'rounddown(level / 5)',
                ),

                const SizedBox(height: 16),

                FormulaInputSection(
                  controller: speedFormulaController,
                  character: character,
                  title: 'Velocidad',
                  label: 'Fórmula · Velocidad',
                  hint: 'rounddown(level / 5)',
                ),

                const SizedBox(height: 16),

                FormulaInputSection(
                  controller: maxHealthFormulaController,
                  character: character,
                  title: 'PG máximos',
                  label: 'Fórmula · PG máximos',
                  hint: 'rounddown(level / 5)',
                ),

                const SizedBox(height: 16),

                FormulaInputSection(
                  controller: attackFormulaController,
                  character: character,
                  title: 'Al golpe',
                  label: 'Fórmula · Al golpe',
                  hint: 'counter(deaths) * 2',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SignedNumberField extends StatelessWidget {
  final TextEditingController controller;

  final String label;

  final IconData icon;

  final String? suffixText;

  const _SignedNumberField({
    required this.controller,
    required this.label,
    required this.icon,
    this.suffixText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,

      keyboardType: const TextInputType.numberWithOptions(signed: true),

      decoration: InputDecoration(
        labelText: label,
        hintText: '0',
        prefixIcon: Icon(icon),
        suffixText: suffixText,
      ),
    );
  }
}
