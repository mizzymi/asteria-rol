import 'package:flutter/material.dart';

import '../models/character.dart';
import '../models/passive.dart';

import '../services/character_storage_service.dart';

import '../widgets/common/empty_state.dart';
import '../widgets/passives/passive_card.dart';

import 'passive_form_screen.dart';

class PassivesScreen extends StatefulWidget {
  final Character character;

  const PassivesScreen({super.key, required this.character});

  @override
  State<PassivesScreen> createState() => _PassivesScreenState();
}

class _PassivesScreenState extends State<PassivesScreen> {
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
  // EDITAR
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
  // ELIMINAR
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

  // ===========================================================================
  // ACTIVAR / DESACTIVAR
  // ===========================================================================

  Future<void> togglePassive(CharacterPassive passive, bool value) async {
    setState(() {
      passive.enabled = value;

      character.normalizeHealth();
    });

    await save();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    /*
     * Pasivas procedentes de objetos equipados.
     */
    final itemPassives = character.items
        .where((item) => item.equipped)
        .expand((item) => item.passives)
        .toList();

    /*
     * Pasivas propias + pasivas de objetos.
     */
    final allPassives = [...character.passives, ...itemPassives];

    return Scaffold(
      appBar: AppBar(title: const Text('Pasivas')),

      // =======================================================================
      // CONTENIDO
      // =======================================================================
      body: allPassives.isEmpty
          ? EmptyState(
              icon: Icons.auto_awesome_rounded,
              title: 'Sin pasivas',
              message:
                  'Añade rasgos raciales, dotes, efectos de clase, objetos o bonificaciones permanentes.',
              actionLabel: 'Crear pasiva',
              onAction: createPassive,
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
              itemCount: allPassives.length,
              itemBuilder: (context, index) {
                final passive = allPassives[index];

                /*
                 * Si está dentro de itemPassives,
                 * significa que procede de un objeto
                 * actualmente equipado.
                 */
                final isItemPassive = itemPassives.contains(passive);

                return PassiveCard(
                  passive: passive,

                  isItemPassive: isItemPassive,

                  // =========================================================
                  // TOGGLE
                  // =========================================================
                  onToggle: isItemPassive
                      ? null
                      : (value) {
                          togglePassive(passive, value);
                        },

                  // =========================================================
                  // EDITAR
                  // =========================================================
                  onEdit: isItemPassive
                      ? null
                      : () {
                          editPassive(passive);
                        },

                  // =========================================================
                  // ELIMINAR
                  // =========================================================
                  onDelete: isItemPassive
                      ? null
                      : () {
                          deletePassive(passive);
                        },
                );
              },
            ),

      // =======================================================================
      // NUEVA PASIVA
      // =======================================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createPassive,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva pasiva'),
      ),
    );
  }
}
