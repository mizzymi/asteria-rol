import 'package:flutter/material.dart';

import '../../models/journal_entry.dart';

class JournalColors {
  const JournalColors._();

  static Color color(JournalEntryType type) {
    switch (type) {
      case JournalEntryType.session:
        return const Color(0xFF8B6FE8);

      case JournalEntryType.quest:
        return const Color(0xFFF29E4C);

      case JournalEntryType.discovery:
        return const Color(0xFFF2C94C);

      case JournalEntryType.npc:
        return const Color(0xFFE45AA7);

      case JournalEntryType.combat:
        return const Color(0xFFE85D5D);

      case JournalEntryType.location:
        return const Color(0xFF55B96B);

      case JournalEntryType.personal:
        return const Color(0xFFE84A8A);

      case JournalEntryType.other:
        return const Color(0xFF82909C);
    }
  }

  static IconData icon(JournalEntryType type) {
    switch (type) {
      case JournalEntryType.session:
        return Icons.history_edu_rounded;

      case JournalEntryType.quest:
        return Icons.flag_rounded;

      case JournalEntryType.discovery:
        return Icons.lightbulb_rounded;

      case JournalEntryType.npc:
        return Icons.people_alt_rounded;

      case JournalEntryType.combat:
        return Icons.sports_martial_arts_rounded;

      case JournalEntryType.location:
        return Icons.location_on_rounded;

      case JournalEntryType.personal:
        return Icons.favorite_rounded;

      case JournalEntryType.other:
        return Icons.notes_rounded;
    }
  }

  static Color background(
    BuildContext context,
    JournalEntryType type, {
    double strength = 0.12,
  }) {
    return Color.lerp(
          Theme.of(context).colorScheme.surface,
          color(type),
          strength,
        ) ??
        color(type);
  }
}
