import 'package:flutter/material.dart';

import '../../models/journal_entry.dart';
import 'journal_colors.dart';

class JournalFilterBar extends StatelessWidget {
  final JournalEntryType? selected;

  final ValueChanged<JournalEntryType?> onChanged;

  const JournalFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        scrollDirection: Axis.horizontal,
        children: [
          ChoiceChip(
            label: const Text('Todo'),
            selected: selected == null,
            onSelected: (_) {
              onChanged(null);
            },
          ),

          const SizedBox(width: 8),

          ...JournalEntryType.values.map((type) {
            final color = JournalColors.color(type);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(JournalColors.icon(type), size: 16, color: color),
                label: Text(type.label),
                selected: selected == type,
                onSelected: (_) {
                  onChanged(type);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
