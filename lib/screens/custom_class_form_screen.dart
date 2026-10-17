import 'package:flutter/material.dart';

import '../models/ability.dart';
import '../models/passive.dart';
import '../models/custom_class_definition.dart';
import '../models/skill.dart';
import 'ability_form_screen.dart';
import 'passive_form_screen.dart';
import '../services/custom_class_storage_service.dart';

class CustomClassFormScreen extends StatefulWidget {
  final CustomClassDefinition? definition;
  final String campaignId;

  const CustomClassFormScreen({
    super.key,
    this.definition,
    required this.campaignId,
  });

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
  final List<ClassProgressionContent> _draftContents = [];

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
    final contents = <String, ClassProgressionContent>{};
    for (final reward in _rewards) {
      for (final content in reward.contents) {
        contents['${content.type.name}:${content.contentId}'] = content;
      }
    }
    for (final content in _draftContents) {
      contents['${content.type.name}:${content.contentId}'] = content;
    }
    return contents.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<ClassProgressionContent?> _createContent(
    BuildContext dialogContext,
    ClassProgressionContentType type,
  ) async {
    if (type == ClassProgressionContentType.ability) {
      final ability = await Navigator.of(dialogContext).push<CharacterAbility>(
        MaterialPageRoute(builder: (_) => const AbilityFormScreen()),
      );
      return ability == null
          ? null
          : ClassProgressionContent.fromAbility(ability);
    }
    final passive = await Navigator.of(dialogContext).push<CharacterPassive>(
      MaterialPageRoute(builder: (_) => const PassiveFormScreen()),
    );
    return passive == null
        ? null
        : ClassProgressionContent.fromPassive(passive);
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Row(
              children: [
                Icon(Icons.workspace_premium_rounded),
                SizedBox(width: 10),
                Expanded(child: Text('Recompensa de nivel')),
              ],
            ),
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
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: const Text('Crear habilidad'),
                          onPressed: () async {
                            final content = await _createContent(
                              dialogContext,
                              ClassProgressionContentType.ability,
                            );
                            if (content == null || !dialogContext.mounted) {
                              return;
                            }
                            setDialogState(() {
                              available.add(content);
                              selected.add(
                                '${content.type.name}:${content.contentId}',
                              );
                            });
                          },
                        ),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.shield_outlined),
                          label: const Text('Crear pasiva'),
                          onPressed: () async {
                            final content = await _createContent(
                              dialogContext,
                              ClassProgressionContentType.passive,
                            );
                            if (content == null || !dialogContext.mounted) {
                              return;
                            }
                            setDialogState(() {
                              available.add(content);
                              selected.add(
                                '${content.type.name}:${content.contentId}',
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (available.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Todavía no hay contenido. Crea aquí una habilidad o una pasiva para esta clase.',
                        ),
                      )
                    else
                      ...available.map((content) {
                        final key = '${content.type.name}:${content.contentId}';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          child: CheckboxListTile(
                            value: selected.contains(key),
                            secondary: Icon(
                              content.type ==
                                      ClassProgressionContentType.ability
                                  ? Icons.auto_awesome_rounded
                                  : Icons.shield_rounded,
                            ),
                            dense: true,
                            controlAffinity: ListTileControlAffinity.trailing,
                            title: Text(content.name),
                            subtitle: Text(
                              content.type ==
                                      ClassProgressionContentType.ability
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
                          ),
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
      for (final content in reward.contents) {
        if (!_draftContents.any(
          (item) =>
              item.type == content.type && item.contentId == content.contentId,
        )) {
          _draftContents.add(content);
        }
      }
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
      campaignId: widget.campaignId,
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

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
    String? subtitle,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colors.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.surfaceContainerHigh,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          editing ? 'Diseña tu clase' : 'Nueva clase',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Define su identidad y lo que aprenderán sus personajes.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _section(
              icon: Icons.edit_note_rounded,
              title: 'Identidad',
              subtitle: 'Nombre, descripción y reglas básicas',
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la clase',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _versionController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Versión',
                            prefixIcon: Icon(Icons.history_rounded),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _hitDie,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Dado de golpe',
                            prefixIcon: Icon(Icons.casino_outlined),
                            border: OutlineInputBorder(),
                          ),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      hintText:
                          'El origen, el estilo de combate y los talentos de esta clase...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _section(
              icon: Icons.verified_user_rounded,
              title: 'Competencias de salvación',
              subtitle:
                  'Selecciona los atributos en los que destaca esta clase',
              child: Wrap(
                spacing: 9,
                runSpacing: 9,
                children: AbilityType.values.map((ability) {
                  final selected = _savingThrows.contains(ability);
                  return FilterChip(
                    selected: selected,
                    showCheckmark: true,
                    avatar: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18,
                    ),
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
            ),
            const SizedBox(height: 16),
            _section(
              icon: Icons.account_tree_rounded,
              title: 'Progresión por nivel',
              subtitle:
                  'Concede habilidades, pasivas o elecciones al subir de nivel',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_rewards.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 28,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.auto_awesome_outlined, size: 34),
                          SizedBox(height: 10),
                          Text(
                            'Aún no hay recompensas',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Puedes dejar niveles vacíos y añadir recompensas cuando quieras.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ..._rewards.map((reward) {
                      final choice =
                          reward.mode == ClassProgressionRewardMode.choice;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'NV.',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${reward.level}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reward.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          choice
                                              ? Icons.rule_rounded
                                              : Icons.bolt_rounded,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            choice
                                                ? 'Elección del jugador'
                                                : 'Entrega automática',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      reward.contents
                                          .map((item) => item.name)
                                          .join(' · '),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Eliminar recompensa',
                                onPressed: () =>
                                    setState(() => _rewards.remove(reward)),
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: _addReward,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Añadir recompensa de nivel'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Guardar clase'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
