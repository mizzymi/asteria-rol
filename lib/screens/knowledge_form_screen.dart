import 'package:flutter/material.dart';

import '../models/ability.dart';
import '../models/passive.dart';
import '../models/knowledge_definition.dart';
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

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late TextEditingController _requiredProgressController;
  late TextEditingController _studyDcController;

  late KnowledgeCategory _category;
  late List<String> _unlockedAbilityIds;
  late List<String> _unlockedPassiveIds;

  @override
  void initState() {
    super.initState();
    final d = widget.definition;

    _nameController = TextEditingController(text: d?.name ?? '');
    _descriptionController = TextEditingController(text: d?.description ?? '');
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _requiredProgressController = TextEditingController(
      text: '${d?.requiredProgress ?? 5}',
    );
    _studyDcController = TextEditingController(text: '${d?.studyDc ?? 15}');

    _category = d?.category ?? KnowledgeCategory.arcana;
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
    _requiredProgressController.dispose();
    _studyDcController.dispose();
    super.dispose();
  }

  Future<void> _createAbility() async {
    final ability = await Navigator.push<CharacterAbility>(
      context,
      MaterialPageRoute(builder: (_) => const AbilityFormScreen()),
    );

    if (ability != null) {
      await AbilityLibraryService.saveAbility(ability);
      if (!_unlockedAbilityIds.contains(ability.id)) {
        setState(() {
          _unlockedAbilityIds.add(ability.id);
        });
      }
    }
  }

  Future<void> _editAbility(String abilityId) async {
    final ability = await AbilityLibraryService.getAbilityById(abilityId);
    if (ability == null || !mounted) return;

    final result = await Navigator.push<CharacterAbility>(
      context,
      MaterialPageRoute(
        builder: (_) => AbilityFormScreen(ability: ability),
      ),
    );

    if (result != null) {
      await AbilityLibraryService.saveAbility(result);
      setState(() {}); // Refresca la vista para mostrar el nombre actualizado si cambió
    }
  }

  Future<void> _createPassive() async {
    final passive = await Navigator.push<CharacterPassive>(
      context,
      MaterialPageRoute(builder: (_) => const PassiveFormScreen()),
    );

    if (passive != null) {
      await PassiveLibraryService.savePassive(passive);
      if (!_unlockedPassiveIds.contains(passive.id)) {
        setState(() {
          _unlockedPassiveIds.add(passive.id);
        });
      }
    }
  }

  Future<void> _editPassive(String passiveId) async {
    final passive = await PassiveLibraryService.getPassiveById(passiveId);
    if (passive == null || !mounted) return;

    final result = await Navigator.push<CharacterPassive>(
      context,
      MaterialPageRoute(
        builder: (_) => PassiveFormScreen(passive: passive),
      ),
    );

    if (result != null) {
      await PassiveLibraryService.savePassive(result);
      setState(() {}); // Refresca la vista para mostrar el nombre actualizado si cambió
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final progress = int.tryParse(_requiredProgressController.text) ?? 5;
    final dc = int.tryParse(_studyDcController.text) ?? 15;
    final id = widget.definition?.id.isNotEmpty == true
        ? widget.definition!.id
        : _nameController.text.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      '_',
    );

    final updated = KnowledgeDefinition(
      id: id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      requiredProgress: progress > 0 ? progress : 1,
      studyDc: dc > 0 ? dc : 10,
      unlockedSpellIds: const [],
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
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Guardar',
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Título del saber o libro *',
                prefixIcon: Icon(Icons.auto_stories_rounded),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Introduce un nombre'
                  : null,
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<KnowledgeCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category_rounded),
                border: OutlineInputBorder(),
              ),
              items: KnowledgeCategory.values
                  .map(
                    (cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat.name.toUpperCase()),
                ),
              )
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _studyDcController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'CD Dificultad',
                      prefixIcon: Icon(Icons.security_rounded),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => int.tryParse(v ?? '') == null
                        ? 'Introduce un número'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _requiredProgressController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Éxitos necesarios',
                      prefixIcon: Icon(Icons.done_all_rounded),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => int.tryParse(v ?? '') == null
                        ? 'Introduce un número'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción / Historia',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notas personales del personaje',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // =================================================================
            // HABILIDADES VINCULADAS
            // =================================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Habilidades Desbloqueables',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _createAbility,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Crear Habilidad'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_unlockedAbilityIds.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: const Center(
                  child: Text('No hay habilidades vinculadas a este saber.'),
                ),
              )
            else
              ..._unlockedAbilityIds.map((abilityId) {
                return FutureBuilder<CharacterAbility?>(
                  future: AbilityLibraryService.getAbilityById(abilityId),
                  builder: (context, snapshot) {
                    final ability = snapshot.data;
                    final abilityName = ability?.name ?? abilityId;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => _editAbility(abilityId),
                        leading: const CircleAvatar(
                          child: Icon(Icons.flash_on_rounded, size: 18),
                        ),
                        title: Text(
                          abilityName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: ability == null
                            ? const Text('ID no encontrado en biblioteca')
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, size: 20),
                              tooltip: 'Editar',
                              onPressed: () => _editAbility(abilityId),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              tooltip: 'Desvincular',
                              onPressed: () {
                                setState(() {
                                  _unlockedAbilityIds.remove(abilityId);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            const SizedBox(height: 20),

            // =================================================================
            // PASIVAS VINCULADAS
            // =================================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pasivas Desbloqueables',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _createPassive,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Crear Pasiva'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_unlockedPassiveIds.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: const Center(
                  child: Text('No hay pasivas vinculadas a este saber.'),
                ),
              )
            else
              ..._unlockedPassiveIds.map((passiveId) {
                return FutureBuilder<CharacterPassive?>(
                  future: PassiveLibraryService.getPassiveById(passiveId),
                  builder: (context, snapshot) {
                    final passive = snapshot.data;
                    final passiveName = passive?.name ?? passiveId;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => _editPassive(passiveId),
                        leading: const CircleAvatar(
                          child: Icon(Icons.verified_user_rounded, size: 18),
                        ),
                        title: Text(
                          passiveName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: passive == null
                            ? const Text('ID no encontrado en biblioteca')
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, size: 20),
                              tooltip: 'Editar',
                              onPressed: () => _editPassive(passiveId),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              tooltip: 'Desvincular',
                              onPressed: () {
                                setState(() {
                                  _unlockedPassiveIds.remove(passiveId);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}
