import 'package:flutter/material.dart';

import '../../../models/passive.dart';
import '../../common/section_header.dart';
import '../item_empty_section.dart';
import '../item_passive_preview.dart';

class ItemPassivesSection extends StatelessWidget {
  final List<CharacterPassive> passives;

  final VoidCallback onAdd;

  final void Function(int index) onEdit;
  final void Function(int index) onDelete;

  const ItemPassivesSection({
    super.key,
    required this.passives,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          icon: Icons.auto_awesome_rounded,
          title: 'Pasivas',
          subtitle: 'Se aplican mientras el objeto esté equipado',
          trailing: IconButton.filledTonal(
            tooltip: 'Añadir pasiva',
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
          ),
        ),

        const SizedBox(height: 12),

        if (passives.isEmpty)
          ItemEmptySection(
            icon: Icons.auto_awesome_rounded,
            text: 'Este objeto no tiene pasivas.',
            buttonText: 'Añadir pasiva',
            onPressed: onAdd,
          )
        else
          ...List.generate(passives.length, (index) {
            final passive = passives[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Stack(
                children: [
                  ItemPassivePreview(passive: passive),

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
