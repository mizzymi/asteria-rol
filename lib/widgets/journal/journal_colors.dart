import 'package:flutter/material.dart';
import '../../models/journal_entry.dart';

class JournalColors {
  const JournalColors._();

  static Color color(BuildContext context, JournalEntryType type) {
    final scheme = Theme.of(context).colorScheme;
    switch (type) {
      case JournalEntryType.session: return scheme.primary;
      case JournalEntryType.quest: return scheme.secondary;
      case JournalEntryType.discovery: return scheme.secondary;
      case JournalEntryType.npc: return scheme.tertiary;
      case JournalEntryType.combat: return scheme.error;
      case JournalEntryType.location: return scheme.tertiary;
      case JournalEntryType.personal: return scheme.primary;
      case JournalEntryType.other: return scheme.onSurfaceVariant;
    }
  }

  static IconData icon(JournalEntryType type) {
    switch (type) {
      case JournalEntryType.session: return Icons.history_edu_rounded;
      case JournalEntryType.quest: return Icons.flag_rounded;
      case JournalEntryType.discovery: return Icons.lightbulb_rounded;
      case JournalEntryType.npc: return Icons.people_alt_rounded;
      case JournalEntryType.combat: return Icons.sports_martial_arts_rounded;
      case JournalEntryType.location: return Icons.location_on_rounded;
      case JournalEntryType.personal: return Icons.favorite_rounded;
      case JournalEntryType.other: return Icons.notes_rounded;
    }
  }

  static Color background(BuildContext context, JournalEntryType type, {double strength = 0.12}) {
    final scheme = Theme.of(context).colorScheme;
    return Color.lerp(scheme.surface, color(context, type), strength) ?? scheme.surface;
  }
}
