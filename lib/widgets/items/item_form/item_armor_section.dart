import 'package:flutter/material.dart';
import '../../../models/character.dart';
import '../../../models/item_definition.dart';
import '../../formulas/formula_insert_bar.dart';

class ItemArmorSection extends StatelessWidget {
  final ArmorCategory armorCategory;
  final TextEditingController armorBaseClassController;
  final TextEditingController customFormulaController;
  final Character? character;
  final ValueChanged<ArmorCategory> onCategoryChanged;

  const ItemArmorSection({
    super.key,
    required this.armorCategory,
    required this.armorBaseClassController,
    required this.customFormulaController,
    required this.onCategoryChanged,
    this.character,
  });

  void _insertToken(String token) {
    final text = customFormulaController.text;
    final selection = customFormulaController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, token);
    customFormulaController.text = newText;
    customFormulaController.selection = TextSelection.collapsed(
      offset: start + token.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = armorCategory == ArmorCategory.custom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<ArmorCategory>(
          initialValue: armorCategory,
          decoration: const InputDecoration(
            labelText: 'Categoría de armadura',
            prefixIcon: Icon(Icons.shield_rounded),
          ),
          items: ArmorCategory.values.map((cat) {
            return DropdownMenuItem(
              value: cat,
              child: Text(cat.label),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onCategoryChanged(val);
          },
        ),
        const SizedBox(height: 16),
        if (!isCustom)
          TextFormField(
            controller: armorBaseClassController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Clase de Armadura Base (CA)',
              prefixIcon: Icon(Icons.security_rounded),
              helperText: 'CA fija otorgada por la pieza.',
            ),
          )
        else ...[
          TextFormField(
            controller: customFormulaController,
            decoration: const InputDecoration(
              labelText: 'Fórmula de Clase de Armadura',
              hintText: 'ej: 10 + DES_MOD + CON_MOD',
              prefixIcon: Icon(Icons.calculate_rounded),
              helperText: 'Calcula la CA dinámicamente según atributos o contadores.',
            ),
          ),
          const SizedBox(height: 10),
          FormulaInsertBar(
            character: character,
            onInsert: _insertToken,
          ),
        ],
      ],
    );
  }
}
