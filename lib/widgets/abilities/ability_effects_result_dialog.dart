import 'package:flutter/material.dart';
import 'package:rol/models/dice_pool.dart';

import '../../models/ability.dart';
import '../../models/character.dart';

import 'effect_result_card.dart';
import 'total_result_card.dart';

class AbilityEffectsResultDialog extends StatefulWidget {
  final CharacterAbility ability;
  final Character character;

  final bool critical;

  final VoidCallback? onRerollAttack;

  /// Se llama antes de repetir los efectos.
  /// Devuelve true si se pueden pagar los costes.
  final Future<bool> Function()? onPayRerollCosts;

  const AbilityEffectsResultDialog({
    super.key,
    required this.ability,
    required this.character,
    this.critical = false,
    this.onRerollAttack,
    this.onPayRerollCosts,
  });

  @override
  State<AbilityEffectsResultDialog> createState() =>
      _AbilityEffectsResultDialogState();
}

class _AbilityEffectsResultDialogState
    extends State<AbilityEffectsResultDialog> {
  late List<_RolledEffect> rolledEffects;

  @override
  void initState() {
    super.initState();

    _rollAllEffects();
  }

  // ===========================================================================
  // TIRAR TODOS LOS EFECTOS
  // ===========================================================================

  void _rollAllEffects() {
    rolledEffects = widget.ability.effects
        .where((effect) => effect.hasEffect)
        .map((effect) {
          /*
             * Solo los daños procedentes de una tirada
             * de ataque pueden ser críticos.
             *
             * Los efectos con salvación nunca son críticos.
             */
          final canCritical =
              widget.critical &&
              widget.ability.requiresAttackRoll &&
              effect.dealsDamage &&
              !effect.usesSavingThrow;

          final result = widget.character.rollAbilityEffectPart(
            widget.ability,
            effect,
            critical: canCritical,
          );

          return _RolledEffect(
            effect: effect,
            result: result,
            saved: false,
            critical: canCritical,
          );
        })
        .toList();
  }

  // ===========================================================================
  // TOTAL DE UN EFECTO
  // ===========================================================================

  int _effectTotal(_RolledEffect rolled) {
    final baseTotal = rolled.result.total;

    if (!rolled.effect.usesSavingThrow) {
      return baseTotal;
    }

    if (!rolled.saved) {
      return baseTotal;
    }

    switch (rolled.effect.saveSuccessEffect) {
      case SaveSuccessEffect.full:
        return baseTotal;

      case SaveSuccessEffect.half:
        return baseTotal ~/ 2;

      case SaveSuccessEffect.none:
        return 0;
    }
  }

  // ===========================================================================
  // TOTALES SEPARADOS
  // ===========================================================================

  int get totalDamage {
    return rolledEffects
        .where((rolled) => rolled.effect.dealsDamage)
        .fold<int>(0, (sum, rolled) => sum + _effectTotal(rolled));
  }

  int get totalHealing {
    return rolledEffects
        .where((rolled) => rolled.effect.heals)
        .fold<int>(0, (sum, rolled) => sum + _effectTotal(rolled));
  }

  bool get hasDamage {
    return rolledEffects.any((rolled) => rolled.effect.dealsDamage);
  }

  bool get hasHealing {
    return rolledEffects.any((rolled) => rolled.effect.heals);
  }

  // ===========================================================================
  // REPETIR TODOS LOS DADOS
  // ===========================================================================

  void rerollAll() {
    setState(() {
      _rollAllEffects();
    });
  }

  // ===========================================================================
  // VOLVER A TIRAR / VOLVER A ATACAR
  // ===========================================================================

  Future<void> _reroll() async {
    // =========================================================================
    // HABILIDAD CON ATAQUE
    // =========================================================================

    if (widget.ability.requiresAttackRoll && widget.onRerollAttack != null) {
      Navigator.pop(context);

      widget.onRerollAttack!();

      return;
    }

    // =========================================================================
    // EFECTO DIRECTO
    //
    // Volver a tirar cuenta como usar de nuevo la habilidad.
    // =========================================================================

    if (widget.onPayRerollCosts != null) {
      final paid = await widget.onPayRerollCosts!();

      if (!paid) {
        return;
      }
    }

    if (!mounted) {
      return;
    }

    rerollAll();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final rerollsAttack =
        widget.ability.requiresAttackRoll && widget.onRerollAttack != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // =================================================================
            // HEADER
            // =================================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.critical
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      widget.critical
                          ? Icons.local_fire_department_rounded
                          : Icons.auto_awesome_rounded,
                      color: widget.critical
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ability.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          widget.critical
                              ? 'Resolución crítica'
                              : 'Resolución de efectos',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // =================================================================
            // CONTENIDO
            // =================================================================
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // =========================================================
                    // EFECTOS
                    // =========================================================
                    ...List.generate(rolledEffects.length, (index) {
                      final rolled = rolledEffects[index];

                      final dc = rolled.effect.usesSavingThrow
                          ? widget.character.abilityEffectSaveDc(
                              widget.ability,
                              rolled.effect,
                            )
                          : null;

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == rolledEffects.length - 1 ? 0 : 12,
                        ),
                        child: EffectResultCard(
                          effect: rolled.effect,
                          result: rolled.result,
                          total: _effectTotal(rolled),
                          saved: rolled.saved,
                          critical: rolled.critical,
                          saveDc: dc,

                          onSavedChanged: rolled.effect.usesSavingThrow
                              ? (saved) {
                                  setState(() {
                                    rolled.saved = saved;
                                  });
                                }
                              : null,
                        ),
                      );
                    }),

                    const SizedBox(height: 22),

                    // =========================================================
                    // RESUMEN
                    // =========================================================
                    Row(
                      children: [
                        Icon(
                          Icons.summarize_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),

                        const SizedBox(width: 7),

                        Text(
                          'Resultado total',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (hasDamage)
                      TotalResultCard(
                        icon: widget.critical
                            ? Icons.local_fire_department_rounded
                            : Icons.flash_on_rounded,
                        label: widget.critical
                            ? 'DAÑO TOTAL CRÍTICO'
                            : 'DAÑO TOTAL',
                        value: totalDamage,
                      ),

                    if (hasDamage && hasHealing) const SizedBox(height: 10),

                    if (hasHealing)
                      TotalResultCard(
                        icon: Icons.favorite_rounded,
                        label: 'CURACIÓN TOTAL',
                        value: totalHealing,
                      ),
                  ],
                ),
              ),
            ),

            // =================================================================
            // ACCIONES
            // =================================================================
            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Cerrar'),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _reroll,

                      icon: Icon(
                        rerollsAttack
                            ? Icons.gps_fixed_rounded
                            : Icons.casino_rounded,
                      ),

                      label: Text(
                        rerollsAttack ? 'Volver a atacar' : 'Volver a tirar',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MODELO INTERNO
// =============================================================================

class _RolledEffect {
  final AbilityEffect effect;

  final DiceCalculationResult result;

  final bool critical;

  bool saved;

  _RolledEffect({
    required this.effect,
    required this.result,
    required this.critical,
    required this.saved,
  });
}
