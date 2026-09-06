import 'package:flutter/material.dart';

import '../../../models/skill.dart';
import '../../../models/character.dart';
import '../../../models/damage_bonus.dart';
import '../../../models/dice_pool.dart';
import '../../../models/passive.dart';
import '../../../models/formulas/character_formula.dart';

import '../../forms/common/ability_multiplier_editor.dart';
import '../../forms/common/dice_pools_editor.dart';
import '../../forms/common/formula_input_section.dart';

import 'action_costs_editor.dart';
import 'passive_charge_scaling_editor.dart';

Future<DamageBonus?> showDamageBonusEditorDialog(
  BuildContext context, {
  required DamageBonus bonus,
  Character? character,
  CharacterPassive? passive,
  required String ownerPassiveId,
  required bool ownerUsesCharges,
}) {
  return showDialog<DamageBonus>(
    context: context,
    barrierDismissible: true,

    builder: (_) {
      return DamageBonusEditorDialog(
        bonus: bonus,

        character: character,

        passive: passive,

        ownerPassiveId: ownerPassiveId,

        ownerUsesCharges: ownerUsesCharges,
      );
    },
  );
}

class DamageBonusEditorDialog extends StatefulWidget {
  final DamageBonus bonus;

  final Character? character;

  final CharacterPassive? passive;

  final String ownerPassiveId;

  final bool ownerUsesCharges;

  const DamageBonusEditorDialog({
    super.key,
    required this.bonus,
    this.character,
    this.passive,
    required this.ownerPassiveId,
    required this.ownerUsesCharges,
  });

  @override
  State<DamageBonusEditorDialog> createState() =>
      _DamageBonusEditorDialogState();
}

class _DamageBonusEditorDialogState extends State<DamageBonusEditorDialog> {
  late DamageBonus bonus;

  late final TextEditingController nameController;

  late final TextEditingController typeController;

  late final TextEditingController flatController;

  late final TextEditingController formulaController;

  @override
  void initState() {
    super.initState();

    bonus = DamageBonus(
      id: widget.bonus.id,
      name: widget.bonus.name,
      dicePools: List<DicePool>.from(
        widget.bonus.dicePools.map(
          (p) => DicePool(count: p.count, sides: p.sides),
        ),
      ),
      abilityModifierMultipliers: Map<AbilityType, int>.from(
        widget.bonus.abilityModifierMultipliers,
      ),
      flatBonus: widget.bonus.flatBonus,
      damageType: widget.bonus.damageType,
      formula: widget.bonus.formula != null
          ? CharacterFormula(expression: widget.bonus.formula!.expression)
          : null,
      condition: widget.bonus.condition,
      optional: widget.bonus.optional,
      optionalGroupId: widget.bonus.optionalGroupId,
      optionalLabel: widget.bonus.optionalLabel,
      hitBehavior: widget.bonus.hitBehavior,
      participatesInCritical: widget.bonus.participatesInCritical,
      chargeScaling: widget.bonus.chargeScaling,
      costs: List.from(widget.bonus.costs),
    );

    nameController = TextEditingController(text: bonus.name);
    typeController = TextEditingController(text: bonus.damageType);
    flatController = TextEditingController(text: '${bonus.flatBonus}');
    formulaController = TextEditingController(
      text: bonus.formula?.expression ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    typeController.dispose();
    flatController.dispose();
    formulaController.dispose();

    super.dispose();
  }

  void _save() {
    bonus.name = nameController.text.trim();

    bonus.damageType = typeController.text.trim();

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
      title: const Text('Daño adicional'),

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

              const SizedBox(height: 12),

              TextFormField(
                controller: typeController,

                decoration: const InputDecoration(
                  labelText: 'Tipo de daño',

                  hintText: 'Fuego, radiante...',
                ),
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

                decoration: const InputDecoration(
                  labelText: 'Bonus fijo',

                  hintText: '0',
                ),
              ),

              const SizedBox(height: 20),

              FormulaInputSection(
                controller: formulaController,

                character: widget.character,

                title: 'Fórmula',

                label: 'Fórmula adicional',

                hint: 'resource(souls)',

                description: 'Se suma al daño adicional.',
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
