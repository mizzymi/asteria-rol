import 'package:flutter/material.dart';

import '../models/ability.dart';
import '../models/passive.dart';
import '../services/ability_library_service.dart';
import '../services/passive_library_service.dart';
import '../models/character.dart';
import '../models/character_knowledge.dart';
import '../models/knowledge_definition.dart';
import '../services/character_storage_service.dart';
import '../services/knowledge_library_service.dart';
import '../services/knowledge_service.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/section_header.dart';
import '../widgets/knowledge/study_dialog.dart';
import 'knowledge_form_screen.dart';

class KnowledgeScreen extends StatefulWidget {
  final Character character;

  const KnowledgeScreen({super.key, required this.character});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  Character get character => widget.character;

  Future<void> _save() async {
    await CharacterStorageService.saveCharacter(character);
    if (mounted) setState(() {});
  }

  Future<void> _createKnowledge() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const KnowledgeFormScreen()),
    );

    if (result == null || !mounted) return;

    final def = result['definition'] as KnowledgeDefinition;
    final notes = result['notes'] as String;

    // Guardamos la definición en la biblioteca global
    await KnowledgeLibraryService.saveDefinition(def);

    setState(() {
      final entry = CharacterKnowledge(
        knowledgeId: def.id,
        status: KnowledgeStatus.discovered,
        currentProgress: 0,
        notes: notes,
      );
      character.knowledges.add(entry);
    });
    await _save();
  }

  Future<void> _editKnowledgeFull(CharacterKnowledge entry) async {
    final existingDef = await KnowledgeLibraryService.getDefinitionById(
      entry.knowledgeId,
    );

    if (!mounted) {
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => KnowledgeFormScreen(
          definition: existingDef,
          initialNotes: entry.notes,
        ),
      ),
    );

    if (result == null || !mounted) return;

    final def = result['definition'] as KnowledgeDefinition;
    final notes = result['notes'] as String;

    await KnowledgeLibraryService.saveDefinition(def);

    setState(() {
      entry.notes = notes;
      if (entry.currentProgress >= def.requiredProgress) {
        entry.status = KnowledgeStatus.mastered;
      }
    });
    await _save();
  }

  Future<void> _studyDuringRest(
    CharacterKnowledge entry,
    RestStudyType restType,
  ) async {
    final def =
        await KnowledgeLibraryService.getDefinitionById(entry.knowledgeId) ??
        KnowledgeDefinition(
          id: entry.knowledgeId,
          name: entry.knowledgeId,
          requiredProgress: 5,
        );

    if (!mounted) {
      return;
    }

    final result = await showStudyDialog(
      context,
      character: character,
      definition: def,
    );

    if (result == null || !mounted) return;

    await _save();

    if (!mounted) return;

    final rollsSummary = result.attempts
        .map(
          (a) =>
              '${a.totalRoll} (${a.success ? "Éxito vs CD ${a.dcUsed}" : "Fallo"})',
        )
        .join(', ');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Tiradas: $rollsSummary. +${result.successesGained} éxito(s). '
          'Progreso: ${result.currentProgress}/${result.requiredProgress}. '
          '${result.completed ? "¡Conocimiento completado!" : ""}',
        ),
      ),
    );
  }

  Future<void> _deleteKnowledge(CharacterKnowledge entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar saber'),
        content: Text('¿Deseas eliminar este saber de tus registros?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        character.knowledges.removeWhere(
          (k) => k.knowledgeId == entry.knowledgeId,
        );
      });
      await _save();
    }
  }

  @override
  void initState() {
    super.initState();
    _syncRewards();
  }

  Future<void> _syncRewards() async {
    for (final entry in character.knowledges) {
      final def = await KnowledgeLibraryService.getDefinitionById(
        entry.knowledgeId,
      );
      if (def == null) continue;

      if (entry.status == KnowledgeStatus.mastered) {
        // =====================================================================
        // SI ESTÁ DOMINADO: Asegurar que tiene las recompensas
        // =====================================================================
        for (final passiveId in def.unlockedPassiveIds) {
          final hasPassive = character.passives.any((p) => p.id == passiveId);
          if (!hasPassive) {
            final passive = await PassiveLibraryService.getPassiveById(
              passiveId,
            );
            if (passive != null) {
              character.addPassive(CharacterPassive.fromMap(passive.toMap()));
            }
          }
        }
        for (final abilityId in def.unlockedAbilityIds) {
          final hasAbility = character.characterAbilities.any(
            (a) => a.id == abilityId,
          );
          if (!hasAbility) {
            final ability = await AbilityLibraryService.getAbilityById(
              abilityId,
            );
            if (ability != null) {
              character.characterAbilities.add(
                CharacterAbility.fromMap(ability.toMap()),
              );
            }
          }
        }
      } else {
        // =====================================================================
        // SI NO ESTÁ DOMINADO (Descubierto / En estudio): Retirar recompensas
        // =====================================================================
        for (final passiveId in def.unlockedPassiveIds) {
          character.removePassive(passiveId);
        }
        for (final abilityId in def.unlockedAbilityIds) {
          character.removeCharacterAbility(abilityId);
        }
      }
    }
    await _save();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final knowledges = character.knowledges;

    final studying = knowledges
        .where((k) => k.status == KnowledgeStatus.studying)
        .toList();
    final mastered = knowledges
        .where((k) => k.status == KnowledgeStatus.mastered)
        .toList();
    final discovered = knowledges
        .where((k) => k.status == KnowledgeStatus.discovered)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Compendio de Saberes')),
      body: knowledges.isEmpty
          ? EmptyState(
              icon: Icons.auto_stories_rounded,
              title: 'Sin conocimientos',
              message:
                  'Lee libros o pergaminos desde tu inventario para descubrir recetas, saberes e historia.',
              actionLabel: 'Añadir saber manual',
              onAction: _createKnowledge,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                if (studying.isNotEmpty) ...[
                  SectionHeader(
                    icon: Icons.hourglass_top_rounded,
                    title: 'En estudio',
                    subtitle: '${studying.length} saberes en progreso',
                  ),
                  const SizedBox(height: 10),
                  ...studying.map((k) => _buildKnowledgeCard(k, theme)),
                  const SizedBox(height: 20),
                ],
                if (discovered.isNotEmpty) ...[
                  SectionHeader(
                    icon: Icons.visibility_rounded,
                    title: 'Descubiertos',
                    subtitle: 'Pendientes de comenzar su lectura',
                  ),
                  const SizedBox(height: 10),
                  ...discovered.map((k) => _buildKnowledgeCard(k, theme)),
                  const SizedBox(height: 20),
                ],
                if (mastered.isNotEmpty) ...[
                  SectionHeader(
                    icon: Icons.verified_rounded,
                    title: 'Dominados',
                    subtitle: 'Conocimientos asimilados por completo',
                  ),
                  const SizedBox(height: 10),
                  ...mastered.map((k) => _buildKnowledgeCard(k, theme)),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createKnowledge,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo saber'),
      ),
    );
  }

  Widget _buildKnowledgeCard(CharacterKnowledge entry, ThemeData theme) {
    final isMastered = entry.status == KnowledgeStatus.mastered;

    return FutureBuilder<KnowledgeDefinition?>(
      future: KnowledgeLibraryService.getDefinitionById(entry.knowledgeId),
      builder: (context, snapshot) {
        final def = snapshot.data;
        final title = def?.name ?? entry.knowledgeId;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isMastered
                  ? Colors.green.withValues(alpha: 0.4)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isMastered
                          ? Icons.check_circle_rounded
                          : Icons.menu_book_rounded,
                      color: isMastered
                          ? Colors.green
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        isMastered
                            ? 'Dominado'
                            : '${entry.currentProgress} éxitos',
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') _editKnowledgeFull(entry);
                        if (val == 'delete') _deleteKnowledge(entry);
                      },
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_rounded),
                            title: Text('Editar saber, habilidades y pasivas'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline_rounded),
                            title: Text('Eliminar saber'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (entry.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    entry.notes,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (!isMastered) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            _studyDuringRest(entry, RestStudyType.shortRest),
                        icon: const Icon(Icons.bedtime_outlined, size: 16),
                        label: const Text('Corto (1 d20)'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () =>
                            _studyDuringRest(entry, RestStudyType.longRest),
                        icon: const Icon(Icons.hotel_rounded, size: 16),
                        label: const Text('Largo (2 d20)'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
