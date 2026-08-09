import 'package:flutter/material.dart';

import '../models/ability.dart';
import '../models/character.dart';
import '../models/item.dart';
import '../models/passive.dart';
import '../models/skill.dart';
import '../services/character_storage_service.dart';
import 'item_form_screen.dart';

class ItemsScreen extends StatefulWidget {
  final Character character;

  const ItemsScreen({super.key, required this.character});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  Character get character => widget.character;

  Future<void> save() async {
    character.normalizeHealth();

    await CharacterStorageService.saveCharacter(character);
  }

  Future<void> createItem() async {
    final result = await Navigator.push<CharacterItem>(
      context,
      MaterialPageRoute(builder: (_) => const ItemFormScreen()),
    );

    if (result == null) {
      return;
    }

    setState(() {
      character.addItem(result);

      if (result.equipped) {
        character.equipItem(result);
      }

      character.normalizeHealth();
    });

    await save();
  }

  Future<void> editItem(CharacterItem item) async {
    final result = await Navigator.push<CharacterItem>(
      context,
      MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)),
    );

    if (result == null) {
      return;
    }

    final index = character.items.indexWhere((value) => value.id == result.id);

    if (index < 0) {
      return;
    }

    setState(() {
      character.items[index] = result;

      if (result.equipped) {
        character.equipItem(result);
      }

      character.normalizeHealth();
    });

    await save();
  }

  Future<void> deleteItem(CharacterItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar objeto'),
          content: Text('¿Quieres eliminar "${item.name}"?'),
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

    if (confirmed != true) {
      return;
    }

    setState(() {
      character.removeItem(item.id);

      character.normalizeHealth();
    });

    await save();
  }

  Future<void> toggleEquip(CharacterItem item) async {
    setState(() {
      if (item.equipped) {
        character.unequipItem(item);
      } else {
        character.equipItem(item);
      }

      character.normalizeHealth();
    });

    await save();
  }

  @override
  Widget build(BuildContext context) {
    final equipped = character.items.where((item) => item.equipped).toList();

    final inventory = character.items.where((item) => !item.equipped).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Objetos')),
      body: character.items.isEmpty
          ? _EmptyItems(onCreate: createItem)
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
              children: [
                if (equipped.isNotEmpty) ...[
                  Text(
                    'Equipados',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ...equipped.map(
                    (item) => _ItemCard(
                      item: item,
                      onEquip: () {
                        toggleEquip(item);
                      },
                      onEdit: () {
                        editItem(item);
                      },
                      onDelete: () {
                        deleteItem(item);
                      },
                    ),
                  ),

                  const SizedBox(height: 22),
                ],

                Text(
                  'Inventario',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                if (inventory.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'No hay objetos sin equipar.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...inventory.map(
                    (item) => _ItemCard(
                      item: item,
                      onEquip: () {
                        toggleEquip(item);
                      },
                      onEdit: () {
                        editItem(item);
                      },
                      onDelete: () {
                        deleteItem(item);
                      },
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createItem,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo objeto'),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final CharacterItem item;

  final VoidCallback onEquip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.onEquip,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _iconForType(item.type),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),

                      Text(item.type.label),
                    ],
                  ),
                ),

                if (item.quantity > 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      'x${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;

                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),

            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(item.description),
            ],

            if (item.passives.isNotEmpty) ...[
              const SizedBox(height: 14),

              Text(
                'Pasivas',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              ...item.passives.map(
                (passive) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PassivePreview(passive: passive),
                ),
              ),
            ],

            if (item.abilities.isNotEmpty) ...[
              const SizedBox(height: 14),

              Text(
                'Habilidades',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              ...item.abilities.map(
                (ability) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AbilityPreview(ability: ability),
                ),
              ),
            ],

            const SizedBox(height: 14),

            if (item.type.isEquipable)
              SizedBox(
                width: double.infinity,
                child: item.equipped
                    ? FilledButton.tonalIcon(
                        onPressed: onEquip,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Equipado · Desequipar'),
                      )
                    : OutlinedButton.icon(
                        onPressed: onEquip,
                        icon: const Icon(Icons.inventory_2_rounded),
                        label: const Text('Equipar'),
                      ),
              ),

            if (!item.type.isEquipable)
              const Text('Este tipo de objeto no se puede equipar.'),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(ItemType type) {
    switch (type) {
      case ItemType.armor:
        return Icons.shield_rounded;

      case ItemType.helmet:
        return Icons.sports_motorsports_rounded;

      case ItemType.gloves:
        return Icons.back_hand_rounded;

      case ItemType.boots:
        return Icons.hiking_rounded;

      case ItemType.ring:
        return Icons.circle_outlined;

      case ItemType.amulet:
        return Icons.diamond_rounded;

      case ItemType.weapon:
        return Icons.sports_martial_arts_rounded;

      case ItemType.accessory:
        return Icons.auto_awesome_rounded;

      case ItemType.consumable:
        return Icons.local_drink_rounded;

      case ItemType.other:
        return Icons.inventory_2_rounded;
    }
  }
}

class _PassivePreview extends StatelessWidget {
  final CharacterPassive passive;

  const _PassivePreview({required this.passive});

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

    for (final entry in passive.savingThrowBonuses.entries) {
      if (entry.value != 0) {
        effects.add('${_bonus(entry.value)} salvación ${entry.key.name}');
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 18),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  passive.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          if (passive.description.isNotEmpty) ...[
            const SizedBox(height: 6),

            Text(passive.description),
          ],

          if (effects.isNotEmpty) ...[
            const SizedBox(height: 8),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: effects
                  .map((effect) => Chip(label: Text(effect)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _bonus(int value) {
    return value >= 0 ? '+$value' : '$value';
  }
}

class _AbilityPreview extends StatelessWidget {
  final CharacterAbility ability;

  const _AbilityPreview({required this.ability});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, size: 18),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  ability.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              Text(
                ability.actionType.label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),

          if (ability.description.isNotEmpty) ...[
            const SizedBox(height: 6),

            Text(ability.description),
          ],

          const SizedBox(height: 8),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (ability.requiresAttackRoll)
                const Chip(
                  avatar: Icon(Icons.gps_fixed_rounded, size: 16),
                  label: Text('Ataque'),
                ),

              if (ability.hasEffect)
                Chip(
                  avatar: Icon(
                    ability.heals
                        ? Icons.favorite_rounded
                        : Icons.flash_on_rounded,
                    size: 16,
                  ),
                  label: Text(ability.diceNotation),
                ),

              if (ability.usesSavingThrow)
                const Chip(
                  avatar: Icon(Icons.shield_rounded, size: 16),
                  label: Text('Salvación'),
                ),

              if (ability.hasLimitedUses)
                Chip(
                  avatar: const Icon(Icons.repeat_rounded, size: 16),
                  label: Text('${ability.currentUses}/${ability.maxUses}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyItems extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyItems({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_rounded,
              size: 68,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(height: 18),

            Text(
              'Inventario vacío',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Añade armaduras, accesorios, armas, consumibles y otros objetos.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 22),

            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear objeto'),
            ),
          ],
        ),
      ),
    );
  }
}
