import 'package:flutter/material.dart';

import '../models/ability.dart';
import '../models/item.dart';
import '../models/passive.dart';
import '../models/skill.dart';

import 'ability_form_screen.dart';
import 'passive_form_screen.dart';

class ItemFormScreen extends StatefulWidget {
  final CharacterItem? item;

  const ItemFormScreen({super.key, this.item});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  ArmorCategory armorCategory = ArmorCategory.light;

  late final TextEditingController armorBaseClassController;
  late final TextEditingController nameController;

  late final TextEditingController descriptionController;

  late final TextEditingController quantityController;

  late final TextEditingController notesController;

  late ItemType itemType;

  bool equipped = false;

  late List<CharacterPassive> passives;

  late List<CharacterAbility> abilities;

  bool get editing => widget.item != null;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    armorCategory = item?.armorCategory ?? ArmorCategory.light;

    armorBaseClassController = TextEditingController(
      text: '${item?.armorBaseClass ?? 11}',
    );
    nameController = TextEditingController(text: item?.name ?? '');

    descriptionController = TextEditingController(
      text: item?.description ?? '',
    );

    quantityController = TextEditingController(text: '${item?.quantity ?? 1}');

    notesController = TextEditingController(text: item?.notes ?? '');

    itemType = item?.type ?? ItemType.other;

    equipped = item?.equipped ?? false;

    passives =
        item?.passives
            .map((passive) => CharacterPassive.fromMap(passive.toMap()))
            .toList() ??
        [];

    abilities =
        item?.abilities
            .map((ability) => CharacterAbility.fromMap(ability.toMap()))
            .toList() ??
        [];
  }

  // ===========================================================================
  // PASIVAS
  // ===========================================================================

  Future<void> addPassive() async {
    final passive = await Navigator.push<CharacterPassive>(
      context,
      MaterialPageRoute(builder: (_) => const PassiveFormScreen()),
    );

    if (passive == null || !mounted) {
      return;
    }

    passive.sourceType = PassiveSourceType.item;

    setState(() {
      passives.add(passive);
    });
  }

  Future<void> editPassive(int index) async {
    final current = passives[index];

    final result = await Navigator.push<CharacterPassive>(
      context,
      MaterialPageRoute(builder: (_) => PassiveFormScreen(passive: current)),
    );

    if (result == null || !mounted) {
      return;
    }

    result.sourceType = PassiveSourceType.item;

    setState(() {
      passives[index] = result;
    });
  }

  Future<void> deletePassive(int index) async {
    final passive = passives[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar pasiva'),
          content: Text('¿Quieres eliminar "${passive.name}"?'),
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
      passives.removeAt(index);
    });
  }

  // ===========================================================================
  // HABILIDADES
  // ===========================================================================

  Future<void> addAbility() async {
    final ability = await Navigator.push<CharacterAbility>(
      context,
      MaterialPageRoute(builder: (_) => const AbilityFormScreen()),
    );

    if (ability == null || !mounted) {
      return;
    }

    setState(() {
      abilities.add(ability);
    });
  }

  Future<void> editAbility(int index) async {
    final current = abilities[index];

    final result = await Navigator.push<CharacterAbility>(
      context,
      MaterialPageRoute(builder: (_) => AbilityFormScreen(ability: current)),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      abilities[index] = result;
    });
  }

  Future<void> deleteAbility(int index) async {
    final ability = abilities[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar habilidad'),
          content: Text('¿Quieres eliminar "${ability.name}"?'),
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
      abilities.removeAt(index);
    });
  }

  // ===========================================================================
  // GUARDAR
  // ===========================================================================

  void saveItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final item = CharacterItem(
      id: widget.item?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      armorCategory: itemType == ItemType.armor ? armorCategory : null,

      armorBaseClass: itemType == ItemType.armor
          ? int.tryParse(armorBaseClassController.text) ?? 10
          : 10,
      name: nameController.text.trim(),

      description: descriptionController.text.trim(),

      type: itemType,

      equipped: itemType.isEquipable ? equipped : false,

      passives: passives
          .map((passive) => CharacterPassive.fromMap(passive.toMap()))
          .toList(),

      abilities: abilities
          .map((ability) => CharacterAbility.fromMap(ability.toMap()))
          .toList(),

      quantity: int.tryParse(quantityController.text) ?? 1,

      notes: notesController.text.trim(),
    );

    Navigator.pop(context, item);
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    quantityController.dispose();
    notesController.dispose();
    armorBaseClassController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar objeto' : 'Nuevo objeto'),
        actions: [
          IconButton(
            onPressed: saveItem,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.inventory_2_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduce un nombre';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: descriptionController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<ItemType>(
                initialValue: itemType,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: ItemType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.label));
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    itemType = value;

                    if (!itemType.isEquipable) {
                      equipped = false;
                    }
                  });
                },
              ),
              if (itemType == ItemType.armor) ...[
                const SizedBox(height: 16),

                Text(
                  'Armadura',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<ArmorCategory>(
                  initialValue: armorCategory,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de armadura',
                    prefixIcon: Icon(Icons.shield_rounded),
                  ),
                  items: ArmorCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      armorCategory = value;
                    });
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: armorBaseClassController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'CA base',
                    prefixIcon: const Icon(Icons.shield_outlined),
                    helperText: switch (armorCategory) {
                      ArmorCategory.light =>
                        'CA base + todo el modificador de DES',

                      ArmorCategory.medium =>
                        'CA base + modificador de DES (máximo +2)',

                      ArmorCategory.heavy => 'CA base, sin modificador de DES',
                    },
                  ),
                  validator: (value) {
                    final result = int.tryParse(value ?? '');

                    if (result == null || result < 1) {
                      return 'Introduce una CA válida';
                    }

                    return null;
                  },
                ),
              ],
              const SizedBox(height: 14),

              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                validator: (value) {
                  final quantity = int.tryParse(value ?? '');

                  if (quantity == null || quantity < 1) {
                    return 'Mínimo 1';
                  }

                  return null;
                },
              ),

              if (itemType.isEquipable) ...[
                const SizedBox(height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: equipped,
                  title: const Text('Equipado'),
                  subtitle: itemType.exclusiveSlot
                      ? Text(
                          'Al equiparlo sustituirá cualquier ${itemType.label.toLowerCase()} equipado.',
                        )
                      : const Text(
                          'Sus pasivas y habilidades estarán disponibles mientras esté equipado.',
                        ),
                  onChanged: (value) {
                    setState(() {
                      equipped = value;
                    });
                  },
                ),
              ],

              const SizedBox(height: 28),

              // ===============================================================
              // PASIVAS
              // ===============================================================
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pasivas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  IconButton.filledTonal(
                    tooltip: 'Añadir pasiva',
                    onPressed: addPassive,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              const Text(
                'Estas pasivas se aplicarán automáticamente mientras el objeto esté equipado.',
              ),

              const SizedBox(height: 12),

              if (passives.isEmpty)
                _EmptySectionCard(
                  icon: Icons.auto_awesome_rounded,
                  text: 'Este objeto no tiene pasivas.',
                  buttonText: 'Añadir pasiva',
                  onPressed: addPassive,
                )
              else
                ...List.generate(passives.length, (index) {
                  final passive = passives[index];

                  return _PassiveCard(
                    passive: passive,
                    onEdit: () {
                      editPassive(index);
                    },
                    onDelete: () {
                      deletePassive(index);
                    },
                  );
                }),

              const SizedBox(height: 28),

              // ===============================================================
              // HABILIDADES
              // ===============================================================
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Habilidades',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  IconButton.filledTonal(
                    tooltip: 'Añadir habilidad',
                    onPressed: addAbility,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              const Text(
                'Las habilidades aparecerán en el panel de Habilidades mientras el objeto esté equipado.',
              ),

              const SizedBox(height: 12),

              if (abilities.isEmpty)
                _EmptySectionCard(
                  icon: Icons.flash_on_rounded,
                  text: 'Este objeto no tiene habilidades.',
                  buttonText: 'Añadir habilidad',
                  onPressed: addAbility,
                )
              else
                ...List.generate(abilities.length, (index) {
                  final ability = abilities[index];

                  return _AbilityCard(
                    ability: ability,
                    onEdit: () {
                      editAbility(index);
                    },
                    onDelete: () {
                      deleteAbility(index);
                    },
                  );
                }),

              const SizedBox(height: 28),

              TextFormField(
                controller: notesController,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 30),

              FilledButton.icon(
                onPressed: saveItem,
                icon: const Icon(Icons.save_rounded),
                label: Text(editing ? 'Guardar cambios' : 'Crear objeto'),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PREVIEW PASIVA
// =============================================================================

class _PassiveCard extends StatelessWidget {
  final CharacterPassive passive;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PassiveCard({
    required this.passive,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final effects = <String>[];

    if (passive.armorClassBonus != 0) {
      effects.add('${_bonus(passive.armorClassBonus)} CA');
    }

    if (passive.initiativeBonus != 0) {
      effects.add('${_bonus(passive.initiativeBonus)} iniciativa');
    }

    if (passive.speedBonus != 0) {
      effects.add('${_bonus(passive.speedBonus)} velocidad');
    }

    if (passive.maxHealthBonus != 0) {
      effects.add('${_bonus(passive.maxHealthBonus)} PG máx.');
    }

    if (passive.attackBonus != 0) {
      effects.add('${_bonus(passive.attackBonus)} al golpe');
    }

    for (final entry in passive.skillBonuses.entries) {
      if (entry.value != 0) {
        effects.add('${_bonus(entry.value)} ${entry.key.label}');
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.auto_awesome_rounded)),
        title: Text(
          passive.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (passive.description.isNotEmpty) Text(passive.description),

            if (effects.isNotEmpty) ...[
              const SizedBox(height: 6),

              Text(effects.join(' · ')),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            }

            if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }

  static String _bonus(int value) {
    return value >= 0 ? '+$value' : '$value';
  }
}

// =============================================================================
// PREVIEW HABILIDAD
// =============================================================================

class _AbilityCard extends StatelessWidget {
  final CharacterAbility ability;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AbilityCard({
    required this.ability,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final details = <String>[];

    if (ability.requiresAttackRoll) {
      details.add('Ataque');
    }

    if (ability.hasEffect) {
      details.add(ability.diceNotation);
    }

    if (ability.usesSavingThrow) {
      details.add('Salvación');
    }

    if (ability.hasLimitedUses) {
      details.add('${ability.currentUses}/${ability.maxUses} usos');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.flash_on_rounded)),
        title: Text(
          ability.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ability.actionType.label),

            if (ability.description.isNotEmpty)
              Text(
                ability.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            if (details.isNotEmpty) ...[
              const SizedBox(height: 4),

              Text(details.join(' · ')),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            }

            if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}

// =============================================================================
// VACÍO
// =============================================================================

class _EmptySectionCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final String buttonText;
  final VoidCallback onPressed;

  const _EmptySectionCard({
    required this.icon,
    required this.text,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),

            const SizedBox(height: 10),

            Text(text, textAlign: TextAlign.center),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add_rounded),
              label: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
