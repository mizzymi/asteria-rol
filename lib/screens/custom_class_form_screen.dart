import 'package:flutter/material.dart';

import '../models/character.dart';
import '../models/custom_class_definition.dart';
import '../models/skill.dart';
import '../services/character_storage_service.dart';
import '../services/custom_class_storage_service.dart';

class CustomClassFormScreen extends StatefulWidget {
  final CustomClassDefinition? definition;

  const CustomClassFormScreen({super.key, this.definition});

  @override
  State<CustomClassFormScreen> createState() => _CustomClassFormScreenState();
}

class _CustomClassFormScreenState extends State<CustomClassFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _versionController;
  late int _hitDie;
  late Set<AbilityType> _savingThrows;
  late List<ClassProgressionReward> _rewards;

  bool get editing => widget.definition != null;

  @override
  void initState() {
    super.initState();
    final definition = widget.definition;
    _nameController = TextEditingController(text: definition?.name ?? '');
    _descriptionController = TextEditingController(
      text: definition?.description ?? '',
    );
    _versionController = TextEditingController(
      text: '${definition?.version ?? 1}',
    );
    _hitDie = definition?.hitDie ?? 8;
    _savingThrows = Set<AbilityType>.from(
      definition?.savingThrowProficiencies ?? const {},
    );
    _rewards = List<ClassProgressionReward>.from(
      definition?.rewards ?? const [],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _versionController.dispose();
    super.dispose();
  }

  List<ClassProgressionContent> get _availableContent {
    final result = <String, ClassProgressionContent>{};
    for (final Character character in CharacterStorageService.getCharacters()) {
      for (final ability in character.characterAbilities) {
        if (ability.id.trim().isEmpty) continue;
        result.putIfAbsent(
          'ability:${ability.id}',
          () => ClassProgressionContent.fromAbility(ability),
        );
      }
      for (final passive in character.passives) {
        if (passive.id.trim().isEmpty) continue;
        result.putIfAbsent(
          'passive:${passive.id}',
          () => ClassProgressionContent.fromPassive(passive),
        );
      }
    }
    final values = result.values.toList();
    values.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return values;
  }

  Future<void> _addReward() async {
    final available = _availableContent;
    int level = 1;
    var mode = ClassProgressionRewardMode.automatic;
    String name = '';
    final selected = <String>{};

    final reward = await showDialog<ClassProgressionReward>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Recompensa de nivel'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: '1',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Nivel'),
                      onChanged: (value) => level = int.tryParse(value) ?? 1,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la recompensa',
                        hintText: 'Ej. Golpe Doble',
                      ),
                      onChanged: (value) => name = value,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ClassProgressionRewardMode>(
                      initialValue: mode,
                      decoration: const InputDecoration(labelText: 'Entrega'),
                      items: const [
                        DropdownMenuItem(
                          value: ClassProgressionRewardMode.automatic,
                          child: Text('Automática'),
                        ),
                        DropdownMenuItem(
                          value: ClassProgressionRewardMode.choice,
                          child: Text('Elección del jugador'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => mode = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        mode == ClassProgressionRewardMode.choice
                            ? 'Opciones que podrá escoger'
                            : 'Contenido que se concederá',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (available.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No hay habilidades o pasivas disponibles. Crea primero el contenido en una ficha del Máster y vuelve aquí.',
                        ),
                      )
                    else
                      ...available.map((content) {
                        final key = '${content.type.name}:${content.contentId}';
                        return CheckboxListTile(
                          value: selected.contains(key),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(content.name),
                          subtitle: Text(
                            content.type == ClassProgressionContentType.ability
                                ? 'Habilidad'
                                : 'Pasiva',
                          ),
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selected.add(key);
                              } else {
                                selected.remove(key);
                              }
                            });
                          },
                        );
                      }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (level < 1 || selected.isEmpty) return;
                  final contents = available.where((content) {
                    final key = '${content.type.name}:${content.contentId}';
                    return selected.contains(key);
                  }).toList();
                  final stamp = DateTime.now().microsecondsSinceEpoch;
                  Navigator.pop(
                    dialogContext,
                    ClassProgressionReward(
                      rewardId: 'reward_$stamp',
                      level: level,
                      mode: mode,
                      name: name.trim().isEmpty
                          ? 'Recompensa de nivel $level'
                          : name.trim(),
                      contents: contents,
                    ),
                  );
                },
                child: const Text('Añadir'),
              ),
            ],
          );
        },
      ),
    );

    if (reward == null || !mounted) return;
    setState(() {
      _rewards.add(reward);
      _rewards.sort((a, b) => a.level.compareTo(b.level));
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final version = int.tryParse(_versionController.text.trim()) ?? 1;
    final old = widget.definition;
    final classId =
        old?.classId ?? 'class_${DateTime.now().microsecondsSinceEpoch}';

    final definition = CustomClassDefinition(
      classId: classId,
      version: version < 1 ? 1 : version,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      hitDie: _hitDie,
      savingThrowProficiencies: _savingThrows,
      rewards: _rewards,
    );

    await CustomClassStorageService.saveClass(definition);
    if (!mounted) return;
    Navigator.pop(context, definition);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar clase' : 'Nueva clase'),
        actions: [
          IconButton(
            tooltip: 'Guardar',
            onPressed: _save,
            icon: const Icon(Icons.save_rounded),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la clase',
                prefixIcon: Icon(Icons.shield_rounded),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Obligatorio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _versionController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Versión',
                helperText: editing
                    ? 'Mantén el classId y aumenta la versión al publicar cambios.'
                    : 'Empieza en 1 y aumenta al publicar actualizaciones.',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _hitDie,
              decoration: const InputDecoration(labelText: 'Dado de golpe'),
              items: const [4, 6, 8, 10, 12, 20]
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text('d$value'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _hitDie = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Salvaciones con competencia',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AbilityType.values.map((ability) {
                final selected = _savingThrows.contains(ability);
                return FilterChip(
                  selected: selected,
                  label: Text(ability.label),
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _savingThrows.add(ability);
                      } else {
                        _savingThrows.remove(ability);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Progresión por nivel',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _addReward,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Recompensa'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_rewards.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Sin recompensas especiales. Puedes dejar niveles vacíos.',
                  ),
                ),
              )
            else
              ..._rewards.map(
                (reward) => Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${reward.level}')),
                    title: Text(
                      reward.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${reward.mode == ClassProgressionRewardMode.automatic ? 'Automática' : 'Elección'} · '
                      '${reward.contents.map((item) => item.name).join(', ')}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Eliminar recompensa',
                      onPressed: () {
                        setState(() => _rewards.remove(reward));
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Guardar clase'),
            ),
          ],
        ),
      ),
    );
  }
}
