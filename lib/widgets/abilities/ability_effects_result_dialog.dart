import 'package:flutter/material.dart';

import '../../models/ability.dart';
import '../../models/ability_effect_part.dart';
import '../../models/character.dart';
import '../../models/dice_pool.dart';

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
    rolledEffects = [];

    for (final effect in widget.ability.effects) {
      if (!effect.hasEffect) {
        continue;
      }

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

      final rolledParts = <_RolledPart>[];

      // =======================================================================
      // NUEVO SISTEMA: PARTES DEL EFECTO
      // =======================================================================

      for (final part in effect.parts) {
        if (!part.hasValue) {
          continue;
        }

        final result = widget.character.rollAbilityEffectPart(
          widget.ability,
          effect,
          part,
          critical: canCritical,
        );

        rolledParts.add(_RolledPart(part: part, result: result));
      }

      /*
       * Si por cualquier motivo el efecto no tiene
       * componentes válidos, no lo mostramos.
       */
      if (rolledParts.isEmpty) {
        continue;
      }

      rolledEffects.add(
        _RolledEffect(
          effect: effect,
          parts: rolledParts,
          saved: false,
          critical: canCritical,
        ),
      );
    }
  }

  // ===========================================================================
  // TOTAL BRUTO DE UN EFECTO
  // ===========================================================================

  int _effectRawTotal(_RolledEffect rolled) {
    return rolled.parts.fold<int>(0, (sum, part) => sum + part.result.total);
  }

  // ===========================================================================
  // TOTAL FINAL DE UN EFECTO
  //
  // La salvación afecta al efecto completo.
  // ===========================================================================

  int _effectTotal(_RolledEffect rolled) {
    final baseTotal = _effectRawTotal(rolled);

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
  // TOTAL FINAL DE UNA PARTE
  //
  // Esto nos permite mostrar correctamente cada tipo de daño después
  // de una salvación.
  // ===========================================================================

  int _partTotal(_RolledEffect rolled, _RolledPart part) {
    final baseTotal = part.result.total;

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
  // ICONO DE UNA PARTE
  // ===========================================================================

  IconData _partIcon(AbilityEffect effect) {
    if (effect.heals) {
      return Icons.favorite_rounded;
    }

    if (effect.dealsDamage) {
      return Icons.flash_on_rounded;
    }

    return Icons.auto_awesome_rounded;
  }

  // ===========================================================================
  // FÓRMULA DE UNA PARTE
  // ===========================================================================

  String _partFormula(AbilityEffectPart part) {
    final pieces = <String>[];

    if (part.diceNotation.isNotEmpty) {
      pieces.add(part.diceNotation);
    }

    for (final entry in part.abilityModifierMultipliers.entries) {
      if (entry.value == 0) {
        continue;
      }

      if (entry.value == 1) {
        pieces.add(entry.key.name);
      } else {
        pieces.add('${entry.value}×${entry.key.name}');
      }
    }

    if (part.flatBonus != 0) {
      pieces.add(
        part.flatBonus > 0 ? '+${part.flatBonus}' : '${part.flatBonus}',
      );
    }

    if (pieces.isEmpty) {
      return 'Sin tirada';
    }

    return pieces.join(' + ').replaceAll('+ -', '- ');
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
                        child: _EffectPartsCard(
                          rolled: rolled,

                          saveDc: dc,

                          partTotal: (part) => _partTotal(rolled, part),

                          effectTotal: _effectTotal(rolled),

                          partFormula: _partFormula,

                          partIcon: _partIcon,

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
// TARJETA DE EFECTO CON VARIOS COMPONENTES
// =============================================================================

class _EffectPartsCard extends StatelessWidget {
  final _RolledEffect rolled;

  final int? saveDc;

  final int Function(_RolledPart) partTotal;

  final int effectTotal;

  final String Function(AbilityEffectPart) partFormula;

  final IconData Function(AbilityEffect) partIcon;

  final ValueChanged<bool>? onSavedChanged;

  const _EffectPartsCard({
    required this.rolled,
    required this.saveDc,
    required this.partTotal,
    required this.effectTotal,
    required this.partFormula,
    required this.partIcon,
    required this.onSavedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===================================================================
          // NOMBRE DEL EFECTO
          // ===================================================================
          Row(
            children: [
              Icon(partIcon(rolled.effect), color: theme.colorScheme.primary),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  rolled.effect.name.trim().isNotEmpty
                      ? rolled.effect.name
                      : rolled.effect.effectType.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              if (rolled.critical)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'CRÍTICO',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ===================================================================
          // COMPONENTES
          // ===================================================================
          ...List.generate(rolled.parts.length, (index) {
            final rolledPart = rolled.parts[index];

            final part = rolledPart.part;

            final total = partTotal(rolledPart);

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == rolled.parts.length - 1 ? 0 : 8,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Icon(
                      partIcon(rolled.effect),
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),

                    const SizedBox(width: 9),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            part.typeName.trim().isNotEmpty
                                ? part.typeName
                                : rolled.effect.effectType.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            partFormula(part),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      '$total',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // ===================================================================
          // SALVACIÓN
          // ===================================================================
          if (rolled.effect.usesSavingThrow) ...[
            const SizedBox(height: 12),

            const Divider(),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salvación ${rolled.effect.savingThrowAbility.name}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),

                      if (saveDc != null)
                        Text('CD $saveDc', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),

                const Text('Superada'),

                const SizedBox(width: 6),

                Switch(value: rolled.saved, onChanged: onSavedChanged),
              ],
            ),
          ],

          // ===================================================================
          // TOTAL DEL EFECTO
          // ===================================================================
          if (rolled.parts.length > 1) ...[
            const SizedBox(height: 12),

            const Divider(),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total del efecto',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),

                Text(
                  '$effectTotal',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// MODELOS INTERNOS
// =============================================================================

class _RolledPart {
  final AbilityEffectPart part;

  final DiceCalculationResult result;

  const _RolledPart({required this.part, required this.result});
}

class _RolledEffect {
  final AbilityEffect effect;

  final List<_RolledPart> parts;

  final bool critical;

  bool saved;

  _RolledEffect({
    required this.effect,
    required this.parts,
    required this.critical,
    required this.saved,
  });
}
