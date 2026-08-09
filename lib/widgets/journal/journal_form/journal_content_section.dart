import 'package:flutter/material.dart';

import '../../common/app_card.dart';
import '../../common/section_header.dart';

class JournalContentSection extends StatelessWidget {
  final TextEditingController contentController;

  final TextEditingController notesController;

  const JournalContentSection({
    super.key,
    required this.contentController,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(
          icon: Icons.menu_book_rounded,
          title: 'Contenido',
          subtitle: 'Qué ocurrió y qué quieres recordar',
        ),

        const SizedBox(height: 12),

        AppCard(
          child: Column(
            children: [
              TextFormField(
                controller: contentController,
                minLines: 7,
                maxLines: 18,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Contenido',
                  hintText: '¿Qué ocurrió?',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: notesController,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
