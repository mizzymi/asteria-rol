import 'package:flutter/material.dart';

import '../models/ability.dart';
import '../models/knowledge_definition.dart';
import '../models/passive.dart';
import '../models/skill.dart';
import '../services/ability_library_service.dart';
import '../services/passive_library_service.dart';
import 'ability_form_screen.dart';
import 'passive_form_screen.dart';

class KnowledgeFormScreen extends StatefulWidget {
  final KnowledgeDefinition? definition;
  final String? initialNotes;
  final List<String>? initialUnlockedAbilityIds;
  final List<String>? initialUnlockedPassiveIds;

  const KnowledgeFormScreen({
    super.key,
    this.definition,
    this.initialNotes,
    this.initialUnlockedAbilityIds,
    this.initialUnlockedPassiveIds,
  });

  @override
  State<KnowledgeFormScreen> createState() => _KnowledgeFormScreenState();
}

class _KnowledgeFormScreenState extends State<KnowledgeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  late final TextEditingController _rarityController;
  late final TextEditingController _difficultyController;
  late final TextEditingController _levelController;
  late final TextEditingController _studyRequirementController;
  late final TextEditingController _legacyProgressController;
  late final TextEditingController _legacyDcController;

  late KnowledgeCategory _category;
  late List<KnowledgeCheckOption> _checkOptions;
  late List<KnowledgeCircle> _circles;
  late List<String> _unlockedAbilityIds;
  late List<String> _unlockedPassiveIds;

  @override
  void initState() {
    super.initState();
    final d = widget.definition;
    _nameController = TextEditingController(text: d?.name ?? '');
    _descriptionController = TextEditingController(text: d?.description ?? '');
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _rarityController = TextEditingController(text: d?.rarity ?? '');
    _difficultyController = TextEditingController(text: d?.difficulty ?? '');
    _levelController = TextEditingController(text: d?.levelLabel ?? '');
    _studyRequirementController = TextEditingController(text: d?.studyRequirement ?? '');
    _legacyProgressController = TextEditingController(text: '${d?.requiredProgress ?? 3}');
    _legacyDcController = TextEditingController(text: '${d?.studyDc ?? 15}');
    _category = d?.category ?? KnowledgeCategory.arcana;
    _checkOptions = List<KnowledgeCheckOption>.from(d?.checkOptions ?? const []);
    if (_checkOptions.isEmpty) {
      _checkOptions.add(KnowledgeCheckOption.ability(AbilityType.intelligence));
    }
    _circles = List<KnowledgeCircle>.from(d?.circles ?? const []);
    _unlockedAbilityIds = List<String>.from(
      widget.initialUnlockedAbilityIds ?? d?.unlockedAbilityIds ?? const [],
    );
    _unlockedPassiveIds = List<String>.from(
      widget.initialUnlockedPassiveIds ?? d?.unlockedPassiveIds ?? const [],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _rarityController.dispose();
    _difficultyController.dispose();
    _levelController.dispose();
    _studyRequirementController.dispose();
    _legacyProgressController.dispose();
    _legacyDcController.dispose();
    super.dispose();
  }

  Future<void> _createAbility() async {
    final ability = await Navigator.push<CharacterAbility>(
      context,
      MaterialPageRoute(builder: (_) => const AbilityFormScreen()),
    );
    if (ability == null) {
      return;
    }
    await AbilityLibraryService.saveAbility(ability);
    if (!mounted) {
      return;
    }
    setState(() {
      if (!_unlockedAbilityIds.contains(ability.id)) _unlockedAbilityIds.add(ability.id);
    });
  }

  Future<void> _createPassive() async {
    final passive = await Navigator.push<CharacterPassive>(
      context,
      MaterialPageRoute(builder: (_) => const PassiveFormScreen()),
    );
    if (passive == null) {
      return;
    }
    await PassiveLibraryService.savePassive(passive);
    if (!mounted) {
      return;
    }
    setState(() {
      if (!_unlockedPassiveIds.contains(passive.id)) _unlockedPassiveIds.add(passive.id);
    });
  }

  Future<void> _editAbility(String id) async {
    final current = await AbilityLibraryService.getAbilityById(id);
    if (current == null || !mounted) {
      return;
    }
    final updated = await Navigator.push<CharacterAbility>(
      context,
      MaterialPageRoute(builder: (_) => AbilityFormScreen(ability: current)),
    );
    if (updated != null) {
      await AbilityLibraryService.saveAbility(updated);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _editPassive(String id) async {
    final current = await PassiveLibraryService.getPassiveById(id);
    if (current == null || !mounted) {
      return;
    }
    final updated = await Navigator.push<CharacterPassive>(
      context,
      MaterialPageRoute(builder: (_) => PassiveFormScreen(passive: current)),
    );
    if (updated != null) {
      await PassiveLibraryService.savePassive(updated);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _addCheckOption() async {
    var kind = KnowledgeCheckKind.ability;
    var ability = AbilityType.intelligence;
    var skill = DndSkill.arcana;

    final option = await showDialog<KnowledgeCheckOption>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Añadir tirada permitida'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<KnowledgeCheckKind>(
                segments: const [
                  ButtonSegment(value: KnowledgeCheckKind.ability, label: Text('Atributo')),
                  ButtonSegment(value: KnowledgeCheckKind.skill, label: Text('Habilidad')),
                ],
                selected: {kind},
                onSelectionChanged: (v) => setDialogState(() => kind = v.first),
              ),
              const SizedBox(height: 14),
              if (kind == KnowledgeCheckKind.ability)
                DropdownButtonFormField<AbilityType>(
                  initialValue: ability,
                  decoration: const InputDecoration(labelText: 'Atributo'),
                  items: AbilityType.values
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => ability = v ?? ability),
                )
              else
                DropdownButtonFormField<DndSkill>(
                  initialValue: skill,
                  decoration: const InputDecoration(labelText: 'Habilidad'),
                  items: DndSkill.values
                      .map((e) => DropdownMenuItem(value: e, child: Text('${e.label} (${e.ability.shortLabel})')))
                      .toList(),
                  onChanged: (v) => setDialogState(() => skill = v ?? skill),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(
                ctx,
                kind == KnowledgeCheckKind.ability
                    ? KnowledgeCheckOption.ability(ability)
                    : KnowledgeCheckOption.skill(skill),
              ),
              child: const Text('Añadir'),
            ),
          ],
        ),
      ),
    );

    if (option == null || !mounted) {
      return;
    }
    final duplicate = _checkOptions.any((e) => e.kind == option.kind && e.value == option.value);
    if (!duplicate) {
      setState(() => _checkOptions.add(option));
    }
  }

  Future<Set<String>?> _pickAbilities(Set<String> initial) async {
    final items = await AbilityLibraryService.loadAbilities();
    if (!mounted) return null;
    var selected = Set<String>.from(initial);
    return showDialog<Set<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Habilidades del círculo'),
          content: SizedBox(
            width: 520,
            child: items.isEmpty
                ? const Text('No hay habilidades guardadas en la biblioteca.')
                : ListView(
                    shrinkWrap: true,
                    children: items.map((a) => CheckboxListTile(
                      value: selected.contains(a.id),
                      title: Text(a.name),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          selected.add(a.id);
                        } else {
                          selected.remove(a.id);
                        }
                      }),
                    )).toList(),
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, selected), child: const Text('Aceptar')),
          ],
        ),
      ),
    );
  }

  Future<Set<String>?> _pickPassives(Set<String> initial, {required String title}) async {
    final items = await PassiveLibraryService.loadPassives();
    if (!mounted) return null;
    var selected = Set<String>.from(initial);
    return showDialog<Set<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 520,
            child: items.isEmpty
                ? const Text('No hay pasivas guardadas en la biblioteca.')
                : ListView(
                    shrinkWrap: true,
                    children: items.map((p) => CheckboxListTile(
                      value: selected.contains(p.id),
                      title: Text(p.name),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          selected.add(p.id);
                        } else {
                          selected.remove(p.id);
                        }
                      }),
                    )).toList(),
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, selected), child: const Text('Aceptar')),
          ],
        ),
      ),
    );
  }

  Future<void> _editCircle({KnowledgeCircle? circle, int? index}) async {
    final title = TextEditingController(text: circle?.title ?? '');
    final dc = TextEditingController(text: '${circle?.dc ?? 10}');
    final description = TextEditingController(text: circle?.description ?? '');
    final reward = TextEditingController(text: circle?.rewardDescription ?? '');
    var abilities = Set<String>.from(circle?.unlockedAbilityIds ?? const []);
    var passives = Set<String>.from(circle?.unlockedPassiveIds ?? const []);
    var temporary = Set<String>.from(circle?.temporaryPassiveIds ?? const []);

    final result = await showDialog<KnowledgeCircle>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(circle == null ? 'Nuevo círculo' : 'Editar círculo'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: title, decoration: const InputDecoration(labelText: 'Nombre del círculo')),
                  const SizedBox(height: 10),
                  TextField(controller: dc, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'CD')),
                  const SizedBox(height: 10),
                  TextField(controller: description, maxLines: 4, decoration: const InputDecoration(labelText: 'Enseñanza / descripción')),
                  const SizedBox(height: 10),
                  TextField(controller: reward, maxLines: 3, decoration: const InputDecoration(labelText: 'Recompensa / efecto narrativo')),
                  const SizedBox(height: 14),
                  _RewardPickerTile(
                    icon: Icons.flash_on_rounded,
                    title: 'Habilidades permanentes',
                    count: abilities.length,
                    onTap: () async {
                      final picked = await _pickAbilities(abilities);
                      if (picked != null) {
                        setDialogState(() => abilities = picked);
                      }
                    },
                  ),
                  _RewardPickerTile(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Pasivas permanentes',
                    count: passives.length,
                    onTap: () async {
                      final picked = await _pickPassives(passives, title: 'Pasivas permanentes');
                      if (picked != null) {
                        setDialogState(() => passives = picked);
                      }
                    },
                  ),
                  _RewardPickerTile(
                    icon: Icons.hourglass_top_rounded,
                    title: 'Pasivas temporales mientras estudia',
                    count: temporary.length,
                    onTap: () async {
                      final picked = await _pickPassives(temporary, title: 'Pasivas temporales');
                      if (picked != null) {
                        setDialogState(() => temporary = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final parsedDc = int.tryParse(dc.text.trim());
                if (title.text.trim().isEmpty || parsedDc == null || parsedDc <= 0) {
                  return;
                }
                Navigator.pop(
                  ctx,
                  KnowledgeCircle(
                    id: circle?.id ?? 'circle_${DateTime.now().microsecondsSinceEpoch}',
                    title: title.text.trim(),
                    dc: parsedDc,
                    description: description.text.trim(),
                    rewardDescription: reward.text.trim(),
                    unlockedAbilityIds: abilities.toList(),
                    unlockedPassiveIds: passives.toList(),
                    temporaryPassiveIds: temporary.toList(),
                  ),
                );
              },
              child: const Text('Guardar círculo'),
            ),
          ],
        ),
      ),
    );

    title.dispose();
    dc.dispose();
    description.dispose();
    reward.dispose();
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      if (index == null) {
        _circles.add(result);
      } else {
        _circles[index] = result;
      }
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final legacyProgress = int.tryParse(_legacyProgressController.text) ?? 3;
    final legacyDc = int.tryParse(_legacyDcController.text) ?? 15;
    final name = _nameController.text.trim();
    final id = widget.definition?.id.isNotEmpty == true
        ? widget.definition!.id
        : name.toLowerCase().replaceAll(RegExp(r'\s+'), '_');

    final updated = KnowledgeDefinition(
      id: id,
      name: name,
      description: _descriptionController.text.trim(),
      category: _category,
      requiredProgress: legacyProgress.clamp(1, 99).toInt(),
      studyDc: legacyDc.clamp(1, 99).toInt(),
      rarity: _rarityController.text.trim(),
      difficulty: _difficultyController.text.trim(),
      levelLabel: _levelController.text.trim(),
      studyRequirement: _studyRequirementController.text.trim(),
      checkOptions: _checkOptions,
      circles: _circles,
      unlockedAbilityIds: _unlockedAbilityIds,
      unlockedPassiveIds: _unlockedPassiveIds,
    );

    Navigator.pop(context, {
      'definition': updated,
      'notes': _notesController.text.trim(),
      'unlockedAbilityIds': _unlockedAbilityIds,
      'unlockedPassiveIds': _unlockedPassiveIds,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.definition == null ? 'Nuevo Saber' : 'Editar Saber'),
        actions: [IconButton(icon: const Icon(Icons.check_rounded), tooltip: 'Guardar', onPressed: _save)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Título del saber o libro *', prefixIcon: Icon(Icons.auto_stories_rounded)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Introduce un nombre' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<KnowledgeCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Categoría', prefixIcon: Icon(Icons.category_rounded)),
              items: KnowledgeCategory.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(controller: _rarityController, decoration: const InputDecoration(labelText: 'Rareza', hintText: 'Legendaria'))),
              const SizedBox(width: 10),
              Expanded(child: TextFormField(controller: _difficultyController, decoration: const InputDecoration(labelText: 'Dificultad', hintText: 'Muy alta'))),
            ]),
            const SizedBox(height: 10),
            TextFormField(controller: _levelController, decoration: const InputDecoration(labelText: 'Nivel / grado', hintText: 'Principiante')),
            const SizedBox(height: 10),
            TextFormField(controller: _descriptionController, maxLines: 4, decoration: const InputDecoration(labelText: 'Descripción / historia', alignLabelWithHint: true)),
            const SizedBox(height: 10),
            TextFormField(controller: _studyRequirementController, maxLines: 2, decoration: const InputDecoration(labelText: 'Requisito especial de estudio', hintText: 'Ej.: requiere práctica física', alignLabelWithHint: true)),
            const SizedBox(height: 22),
            _SectionTitle(title: 'Tiradas permitidas', actionLabel: 'Añadir', onAction: _addCheckOption),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _checkOptions.asMap().entries.map((entry) => InputChip(
                avatar: Icon(entry.value.kind == KnowledgeCheckKind.skill ? Icons.psychology_rounded : Icons.person_rounded, size: 17),
                label: Text(entry.value.label),
                onDeleted: _checkOptions.length <= 1 ? null : () => setState(() => _checkOptions.removeAt(entry.key)),
              )).toList(),
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Círculos de aprendizaje', actionLabel: 'Añadir círculo', onAction: () => _editCircle()),
            const SizedBox(height: 8),
            if (_circles.isEmpty) ...[
              Text('Sin círculos: se usará el modo clásico por éxitos.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextFormField(controller: _legacyDcController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'CD clásica'))),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: _legacyProgressController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Éxitos necesarios'))),
              ]),
            ] else
              ..._circles.asMap().entries.map((entry) {
                final c = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${entry.key + 1}')),
                    title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('CD ${c.dc}${c.rewardDescription.isNotEmpty ? ' · ${c.rewardDescription}' : ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => _editCircle(circle: c, index: entry.key)),
                      IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () => setState(() => _circles.removeAt(entry.key))),
                    ]),
                  ),
                );
              }),
            const SizedBox(height: 24),
            _SectionTitle(title: 'Recompensas al completar el libro'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: FilledButton.tonalIcon(onPressed: _createAbility, icon: const Icon(Icons.add_rounded), label: const Text('Crear habilidad'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.tonalIcon(onPressed: _createPassive, icon: const Icon(Icons.add_rounded), label: const Text('Crear pasiva'))),
            ]),
            const SizedBox(height: 10),
            ..._unlockedAbilityIds.map((id) => FutureBuilder<CharacterAbility?>(
              future: AbilityLibraryService.getAbilityById(id),
              builder: (context, snap) => ListTile(
                leading: const Icon(Icons.flash_on_rounded),
                title: Text(snap.data?.name ?? id),
                subtitle: const Text('Habilidad al completar'),
                onTap: () => _editAbility(id),
                trailing: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _unlockedAbilityIds.remove(id))),
              ),
            )),
            ..._unlockedPassiveIds.map((id) => FutureBuilder<CharacterPassive?>(
              future: PassiveLibraryService.getPassiveById(id),
              builder: (context, snap) => ListTile(
                leading: const Icon(Icons.auto_awesome_rounded),
                title: Text(snap.data?.name ?? id),
                subtitle: const Text('Pasiva al completar'),
                onTap: () => _editPassive(id),
                trailing: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _unlockedPassiveIds.remove(id))),
              ),
            )),
            const SizedBox(height: 16),
            TextFormField(controller: _notesController, maxLines: 2, decoration: const InputDecoration(labelText: 'Notas personales del personaje', alignLabelWithHint: true)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
      if (actionLabel != null && onAction != null)
        TextButton.icon(onPressed: onAction, icon: const Icon(Icons.add_rounded), label: Text(actionLabel!)),
    ]);
  }
}

class _RewardPickerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  const _RewardPickerTile({required this.icon, required this.title, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(count == 0 ? 'Ninguna' : '$count vinculada(s)'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
