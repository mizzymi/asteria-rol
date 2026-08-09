import 'package:flutter/material.dart';

import '../models/ability.dart';
import '../models/character.dart';
import '../models/dice_pool.dart';

import '../services/character_storage_service.dart';

import '../widgets/abilities/ability_card.dart';
import '../widgets/abilities/attack_roll_sheet.dart';
import '../widgets/abilities/ability_effects_result_dialog.dart';

import 'ability_form_screen.dart';

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
  // CREAR
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
  // EDITAR
  // ===========================================================================

  Future<void> editAbility(CharacterAbility ability) async {
    final result = await Navigator.push<CharacterAbility>(
      context,
      MaterialPageRoute(builder: (_) => AbilityFormScreen(ability: ability)),
    );

    if (result == null) {
      return;
    }

    /*
     * Solo editamos habilidades propias.
     *
     * availableAbilities incluye también
     * habilidades de objetos equipados.
     */
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
  // ELIMINAR
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
  // USOS
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
  // RESOLVER TODOS LOS EFECTOS
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
    // POPUP DE ATAQUE
    // -------------------------------------------------------------------------

    showDialog(
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

          /*
           * Si no existen efectos,
           * no mostramos botón.
           */
          onRollDamage: ability.effects.any((effect) => effect.hasEffect)
              ? () {
                  Navigator.pop(dialogContext);

                  /*
                   * Todos los efectos se tiran
                   * juntos en el mismo popup.
                   */
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
    /*
     * Incluye:
     *
     * - habilidades propias
     * - habilidades de objetos equipados
     */
    final abilities = character.availableAbilities;

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

      // =======================================================================
      // LISTA
      // =======================================================================
      body: abilities.isEmpty
          ? _EmptyAbilities(onCreate: createAbility)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),

              itemCount: abilities.length,

              itemBuilder: (context, index) {
                final ability = abilities[index];

                final sourceItem = character.itemForAbility(ability);

                return AbilityCard(
                  ability: ability,

                  character: character,

                  sourceItem: sourceItem,

                  // =========================================================
                  // EDITAR
                  // =========================================================
                  onEdit: sourceItem == null
                      ? () {
                          editAbility(ability);
                        }
                      : null,

                  // =========================================================
                  // ELIMINAR
                  // =========================================================
                  onDelete: sourceItem == null
                      ? () {
                          deleteAbility(ability);
                        }
                      : null,

                  // =========================================================
                  // RESTAURAR
                  // =========================================================
                  onRestore: ability.hasLimitedUses
                      ? () {
                          restoreAbility(ability);
                        }
                      : null,

                  // =========================================================
                  // USAR
                  // =========================================================
                  onUse: () {
                    useAbility(ability);
                  },

                  // =========================================================
                  // ATAQUE
                  // =========================================================
                  onAttack: () {
                    rollAttack(ability);
                  },

                  // =========================================================
                  // EFECTOS
                  // =========================================================

                  /*
                   * Para habilidades sin ataque:
                   *
                   * Bola de fuego
                   * Aliento
                   * Curación
                   * etc.
                   *
                   * Abrimos directamente el popup
                   * de todos los efectos.
                   */
                  onResolveEffects: () {
                    resolveAllEffects(ability);
                  },
                );
              },
            ),

      // =======================================================================
      // CREAR
      // =======================================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createAbility,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva habilidad'),
      ),
    );
  }
}

// =============================================================================
// EMPTY
// =============================================================================

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
