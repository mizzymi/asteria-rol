import 'package:flutter/material.dart';

import '../models/character.dart';
import '../models/passive.dart';
import '../models/skill.dart';
import '../services/character_storage_service.dart';
import 'passive_form_screen.dart';

class PassivesScreen extends StatefulWidget {
  final Character character;

  const PassivesScreen({super.key, required this.character});

  @override
  State<PassivesScreen> createState() => _PassivesScreenState();
}

class _PassivesScreenState extends State<PassivesScreen> {
  Character get character => widget.character;

  Future<void> save() async {
    await CharacterStorageService.saveCharacter(character);
  }

  Future<void> createPassive() async {
    final passive = await Navigator.push<CharacterPassive>(
      context,
      MaterialPageRoute(builder: (_) => const PassiveFormScreen()),
    );

    if (passive == null) {
      return;
    }

    setState(() {
      character.addPassive(passive);

      character.normalizeHealth();
    });

    await save();
  }

  Future<void> editPassive(CharacterPassive passive) async {
    final result = await Navigator.push<CharacterPassive>(
      context,
      MaterialPageRoute(builder: (_) => PassiveFormScreen(passive: passive)),
    );

    if (result == null) {
      return;
    }

    final index = character.passives.indexWhere((item) => item.id == result.id);

    if (index < 0) {
      return;
    }

    setState(() {
      character.passives[index] = result;

      character.normalizeHealth();
    });

    await save();
  }

  Future<void> deletePassive(CharacterPassive passive) async {
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

    if (confirmed != true) {
      return;
    }

    setState(() {
      character.removePassive(passive.id);

      character.normalizeHealth();
    });

    await save();
  }

  Future<void> togglePassive(CharacterPassive passive, bool value) async {
    setState(() {
      passive.enabled = value;

      character.normalizeHealth();
    });

    await save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pasivas')),
      body: character.passives.isEmpty
          ? _EmptyPassives(onCreate: createPassive)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
              itemCount: character.passives.length,
              itemBuilder: (context, index) {
                final passive = character.passives[index];

                return _PassiveCard(
                  passive: passive,
                  onToggle: (value) {
                    togglePassive(passive, value);
                  },
                  onEdit: () {
                    editPassive(passive);
                  },
                  onDelete: () {
                    deletePassive(passive);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createPassive,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva pasiva'),
      ),
    );
  }
}

class _PassiveCard extends StatelessWidget {
  final CharacterPassive passive;

  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PassiveCard({
    required this.passive,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final effects = <Widget>[];

    if (passive.armorClassBonus != 0) {
      effects.add(
        _EffectChip(
          icon: Icons.shield_rounded,
          label: '${_bonusText(passive.armorClassBonus)} CA',
        ),
      );
    }

    if (passive.initiativeBonus != 0) {
      effects.add(
        _EffectChip(
          icon: Icons.bolt_rounded,
          label: '${_bonusText(passive.initiativeBonus)} iniciativa',
        ),
      );
    }

    if (passive.speedBonus != 0) {
      effects.add(
        _EffectChip(
          icon: Icons.directions_run_rounded,
          label: '${_bonusText(passive.speedBonus)} pies',
        ),
      );
    }

    if (passive.maxHealthBonus != 0) {
      effects.add(
        _EffectChip(
          icon: Icons.favorite_rounded,
          label: '${_bonusText(passive.maxHealthBonus)} PG máx.',
        ),
      );
    }

    if (passive.attackBonus != 0) {
      effects.add(
        _EffectChip(
          icon: Icons.gps_fixed_rounded,
          label: '${_bonusText(passive.attackBonus)} al golpe',
        ),
      );
    }

    for (final entry in passive.skillBonuses.entries) {
      if (entry.value == 0) {
        continue;
      }

      effects.add(
        _EffectChip(
          icon: Icons.bar_chart_rounded,
          label: '${_bonusText(entry.value)} ${entry.key.label}',
        ),
      );
    }

    for (final entry in passive.savingThrowBonuses.entries) {
      if (entry.value == 0) {
        continue;
      }

      effects.add(
        _EffectChip(
          icon: Icons.security_rounded,
          label:
              '${_bonusText(entry.value)} Salv. ${_abilityShortName(entry.key)}',
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
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
                    Icons.auto_awesome_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passive.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(passive.sourceType.label),
                    ],
                  ),
                ),

                Switch(value: passive.enabled, onChanged: onToggle),

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
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ];
                  },
                ),
              ],
            ),

            if (passive.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(passive.description),
            ],

            if (effects.isNotEmpty) ...[
              const SizedBox(height: 14),

              Wrap(spacing: 8, runSpacing: 8, children: effects),
            ],

            if (!passive.enabled) ...[
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Esta pasiva está desactivada y sus bonificaciones no se aplican.',
                ),
              ),
            ],

            if (passive.notes.isNotEmpty) ...[
              const SizedBox(height: 12),

              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 6),
                title: const Text('Notas'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(passive.notes),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _bonusText(int value) {
    return value >= 0 ? '+$value' : '$value';
  }

  static String _abilityShortName(dynamic ability) {
    switch (ability.name) {
      case 'strength':
        return 'FUE';

      case 'dexterity':
        return 'DES';

      case 'constitution':
        return 'CON';

      case 'intelligence':
        return 'INT';

      case 'wisdom':
        return 'SAB';

      case 'charisma':
        return 'CAR';

      default:
        return ability.name;
    }
  }
}

class _EffectChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EffectChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 17), label: Text(label));
  }
}

class _EmptyPassives extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyPassives({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 68,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(height: 18),

            Text(
              'Sin pasivas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Añade rasgos raciales, dotes, efectos de clase, objetos o bonificaciones permanentes.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 22),

            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear pasiva'),
            ),
          ],
        ),
      ),
    );
  }
}
