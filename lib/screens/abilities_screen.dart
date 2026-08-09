import 'package:flutter/material.dart';

import '../models/ability.dart';
import '../models/character.dart';
import '../models/dice_pool.dart';
import '../services/character_storage_service.dart';
import 'ability_form_screen.dart';
import '../models/item.dart';

enum AttackRollMode { normal, advantage, disadvantage }

extension AttackRollModeData on AttackRollMode {
  String get label {
    switch (this) {
      case AttackRollMode.normal:
        return 'Normal';

      case AttackRollMode.advantage:
        return 'Ventaja';

      case AttackRollMode.disadvantage:
        return 'Desventaja';
    }
  }

  IconData get icon {
    switch (this) {
      case AttackRollMode.normal:
        return Icons.casino_rounded;

      case AttackRollMode.advantage:
        return Icons.trending_up_rounded;

      case AttackRollMode.disadvantage:
        return Icons.trending_down_rounded;
    }
  }
}

class AbilitiesScreen extends StatefulWidget {
  final Character character;

  const AbilitiesScreen({super.key, required this.character});

  @override
  State<AbilitiesScreen> createState() => _AbilitiesScreenState();
}

class _AbilitiesScreenState extends State<AbilitiesScreen> {
  Character get character => widget.character;

  String bonusText(int value) {
    return value >= 0 ? '+$value' : '$value';
  }

  Future<void> save() async {
    await CharacterStorageService.saveCharacter(character);
  }

  Future<void> createAbility() async {
    final ability = await Navigator.push<CharacterAbility>(
      context,
      MaterialPageRoute(builder: (_) => const AbilityFormScreen()),
    );

    if (ability == null) {
      return;
    }

    setState(() {
      character.addCharacterAbility(ability);
    });

    await save();
  }

  Future<void> editAbility(CharacterAbility ability) async {
    final result = await Navigator.push<CharacterAbility>(
      context,
      MaterialPageRoute(builder: (_) => AbilityFormScreen(ability: ability)),
    );

    if (result == null) {
      return;
    }

    final index = character.availableAbilities.indexWhere(
      (item) => item.id == result.id,
    );

    if (index < 0) {
      return;
    }

    setState(() {
      character.availableAbilities[index] = result;
    });

    await save();
  }

  Future<void> deleteAbility(CharacterAbility ability) async {
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

    if (confirmed != true) {
      return;
    }

    setState(() {
      character.removeCharacterAbility(ability.id);
    });

    await save();
  }

  Future<void> useAbility(CharacterAbility ability) async {
    if (!ability.hasLimitedUses) {
      return;
    }

    if (ability.currentUses <= 0) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No quedan usos disponibles.')),
      );

      return;
    }

    setState(() {
      character.useCharacterAbility(ability);
    });

    await save();
  }

  Future<void> restoreAbility(CharacterAbility ability) async {
    setState(() {
      character.restoreCharacterAbility(ability);
    });

    await save();
  }

  Future<void> restoreAllAbilities() async {
    setState(() {
      character.restoreAllAbilities();
    });

    await save();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Usos restaurados.')));
  }

  Future<void> rollAttack(CharacterAbility ability) async {
    final mode = await showModalBottomSheet<AttackRollMode>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Cómo quieres atacar?',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                ...AttackRollMode.values.map((mode) {
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        mode.icon,
                        color: Theme.of(sheetContext).colorScheme.primary,
                      ),
                      title: Text(
                        mode.label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(switch (mode) {
                        AttackRollMode.normal => 'Tira 1d20',
                        AttackRollMode.advantage => 'Tira 2d20 y usa el mayor',
                        AttackRollMode.disadvantage =>
                          'Tira 2d20 y usa el menor',
                      }),
                      onTap: () {
                        Navigator.of(sheetContext).pop(mode);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (mode == null || !mounted) {
      return;
    }

    _performAttackRoll(ability, mode);
  }

  void _performAttackRoll(CharacterAbility ability, AttackRollMode mode) {
    final bonus = character.characterAbilityAttackBonus(ability);

    final firstResult = DicePoolRoller.roll(
      pools: [DicePool(count: 1, sides: 20)],
    );

    final firstRoll = firstResult.groups.first.rolls.first;

    int? secondRoll;

    int naturalRoll = firstRoll;

    if (mode != AttackRollMode.normal) {
      final secondResult = DicePoolRoller.roll(
        pools: [DicePool(count: 1, sides: 20)],
      );

      secondRoll = secondResult.groups.first.rolls.first;

      switch (mode) {
        case AttackRollMode.normal:
          naturalRoll = firstRoll;
          break;

        case AttackRollMode.advantage:
          naturalRoll = firstRoll > secondRoll ? firstRoll : secondRoll;
          break;

        case AttackRollMode.disadvantage:
          naturalRoll = firstRoll < secondRoll ? firstRoll : secondRoll;
          break;
      }
    }

    final total = naturalRoll + bonus;

    final critical = naturalRoll == 20;

    final criticalFailure = naturalRoll == 1;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(ability.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                mode.icon,
                size: 54,
                color: Theme.of(context).colorScheme.primary,
              ),

              const SizedBox(height: 12),

              Text(
                mode.label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              if (secondRoll != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AttackDieResult(
                      value: firstRoll,
                      selected: firstRoll == naturalRoll,
                    ),

                    const SizedBox(width: 14),

                    _AttackDieResult(
                      value: secondRoll,
                      selected: secondRoll == naturalRoll,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  mode == AttackRollMode.advantage
                      ? 'Usamos el mayor'
                      : 'Usamos el menor',
                ),

                const SizedBox(height: 12),
              ] else ...[
                Text(
                  '$naturalRoll',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Text('d20'),

                const SizedBox(height: 14),
              ],

              Text(
                bonus >= 0
                    ? '$naturalRoll + $bonus'
                    : '$naturalRoll - ${bonus.abs()}',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 6),

              Text(
                'TOTAL $total',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (critical) ...[
                const SizedBox(height: 12),

                const Text(
                  '💥 CRÍTICO',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],

              if (criticalFailure) ...[
                const SizedBox(height: 12),

                const Text(
                  '💀 1 NATURAL',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cerrar'),
            ),

            if (critical && ability.dealsDamage && ability.hasEffect)
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();

                  rollAbilityEffect(ability, critical: true);
                },
                icon: const Icon(Icons.local_fire_department_rounded),
                label: const Text('Daño crítico'),
              ),

            if (!critical && ability.hasEffect)
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();

                  rollAbilityEffect(ability);
                },
                icon: Icon(
                  ability.heals
                      ? Icons.favorite_rounded
                      : Icons.flash_on_rounded,
                ),
                label: Text(ability.heals ? 'Curar' : 'Daño'),
              ),
          ],
        );
      },
    );
  }

  void rollAbilityEffect(CharacterAbility ability, {bool critical = false}) {
    if (!ability.hasEffect) {
      return;
    }

    final result = character.rollAbilityEffect(ability, critical: critical);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(critical ? '💥 Crítico · ${ability.name}' : ability.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...result.groups.map((group) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.pool.notation,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text('${group.rolls.join(' + ')} = ${group.total}'),
                    ],
                  ),
                );
              }),

              if (critical) ...[
                const Divider(),

                Row(
                  children: [
                    const Expanded(child: Text('Máximo de dados')),
                    Text(
                      '+${result.maximumDiceTotal}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],

              if (result.modifier != 0) ...[
                const SizedBox(height: 6),

                Row(
                  children: [
                    const Expanded(child: Text('Modificador')),
                    Text(
                      bonusText(result.modifier),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],

              const Divider(height: 28),

              Text(
                ability.heals
                    ? 'CURACIÓN'
                    : critical
                    ? 'DAÑO CRÍTICO'
                    : 'DAÑO',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 4),

              Text(
                '${result.total}',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),

              if (ability.effectTypeName.isNotEmpty)
                Text(ability.effectTypeName, textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cerrar'),
            ),

            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                rollAbilityEffect(ability, critical: critical);
              },
              icon: const Icon(Icons.casino_rounded),
              label: const Text('Repetir'),
            ),
          ],
        );
      },
    );
  }

  void showSavingThrowInfo(CharacterAbility ability) {
    final dc = character.characterAbilitySaveDc(ability);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(ability.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_rounded, size: 48),

              const SizedBox(height: 14),

              Text(
                'CD $dc',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text('Salvación de ${_abilityLabel(ability.savingThrowAbility)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  String _abilityLabel(dynamic ability) {
    switch (ability.name) {
      case 'strength':
        return 'Fuerza';
      case 'dexterity':
        return 'Destreza';
      case 'constitution':
        return 'Constitución';
      case 'intelligence':
        return 'Inteligencia';
      case 'wisdom':
        return 'Sabiduría';
      case 'charisma':
        return 'Carisma';
      default:
        return ability.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habilidades'),
        actions: [
          if (character.availableAbilities.any(
            (ability) => ability.hasLimitedUses,
          ))
            IconButton(
              tooltip: 'Restaurar usos',
              onPressed: restoreAllAbilities,
              icon: const Icon(Icons.restart_alt_rounded),
            ),
        ],
      ),

      body: character.availableAbilities.isEmpty
          ? _EmptyAbilities(onCreate: createAbility)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
              itemCount: character.availableAbilities.length,
              itemBuilder: (context, index) {
                final ability = character.availableAbilities[index];

                final sourceItem = character.itemForAbility(ability);

                return _AbilityCard(
                  ability: ability,
                  character: character,
                  sourceItem: sourceItem,
                  bonusText: bonusText,

                  onEdit: sourceItem == null
                      ? () {
                          editAbility(ability);
                        }
                      : () {},

                  onDelete: sourceItem == null
                      ? () {
                          deleteAbility(ability);
                        }
                      : () {},

                  onUse: () {
                    useAbility(ability);
                  },

                  onRestore: () {
                    restoreAbility(ability);
                  },

                  onAttack: () {
                    rollAttack(ability);
                  },

                  onEffect: () {
                    rollAbilityEffect(ability);
                  },

                  onCritical: () {
                    rollAbilityEffect(ability, critical: true);
                  },

                  onSavingThrow: () {
                    showSavingThrowInfo(ability);
                  },
                );
              },
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: createAbility,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva habilidad'),
      ),
    );
  }
}

class _AbilityCard extends StatelessWidget {
  final CharacterAbility ability;
  final CharacterItem? sourceItem;
  final Character character;

  final String Function(int) bonusText;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onUse;
  final VoidCallback onRestore;
  final VoidCallback onAttack;
  final VoidCallback onEffect;
  final VoidCallback onCritical;
  final VoidCallback onSavingThrow;

  const _AbilityCard({
    required this.ability,
    required this.character,
    required this.bonusText,
    required this.onEdit,
    required this.onDelete,
    required this.onUse,
    required this.onRestore,
    required this.onAttack,
    required this.onEffect,
    required this.onCritical,
    required this.onSavingThrow,
    required this.sourceItem,
  });

  String get effectIconText {
    if (ability.heals) {
      return 'Curación';
    }

    return ability.effectTypeName.isNotEmpty ? ability.effectTypeName : 'Daño';
  }

  @override
  Widget build(BuildContext context) {
    final attackBonus = character.characterAbilityAttackBonus(ability);

    final effectModifier = character.characterAbilityEffectModifier(ability);

    final saveDc = character.characterAbilitySaveDc(ability);

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
                    ability.heals
                        ? Icons.favorite_rounded
                        : Icons.auto_awesome_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ability.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(ability.actionType.label),

                      if (sourceItem != null) ...[
                        const SizedBox(height: 4),

                        Row(
                          children: [
                            const Icon(Icons.inventory_2_rounded, size: 14),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Objeto · ${sourceItem!.name}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                if (sourceItem == null)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;

                        case 'restore':
                          onRestore();
                          break;

                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar'),
                        ),

                        if (ability.hasLimitedUses)
                          const PopupMenuItem(
                            value: 'restore',
                            child: Text('Restaurar usos'),
                          ),

                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Eliminar'),
                        ),
                      ];
                    },
                  )
                else
                  Tooltip(
                    message: 'Esta habilidad pertenece a ${sourceItem!.name}',
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),

            if (ability.description.isNotEmpty) ...[
              const SizedBox(height: 12),

              Text(ability.description),
            ],

            const SizedBox(height: 14),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (ability.requiresAttackRoll)
                  Chip(
                    avatar: const Icon(Icons.gps_fixed_rounded, size: 17),
                    label: Text('${bonusText(attackBonus)} al golpe'),
                  ),

                if (ability.hasEffect)
                  Chip(
                    avatar: Icon(
                      ability.heals
                          ? Icons.favorite_rounded
                          : Icons.flash_on_rounded,
                      size: 17,
                    ),
                    label: Text(_effectText(ability, effectModifier)),
                  ),

                if (ability.usesSavingThrow)
                  Chip(
                    avatar: const Icon(Icons.shield_rounded, size: 17),
                    label: Text('CD $saveDc'),
                  ),

                if (ability.hasLimitedUses)
                  Chip(
                    avatar: const Icon(Icons.repeat_rounded, size: 17),
                    label: Text('${ability.currentUses}/${ability.maxUses}'),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (ability.requiresAttackRoll)
                  FilledButton.icon(
                    onPressed: onAttack,
                    icon: const Icon(Icons.casino_rounded),
                    label: const Text('Atacar'),
                  ),

                if (!ability.requiresAttackRoll && ability.hasEffect)
                  FilledButton.icon(
                    onPressed: onEffect,
                    icon: Icon(
                      ability.heals
                          ? Icons.favorite_rounded
                          : Icons.casino_rounded,
                    ),
                    label: Text(ability.heals ? 'Curar' : 'Daño'),
                  ),

                if (ability.dealsDamage && ability.hasEffect)
                  OutlinedButton.icon(
                    onPressed: onCritical,
                    icon: const Icon(Icons.local_fire_department_rounded),
                    label: const Text('Crítico'),
                  ),

                if (ability.usesSavingThrow)
                  OutlinedButton.icon(
                    onPressed: onSavingThrow,
                    icon: const Icon(Icons.shield_rounded),
                    label: const Text('Salvación'),
                  ),
              ],
            ),

            if (ability.hasLimitedUses) ...[
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: ability.maxUses > 0
                          ? ability.currentUses / ability.maxUses
                          : 0,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Text(
                    '${ability.currentUses}/${ability.maxUses}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: ability.currentUses > 0 ? onUse : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  label: const Text('Gastar 1 uso'),
                ),
              ),
            ],

            if (ability.notes.isNotEmpty) ...[
              const SizedBox(height: 12),

              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: const Text('Notas'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(ability.notes),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _effectText(CharacterAbility ability, int modifier) {
    String result = ability.diceNotation;

    if (modifier > 0) {
      result += ' + $modifier';
    }

    if (modifier < 0) {
      result += ' - ${modifier.abs()}';
    }

    if (ability.effectTypeName.isNotEmpty) {
      result += ' ${ability.effectTypeName}';
    } else if (ability.heals) {
      result += ' curación';
    }

    return result;
  }
}

class _AttackDieResult extends StatelessWidget {
  final int value;
  final bool selected;

  const _AttackDieResult({required this.value, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: selected
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: selected ? Theme.of(context).colorScheme.primary : null,
            ),
          ),

          if (selected) const Icon(Icons.check_rounded, size: 17),
        ],
      ),
    );
  }
}

class _EmptyAbilities extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyAbilities({required this.onCreate});

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
              'Sin habilidades',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Añade ataques especiales, poderes, técnicas o curaciones.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 22),

            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear habilidad'),
            ),
          ],
        ),
      ),
    );
  }
}
