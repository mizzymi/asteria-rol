import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/custom_class_definition.dart';
import '../services/character_storage_service.dart';
import '../services/class_progression_service.dart';
import '../services/custom_class_import_export_service.dart';
import '../services/custom_class_storage_service.dart';
import 'custom_class_form_screen.dart';

class CustomClassesScreen extends StatefulWidget {
  final String campaignId;
  final bool embedded;

  const CustomClassesScreen({
    super.key,
    required this.campaignId,
    this.embedded = false,
  });

  @override
  State<CustomClassesScreen> createState() => _CustomClassesScreenState();
}

class _CustomClassesScreenState extends State<CustomClassesScreen> {
  List<CustomClassDefinition> classes = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    classes = CustomClassStorageService.getClasses(widget.campaignId);
    if (mounted) setState(() {});
  }

  Future<void> _edit([CustomClassDefinition? definition]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomClassFormScreen(
          definition: definition,
          campaignId: widget.campaignId,
        ),
      ),
    );
    _reload();
  }

  Future<void> _newClass() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Nueva clase'),
                subtitle: Text('¿Qué quieres hacer?'),
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline_rounded),
                title: const Text('Crear clase'),
                onTap: () => Navigator.pop(sheetContext, 'create'),
              ),
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('Importar clase'),
                onTap: () => Navigator.pop(sheetContext, 'import'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'create') {
      await _edit();
    } else if (action == 'import') {
      await _import();
    }
  }

  Future<void> _export(CustomClassDefinition definition) async {
    try {
      await CustomClassImportExportService.shareClass(definition);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar la clase: $error')),
      );
    }
  }

  Future<void> _import() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['asteria-class', 'json'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) {
        throw const FormatException('No se pudo acceder al archivo.');
      }

      final source = await CustomClassImportExportService.importFile(
        File(path),
      );
      final imported = CustomClassDefinition.fromMap({
        ...source.toMap(),
        'campaignId': widget.campaignId,
      });
      if (imported.classId.trim().isEmpty) {
        throw const FormatException('La clase no tiene classId.');
      }

      final existing = CustomClassStorageService.getClass(
        widget.campaignId,
        imported.classId,
      );
      if (existing != null && imported.version < existing.version) {
        throw FormatException(
          'La versión importada (${imported.version}) es anterior a la instalada (${existing.version}).',
        );
      }

      await CustomClassStorageService.saveClass(imported);

      var updatedCharacters = 0;
      final definitions = CustomClassStorageService.getClasses(
        widget.campaignId,
      );
      for (final character in CharacterStorageService.getCharacters().where(
        (c) => c.campaignId == widget.campaignId,
      )) {
        final outcome = ClassProgressionService.reconcile(
          character,
          definitions,
        );
        if (outcome.appliedRewards > 0) {
          await CharacterStorageService.saveCharacter(character);
          updatedCharacters++;
        }
      }

      if (!mounted) return;
      _reload();
      final action = existing == null ? 'importada' : 'actualizada';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Clase “${imported.name}” $action · v${imported.version}'
            '${updatedCharacters > 0 ? ' · $updatedCharacters fichas recibieron recompensas pendientes' : ''}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo importar la clase: $error')),
      );
    }
  }

  Future<void> _delete(CustomClassDefinition definition) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar clase'),
        content: Text(
          'Se eliminará “${definition.name}” del catálogo. '
          'Las fichas que ya la usan conservarán su snapshot y recompensas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await CustomClassStorageService.deleteClass(
      widget.campaignId,
      definition.classId,
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Clases personalizadas'),
              actions: [
                IconButton(
                  tooltip: 'Nueva clase',
                  onPressed: _newClass,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
      body: CustomScrollView(
        slivers: [
          if (classes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school_rounded, size: 44,
                        color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 12),
                      Text('Aún no hay clases',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      const Text('Prepara clases personalizadas y progresiones para la campaña.',
                        textAlign: TextAlign.center),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _newClass,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Nueva clase'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clases',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${classes.length} clases personalizadas de la campaña',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _newClass,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Añadir clase'),
                  ),
                ],
              ),
            ),
          ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  final columns = width >= 800
                      ? 4
                      : width >= 540
                      ? 3
                      : 2;
                  return SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final definition = classes[index];
                      return _ClassVisualCard(
                        definition: definition,
                        onTap: () => _edit(definition),
                        onEdit: () => _edit(definition),
                        onExport: () => _export(definition),
                        onDelete: () => _delete(definition),
                      );
                    }, childCount: classes.length),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: .78,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClassVisualCard extends StatelessWidget {
  final CustomClassDefinition definition;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const _ClassVisualCard({
    required this.definition,
    required this.onTap,
    required this.onEdit,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .55)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.primaryContainer,
                          colors.tertiaryContainer,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_rounded,
                          size: 52,
                          color: colors.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'd${definition.hitDie}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: colors.onPrimaryContainer,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(24),
                      child: PopupMenuButton<String>(
                        tooltip: 'Opciones de clase',
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (value) {
                          if (value == 'edit') onEdit();
                          if (value == 'export') onExport();
                          if (value == 'delete') onDelete();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar clase'),
                          ),
                          PopupMenuItem(
                            value: 'export',
                            child: Text('Exportar clase'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar clase'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    definition.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Versión ${definition.version} · ${definition.rewards.length} recompensas',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
