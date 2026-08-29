import 'package:flutter/material.dart';

import '../../../models/character.dart';
import '../../../models/passive.dart';
import '../../../models/passive_resource_modifier.dart';
import '../../../models/formulas/character_formula.dart';
import '../../../models/formulas/formula_modifier.dart';

import '../../forms/common/formula_input_section.dart';

Future<PassiveResourceModifier?> showResourceModifierEditorDialog(
  BuildContext context, {
  required PassiveResourceModifier modifier,
  required Character character,
  CharacterPassive? passive,
}) {
  return showDialog<PassiveResourceModifier>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return ResourceModifierEditorDialog(
        modifier: modifier,
        character: character,
        passive: passive,
      );
    },
  );
}

class ResourceModifierEditorDialog extends StatefulWidget {
  final PassiveResourceModifier modifier;

  final Character character;

  final CharacterPassive? passive;

  const ResourceModifierEditorDialog({
    super.key,
    required this.modifier,
    required this.character,
    this.passive,
  });

  @override
  State<ResourceModifierEditorDialog> createState() =>
      _ResourceModifierEditorDialogState();
}

class _ResourceModifierEditorDialogState
    extends State<ResourceModifierEditorDialog> {
  late PassiveResourceModifier modifier;

  late final TextEditingController formulaController;

  @override
  void initState() {
    super.initState();

    modifier = PassiveResourceModifier.fromMap(widget.modifier.toMap());

    formulaController = TextEditingController(
      text: modifier.formula.expression,
    );
  }

  @override
  void dispose() {
    formulaController.dispose();

    super.dispose();
  }

  void _save() {
    final expression = formulaController.text.trim();

    modifier.formula = CharacterFormula(
      expression: expression.isEmpty ? '0' : expression,
    );

    Navigator.pop(context, modifier);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modificar recurso'),

      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: modifier.resourceId,

                decoration: const InputDecoration(
                  labelText: 'Recurso',
                  prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                ),

                items: widget.character.resources.map((resource) {
                  return DropdownMenuItem(
                    value: resource.id,
                    child: Text(resource.name),
                  );
                }).toList(),

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    modifier.resourceId = value;
                  });
                },
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<PassiveResourceTarget>(
                initialValue: modifier.target,

                decoration: const InputDecoration(
                  labelText: 'Valor a modificar',
                ),

                items: PassiveResourceTarget.values.map((target) {
                  return DropdownMenuItem(
                    value: target,
                    child: Text(
                      target == PassiveResourceTarget.current
                          ? 'Cantidad actual'
                          : 'Cantidad máxima',
                    ),
                  );
                }).toList(),

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    modifier.target = value;
                  });
                },
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<FormulaModifierOperation>(
                initialValue: modifier.operation,

                decoration: const InputDecoration(labelText: 'Operación'),

                items: FormulaModifierOperation.values.map((operation) {
                  return DropdownMenuItem(
                    value: operation,
                    child: Text(operation.label),
                  );
                }).toList(),

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    modifier.operation = value;
                  });
                },
              ),

              const SizedBox(height: 18),

              FormulaInputSection(
                controller: formulaController,

                character: widget.character,

                title: 'Fórmula',

                label: 'Fórmula',

                hint: 'rounddown(counter(kills) / 75)',
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
