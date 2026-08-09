import 'package:flutter/material.dart';

import '../../../models/journal_entry.dart';

import '../../common/app_card.dart';
import '../../common/section_header.dart';

class JournalGeneralSection extends StatelessWidget {
  final TextEditingController titleController;

  final JournalEntryType type;

  final ValueChanged<JournalEntryType> onTypeChanged;

  const JournalGeneralSection({
    super.key,
    required this.titleController,
    required this.type,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(
          icon: Icons.history_edu_rounded,
          title: 'Entrada',
          subtitle: 'Información principal',
        ),

        const SizedBox(height: 12),

        AppCard(
          child: Column(
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduce un título';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<JournalEntryType>(
                initialValue: type,
                decoration: const InputDecoration(
                  labelText: 'Tipo de entrada',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: JournalEntryType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.label));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onTypeChanged(value);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
