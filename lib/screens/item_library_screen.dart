import 'package:flutter/material.dart';

import '../models/item_definition.dart';
import '../models/ability.dart';
import '../models/item_library_entry.dart';

import '../services/item_import_export_service.dart';
import '../services/item_library_service.dart';

import '../widgets/common/section_header.dart';

import '../widgets/items/library/import_item_button.dart';
import '../widgets/items/library/library_item_card.dart';

import 'item_form_screen.dart';

enum ItemLibraryMode { manage, select }

class ItemLibraryScreen extends StatefulWidget {
  final ItemLibraryMode mode;

  const ItemLibraryScreen({super.key, this.mode = ItemLibraryMode.manage});

  bool get selectable {
    return mode == ItemLibraryMode.select;
  }

  @override
  State<ItemLibraryScreen> createState() {
    return _ItemLibraryScreenState();
  }
}

class _ItemLibraryScreenState extends State<ItemLibraryScreen> {
  bool loading = true;

  String search = '';

  List<ItemLibraryEntry> entries = [];

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    loadLibrary();
  }

  // ===========================================================================
  // LOAD
  // ===========================================================================

  Future<void> loadLibrary() async {
    final result = await ItemLibraryService.loadLibrary();

    if (!mounted) {
      return;
    }

    setState(() {
      entries = result;
      loading = false;
    });
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  List<ItemLibraryEntry> get filteredEntries {
    final query = search.trim().toLowerCase();

    if (query.isEmpty) {
      return entries;
    }

    return entries.where((entry) {
      final item = entry.definition;

      final searchable = <String>[
        item.name,
        item.description,
        item.type.label,
        item.notes,

        // =====================================================================
        // WEAPON
        // =====================================================================
        if (item.weapon != null) ...[
          item.weapon!.name,
          item.weapon!.attackAbility.name,
          '${item.weapon!.magicBonus}',

          ...item.weapon!.damages.expand(
            (damage) => [damage.name, damage.diceNotation, damage.damageType],
          ),
        ],

        // =====================================================================
        // CONSUMABLE
        // =====================================================================
        if (item.consumable != null) ...[
          item.consumable!.useText,

          ...item.consumable!.effects.expand(
            (effect) => [
              effect.name,
              effect.effectType.name,
              effect.diceNotation,
              effect.effectTypeName,

              ...effect.abilityModifierMultipliers.entries.map(
                (entry) => '${entry.value} ${entry.key.name}',
              ),
            ],
          ),
        ],

        // =====================================================================
        // PASSIVES / ABILITIES
        // =====================================================================
        ...item.passives.expand(
          (passive) => [
            passive.name,
            passive.description,
            passive.notes,
            passive.rechargeDescription,
            passive.sourceType.name,
            ...passive.triggers.expand(
              (trigger) => [
                trigger.event.name,
                trigger.customEvent ?? '',
                ...trigger.actions.map((action) => action.type.name),
              ],
            ),
          ],
        ),

        ...item.abilities.expand(
          (ability) => [
            ability.name,
            ability.description,
            ability.notes,
            ability.actionType.label,
          ],
        ),

        if (item.actionDefinition != null) item.actionDefinition!.name,
      ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  // ===========================================================================
  // CREATE
  // ===========================================================================

  Future<void> createEntry() async {
    final definition = await Navigator.push<ItemDefinition>(
      context,
      MaterialPageRoute(builder: (_) => const ItemFormScreen()),
    );

    if (definition == null || !mounted) {
      return;
    }

    await ItemLibraryService.addDefinition(definition);

    await loadLibrary();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${definition.name} añadido a la biblioteca.')),
    );
  }

  // ===========================================================================
  // EDIT
  // ===========================================================================

  Future<void> editEntry(ItemLibraryEntry entry) async {
    final definition = await Navigator.push<ItemDefinition>(
      context,
      MaterialPageRoute(
        builder: (_) => ItemFormScreen(definition: entry.definition),
      ),
    );

    if (definition == null || !mounted) {
      return;
    }

    final normalizedDefinition = definition.copyWith(id: entry.definition.id);

    await ItemLibraryService.updateDefinition(
      entryId: entry.id,
      definition: normalizedDefinition,
    );

    await loadLibrary();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${normalizedDefinition.name} actualizado.')),
    );
  }

  // ===========================================================================
  // ADD TO CHARACTER
  // ===========================================================================

  Future<void> addToCharacter(ItemLibraryEntry entry) async {
    if (!mounted) {
      return;
    }

    Navigator.pop<ItemDefinition>(context, entry.definition);
  }

  // ===========================================================================
  // SHARE
  // ===========================================================================

  Future<void> shareEntry(ItemLibraryEntry entry) async {
    try {
      await ItemImportExportService.shareDefinition(entry.definition);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido compartir el objeto.')),
      );
    }
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  Future<void> deleteEntry(ItemLibraryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar de biblioteca'),

          content: Text(
            '¿Quieres eliminar '
            '"${entry.definition.name}" '
            'de la biblioteca?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
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

    await ItemLibraryService.removeItem(entry.id);

    await loadLibrary();
  }

  // ===========================================================================
  // IMPORT
  // ===========================================================================

  Future<void> importToLibrary() async {
    try {
      final definition =
          await ItemImportExportService.pickAndImportDefinition();

      if (definition == null || !mounted) {
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Guardar en biblioteca'),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  definition.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),

                if (definition.description.isNotEmpty) ...[
                  const SizedBox(height: 8),

                  Text(definition.description),
                ],

                const SizedBox(height: 10),

                Text(definition.type.label),

                if (definition.passives.isNotEmpty) ...[
                  const SizedBox(height: 4),

                  Text(
                    '${definition.passives.length} '
                    '${definition.passives.length == 1 ? 'pasiva' : 'pasivas'}',
                  ),
                ],

                if (definition.abilities.isNotEmpty) ...[
                  const SizedBox(height: 4),

                  Text(
                    '${definition.abilities.length} '
                    '${definition.abilities.length == 1 ? 'habilidad' : 'habilidades'}',
                  ),
                ],
              ],
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Cancelar'),
              ),

              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                icon: const Icon(Icons.library_add_rounded),
                label: const Text('Guardar'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      await ItemLibraryService.addDefinition(definition);

      await loadLibrary();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${definition.name} añadido a la biblioteca.')),
      );
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido importar el objeto.')),
      );
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final filtered = filteredEntries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca de objetos'),

        actions: [
          ImportItemButton(onPressed: importToLibrary),

          IconButton(
            tooltip: 'Nuevo objeto',
            onPressed: createEntry,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
          ? _EmptyLibrary(onCreate: createEntry, onImport: importToLibrary)
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText: 'Buscar objeto...',
                      ),
                      onChanged: (value) {
                        setState(() {
                          search = value;
                        });
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: SectionHeader(
                      icon: Icons.local_library_rounded,
                      title: 'Objetos guardados',
                      subtitle:
                          '${filtered.length} '
                          '${filtered.length == 1 ? 'objeto' : 'objetos'}',
                      trailing: IconButton.filledTonal(
                        tooltip: 'Crear objeto',
                        onPressed: createEntry,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.search_off_rounded,
                                    size: 54,
                                  ),

                                  const SizedBox(height: 14),

                                  Text(
                                    'No hay resultados para "$search".',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final entry = filtered[index];

                              return LibraryItemCard(
                                entry: entry,

                                onAdd: widget.selectable
                                    ? () {
                                        addToCharacter(entry);
                                      }
                                    : null,

                                onEdit: () {
                                  editEntry(entry);
                                },

                                onShare: () {
                                  shareEntry(entry);
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

      floatingActionButton: FloatingActionButton.extended(
        onPressed: createEntry,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo objeto'),
      ),
    );
  }
}

// =============================================================================
// EMPTY
// =============================================================================

class _EmptyLibrary extends StatelessWidget {
  final VoidCallback onCreate;

  final VoidCallback onImport;

  const _EmptyLibrary({required this.onCreate, required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.local_library_rounded,
                size: 44,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Biblioteca vacía',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 8),

            Text(
              'Crea objetos reutilizables o '
              'importa los que te hayan compartido.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crear objeto'),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onImport,
                icon: const Icon(Icons.file_download_rounded),
                label: const Text('Importar objeto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
