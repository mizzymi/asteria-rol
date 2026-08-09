import 'package:flutter/material.dart';

import '../models/character.dart';
import '../models/journal_entry.dart';
import '../services/character_storage_service.dart';
import 'journal_form_screen.dart';

class JournalScreen extends StatefulWidget {
  final Character character;

  const JournalScreen({super.key, required this.character});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  Character get character => widget.character;

  JournalEntryType? filter;

  Future<void> save() async {
    await CharacterStorageService.saveCharacter(character);
  }

  Future<void> createEntry() async {
    final entry = await Navigator.push<JournalEntry>(
      context,
      MaterialPageRoute(builder: (_) => const JournalFormScreen()),
    );

    if (entry == null) {
      return;
    }

    setState(() {
      character.addJournalEntry(entry);
    });

    await save();
  }

  Future<void> editEntry(JournalEntry entry) async {
    final result = await Navigator.push<JournalEntry>(
      context,
      MaterialPageRoute(builder: (_) => JournalFormScreen(entry: entry)),
    );

    if (result == null) {
      return;
    }

    final index = character.journalEntries.indexWhere(
      (item) => item.id == result.id,
    );

    if (index < 0) {
      return;
    }

    setState(() {
      character.journalEntries[index] = result;
    });

    await save();
  }

  Future<void> deleteEntry(JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar entrada'),
          content: Text('¿Quieres eliminar "${entry.title}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      character.removeJournalEntry(entry.id);
    });

    await save();
  }

  List<JournalEntry> get visibleEntries {
    final entries = character.journalEntries
        .where((entry) => filter == null || entry.type == filter)
        .toList();

    return entries.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries = visibleEntries;

    return Scaffold(
      appBar: AppBar(title: const Text('Diario')),
      body: Column(
        children: [
          SizedBox(
            height: 54,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('Todo'),
                  selected: filter == null,
                  onSelected: (_) {
                    setState(() {
                      filter = null;
                    });
                  },
                ),

                const SizedBox(width: 8),

                ...JournalEntryType.values.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type.label),
                      selected: filter == type,
                      onSelected: (_) {
                        setState(() {
                          filter = type;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          Expanded(
            child: entries.isEmpty
                ? _EmptyJournal(onCreate: createEntry)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];

                      return _JournalCard(
                        entry: entry,
                        onEdit: () {
                          editEntry(entry);
                        },
                        onDelete: () {
                          deleteEntry(entry);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createEntry,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva entrada'),
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final JournalEntry entry;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _JournalCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _iconForType(entry.type),
                    color: Theme.of(context).colorScheme.primary,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      entry.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  if (entry.important) const Icon(Icons.star_rounded),

                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      }

                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 7),

              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(entry.type.label)),

                  if (entry.dateText.isNotEmpty)
                    Chip(label: Text(entry.dateText)),

                  if (entry.sessionText.isNotEmpty)
                    Chip(label: Text(entry.sessionText)),
                ],
              ),

              if (entry.content.isNotEmpty) ...[
                const SizedBox(height: 8),

                Text(
                  entry.content,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(JournalEntryType type) {
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
}

class _EmptyJournal extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyJournal({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_edu_rounded,
              size: 68,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(height: 18),

            Text(
              'El diario está vacío',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Guarda aquí sesiones, descubrimientos, misiones, NPCs y momentos importantes.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 22),

            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Primera entrada'),
            ),
          ],
        ),
      ),
    );
  }
}
