import 'package:flutter/material.dart';

import '../../../models/item_definition.dart';
import '../../common/app_card.dart';
import '../../common/section_header.dart';

class ItemArmorSection extends StatelessWidget {
  final ArmorCategory armorCategory;
  final TextEditingController armorBaseClassController;

  final ValueChanged<ArmorCategory> onCategoryChanged;

  const ItemArmorSection({
    super.key,
    required this.armorCategory,
    required this.armorBaseClassController,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(
          icon: Icons.shield_rounded,
          title: 'Armadura',
          subtitle: 'Configura la CA automática',
        ),

        const SizedBox(height: 12),

        AppCard(
          accentColor: const Color(0xFF4D8FE8),
          child: Column(
            children: [
              DropdownButtonFormField<ArmorCategory>(
                initialValue: armorCategory,
                decoration: const InputDecoration(
                  labelText: 'Tipo de armadura',
                  prefixIcon: Icon(Icons.shield_rounded),
                ),
                items: ArmorCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    onCategoryChanged(value);
                  }
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: armorBaseClassController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'CA base',
                  prefixIcon: const Icon(Icons.shield_outlined),
                  helperText: switch (armorCategory) {
                    ArmorCategory.light =>
                      'CA base + todo el modificador de DES',

                    ArmorCategory.medium => 'CA base + DES (máximo +2)',

                    ArmorCategory.heavy => 'CA base sin modificador de DES',
                  },
                ),
                validator: (value) {
                  final result = int.tryParse(value ?? '');

                  if (result == null || result < 1) {
                    return 'Introduce una CA válida';
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
