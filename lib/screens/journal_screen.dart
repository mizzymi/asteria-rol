import 'package:flutter/material.dart';

import '../models/character.dart';
import '../models/journal_entry.dart';

import '../services/character_storage_service.dart';

import '../widgets/journal/journal_entry_card.dart';
import '../widgets/journal/journal_filter_bar.dart';
import '../widgets/journal/journal_empty_state.dart';

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

  // ===========================================================================
  // GUARDAR
  // ===========================================================================

  Future<void> save() async {
    await CharacterStorageService.saveCharacter(character);
  }

  // ===========================================================================
  // CREAR
  // ===========================================================================

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

  // ===========================================================================
  // EDITAR
  // ===========================================================================

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

  // ===========================================================================
  // ELIMINAR
  // ===========================================================================

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

  // ===========================================================================
  // FILTRADO
  // ===========================================================================

  List<JournalEntry> get visibleEntries {
    final entries = character.journalEntries
        .where((entry) => filter == null || entry.type == filter)
        .toList();

    /*
     * Las entradas más recientes
     * aparecen primero.
     */
    return entries.reversed.toList();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final entries = visibleEntries;

    return Scaffold(
      appBar: AppBar(title: const Text('Diario')),

      body: SafeArea(
        child: Column(
          children: [
            // =================================================================
            // FILTROS
            // =================================================================
            JournalFilterBar(
              selected: filter,
              onChanged: (value) {
                setState(() {
                  filter = value;
                });
              },
            ),

            const Divider(height: 1),

            // =================================================================
            // CONTENIDO
            // =================================================================
            Expanded(
              child: entries.isEmpty
                  ? JournalEmptyState(
                      filtered: filter != null,
                      onCreate: createEntry,
                      onClearFilter: filter != null
                          ? () {
                              setState(() {
                                filter = null;
                              });
                            }
                          : null,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];

                        return JournalEntryCard(
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
      ),

      // =======================================================================
      // NUEVA ENTRADA
      // =======================================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createEntry,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva entrada'),
      ),
    );
  }
}
