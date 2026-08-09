import 'package:flutter/material.dart';

import '../../common/app_card.dart';
import '../../common/section_header.dart';

class ItemNotesSection extends StatelessWidget {
  final TextEditingController notesController;

  const ItemNotesSection({super.key, required this.notesController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(
          icon: Icons.notes_rounded,
          title: 'Notas',
          subtitle: 'Información adicional del objeto',
        ),

        const SizedBox(height: 12),

        AppCard(
          child: TextFormField(
            controller: notesController,
            minLines: 2,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Notas',
              alignLabelWithHint: true,
            ),
          ),
        ),
      ],
    );
  }
}
