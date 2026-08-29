import 'package:flutter/material.dart';

import '../../../models/character.dart';
import '../../../models/formulas/character_formula.dart';
import '../../../models/formulas/formula_bonus.dart';

import 'formula_input_section.dart';

Future<FormulaBonus?> showFormulaBonusEditorDialog(
  BuildContext context, {
  required String title,
  required FormulaBonus bonus,
  Character? character,
}) {
  return showDialog<FormulaBonus>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return FormulaBonusEditorDialog(
        title: title,
        bonus: bonus,
        character: character,
      );
    },
  );
}

class FormulaBonusEditorDialog extends StatefulWidget {
  final String title;

  final FormulaBonus bonus;

  final Character? character;

  const FormulaBonusEditorDialog({
    super.key,
    required this.title,
    required this.bonus,
    this.character,
  });

  @override
  State<FormulaBonusEditorDialog> createState() =>
      _FormulaBonusEditorDialogState();
}

class _FormulaBonusEditorDialogState extends State<FormulaBonusEditorDialog> {
  late final TextEditingController flatController;

  late final TextEditingController formulaController;

  @override
  void initState() {
    super.initState();

    flatController = TextEditingController(text: '${widget.bonus.flatValue}');

    formulaController = TextEditingController(
      text: widget.bonus.formula?.expression ?? '',
    );
  }

  @override
  void dispose() {
    flatController.dispose();
    formulaController.dispose();

    super.dispose();
  }

  void _save() {
    final expression = formulaController.text.trim();

    Navigator.pop(
      context,
      FormulaBonus(
        flatValue: int.tryParse(flatController.text.trim()) ?? 0,
        formula: expression.isEmpty
            ? null
            : CharacterFormula(expression: expression),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),

      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: flatController,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Bonus fijo',
                  hintText: '0',
                  prefixIcon: Icon(Icons.exposure_plus_1_rounded),
                ),
              ),

              const SizedBox(height: 18),

              FormulaInputSection(
                controller: formulaController,
                character: widget.character,
                title: 'Fórmula',
                label: 'Fórmula opcional',
                hint: 'rounddown(level / 5)',
                description:
                    'Se suma al bonus fijo. Puede utilizar atributos, recursos, contadores y otras variables disponibles.',
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
