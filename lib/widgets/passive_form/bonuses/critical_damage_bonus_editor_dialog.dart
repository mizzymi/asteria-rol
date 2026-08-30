import 'package:flutter/material.dart';

import '../../../models/character.dart';
import '../../../models/critical_damage_bonus.dart';
import '../../../models/dice_pool.dart';
import '../../../models/passive.dart';
import '../../../models/formulas/character_formula.dart';

import '../../forms/common/ability_multiplier_editor.dart';
import '../../forms/common/dice_pools_editor.dart';
import '../../forms/common/formula_input_section.dart';

Future<CriticalDamageBonus?> showCriticalDamageBonusEditorDialog(
  BuildContext context, {
  required CriticalDamageBonus bonus,
  Character? character,
  CharacterPassive? passive,
}) {
  return showDialog<CriticalDamageBonus>(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return CriticalDamageBonusEditorDialog(
        bonus: bonus,
        character: character,
        passive: passive,
      );
    },
  );
}

class CriticalDamageBonusEditorDialog extends StatefulWidget {
  final CriticalDamageBonus bonus;

  final Character? character;

  final CharacterPassive? passive;

  const CriticalDamageBonusEditorDialog({
    super.key,
    required this.bonus,
    this.character,
    this.passive,
  });

  @override
  State<CriticalDamageBonusEditorDialog> createState() =>
      _CriticalDamageBonusEditorDialogState();
}

class _CriticalDamageBonusEditorDialogState
    extends State<CriticalDamageBonusEditorDialog> {
  late CriticalDamageBonus bonus;

  late final TextEditingController nameController;
  late final TextEditingController typeController;
  late final TextEditingController chanceController;
  late final TextEditingController descriptionController;
  late final TextEditingController flatController;
  late final TextEditingController formulaController;

  @override
  void initState() {
    super.initState();

    bonus = CriticalDamageBonus.fromMap(widget.bonus.toMap());

    nameController = TextEditingController(text: bonus.name);

    typeController = TextEditingController(text: bonus.damageType);

    chanceController = TextEditingController(text: '${bonus.chancePercent}');

    descriptionController = TextEditingController(text: bonus.description);

    flatController = TextEditingController(text: '${bonus.flatBonus}');

    formulaController = TextEditingController(
      text: bonus.formula?.expression ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    typeController.dispose();
    chanceController.dispose();
    descriptionController.dispose();
    flatController.dispose();
    formulaController.dispose();

    super.dispose();
  }

  void _save() {
    bonus.name = nameController.text.trim();

    bonus.damageType = typeController.text.trim();

    bonus.description = descriptionController.text.trim();

    bonus.flatBonus = int.tryParse(flatController.text.trim()) ?? 0;

    bonus.chancePercent = int.tryParse(chanceController.text.trim()) ?? 100;

    final expression = formulaController.text.trim();

    bonus.formula = expression.isEmpty
        ? null
        : CharacterFormula(expression: expression);

    bonus.normalize();

    Navigator.pop(context, bonus);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Daño crítico adicional'),

      content: SizedBox(
        width: 580,
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
                decoration: const InputDecoration(labelText: 'Tipo de daño'),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: chanceController,

                keyboardType: TextInputType.number,

                decoration: const InputDecoration(
                  labelText: 'Probabilidad',
                  suffixText: '%',
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
                  labelText: 'Modificador fijo',
                ),
              ),

              const SizedBox(height: 20),

              FormulaInputSection(
                controller: formulaController,

                character: widget.character,

                title: 'Fórmula',

                label: 'Fórmula adicional',

                hint: 'rounddown(level / 5)',
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: descriptionController,

                minLines: 2,
                maxLines: 4,

                decoration: const InputDecoration(labelText: 'Descripción'),
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
