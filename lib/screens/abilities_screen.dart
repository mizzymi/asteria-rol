import 'package:flutter/material.dart';

import '../models/ability.dart';
import '../models/character.dart';
import '../models/dice_pool.dart';
import '../models/passive.dart';

import '../services/character_storage_service.dart';

import '../widgets/common/empty_state.dart';
import '../widgets/common/section_header.dart';

import '../widgets/abilities/ability_card.dart';
import '../widgets/abilities/attack_roll_sheet.dart';
import '../widgets/abilities/ability_effects_result_dialog.dart';

import '../widgets/passives/passive_card.dart';

import 'ability_form_screen.dart';
import 'passive_form_screen.dart';

class AbilitiesScreen extends StatefulWidget {
  final Character character;

  const AbilitiesScreen({super.key, required this.character});

  @override
  State<AbilitiesScreen> createState() => _AbilitiesScreenState();
}

class _AbilitiesScreenState extends State<AbilitiesScreen> {
  Character get character => widget.character;

  // ===========================================================================
  // GUARDAR
  // ===========================================================================

  Future<void> save() async {
    await CharacterStorageService.saveCharacter(character);
  }

  // ===========================================================================
  // CREAR HABILIDAD
  // ===========================================================================

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

  // ===========================================================================
  // EDITAR HABILIDAD
  // ===========================================================================

  Future<void> editAbility(CharacterAbility ability) async {
    final result = await Navigator.push<CharacterAbility>(
      context,
      MaterialPageRoute(builder: (_) => AbilityFormScreen(ability: ability)),
    );

    if (result == null) {
      return;
    }

    final index = character.characterAbilities.indexWhere(
      (item) => item.id == result.id,
    );

    if (index < 0) {
      return;
    }

    setState(() {
      character.characterAbilities[index] = result;
    });

    await save();
  }

  // ===========================================================================
  // ELIMINAR HABILIDAD
  // ===========================================================================

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
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
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

  // ===========================================================================
  // CREAR PASIVA
  // ===========================================================================

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

  // ===========================================================================
  // EDITAR PASIVA
  // ===========================================================================

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

  // ===========================================================================
  // ELIMINAR PASIVA
  // ===========================================================================

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
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
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

  // ===========================================================================
  // ACTIVAR / DESACTIVAR PASIVA
  // ===========================================================================

  Future<void> togglePassive(CharacterPassive passive, bool value) async {
    setState(() {
      passive.enabled = value;

      character.normalizeHealth();
    });

    await save();
  }

  // ===========================================================================
  // USOS DE HABILIDADES
  // ===========================================================================

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

  // ===========================================================================
  // RESOLVER EFECTOS
  // ===========================================================================

  Future<void> resolveAllEffects(
    CharacterAbility ability, {
    bool critical = false,
  }) async {
    final effects = ability.effects
        .where((effect) => effect.hasEffect)
        .toList();

    if (effects.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) {
        return AbilityEffectsResultDialog(
          ability: ability,
          character: character,
          critical: critical,
          onRerollAttack: ability.requiresAttackRoll
              ? () {
                  rollAttack(ability);
                }
              : null,
        );
      },
    );
  }

  // ===========================================================================
  // ATAQUE
  // ===========================================================================

  Future<void> rollAttack(CharacterAbility ability) async {
    final mode = await showAttackRollModeSheet(context);

    if (mode == null || !mounted) {
      return;
    }

    _performAttackRoll(ability, mode);
  }

  void _performAttackRoll(CharacterAbility ability, AttackRollMode mode) {
    final bonus = character.characterAbilityAttackBonus(ability);

    // -------------------------------------------------------------------------
    // PRIMER D20
    // -------------------------------------------------------------------------

    final firstResult = DicePoolRoller.roll(
      pools: [DicePool(count: 1, sides: 20)],
    );

    final firstRoll = firstResult.groups.first.rolls.first;

    // -------------------------------------------------------------------------
    // SEGUNDO D20
    // -------------------------------------------------------------------------

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

    // -------------------------------------------------------------------------
    // RESULTADO
    // -------------------------------------------------------------------------

    final total = naturalRoll + bonus;

    final critical = naturalRoll == 20;

    final criticalFailure = naturalRoll == 1;

    // -------------------------------------------------------------------------
    // POPUP
    // -------------------------------------------------------------------------

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AttackResultDialog(
          abilityName: ability.name,
          mode: mode,
          firstRoll: firstRoll,
          secondRoll: secondRoll,
          naturalRoll: naturalRoll,
          bonus: bonus,
          total: total,
          critical: critical,
          criticalFailure: criticalFailure,
          onRollDamage: ability.effects.any((effect) => effect.hasEffect)
              ? () {
                  Navigator.pop(dialogContext);

                  resolveAllEffects(ability, critical: critical);
                }
              : null,
        );
      },
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------------------------
    // HABILIDADES
    // -------------------------------------------------------------------------

    final abilities = character.availableAbilities;

    // -------------------------------------------------------------------------
    // PASIVAS DE OBJETOS EQUIPADOS
    // -------------------------------------------------------------------------

    final itemPassives = character.items
        .where((item) => item.equipped)
        .expand((item) => item.passives)
        .toList();

    // -------------------------------------------------------------------------
    // TODAS LAS PASIVAS
    // -------------------------------------------------------------------------

    final passives = [...character.passives, ...itemPassives];

    final empty = abilities.isEmpty && passives.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habilidades'),
        actions: [
          if (abilities.any((ability) => ability.hasLimitedUses))
            IconButton(
              tooltip: 'Restaurar usos',
              onPressed: restoreAllAbilities,
              icon: const Icon(Icons.restart_alt_rounded),
            ),

          PopupMenuButton<String>(
            tooltip: 'Crear',
            icon: const Icon(Icons.add_rounded),
            onSelected: (value) {
              switch (value) {
                case 'ability':
                  createAbility();
                  break;

                case 'passive':
                  createPassive();
                  break;
              }
            },
            itemBuilder: (_) {
              return const [
                PopupMenuItem(
                  value: 'ability',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.flash_on_rounded),
                    title: Text('Nueva habilidad'),
                  ),
                ),

                PopupMenuItem(
                  value: 'passive',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.auto_awesome_rounded),
                    title: Text('Nueva pasiva'),
                  ),
                ),
              ];
            },
          ),
        ],
      ),

      // =======================================================================
      // CONTENIDO
      // =======================================================================
      body: empty
          ? EmptyState(
              icon: Icons.auto_awesome_rounded,
              title: 'Sin habilidades',
              message:
                  'Añade habilidades activas, ataques, poderes, rasgos y efectos pasivos.',
              actionLabel: 'Crear habilidad',
              onAction: createAbility,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
              children: [
                // =============================================================
                // HABILIDADES ACTIVAS
                // =============================================================
                if (abilities.isNotEmpty) ...[
                  SectionHeader(
                    icon: Icons.flash_on_rounded,
                    title: 'Habilidades',
                    subtitle:
                        '${abilities.length} ${abilities.length == 1 ? 'habilidad' : 'habilidades'}',
                  ),

                  const SizedBox(height: 12),

                  ...abilities.map((ability) {
                    final sourceItem = character.itemForAbility(ability);

                    return AbilityCard(
                      ability: ability,

                      character: character,

                      sourceItem: sourceItem,

                      onEdit: sourceItem == null
                          ? () {
                              editAbility(ability);
                            }
                          : null,

                      onDelete: sourceItem == null
                          ? () {
                              deleteAbility(ability);
                            }
                          : null,

                      onRestore: ability.hasLimitedUses
                          ? () {
                              restoreAbility(ability);
                            }
                          : null,

                      onUse: () {
                        useAbility(ability);
                      },

                      onAttack: () {
                        rollAttack(ability);
                      },

                      onResolveEffects: () {
                        resolveAllEffects(ability);
                      },
                    );
                  }),

                  if (passives.isNotEmpty) const SizedBox(height: 24),
                ],

                // =============================================================
                // PASIVAS
                // =============================================================
                if (passives.isNotEmpty) ...[
                  SectionHeader(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Pasivas',
                    subtitle:
                        '${passives.length} ${passives.length == 1 ? 'pasiva' : 'pasivas'}',
                  ),

                  const SizedBox(height: 12),

                  ...passives.map((passive) {
                    final isItemPassive = itemPassives.contains(passive);

                    return PassiveCard(
                      passive: passive,

                      isItemPassive: isItemPassive,

                      /*
                         * NUEVO:
                         * queremos mostrar el badge
                         * "PASIVA" en esta pantalla.
                         */
                      showPassiveBadge: true,

                      onToggle: isItemPassive
                          ? null
                          : (value) {
                              togglePassive(passive, value);
                            },

                      onEdit: isItemPassive
                          ? null
                          : () {
                              editPassive(passive);
                            },

                      onDelete: isItemPassive
                          ? null
                          : () {
                              deletePassive(passive);
                            },
                    );
                  }),
                ],
              ],
            ),

      // =======================================================================
      // CREAR
      // =======================================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateMenu();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Añadir'),
      ),
    );
  }

  // ===========================================================================
  // MENÚ CREAR
  // ===========================================================================

  Future<void> _showCreateMenu() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.flash_on_rounded),
                  title: const Text('Nueva habilidad'),
                  subtitle: const Text(
                    'Ataques, poderes, curaciones y técnicas',
                  ),
                  onTap: () {
                    Navigator.pop(context, 'ability');
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.auto_awesome_rounded),
                  title: const Text('Nueva pasiva'),
                  subtitle: const Text(
                    'Rasgos, bonificaciones y efectos permanentes',
                  ),
                  onTap: () {
                    Navigator.pop(context, 'passive');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    switch (result) {
      case 'ability':
        await createAbility();
        break;

      case 'passive':
        await createPassive();
        break;
    }
  }
}
