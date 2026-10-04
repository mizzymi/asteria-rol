import 'package:flutter/material.dart';

import '../../../models/skill.dart';
import '../../../models/character.dart';
import '../../../models/dice_pool.dart';
import '../../../models/healing_bonus.dart';
import '../../../models/passive.dart';
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
  String title = 'Curación adicional',
  String formulaDescription = 'Se suma a la curación.',
  bool allowDamageType = false,
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
        title: title,
        formulaDescription: formulaDescription,
        allowDamageType: allowDamageType,
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

  final String title;

  final String formulaDescription;

  final bool allowDamageType;

  const HealingBonusEditorDialog({
    super.key,
    required this.bonus,
    this.character,
    this.passive,
    required this.ownerPassiveId,
    required this.ownerUsesCharges,
    this.title = 'Curación adicional',
    this.formulaDescription = 'Se suma a la curación.',
    this.allowDamageType = false,
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

  static const _damageTypeOptions = <String>[
    '',
    'Cortante',
    'Perforante',
    'Contundente',
    'Fuego',
    'Frío',
    'Ácido',
    'Rayo',
    'Trueno',
    'Veneno',
    'Psíquico',
    'Radiante',
    'Necrótico',
    'Fuerza',
  ];

  late String selectedDamageType;

  @override
  void initState() {
    super.initState();

    bonus = HealingBonus(
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
      formula: widget.bonus.formula != null
          ? CharacterFormula(expression: widget.bonus.formula!.expression)
          : null,
      damageType: widget.bonus.damageType,
      chargeScaling: widget.bonus.chargeScaling,
      costs: List.from(widget.bonus.costs),
    );

    nameController = TextEditingController(text: bonus.name);

    flatController = TextEditingController(text: '${bonus.flatBonus}');

    formulaController = TextEditingController(
      text: bonus.formula?.expression ?? '',
    );

    final storedDamageType = bonus.damageType.trim();
    selectedDamageType = _damageTypeOptions.contains(storedDamageType)
        ? storedDamageType
        : '';
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

    bonus.damageType = widget.allowDamageType ? selectedDamageType : '';

    Navigator.pop(context, bonus);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),

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

                description: widget.formulaDescription,
              ),

              if (widget.allowDamageType) ...[
                const SizedBox(height: 18),

                DropdownButtonFormField<String>(
                  initialValue: selectedDamageType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de mitigación',
                    helperText:
                        'General mitiga cualquier daño. También puedes limitarla a un tipo concreto.',
                    prefixIcon: Icon(Icons.shield_rounded),
                  ),
                  items: _damageTypeOptions.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type.isEmpty ? 'General' : type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDamageType = value ?? '';
                    });
                  },
                ),
              ],

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
