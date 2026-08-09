import 'package:flutter/material.dart';

import '../models/character.dart';
import '../models/character_class_level.dart';
import '../models/dnd_class.dart';
import '../services/character_storage_service.dart';

class ClassEditorScreen extends StatefulWidget {
  final Character character;

  const ClassEditorScreen({super.key, required this.character});

  @override
  State<ClassEditorScreen> createState() => _ClassEditorScreenState();
}

class _ClassEditorScreenState extends State<ClassEditorScreen> {
  Character get character => widget.character;

  Future<void> save() async {
    character.normalizeHealth();

    await CharacterStorageService.saveCharacter(character);
  }

  Future<void> addClass() async {
    final available = DndClass.values
        .where(
          (dndClass) =>
              !character.classes.any((item) => item.dndClass == dndClass),
        )
        .toList();

    if (available.isEmpty) {
      return;
    }

    DndClass selectedClass = available.first;
    int selectedLevel = 1;

    final result = await showDialog<CharacterClassLevel>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Añadir clase'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<DndClass>(
                    initialValue: selectedClass,
                    decoration: const InputDecoration(labelText: 'Clase'),
                    items: available.map((dndClass) {
                      return DropdownMenuItem(
                        value: dndClass,
                        child: Text('${dndClass.label} · d${dndClass.hitDie}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setDialogState(() {
                        selectedClass = value;
                      });
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
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (selectedLevel < 1) {
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      CharacterClassLevel(
                        dndClass: selectedClass,
                        level: selectedLevel,
                      ),
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

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      character.classes.add(result);
      character.normalizeHealth();
    });

    await save();
  }

  Future<void> editClass(int index) async {
    final current = character.classes[index];

    DndClass selectedClass = current.dndClass;

    int selectedLevel = current.level;

    final result = await showDialog<CharacterClassLevel>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar clase'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<DndClass>(
                    initialValue: selectedClass,
                    decoration: const InputDecoration(labelText: 'Clase'),
                    items: DndClass.values
                        .where((dndClass) {
                          if (dndClass == selectedClass) {
                            return true;
                          }

                          return !character.classes.any(
                            (item) => item.dndClass == dndClass,
                          );
                        })
                        .map(
                          (dndClass) => DropdownMenuItem(
                            value: dndClass,
                            child: Text(
                              '${dndClass.label} · d${dndClass.hitDie}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setDialogState(() {
                        selectedClass = value;
                      });
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
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (selectedLevel < 1) {
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      CharacterClassLevel(
                        dndClass: selectedClass,
                        level: selectedLevel,
                      ),
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

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      character.classes[index] = result;

      character.normalizeHealth();
    });

    /*
     * Si editamos la clase principal, sus
     * salvaciones deberían actualizarse.
     *
     * Solo hacemos esto con índice 0.
     */
    if (index == 0) {
      character.resetSavingThrowProficienciesFromClass();
    }

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
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar clase'),
          content: Text(
            '¿Quieres quitar ${item.dndClass.label} del personaje?',
          ),
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

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      character.classes.removeAt(index);
      character.normalizeHealth();
    });

    /*
     * Si eliminamos la clase principal,
     * la siguiente pasa a ser la principal.
     */
    if (index == 0) {
      character.resetSavingThrowProficienciesFromClass();
    }

    await save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clases')),
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

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(child: Text('${item.level}')),
                  title: Text(
                    item.dndClass.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    index == 0
                        ? 'Clase inicial · d${item.dndClass.hitDie}'
                        : 'Multiclase · d${item.dndClass.hitDie}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () {
                          editClass(index);
                        },
                        icon: const Icon(Icons.edit_rounded),
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        onPressed: () {
                          deleteClass(index);
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                  onTap: () {
                    editClass(index);
                  },
                ),
              );
            }),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: addClass,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Añadir multiclase'),
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
