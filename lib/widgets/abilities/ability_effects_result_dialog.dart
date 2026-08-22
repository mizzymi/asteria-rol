import 'package:flutter/material.dart';

import '../../models/critical_damage_bonus_result.dart';
import '../../models/damage_bonus_result.dart';
import '../../models/healing_bonus_result.dart';
import '../../models/ability.dart';
import '../../models/ability_effect_part.dart';
import '../../models/character.dart';
import '../../models/dice_pool.dart';
import '../../models/skill.dart';

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

  late List<DamageBonusResult> rolledDamageBonuses;

  late List<HealingBonusResult> rolledHealingBonuses;

  late List<CriticalDamageBonusResult> rolledCriticalDamageBonuses;

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

    rolledDamageBonuses = [];

    rolledHealingBonuses = [];

    rolledCriticalDamageBonuses = [];

    for (final effect in widget.ability.effects) {
      if (!effect.hasEffect) {
        continue;
      }

      /*
       * Solo el daño procedente de una tirada
       * de ataque puede ser crítico.
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
      // COMPONENTES DEL EFECTO
      // =======================================================================

      for (final part in effect.parts) {
        if (!part.hasValue) {
          continue;
        }

        final result = widget.character.rollAbilityEffectPart(
          part,
          critical: canCritical,
        );

        rolledParts.add(_RolledPart(part: part, result: result));
      }

      // =======================================================================
      // DAÑO / CURACIÓN EXTRA DEL EFECTO
      //
      // Este es el bonus que se configura directamente sobre AbilityEffect:
      //
      // dicePools
      // abilityModifierMultipliers
      // effectBonus
      //
      // Ej:
      //
      // Componente:
      // 2d6 + FUE fuego
      //
      // Extra:
      // 1d4 + SAB + 3 radiante
      // =======================================================================

      final extraMultipliers = Map<AbilityType, int>.from(
        effect.abilityModifierMultipliers,
      );

      /*
       * Compatibilidad antigua.
       *
       * Si una habilidad antigua tenía simplemente:
       *
       * addAbilityModifierToEffect = true
       *
       * convertimos temporalmente eso en:
       *
       * atributo principal ×1
       */
      if (extraMultipliers.isEmpty && effect.legacyAddAbilityModifier) {
        extraMultipliers[widget.ability.abilityType] = 1;
      }

      final hasExtra =
          effect.dicePools.isNotEmpty ||
          extraMultipliers.values.any((value) => value != 0) ||
          effect.effectBonus != 0;

      DiceCalculationResult? extraResult;

      if (hasExtra) {
        extraResult = widget.character.rollAbilityEffectExtra(
          widget.ability,
          effect,
          critical: canCritical,
        );
      }

      /*
       * Un efecto puede existir únicamente gracias
       * al extra.
       *
       * Antes se descartaba si parts estaba vacío.
       */
      if (rolledParts.isEmpty && extraResult == null) {
        continue;
      }

      rolledEffects.add(
        _RolledEffect(
          effect: effect,
          parts: rolledParts,
          extraResult: extraResult,
          extraMultipliers: extraMultipliers,
          saved: false,
          critical: canCritical,
        ),
      );
    }

    // =========================================================================
    // BONIFICACIONES ACTIVAS DEL PERSONAJE
    //
    // Pasivas, estados, etc.
    //
    // Se añaden UNA sola vez por uso de habilidad.
    // =========================================================================

    final hasDamageEffect = rolledEffects.any(
      (rolled) => rolled.effect.dealsDamage,
    );

    final hasHealingEffect = rolledEffects.any((rolled) => rolled.effect.heals);

    /*
     * Los bonus activos solo deben recibir crítico
     * si realmente existe un efecto de daño que haya
     * sido crítico.
     *
     * Esto evita criticar bonus en un efecto que use
     * salvación solo porque la habilidad tenga
     * requiresAttackRoll = true.
     */
    final hasCriticalDamageEffect = rolledEffects.any(
      (rolled) => rolled.effect.dealsDamage && rolled.critical,
    );

    if (hasDamageEffect) {
      rolledDamageBonuses.addAll(
        widget.character.rollActiveDamageBonuses(
          critical: hasCriticalDamageEffect,
        ),
      );
    }

    if (hasCriticalDamageEffect) {
      rolledCriticalDamageBonuses.addAll(
        widget.character.rollActiveCriticalDamageBonuses(),
      );
    }

    if (hasHealingEffect) {
      rolledHealingBonuses.addAll(widget.character.rollActiveHealingBonuses());
    }
  }

  // ===========================================================================
  // TOTAL BRUTO DEL EXTRA
  // ===========================================================================

  int _extraRawTotal(_RolledEffect rolled) {
    return rolled.extraResult?.total ?? 0;
  }

  // ===========================================================================
  // TOTAL BRUTO DE UN EFECTO
  // ===========================================================================

  int _effectRawTotal(_RolledEffect rolled) {
    final partsTotal = rolled.parts.fold<int>(
      0,
      (sum, part) => sum + part.result.total,
    );

    return partsTotal + _extraRawTotal(rolled);
  }

  // ===========================================================================
  // APLICAR SALVACIÓN
  // ===========================================================================

  int _applySave(_RolledEffect rolled, int baseTotal) {
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
  // TOTAL FINAL DEL EFECTO
  //
  // IMPORTANTE:
  //
  // La salvación se aplica AL TOTAL DEL EFECTO:
  //
  // partes + extra
  // ===========================================================================

  int _effectTotal(_RolledEffect rolled) {
    return _applySave(rolled, _effectRawTotal(rolled));
  }

  // ===========================================================================
  // TOTAL VISUAL DE UNA PARTE
  // ===========================================================================

  int _partTotal(_RolledEffect rolled, _RolledPart part) {
    return part.result.total;
  }

  // ===========================================================================
  // TOTAL VISUAL DEL EXTRA
  // ===========================================================================

  int _extraTotal(_RolledEffect rolled) {
    return rolled.extraResult?.total ?? 0;
  }

  // ===========================================================================
  // TOTALES GENERALES
  // ===========================================================================

  int get totalDamage {
    final effectsTotal = rolledEffects
        .where((rolled) => rolled.effect.dealsDamage)
        .fold<int>(0, (sum, rolled) => sum + _effectTotal(rolled));

    final bonusesTotal = rolledDamageBonuses.fold<int>(
      0,
      (sum, result) => sum + result.total,
    );

    final criticalBonusesTotal = rolledCriticalDamageBonuses.fold<int>(
      0,
      (sum, result) => sum + result.total,
    );

    return effectsTotal + bonusesTotal + criticalBonusesTotal;
  }

  int get totalHealing {
    final effectsTotal = rolledEffects
        .where((rolled) => rolled.effect.heals)
        .fold<int>(0, (sum, rolled) => sum + _effectTotal(rolled));

    final bonusesTotal = rolledHealingBonuses.fold<int>(
      0,
      (sum, result) => sum + result.total,
    );

    return effectsTotal + bonusesTotal;
  }

  bool get hasDamage {
    return rolledEffects.any((rolled) => rolled.effect.dealsDamage) ||
        rolledDamageBonuses.isNotEmpty ||
        rolledCriticalDamageBonuses.any((result) => result.triggered);
  }

  bool get hasHealing {
    return rolledEffects.any((rolled) => rolled.effect.heals) ||
        rolledHealingBonuses.isNotEmpty;
  }

  bool get hasCriticalDamage {
    return rolledEffects.any(
      (rolled) => rolled.effect.dealsDamage && rolled.critical,
    );
  }

  // ===========================================================================
  // REPETIR
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
    // Habilidad con ataque.
    if (widget.ability.requiresAttackRoll && widget.onRerollAttack != null) {
      Navigator.pop(context);

      widget.onRerollAttack!();

      return;
    }

    /*
     * Un reroll directo cuenta como volver
     * a utilizar la habilidad.
     */
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
  // ICONO
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
  // NOMBRE CORTO DE ATRIBUTO
  // ===========================================================================

  String _abilityLabel(AbilityType ability) {
    return ability.shortLabel;
  }

  // ===========================================================================
  // NOMBRE DE RECURSO
  // ===========================================================================

  String _resourceName(String resourceId) {
    for (final resource in widget.character.resources) {
      if (resource.id == resourceId) {
        return resource.name;
      }
    }

    return resourceId;
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
        pieces.add(_abilityLabel(entry.key));
      } else {
        pieces.add('${entry.value}×${_abilityLabel(entry.key)}');
      }
    }

    // Recursos.
    for (final entry in part.resourceValueMultipliers.entries) {
      if (entry.value == 0) {
        continue;
      }

      final name = _resourceName(entry.key);

      if (entry.value == 1) {
        pieces.add(name);
      } else {
        pieces.add('${entry.value}×$name');
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
  // FÓRMULA DEL EXTRA
  // ===========================================================================

  String _extraFormula(_RolledEffect rolled) {
    final pieces = <String>[];

    final effect = rolled.effect;

    if (effect.dicePools.isNotEmpty) {
      pieces.add(effect.dicePools.map((pool) => pool.notation).join(' + '));
    }

    for (final entry in rolled.extraMultipliers.entries) {
      if (entry.value == 0) {
        continue;
      }

      if (entry.value == 1) {
        pieces.add(_abilityLabel(entry.key));
      } else {
        pieces.add('${entry.value}×${_abilityLabel(entry.key)}');
      }
    }

    if (effect.effectBonus != 0) {
      pieces.add(
        effect.effectBonus > 0
            ? '+${effect.effectBonus}'
            : '${effect.effectBonus}',
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

    final isCriticalResult = hasCriticalDamage;

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
                      color: isCriticalResult
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      isCriticalResult
                          ? Icons.local_fire_department_rounded
                          : Icons.auto_awesome_rounded,
                      color: isCriticalResult
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
                          isCriticalResult
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

                          extraTotal: _extraTotal(rolled),

                          effectTotal: _effectTotal(rolled),

                          partFormula: _partFormula,

                          extraFormula: () => _extraFormula(rolled),

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

                    // =========================================================
                    // BONIFICADORES ACTIVOS DE DAÑO
                    // =========================================================
                    if (rolledDamageBonuses.isNotEmpty) ...[
                      const SizedBox(height: 16),

                      _BonusSection(
                        title: 'Bonus de daño activos',
                        icon: Icons.add_circle_rounded,
                        children: rolledDamageBonuses
                            .map(
                              (result) => _BonusResultRow(
                                name: result.bonus.name,
                                typeName: result.bonus.damageType,
                                result: result.roll,
                              ),
                            )
                            .toList(),
                      ),
                    ],

                    if (rolledCriticalDamageBonuses.isNotEmpty) ...[
                      const SizedBox(height: 16),

                      _CriticalBonusSection(
                        results: rolledCriticalDamageBonuses,
                      ),
                    ],

                    // =========================================================
                    // BONIFICADORES ACTIVOS DE CURACIÓN
                    // =========================================================
                    if (rolledHealingBonuses.isNotEmpty) ...[
                      const SizedBox(height: 16),

                      _BonusSection(
                        title: 'Bonus de curación activos',
                        icon: Icons.favorite_rounded,
                        children: rolledHealingBonuses
                            .map(
                              (result) => _BonusResultRow(
                                name: result.bonus.name,
                                result: result.roll,
                              ),
                            )
                            .toList(),
                      ),
                    ],

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
                        icon: isCriticalResult
                            ? Icons.local_fire_department_rounded
                            : Icons.flash_on_rounded,
                        label: isCriticalResult
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
// TARJETA DEL EFECTO
// =============================================================================

class _EffectPartsCard extends StatelessWidget {
  final _RolledEffect rolled;

  final int? saveDc;

  final int Function(_RolledPart) partTotal;

  final int extraTotal;

  final int effectTotal;

  final String Function(AbilityEffectPart) partFormula;

  final String Function() extraFormula;

  final IconData Function(AbilityEffect) partIcon;

  final ValueChanged<bool>? onSavedChanged;

  const _EffectPartsCard({
    required this.rolled,
    required this.saveDc,
    required this.partTotal,
    required this.extraTotal,
    required this.effectTotal,
    required this.partFormula,
    required this.extraFormula,
    required this.partIcon,
    required this.onSavedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final componentCount =
        rolled.parts.length + (rolled.extraResult != null ? 1 : 0);

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
          // NOMBRE
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
              padding: const EdgeInsets.only(bottom: 8),
              child: _EffectValueRow(
                icon: partIcon(rolled.effect),

                title: part.typeName.trim().isNotEmpty
                    ? part.typeName
                    : rolled.effect.effectType.label,

                formula: partFormula(part),

                total: total,
              ),
            );
          }),

          // ===================================================================
          // EXTRA DEL EFECTO
          // ===================================================================
          if (rolled.extraResult != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _EffectValueRow(
                icon: Icons.add_circle_outline_rounded,

                title: rolled.effect.effectTypeName.trim().isNotEmpty
                    ? '${rolled.effect.effectTypeName} extra'
                    : rolled.effect.heals
                    ? 'Curación extra'
                    : 'Daño extra',

                formula: extraFormula(),

                total: extraTotal,

                highlight: true,
              ),
            ),

          // ===================================================================
          // SALVACIÓN
          // ===================================================================
          if (rolled.effect.usesSavingThrow) ...[
            const SizedBox(height: 4),

            const Divider(),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salvación ${rolled.effect.savingThrowAbility.shortLabel}',
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
          if (componentCount > 1 || rolled.effect.usesSavingThrow) ...[
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
// FILA DE COMPONENTE / EXTRA
// =============================================================================

class _EffectValueRow extends StatelessWidget {
  final IconData icon;

  final String title;

  final String formula;

  final int total;

  final bool highlight;

  const _EffectValueRow({
    required this.icon,
    required this.title,
    required this.formula,
    required this.total,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: highlight
            ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.35)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: highlight
                ? theme.colorScheme.tertiary
                : theme.colorScheme.primary,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  formula,
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
    );
  }
}

// =============================================================================
// SECCIÓN DE BONUS ACTIVOS
// =============================================================================

class _BonusSection extends StatelessWidget {
  final String title;

  final IconData icon;

  final List<Widget> children;

  const _BonusSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: theme.colorScheme.primary),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ...children,
        ],
      ),
    );
  }
}

// =============================================================================
// RESULTADO DE BONUS ACTIVO
// =============================================================================

class _BonusResultRow extends StatelessWidget {
  final String name;

  final String typeName;

  final DiceCalculationResult result;

  const _BonusResultRow({
    required this.name,
    this.typeName = '',
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = name.trim().isNotEmpty ? name.trim() : 'Bonificación';

    final subtitlePieces = <String>[];

    if (result.groups.isNotEmpty) {
      subtitlePieces.add(
        result.groups.map((group) => group.pool.notation).join(' + '),
      );
    }

    if (result.modifier != 0) {
      subtitlePieces.add(
        result.modifier > 0 ? '+${result.modifier}' : '${result.modifier}',
      );
    }

    if (typeName.trim().isNotEmpty) {
      subtitlePieces.add(typeName.trim());
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),

                if (subtitlePieces.isNotEmpty)
                  Text(
                    subtitlePieces.join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            '+${result.total}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
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

  /// Daño/curación extra configurado directamente
  /// en AbilityEffect.
  final DiceCalculationResult? extraResult;

  /// Multiplicadores utilizados para el extra.
  ///
  /// Se guarda aquí para poder representar también
  /// datos legacy.
  final Map<AbilityType, int> extraMultipliers;

  final bool critical;

  bool saved;

  _RolledEffect({
    required this.effect,
    required this.parts,
    required this.extraResult,
    required this.extraMultipliers,
    required this.critical,
    required this.saved,
  });
}

class _CriticalBonusSection extends StatelessWidget {
  final List<CriticalDamageBonusResult> results;

  const _CriticalBonusSection({required this.results});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: theme.colorScheme.error,
              ),

              const SizedBox(width: 8),

              const Expanded(
                child: Text(
                  'Bonus al hacer crítico',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ...results.map((result) {
            final bonus = result.bonus;

            final title = bonus.name.trim().isNotEmpty
                ? bonus.name.trim()
                : 'Daño crítico extra';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),

                          const SizedBox(height: 2),

                          if (bonus.damageType.trim().isNotEmpty)
                            Text(
                              bonus.damageType.trim(),
                              style: theme.textTheme.bodySmall,
                            ),

                          if (!bonus.alwaysTriggers)
                            Text(
                              'Activación: '
                              '${result.chanceRoll} / '
                              '${bonus.chancePercent}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    if (result.triggered)
                      Text(
                        '+${result.total}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    else
                      Text(
                        'No activa',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
