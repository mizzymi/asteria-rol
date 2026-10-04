import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _syncRewards();
  }

  Future<void> _syncRewards() async {
    for (final entry in character.knowledges) {
      final definition = await KnowledgeLibraryService.getDefinitionById(
        entry.knowledgeId,
      );
      if (definition == null) continue;
      await const KnowledgeService().syncKnowledgeRewards(
        character: character,
        definition: definition,
        entry: entry,
      );
    }
    await CharacterStorageService.saveCharacter(character);
    if (mounted) setState(() {});
  }

  Future<void> _createKnowledge() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const KnowledgeFormScreen()),
    );
    if (result == null || !mounted) return;

    final definition = result['definition'] as KnowledgeDefinition;
    final notes = result['notes'] as String;
    await KnowledgeLibraryService.saveDefinition(definition);

    if (!mounted) return;
    setState(() {
      character.knowledges.add(
        CharacterKnowledge(
          knowledgeId: definition.id,
          status: KnowledgeStatus.discovered,
          notes: notes,
        ),
      );
    });
    await _save();
  }

  Future<void> _editKnowledgeFull(CharacterKnowledge entry) async {
    final existing = await KnowledgeLibraryService.getDefinitionById(
      entry.knowledgeId,
    );
    if (!mounted) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => KnowledgeFormScreen(
          definition: existing,
          initialNotes: entry.notes,
        ),
      ),
    );
    if (result == null || !mounted) return;

    final definition = result['definition'] as KnowledgeDefinition;
    entry.notes = result['notes'] as String;
    await KnowledgeLibraryService.saveDefinition(definition);

    final maxProgress = definition.effectiveRequiredProgress;
    if (entry.currentProgress > maxProgress) {
      entry.currentProgress = maxProgress;
    }
    entry.status = entry.currentProgress >= maxProgress
        ? KnowledgeStatus.mastered
        : entry.currentProgress > 0
        ? KnowledgeStatus.studying
        : KnowledgeStatus.discovered;

    await const KnowledgeService().syncKnowledgeRewards(
      character: character,
      definition: definition,
      entry: entry,
    );
    await _save();
  }

  Future<void> _study(CharacterKnowledge entry) async {
    final definition =
        await KnowledgeLibraryService.getDefinitionById(entry.knowledgeId) ??
        KnowledgeDefinition(id: entry.knowledgeId, name: entry.knowledgeId);
    if (!mounted) return;

    final result = await showStudyDialog(
      context,
      character: character,
      definition: definition,
    );
    if (result == null || !mounted) return;

    await _save();
    if (!mounted) return;

    final summary = result.attempts
        .map((a) {
          final circle = a.circleTitle == null ? '' : ' · ${a.circleTitle}';
          return '${a.totalRoll} vs CD ${a.dcUsed}$circle (${a.success ? 'Éxito' : 'Fallo'})';
        })
        .join(', ');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$summary. Progreso ${result.currentProgress}/${result.requiredProgress}'
          '${result.completed ? ' · ¡Libro completado!' : ''}',
        ),
      ),
    );
  }

  Future<void> _deleteKnowledge(CharacterKnowledge entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar saber'),
        content: const Text('¿Deseas eliminar este saber de tus registros?'),
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
    if (confirmed != true) return;

    for (final passiveId in entry.temporaryPassiveIdsGranted) {
      character.removePassive(passiveId);
    }
    character.knowledges.removeWhere((k) => k.knowledgeId == entry.knowledgeId);
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final knowledges = character.knowledges;
    final studying = knowledges
        .where((k) => k.status == KnowledgeStatus.studying)
        .toList();
    final discovered = knowledges
        .where((k) => k.status == KnowledgeStatus.discovered)
        .toList();
    final mastered = knowledges
        .where((k) => k.status == KnowledgeStatus.mastered)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Compendio de Saberes')),
      body: knowledges.isEmpty
          ? EmptyState(
              icon: Icons.auto_stories_rounded,
              title: 'Sin conocimientos',
              message:
                  'Añade libros, manuales o tratados con círculos de aprendizaje y recompensas.',
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
                  ...studying.map(_buildKnowledgeCard),
                  const SizedBox(height: 20),
                ],
                if (discovered.isNotEmpty) ...[
                  SectionHeader(
                    icon: Icons.visibility_rounded,
                    title: 'Descubiertos',
                    subtitle: 'Pendientes de comenzar su estudio',
                  ),
                  const SizedBox(height: 10),
                  ...discovered.map(_buildKnowledgeCard),
                  const SizedBox(height: 20),
                ],
                if (mastered.isNotEmpty) ...[
                  SectionHeader(
                    icon: Icons.verified_rounded,
                    title: 'Dominados',
                    subtitle: 'Conocimientos asimilados por completo',
                  ),
                  const SizedBox(height: 10),
                  ...mastered.map(_buildKnowledgeCard),
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

  Widget _buildKnowledgeCard(CharacterKnowledge entry) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mastered = entry.status == KnowledgeStatus.mastered;

    return FutureBuilder<KnowledgeDefinition?>(
      future: KnowledgeLibraryService.getDefinitionById(entry.knowledgeId),
      builder: (context, snapshot) {
        final definition = snapshot.data;
        final title = definition?.name ?? entry.knowledgeId;
        final total = definition?.effectiveRequiredProgress ?? 1;
        final progress = entry.currentProgress.clamp(0, total).toInt();
        final currentCircle = definition?.circleAtProgress(progress);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      mastered
                          ? Icons.check_circle_rounded
                          : Icons.menu_book_rounded,
                      color: mastered ? colors.tertiary : colors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (definition != null) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (definition.rarity.isNotEmpty)
                                  _MiniBadge(definition.rarity),
                                if (definition.difficulty.isNotEmpty)
                                  _MiniBadge(definition.difficulty),
                                if (definition.levelLabel.isNotEmpty)
                                  _MiniBadge(definition.levelLabel),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _editKnowledgeFull(entry);
                        if (value == 'delete') _deleteKnowledge(entry);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar libro'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Eliminar saber'),
                        ),
                      ],
                    ),
                  ],
                ),
                if (definition?.description.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Text(
                    definition!.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: total > 0 ? progress / total : 0,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$progress/$total',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                if (!mastered && currentCircle != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.38),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Siguiente: ${currentCircle.title} · CD ${currentCircle.dc}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                if (definition != null &&
                    definition.effectiveCheckOptions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tirada: ${definition.effectiveCheckOptions.map((e) => e.label).join(' o ')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                if (entry.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    entry.notes,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                if (!mastered) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => _study(entry),
                      icon: const Icon(Icons.auto_stories_rounded, size: 18),
                      label: const Text('Estudiar'),
                    ),
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

class _MiniBadge extends StatelessWidget {
  final String text;
  const _MiniBadge(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
