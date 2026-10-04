import 'package:flutter/material.dart';
import '../../models/journal_entry.dart';
import '../../theme/asteria_semantic_colors.dart';

class JournalColors {
  const JournalColors._();

  static Color color(BuildContext context, JournalEntryType type) {
    final theme = Theme.of(context);
    final semantic =
        theme.extension<AsteriaSemanticColors>() ??
        AsteriaSemanticColors.asteria(theme.colorScheme);

    if (!semantic.isRainbow) {
      switch (type) {
        case JournalEntryType.session:
          return theme.colorScheme.primary;
        case JournalEntryType.quest:
          return theme.colorScheme.secondary;
        case JournalEntryType.discovery:
          return theme.colorScheme.secondary;
        case JournalEntryType.npc:
          return theme.colorScheme.tertiary;
        case JournalEntryType.combat:
          return theme.colorScheme.error;
        case JournalEntryType.location:
          return theme.colorScheme.tertiary;
        case JournalEntryType.personal:
          return theme.colorScheme.primary;
        case JournalEntryType.other:
          return theme.colorScheme.onSurfaceVariant;
      }
    }

    switch (type) {
      case JournalEntryType.session:
        return semantic.neutral;
      case JournalEntryType.quest:
        return semantic.condition;
      case JournalEntryType.discovery:
        return semantic.edit;
      case JournalEntryType.npc:
        return semantic.positive;
      case JournalEntryType.combat:
        return semantic.negative;
      case JournalEntryType.location:
        return semantic.journal;
      case JournalEntryType.personal:
        return semantic.create;
      case JournalEntryType.other:
        return semantic.notes;
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
    final scheme = Theme.of(context).colorScheme;
    return Color.lerp(scheme.surface, color(context, type), strength) ??
        scheme.surface;
  }
}
