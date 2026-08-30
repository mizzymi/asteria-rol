import 'package:flutter/material.dart';

import '../../../models/character.dart';
import '../../../models/damage_bonus.dart';
import '../../../models/dice_pool.dart';
import '../../../models/passive.dart';
import '../../../models/formulas/character_formula.dart';

import '../../forms/common/ability_multiplier_editor.dart';
import '../../forms/common/dice_pools_editor.dart';
import '../../forms/common/formula_input_section.dart';

Future<DamageBonus?> showDamageBonusEditorDialog(
  BuildContext context, {
  required DamageBonus bonus,
  Character? character,
  CharacterPassive? passive,
}) {
  return showDialog<DamageBonus>(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return DamageBonusEditorDialog(
        bonus: bonus,
        character: character,
        passive: passive,
      );
    },
  );
}

class DamageBonusEditorDialog extends StatefulWidget {
  final DamageBonus bonus;

  final Character? character;

  final CharacterPassive? passive;

  const DamageBonusEditorDialog({
    super.key,
    required this.bonus,
    this.character,
    this.passive,
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

    bonus = DamageBonus.fromMap(widget.bonus.toMap());

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
