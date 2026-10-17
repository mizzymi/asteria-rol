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
      body: classes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_outlined, size: 64),
                    const SizedBox(height: 12),
                    Text(
                      'Todavía no hay clases personalizadas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Crea una clase con classId estable, versión y progresión por nivel, o importa una compartida.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _newClass,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Nueva clase'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
              children: [
                for (final definition in classes)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('d${definition.hitDie}'),
                      ),
                      title: Text(
                        definition.name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        'Versión ${definition.version} · ${definition.rewards.length} recompensas',
                      ),
                      isThreeLine: false,
                      onTap: () => _edit(definition),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') _edit(definition);
                          if (value == 'export') _export(definition);
                          if (value == 'delete') _delete(definition);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(
                            value: 'export',
                            child: Text('Exportar'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newClass,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva clase'),
      ),
    );
  }
}
