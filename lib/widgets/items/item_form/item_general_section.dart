import 'package:flutter/material.dart';

import '../../../models/item.dart';
import '../../common/app_card.dart';
import '../../common/section_header.dart';

class ItemGeneralSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController quantityController;

  final ItemType itemType;
  final bool equipped;

  final ValueChanged<ItemType> onTypeChanged;
  final ValueChanged<bool> onEquippedChanged;

  const ItemGeneralSection({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.quantityController,
    required this.itemType,
    required this.equipped,
    required this.onTypeChanged,
    required this.onEquippedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(
          icon: Icons.inventory_2_rounded,
          title: 'Información',
          subtitle: 'Datos principales del objeto',
        ),

        const SizedBox(height: 12),

        AppCard(
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.inventory_2_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduce un nombre';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: descriptionController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<ItemType>(
                initialValue: itemType,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: ItemType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    onTypeChanged(value);
                  }
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  prefixIcon: Icon(Icons.layers_rounded),
                ),
                validator: (value) {
                  final quantity = int.tryParse(value ?? '');

                  if (quantity == null || quantity < 1) {
                    return 'Mínimo 1';
                  }

                  return null;
                },
              ),

              if (itemType.isEquipable) ...[
                const SizedBox(height: 6),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: equipped,
                  title: const Text('Equipado'),
                  subtitle: itemType.exclusiveSlot
                      ? Text(
                          'Al equiparlo sustituirá cualquier ${itemType.label.toLowerCase()} equipado.',
                        )
                      : const Text(
                          'Sus pasivas y habilidades estarán disponibles mientras esté equipado.',
                        ),
                  onChanged: onEquippedChanged,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
