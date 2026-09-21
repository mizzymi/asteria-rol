import 'package:flutter/material.dart';

import '../models/character.dart';
import '../models/character_effect.dart';

import '../services/character_storage_service.dart';

import '../widgets/common/empty_state.dart';
import '../widgets/effects/effect_card.dart';

import 'effect_form_screen.dart';

class EffectsScreen extends StatefulWidget {
  final Character character;

  const EffectsScreen({super.key, required this.character});

  @override
  State<EffectsScreen> createState() => _EffectsScreenState();
}

class _EffectsScreenState extends State<EffectsScreen> {
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

  Future<void> createEffect() async {
    final effect = await Navigator.push<CharacterEffect>(
      context,
      MaterialPageRoute(builder: (_) => const EffectFormScreen()),
    );

    if (effect == null) {
      return;
    }

    setState(() {
      character.addEffect(effect);
      character.normalizeHealth();
    });

    await save();
  }

  // ===========================================================================
  // EDITAR
  // ===========================================================================

  Future<void> editEffect(CharacterEffect effect) async {
    final result = await Navigator.push<CharacterEffect>(
      context,
      MaterialPageRoute(builder: (_) => EffectFormScreen(effect: effect)),
    );

    if (result == null) {
      return;
    }

    setState(() {
      character.updateEffect(result);
      character.normalizeHealth();
    });

    await save();
  }

  // ===========================================================================
  // ELIMINAR
  // ===========================================================================

  Future<void> deleteEffect(CharacterEffect effect) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar efecto'),
          content: Text('¿Quieres eliminar "${effect.name}"?'),
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
      character.removeEffect(effect.id);

      character.normalizeHealth();
    });

    await save();
  }

  // ===========================================================================
  // ACTIVAR / DESACTIVAR
  // ===========================================================================

  Future<void> toggleEffect(CharacterEffect effect, bool value) async {
    setState(() {
      effect.enabled = value;

      character.normalizeHealth();
    });

    await save();
  }

  // ===========================================================================
  // DURACIÓN
  // ===========================================================================

  Future<void> decreaseDuration(CharacterEffect effect) async {
    setState(() {
      effect.decreaseDuration();

      character.normalizeHealth();
    });

    await save();
  }

  Future<void> increaseDuration(CharacterEffect effect) async {
    setState(() {
      effect.increaseDuration();

      character.normalizeHealth();
    });

    await save();
  }

  Future<void> resetDuration(CharacterEffect effect) async {
    setState(() {
      effect.resetDuration();

      character.normalizeHealth();
    });

    await save();
  }

  // ===========================================================================
  // LIMPIAR EXPIRADOS
  // ===========================================================================

  Future<void> clearExpired() async {
    final expired = character.effects
        .where((effect) => effect.expired)
        .toList();

    if (expired.isEmpty) {
      return;
    }

    setState(() {
      character.effects.removeWhere((effect) => effect.expired);

      character.normalizeHealth();
    });

    await save();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${expired.length} ${expired.length == 1 ? 'efecto expirado eliminado' : 'efectos expirados eliminados'}.',
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final effects = character.effects;

    final hasExpired = effects.any((effect) => effect.expired);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estados y efectos'),
        actions: [
          if (hasExpired)
            IconButton(
              tooltip: 'Eliminar expirados',
              onPressed: clearExpired,
              icon: const Icon(Icons.cleaning_services_rounded),
            ),
        ],
      ),

      // =======================================================================
      // CONTENIDO
      // =======================================================================
      body: effects.isEmpty
          ? EmptyState(
              icon: Icons.auto_awesome_rounded,
              title: 'Sin efectos',
              message:
                  'Añade bendiciones, venenos, mejoras, penalizaciones y otros estados temporales.',
              actionLabel: 'Crear efecto',
              onAction: createEffect,
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
              itemCount: effects.length,
              itemBuilder: (context, index) {
                final effect = effects[index];

                return EffectCard(
                  effect: effect,
                  character: character,

                  onToggle: (value) {
                    toggleEffect(effect, value);
                  },

                  onEdit: () {
                    editEffect(effect);
                  },

                  onDelete: () {
                    deleteEffect(effect);
                  },

                  onDecreaseDuration: effect.hasDuration
                      ? () {
                          decreaseDuration(effect);
                        }
                      : null,

                  onIncreaseDuration: effect.hasDuration
                      ? () {
                          increaseDuration(effect);
                        }
                      : null,

                  onResetDuration: effect.hasDuration
                      ? () {
                          resetDuration(effect);
                        }
                      : null,
                );
              },
            ),

      // =======================================================================
      // NUEVO EFECTO
      // =======================================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createEffect,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo efecto'),
      ),
    );
  }
}
