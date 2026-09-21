import 'dart:io';

import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../models/ability_scores.dart';
import '../models/ability.dart';
import '../services/pet_image_service.dart';

class PetFormScreen extends StatefulWidget {
  final Pet? pet;

  const PetFormScreen({super.key, this.pet});

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _speciesController;
  late TextEditingController _maxHpController;
  late TextEditingController _acController;
  late TextEditingController _speedController;
  late TextEditingController _profBonusController;
  late TextEditingController _notesController;
  late String _avatarPath;
  late double _avatarAlignmentX;
  late double _avatarAlignmentY;

  late int _str;
  late int _dex;
  late int _con;
  late int _int;
  late int _wis;
  late int _cha;

  @override
  void initState() {
    super.initState();
    final p = widget.pet;

    _nameController = TextEditingController(text: p?.name ?? '');
    _speciesController = TextEditingController(text: p?.species ?? '');
    _maxHpController = TextEditingController(text: '${p?.maxHealth ?? 10}');
    _acController = TextEditingController(text: '${p?.armorClass ?? 12}');
    _speedController = TextEditingController(text: '${p?.speed ?? 30}');
    _profBonusController = TextEditingController(
      text: '${p?.proficiencyBonus ?? 2}',
    );
    _notesController = TextEditingController(text: p?.notes ?? '');
    _avatarPath = p?.avatarPath ?? '';
    _avatarAlignmentX = p?.avatarAlignmentX ?? 0;
    _avatarAlignmentY = p?.avatarAlignmentY ?? 0;

    _str = p?.strengthScore ?? 10;
    _dex = p?.dexterityScore ?? 10;
    _con = p?.constitutionScore ?? 10;
    _int = p?.intelligenceScore ?? 10;
    _wis = p?.wisdomScore ?? 10;
    _cha = p?.charismaScore ?? 10;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _maxHpController.dispose();
    _acController.dispose();
    _speedController.dispose();
    _profBonusController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final maxHp = int.tryParse(_maxHpController.text.trim()) ?? 10;
    final ac = int.tryParse(_acController.text.trim()) ?? 12;
    final speed = int.tryParse(_speedController.text.trim()) ?? 30;
    final profBonus = int.tryParse(_profBonusController.text.trim()) ?? 2;

    final id = widget.pet?.id.isNotEmpty == true
        ? widget.pet!.id
        : 'pet_${DateTime.now().microsecondsSinceEpoch}';

    final currentHp = widget.pet != null
        ? widget.pet!.currentHealth.clamp(0, maxHp)
        : maxHp;

    final updatedPet = Pet(
      id: id,
      name: _nameController.text.trim(),
      species: _speciesController.text.trim(),
      avatarPath: _avatarPath,
      avatarAlignmentX: _avatarAlignmentX,
      avatarAlignmentY: _avatarAlignmentY,
      maxHealth: maxHp,
      currentHealth: currentHp,
      armorClass: ac,
      speed: speed,
      proficiencyBonus: profBonus,
      abilities: AbilityScores(
        strength: _str,
        dexterity: _dex,
        constitution: _con,
        intelligence: _int,
        wisdom: _wis,
        charisma: _cha,
      ),
      characterAbilities: widget.pet?.characterAbilities ?? <CharacterAbility>[],
      passives: widget.pet?.passives ?? [],
      weapons: widget.pet?.weapons ?? [],
      statModifiers: widget.pet?.statModifiers ?? {},
      effects: widget.pet?.effects ?? [],
      notes: _notesController.text.trim(),
    );

    Navigator.pop(context, updatedPet);
  }

  Future<void> _pickAvatar() async {
    final imagePath = await PetImageService.pickImage();
    if (imagePath == null || !mounted) return;
    setState(() {
      _avatarPath = imagePath;
      _avatarAlignmentX = 0;
      _avatarAlignmentY = 0;
    });
    await _adjustAvatarFraming();
  }

  void _removeAvatar() {
    setState(() {
      _avatarPath = '';
      _avatarAlignmentX = 0;
      _avatarAlignmentY = 0;
    });
  }

  Future<void> _adjustAvatarFraming() async {
    if (_avatarPath.isEmpty || !File(_avatarPath).existsSync()) return;

    var x = _avatarAlignmentX;
    var y = _avatarAlignmentY;

    final result = await showDialog<Alignment>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Elegir encuadre'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Arrastra la imagen para elegir qué parte se verá. La foto original no se recorta ni se modifica.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) {
                          setDialogState(() {
                            x = (x - details.delta.dx / 120).clamp(-1.0, 1.0);
                            y = (y - details.delta.dy / 90).clamp(-1.0, 1.0);
                          });
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(_avatarPath),
                              fit: BoxFit.cover,
                              alignment: Alignment(x, y),
                            ),
                            IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.open_with_rounded, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Desliza para recolocar el encuadre',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setDialogState(() {
                          x = 0;
                          y = 0;
                        }),
                        child: const Text('Centrar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, Alignment(x, y)),
                child: const Text('Guardar encuadre'),
              ),
            ],
          );
        },
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _avatarAlignmentX = result.x;
      _avatarAlignmentY = result.y;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pet == null ? 'Nueva Mascota' : 'Editar Mascota'),
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
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest,
              child: InkWell(
                onTap: _pickAvatar,
                child: SizedBox(
                  height: 190,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_avatarPath.isNotEmpty && File(_avatarPath).existsSync())
                        Image.file(
                          File(_avatarPath),
                          fit: BoxFit.cover,
                          alignment: Alignment(_avatarAlignmentX, _avatarAlignmentY),
                        )
                      else
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primaryContainer,
                                theme.colorScheme.tertiaryContainer,
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.pets_rounded,
                            size: 72,
                            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.72),
                          ),
                        ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Theme.of(context).colorScheme.surface.withValues(alpha: 0),
                                Theme.of(context).colorScheme.scrim.withValues(alpha: 0.42),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 12,
                        bottom: 12,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _avatarPath.isEmpty ? 'Añadir imagen' : 'Cambiar imagen',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onInverseSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: _pickAvatar,
                              icon: const Icon(Icons.photo_library_rounded),
                              label: const Text('Galería'),
                            ),
                            if (_avatarPath.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              IconButton.filledTonal(
                                onPressed: _adjustAvatarFraming,
                                tooltip: 'Ajustar encuadre',
                                icon: const Icon(Icons.crop_free_rounded),
                              ),
                              const SizedBox(width: 6),
                              IconButton.filledTonal(
                                onPressed: _removeAvatar,
                                tooltip: 'Quitar imagen',
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del compañero *',
                prefixIcon: Icon(Icons.pets_rounded),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Introduce un nombre'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _speciesController,
              decoration: const InputDecoration(
                labelText: 'Especie / Tipo (ej. Bestia, Familiar)',
                prefixIcon: Icon(Icons.category_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxHpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'PV Máximos',
                      prefixIcon: Icon(Icons.favorite_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _acController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'CA',
                      prefixIcon: Icon(Icons.shield_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _speedController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Velocidad (pies)',
                      prefixIcon: Icon(Icons.directions_run_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _profBonusController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Bono Competencia',
                      prefixIcon: Icon(Icons.military_tech_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Atributos del Compañero',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildAttributesGrid(),
            const SizedBox(height: 20),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas o descripción general',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributesGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _attributeBox('FUE', _str, (val) => setState(() => _str = val)),
        _attributeBox('DES', _dex, (val) => setState(() => _dex = val)),
        _attributeBox('CON', _con, (val) => setState(() => _con = val)),
        _attributeBox('INT', _int, (val) => setState(() => _int = val)),
        _attributeBox('SAB', _wis, (val) => setState(() => _wis = val)),
        _attributeBox('CAR', _cha, (val) => setState(() => _cha = val)),
      ],
    );
  }

  Widget _attributeBox(String label, int value, ValueChanged<int> onChanged) {
    final mod = AbilityScores.modifierFor(value);
    final modText = mod >= 0 ? '+$mod' : '$mod';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                modText,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          SizedBox(
            width: 60,
            child: TextField(
              controller: TextEditingController(text: '$value')
                ..selection = TextSelection.collapsed(offset: '$value'.length),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
              ),
              onSubmitted: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null) onChanged(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }
}
