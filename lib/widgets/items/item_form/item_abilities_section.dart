import 'package:flutter/material.dart';

import '../../../models/ability.dart';
import '../../common/section_header.dart';
import '../item_ability_preview.dart';
import '../item_empty_section.dart';

class ItemAbilitiesSection extends StatelessWidget {
  final List<CharacterAbility> abilities;

  final VoidCallback onAdd;

  final void Function(int index) onEdit;
  final void Function(int index) onDelete;

  const ItemAbilitiesSection({
    super.key,
    required this.abilities,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          icon: Icons.flash_on_rounded,
          title: 'Habilidades',
          subtitle: 'Aparecen en Habilidades mientras el objeto esté equipado',
          trailing: IconButton.filledTonal(
            tooltip: 'Añadir habilidad',
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
          ),
        ),

        const SizedBox(height: 12),

        if (abilities.isEmpty)
          ItemEmptySection(
            icon: Icons.flash_on_rounded,
            text: 'Este objeto no tiene habilidades.',
            buttonText: 'Añadir habilidad',
            onPressed: onAdd,
          )
        else
          ...List.generate(abilities.length, (index) {
            final ability = abilities[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Stack(
                children: [
                  ItemAbilityPreview(ability: ability),

                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit(index);
                        }

                        if (value == 'delete') {
                          onDelete(index);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
