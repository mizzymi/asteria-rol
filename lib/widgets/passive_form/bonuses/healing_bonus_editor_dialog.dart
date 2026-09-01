import 'package:flutter/material.dart';

import '../../../models/character.dart';
import '../../../models/dice_pool.dart';
import '../../../models/healing_bonus.dart';
import '../../../models/passive.dart';
import '../../../models/passive_charge_dice_scaling.dart';
import '../../../models/formulas/character_formula.dart';

import '../../forms/common/ability_multiplier_editor.dart';
import '../../forms/common/dice_pools_editor.dart';
import '../../forms/common/formula_input_section.dart';

import 'action_costs_editor.dart';
import 'passive_charge_scaling_editor.dart';

Future<HealingBonus?> showHealingBonusEditorDialog(
  BuildContext context, {
  required HealingBonus bonus,
  Character? character,
  CharacterPassive? passive,
  required String ownerPassiveId,
  required bool ownerUsesCharges,
}) {
  return showDialog<HealingBonus>(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return HealingBonusEditorDialog(
        bonus: bonus,
        character: character,
        passive: passive,
        ownerPassiveId: ownerPassiveId,
        ownerUsesCharges: ownerUsesCharges,
      );
    },
  );
}

class HealingBonusEditorDialog extends StatefulWidget {
  final HealingBonus bonus;

  final Character? character;

  final CharacterPassive? passive;

  final String ownerPassiveId;

  final bool ownerUsesCharges;

  const HealingBonusEditorDialog({
    super.key,
    required this.bonus,
    this.character,
    this.passive,
    required this.ownerPassiveId,
    required this.ownerUsesCharges,
  });

  @override
  State<HealingBonusEditorDialog> createState() =>
      _HealingBonusEditorDialogState();
}

class _HealingBonusEditorDialogState extends State<HealingBonusEditorDialog> {
  late HealingBonus bonus;

  late final TextEditingController nameController;

  late final TextEditingController flatController;

  late final TextEditingController formulaController;

  @override
  void initState() {
    super.initState();

    bonus = HealingBonus.fromMap(widget.bonus.toMap());

    nameController = TextEditingController(text: bonus.name);

    flatController = TextEditingController(text: '${bonus.flatBonus}');

    formulaController = TextEditingController(
      text: bonus.formula?.expression ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    flatController.dispose();
    formulaController.dispose();

    super.dispose();
  }

  void _save() {
    bonus.name = nameController.text.trim();

    bonus.flatBonus = int.tryParse(flatController.text.trim()) ?? 0;

    final expression = formulaController.text.trim();

    bonus.formula = expression.isEmpty
        ? null
        : CharacterFormula(expression: expression);

    Navigator.pop(context, bonus);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Curación adicional'),

      content: SizedBox(
        width: 560,

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              TextFormField(
                controller: nameController,

                decoration: const InputDecoration(labelText: 'Nombre'),
              ),

              const SizedBox(height: 18),

              DicePoolsEditor(
                pools: bonus.dicePools,

                onAdd: () {
                  setState(() {
                    bonus.dicePools.add(DicePool(count: 1, sides: 6));
                  });
                },

                onChanged: () {
                  setState(() {});
                },
              ),

              const SizedBox(height: 18),

              AbilityMultiplierEditor(
                multipliers: bonus.abilityModifierMultipliers,

                onChanged: (value) {
                  setState(() {
                    bonus.abilityModifierMultipliers = value;
                  });
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: flatController,

                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),

                decoration: const InputDecoration(labelText: 'Bonus fijo'),
              ),

              const SizedBox(height: 20),

              FormulaInputSection(
                controller: formulaController,

                character: widget.character,

                title: 'Fórmula',

                label: 'Fórmula adicional',

                hint: 'SAB_MOD * 2',

                description: 'Se suma a la curación.',
              ),

              const SizedBox(height: 24),

              const Divider(),

              const SizedBox(height: 12),

              Text(
                'Escalado por cargas',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 8),

              PassiveChargeScalingEditor(
                scaling: bonus.chargeScaling,

                ownerUsesCharges: widget.ownerUsesCharges,

                onChanged: (value) {
                  setState(() {
                    bonus.chargeScaling = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              const Divider(),

              const SizedBox(height: 12),

              ActionCostsEditor(
                costs: bonus.costs,

                character: widget.character,

                ownerPassiveId: widget.ownerPassiveId,

                ownerUsesCharges: widget.ownerUsesCharges,

                onChanged: () {
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),

        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
