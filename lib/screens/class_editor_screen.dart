import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/character.dart';
import '../models/character_class_level.dart';
import '../models/custom_class_definition.dart';
import '../models/dnd_class.dart';
import '../services/character_storage_service.dart';
import '../services/class_progression_service.dart';
import '../services/custom_class_storage_service.dart';
import '../services/custom_class_import_export_service.dart';

class ClassEditorScreen extends StatefulWidget {
  final Character character;

  const ClassEditorScreen({super.key, required this.character});

  @override
  State<ClassEditorScreen> createState() => _ClassEditorScreenState();
}

class _ClassEditorScreenState extends State<ClassEditorScreen> {
  Character get character => widget.character;

  List<CustomClassDefinition> get customClasses =>
      CustomClassStorageService.getClasses(character.campaignId ?? '');

  List<_ClassOption> get classOptions {
    final result = <_ClassOption>[
      ...DndClass.values.map(
        (dndClass) => _ClassOption(
          key: 'core:${dndClass.name}',
          label: dndClass.label,
          hitDie: dndClass.hitDie,
          builtIn: dndClass,
        ),
      ),
      ...customClasses.map(
        (definition) => _ClassOption(
          key: definition.classId,
          label: definition.name,
          hitDie: definition.hitDie,
          custom: definition,
        ),
      ),
    ];
    return result;
  }

  Future<void> save() async {
    character.normalizeHealth();
    await CharacterStorageService.saveCharacter(character);
  }

  CharacterClassLevel _classLevelFromOption(_ClassOption option, int level) {
    final builtIn = option.builtIn;
    if (builtIn != null) {
      return CharacterClassLevel(dndClass: builtIn, level: level);
    }

    final definition = option.custom!;
    return CharacterClassLevel(
      dndClass: DndClass.fighter,
      classId: definition.classId,
      customName: definition.name,
      customHitDie: definition.hitDie,
      customSavingThrowProficiencies: definition.savingThrowProficiencies,
      level: level,
    );
  }

  void _syncCustomClassSnapshots(List<CustomClassDefinition> definitions) {
    final byId = {
      for (final definition in definitions) definition.classId: definition,
    };
    for (final classLevel in character.classes) {
      if (!classLevel.isCustom) continue;
      final definition = byId[classLevel.classId];
      if (definition == null) continue;
      classLevel.customName = definition.name;
      classLevel.customHitDie = definition.hitDie;
      classLevel.customSavingThrowProficiencies = Set.of(
        definition.savingThrowProficiencies,
      );
    }
  }

  Future<void> _reconcileProgression() async {
    final definitions = customClasses;
    _syncCustomClassSnapshots(definitions);

    var result = ClassProgressionService.reconcile(character, definitions);
    if (result.appliedRewards > 0) {
      await save();
    }

    for (final pending in result.pendingChoices) {
      if (!mounted) return;
      final alreadySelected = character.classProgressionChoices.entries
          .where((entry) => entry.key.startsWith('${pending.definition.classId}::'))
          .map((entry) => entry.value).toSet();
      final availableOptions = pending.reward.contents.where((option) =>
          pending.reward.stackable || !alreadySelected.contains(option.contentId)).toList();
      if (availableOptions.isEmpty) continue;
      final contentId = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              pending.reward.name.trim().isEmpty
                  ? 'Elección de nivel ${pending.reward.level}'
                  : pending.reward.name,
            ),
            content: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${pending.definition.name} · nivel ${pending.reward.level} · elección ${pending.slot + 1}/${pending.reward.choiceCount}',
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                const Text('Escoge una recompensa:'),
                const SizedBox(height: 8),
                for (final option in availableOptions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      option.type == ClassProgressionContentType.ability
                          ? Icons.auto_awesome_rounded
                          : Icons.shield_outlined,
                    ),
                    title: Text(option.name),
                    subtitle: Text(
                      option.type == ClassProgressionContentType.ability
                          ? 'Habilidad activa'
                          : 'Pasiva',
                    ),
                    onTap: () => Navigator.pop(dialogContext, option.contentId),
                  ),
              ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Elegir más tarde'),
              ),
            ],
          );
        },
      );

      if (contentId == null) continue;
      ClassProgressionService.applyChoice(
        character,
        definition: pending.definition,
        reward: pending.reward,
        contentId: contentId,
        slot: pending.slot,
      );
      await save();
    }

    if (mounted) setState(() {});
  }

  Future<void> _importCustomClass() async {
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

      final campaignId = character.campaignId;
      if (campaignId == null || campaignId.isEmpty) {
        throw const FormatException(
          'Selecciona una campaña antes de importar una clase.',
        );
      }
      final source = await CustomClassImportExportService.importFile(
        File(path),
      );
      final imported = CustomClassDefinition.fromMap({
        ...source.toMap(),
        'campaignId': campaignId,
      });
      if (imported.classId.trim().isEmpty) {
        throw const FormatException('La clase no tiene classId.');
      }

      final existing = CustomClassStorageService.getClass(
        character.campaignId ?? '',
        imported.classId,
      );
      if (existing != null && imported.version < existing.version) {
        throw FormatException(
          'La versión importada (${imported.version}) es anterior a la instalada (${existing.version}).',
        );
      }

      await CustomClassStorageService.saveClass(imported);
      await _reconcileProgression();

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? 'Clase “${imported.name}” importada.'
                : 'Clase “${imported.name}” actualizada a v${imported.version}.',
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

  Future<void> addClass() async {
    final options = classOptions
        .where(
          (option) =>
              !character.classes.any((item) => item.classId == option.key),
        )
        .toList();

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay más clases disponibles.')),
      );
      return;
    }

    var selectedKey = options.first.key;
    var selectedLevel = 1;

    final result = await showDialog<CharacterClassLevel>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selected = options.firstWhere(
              (option) => option.key == selectedKey,
            );
            return AlertDialog(
              title: const Text('Añadir clase'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedKey,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Clase'),
                    items: options.map((option) {
                      return DropdownMenuItem(
                        value: option.key,
                        child: Text(
                          '${option.label} · d${option.hitDie}'
                          '${option.custom != null ? ' · personalizada' : ''}',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedKey = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: '1',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nivel'),
                    onChanged: (value) {
                      selectedLevel = int.tryParse(value) ?? 1;
                    },
                  ),
                  if (selected.custom != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Clase personalizada v${selected.custom!.version} · '
                      '${selected.custom!.rewards.length} recompensas configuradas.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (selectedLevel < 1) return;
                    Navigator.pop(
                      dialogContext,
                      _classLevelFromOption(selected, selectedLevel),
                    );
                  },
                  child: const Text('Añadir'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    setState(() {
      character.classes.add(result);
      character.normalizeHealth();
    });
    await _reconcileProgression();
    await save();
  }

  Future<void> editClass(int index) async {
    final current = character.classes[index];
    final options = classOptions.where((option) {
      if (option.key == current.classId) return true;
      return !character.classes.any((item) => item.classId == option.key);
    }).toList();

    if (!options.any((option) => option.key == current.classId)) {
      options.insert(
        0,
        _ClassOption(
          key: current.classId,
          label: current.label,
          hitDie: current.hitDie,
          builtIn: current.isCustom ? null : current.dndClass,
        ),
      );
    }

    var selectedKey = current.classId;
    var selectedLevel = current.level;

    final result = await showDialog<CharacterClassLevel>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selected = options.firstWhere(
              (option) => option.key == selectedKey,
            );
            return AlertDialog(
              title: const Text('Editar clase'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedKey,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Clase'),
                    items: options
                        .map(
                          (option) => DropdownMenuItem(
                            value: option.key,
                            child: Text(
                              '${option.label} · d${option.hitDie}'
                              '${option.custom != null ? ' · personalizada' : ''}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedKey = value);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: '${current.level}',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nivel'),
                    onChanged: (value) {
                      selectedLevel = int.tryParse(value) ?? current.level;
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (selectedLevel < 1) return;
                    if (selected.custom == null &&
                        selected.builtIn == null &&
                        selected.key == current.classId) {
                      final copy = CharacterClassLevel(
                        dndClass: current.dndClass,
                        classId: current.classId,
                        customName: current.customName,
                        customHitDie: current.customHitDie,
                        customSavingThrowProficiencies:
                            current.customSavingThrowProficiencies,
                        level: selectedLevel,
                      );
                      Navigator.pop(dialogContext, copy);
                      return;
                    }
                    Navigator.pop(
                      dialogContext,
                      _classLevelFromOption(selected, selectedLevel),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    setState(() {
      character.classes[index] = result;
      character.normalizeHealth();
    });

    if (index == 0) {
      character.resetSavingThrowProficienciesFromClass();
    }

    await _reconcileProgression();
    await save();
  }

  Future<void> deleteClass(int index) async {
    if (character.classes.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El personaje debe tener al menos una clase.'),
        ),
      );
      return;
    }

    final item = character.classes[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar clase'),
        content: Text(
          '¿Quieres quitar ${item.label} del personaje? '
          'Las habilidades y pasivas ya aprendidas se conservarán.',
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

    if (confirmed != true || !mounted) return;

    setState(() {
      character.classes.removeAt(index);
      character.normalizeHealth();
    });

    if (index == 0) {
      character.resetSavingThrowProficienciesFromClass();
    }
    await save();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reconcileProgression();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clases'),
        actions: [
          IconButton(
            tooltip: 'Importar clase',
            onPressed: _importCustomClass,
            icon: const Icon(Icons.file_download_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.military_tech_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nivel total',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${character.level}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Text('+${character.proficiencyBonus} competencia'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Clases',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(character.classes.length, (index) {
              final item = character.classes[index];
              final definition = item.isCustom
                  ? CustomClassStorageService.getClass(
                      character.campaignId ?? '',
                      item.classId,
                    )
                  : null;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(child: Text('${item.level}')),
                  title: Text(
                    item.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${index == 0 ? 'Clase inicial' : 'Multiclase'} · '
                    'd${item.hitDie}'
                    '${item.isCustom ? ' · personalizada${definition != null ? ' v${definition.version}' : ''}' : ''}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () => editClass(index),
                        icon: const Icon(Icons.edit_rounded),
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        onPressed: () => deleteClass(index),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                  onTap: () => editClass(index),
                ),
              );
            }),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: addClass,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Añadir clase'),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dados de golpe',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      character.hitDiceText,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                leading: const Icon(Icons.sync_rounded),
                title: const Text('Comprobar progresión'),
                subtitle: const Text(
                  'Aplica recompensas nuevas de clases actualizadas y recupera elecciones pendientes.',
                ),
                onTap: _reconcileProgression,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addClass,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Añadir clase'),
      ),
    );
  }
}

class _ClassOption {
  final String key;
  final String label;
  final int hitDie;
  final DndClass? builtIn;
  final CustomClassDefinition? custom;

  const _ClassOption({
    required this.key,
    required this.label,
    required this.hitDie,
    this.builtIn,
    this.custom,
  });
}
