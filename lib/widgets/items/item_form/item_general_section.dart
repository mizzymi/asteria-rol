import 'package:flutter/material.dart';

import '../../../models/item_definition.dart';

import '../../common/app_card.dart';
import '../../common/section_header.dart';

class ItemGeneralSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  final ItemType itemType;

  final ValueChanged<ItemType> onTypeChanged;

  const ItemGeneralSection({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.itemType,
    required this.onTypeChanged,
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
                      (type) => DropdownMenuItem<ItemType>(
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

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _typeDescription(itemType),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _typeDescription(ItemType type) {
    switch (type) {
      case ItemType.armor:
        return 'Armadura corporal con configuración de CA.';

      case ItemType.shield:
        return 'Escudo equipable para protección adicional.';

      case ItemType.helmet:
        return 'Objeto pensado para el slot de cabeza.';

      case ItemType.gloves:
        return 'Objeto pensado para el slot de manos.';

      case ItemType.boots:
        return 'Objeto pensado para el slot de pies.';

      case ItemType.ring:
        return 'Anillo equipable.';

      case ItemType.amulet:
        return 'Amuleto equipable.';

      case ItemType.weapon:
        return 'Arma que puede utilizar el Action Engine.';

      case ItemType.accessory:
        return 'Objeto equipable de propósito general.';

      case ItemType.consumable:
        return 'Objeto que puede consumirse al utilizarlo.';

      case ItemType.potion:
        return 'Poción o brebaje con efectos consumibles inmediatos.';

      case ItemType.scroll:
        return 'Pergamino mágico o escrito de un solo uso.';

      case ItemType.tool:
        return 'Herramienta; no necesita habilidades ni pasivas.';

      case ItemType.material:
        return 'Material almacenado normalmente en cantidades.';

      case ItemType.book:
        return 'Libro o fuente de conocimiento.';

      case ItemType.special:
        return 'Objeto especial con comportamiento personalizado.';

      case ItemType.ammunition:
        return 'Munición consumible utilizada por armas a distancia.';

      case ItemType.container:
        return 'Contenedor o bolsa para almacenar otros objetos.';

      case ItemType.misc:
        return 'Objeto sin una categoría específica.';
    }
  }
}
