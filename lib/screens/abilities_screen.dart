import 'package:flutter/material.dart';

import '../models/ability.dart';
import '../models/character.dart';
import '../models/passive.dart';

import '../services/character_effect_application_service.dart';
import '../services/action_resolution_flow.dart';
import '../services/character_storage_service.dart';

import '../widgets/common/empty_state.dart';
import '../widgets/common/section_header.dart';
import '../widgets/passives/passive_roll_dialog.dart';
import '../widgets/combat/combat_action_sheet.dart';
import '../widgets/abilities/ability_card.dart';
import '../widgets/passives/passive_card.dart';
import '../widgets/action_resolution/result/action_resolution_result_dialog.dart';

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
  // STORAGE
  // ===========================================================================

  Future<void> save() {
    return CharacterStorageService.saveCharacter(character);
  }

  // ===========================================================================
  // ACTION RESOLUTION
  // ===========================================================================

  Future<void> _resolveAbility(CharacterAbility ability) async {
    final flow = ActionResolutionFlow(character: character);

    try {
      final execution = await flow.resolveAbility(context, ability: ability);

      if (execution == null) {
        return;
      }

      // -----------------------------------------------------------------------
      // El commit ya ocurrió dentro del flow.
      // Ahora persistimos una sola vez.
      // -----------------------------------------------------------------------

      await save();

      if (!mounted) {
        return;
      }

      setState(() {});

      await showActionResolutionResultDialog(
        context,
        character: character,
        execution: execution,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se ha podido resolver la acción: $error')),
      );
    }
  }

  // ===========================================================================
  // COMBAT ACTIONS
  // ===========================================================================

  Future<void> showAbilityCombatActions(CharacterAbility ability) async {
    final requiresAttack = ability.requiresAttackRoll;

    final hasDamage = ability.dealsDamage;

    final hasHealing = ability.heals;

    final hasEffects = ability.effects.any((effect) => effect.hasEffect);

    final hasLinkedEffects = ability.linkedEffects.isNotEmpty;

    final canUse =
        !requiresAttack &&
        !hasDamage &&
        !hasHealing &&
        (hasEffects || hasLinkedEffects);

    await CombatActionSheet.show(
      context,

      title: ability.name,

      subtitle: 'Habilidad',

      // -----------------------------------------------------------------------
      // ATAQUE
      //
      // Si existe ataque, el daño/curación/etc.
      // se resuelve dentro del ataque.
      // -----------------------------------------------------------------------
      canAttack: requiresAttack,

      // -----------------------------------------------------------------------
      // SIN ATAQUE
      // -----------------------------------------------------------------------
      canDamage: !requiresAttack && hasDamage,

      canHeal: !requiresAttack && hasHealing,

      canUse: canUse,

      // Crítico manual eliminado.
      // El crítico pertenece al resultado
      // del ataque.
      canCritical: false,

      onAttack: () {
        _resolveAbility(ability);
      },

      onDamage: () {
        _resolveAbility(ability);
      },

      onHeal: () {
        _resolveAbility(ability);
      },

      onUse: () {
        _resolveAbility(ability);
      },

      onCritical: null,
    );
  }

  Future<void> rollPassive(CharacterPassive passive) async {
    if (!passive.enabled || !passive.hasRoll) {
      return;
    }

    await showPassiveRollDialog(
      context,
      character: character,
      passive: passive,
    );
  }

  Future<void> applyPassiveLinkedEffects(CharacterPassive passive) async {
    if (!passive.enabled || passive.linkedEffects.isEmpty) {
      return;
    }

    final service = CharacterEffectApplicationService(character: character);

    final applied = service.applyTemplates(passive.linkedEffects);

    if (applied.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {});
    }

    await save();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          applied.length == 1
              ? 'Se ha aplicado ${applied.first.name}.'
              : 'Se han aplicado ${applied.length} efectos.',
        ),
      ),
    );
  }

  // ===========================================================================
  // CREATE ABILITY
  // ===========================================================================

  Future<void> createAbility() async {
    final ability = await Navigator.push<CharacterAbility>(
      context,

      MaterialPageRoute(
        builder: (_) => AbilityFormScreen(character: character),
      ),
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
  // EDIT ABILITY
  // ===========================================================================

  Future<void> editAbility(CharacterAbility ability) async {
    final result = await Navigator.push<CharacterAbility>(
      context,

      MaterialPageRoute(
        builder: (_) =>
            AbilityFormScreen(ability: ability, character: character),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      character.updateCharacterAbility(result);
    });

    await save();
  }

  // ===========================================================================
  // DELETE ABILITY
  // ===========================================================================

  Future<void> deleteAbility(CharacterAbility ability) async {
    final confirmed = await _confirmDelete(
      title: 'Eliminar habilidad',
      message: '¿Quieres eliminar "${ability.name}"?',
    );

    if (!confirmed) {
      return;
    }

    setState(() {
      character.removeCharacterAbility(ability.id);
    });

    await save();
  }

  // ===========================================================================
  // RESTORE ABILITY
  // ===========================================================================

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
  // CREATE PASSIVE
  // ===========================================================================

  Future<void> createPassive() async {
    final passive = await Navigator.push<CharacterPassive>(
      context,
      MaterialPageRoute(
        builder: (_) => PassiveFormScreen(character: character),
      ),
    );

    if (passive == null) {
      return;
    }

    setState(() {
      character.addPassive(passive);
    });

    await save();
  }

  // ===========================================================================
  // EDIT PASSIVE
  // ===========================================================================

  Future<void> editPassive(CharacterPassive passive) async {
    final result = await Navigator.push<CharacterPassive>(
      context,

      MaterialPageRoute(
        builder: (_) =>
            PassiveFormScreen(character: character, passive: passive),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      character.updatePassive(result);
    });

    await save();
  }

  // ===========================================================================
  // DELETE PASSIVE
  // ===========================================================================

  Future<void> deletePassive(CharacterPassive passive) async {
    final confirmed = await _confirmDelete(
      title: 'Eliminar pasiva',
      message: '¿Quieres eliminar "${passive.name}"?',
    );

    if (!confirmed) {
      return;
    }

    setState(() {
      character.removePassive(passive.id);
    });

    await save();
  }

  // ===========================================================================
  // PASSIVE ENABLED
  // ===========================================================================

  Future<void> togglePassive(CharacterPassive passive, bool value) async {
    setState(() {
      character.setPassiveEnabled(passive, value);
    });

    await save();
  }

  // ===========================================================================
  // PASSIVE CHARGES
  // ===========================================================================
  Future<void> restorePassiveCharge(CharacterPassive passive) async {
    character.addPassiveCharges(passive.id, 1);

    if (mounted) {
      setState(() {});
    }

    await save();
  }

  // ===========================================================================
  // CONFIRM
  // ===========================================================================

  Future<bool> _confirmDelete({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),

          content: Text(message),

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

    return result == true;
  }

  // ===========================================================================
  // CREATE MENU
  // ===========================================================================

  Future<void> _showCreateMenu() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
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
                    Navigator.pop(sheetContext, 'ability');
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.auto_awesome_rounded),

                  title: const Text('Nueva pasiva'),

                  subtitle: const Text(
                    'Rasgos, bonificaciones y efectos permanentes',
                  ),

                  onTap: () {
                    Navigator.pop(sheetContext, 'passive');
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

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final abilities = character.availableAbilities;

    final itemPassives = character.items
        .where((item) => item.equipped)
        .expand((item) => item.passives)
        .toList();

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
        ],
      ),

      body: empty
          ? EmptyState(
              icon: Icons.auto_awesome_rounded,

              title: 'Sin habilidades',

              message: 'Añade habilidades activas, ataques, poderes y pasivas.',

              actionLabel: 'Crear habilidad',

              onAction: createAbility,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),

              children: [
                // ===========================================================
                // HABILIDADES
                // ===========================================================
                if (abilities.isNotEmpty) ...[
                  SectionHeader(
                    icon: Icons.flash_on_rounded,

                    title: 'Habilidades',

                    subtitle:
                        '${abilities.length} '
                        '${abilities.length == 1 ? 'habilidad' : 'habilidades'}',
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

                      onCombatActions: () {
                        showAbilityCombatActions(ability);
                      },
                    );
                  }),

                  if (passives.isNotEmpty) const SizedBox(height: 24),
                ],

                // ===========================================================
                // PASIVAS
                // ===========================================================
                if (passives.isNotEmpty) ...[
                  SectionHeader(
                    icon: Icons.auto_awesome_rounded,

                    title: 'Pasivas',

                    subtitle:
                        '${passives.length} '
                        '${passives.length == 1 ? 'pasiva' : 'pasivas'}',
                  ),

                  const SizedBox(height: 12),

                  ...passives.map((passive) {
                    final sourceItem = character.itemForPassive(passive);

                    final fromItem = sourceItem != null;

                    return PassiveCard(
                      passive: passive,
                      sourceItem: sourceItem,
                      showPassiveBadge: true,

                      onRoll: passive.hasRoll
                          ? () {
                              rollPassive(passive);
                            }
                          : null,

                      onApplyLinkedEffects:
                          passive.linkedEffects.isNotEmpty &&
                              !passive.hasAutomaticLinkedEffectTriggers
                          ? () {
                              applyPassiveLinkedEffects(passive);
                            }
                          : null,

                      onRestoreCharges: passive.usesCharges
                          ? () {
                              restorePassiveCharge(passive);
                            }
                          : null,

                      onToggle: fromItem
                          ? null
                          : (value) {
                              togglePassive(passive, value);
                            },

                      onEdit: fromItem
                          ? null
                          : () {
                              editPassive(passive);
                            },

                      onDelete: fromItem
                          ? null
                          : () {
                              deletePassive(passive);
                            },
                    );
                  }),
                ],
              ],
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateMenu,

        icon: const Icon(Icons.add_rounded),

        label: const Text('Añadir'),
      ),
    );
  }
}
