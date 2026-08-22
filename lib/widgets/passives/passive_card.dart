import 'package:flutter/material.dart';

import '../../models/damage_bonus.dart';
import '../../models/critical_damage_bonus.dart';
import '../../models/healing_bonus.dart';
import '../../models/item.dart';
import '../../models/passive.dart';
import '../../models/skill.dart';

import '../common/app_card.dart';
import '../common/info_badge.dart';

import 'passive_colors.dart';
import 'passive_effect_badge.dart';
import 'passive_disabled_banner.dart';

class PassiveCard extends StatefulWidget {
  final CharacterPassive passive;

  /// True cuando esta pasiva procede de
  /// un objeto equipado.
  final CharacterItem? sourceItem;

  bool get isItemPassive => sourceItem != null;

  /// Permite mostrar el badge PASIVA.
  ///
  /// En la pantalla Habilidades lo usamos
  /// para distinguir habilidades activas
  /// de pasivas.
  final bool showPassiveBadge;

  final ValueChanged<bool>? onToggle;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onUseCharge;
  final VoidCallback? onRestoreCharges;

  const PassiveCard({
    super.key,
    required this.passive,
    this.sourceItem,
    this.showPassiveBadge = false,
    this.onToggle,
    this.onEdit,
    this.onDelete,
    this.onUseCharge,
    this.onRestoreCharges,
  });

  @override
  State<PassiveCard> createState() => _PassiveCardState();
}

class _PassiveCardState extends State<PassiveCard> {
  bool expanded = false;

  CharacterPassive get passive => widget.passive;

  @override
  Widget build(BuildContext context) {
    final color = PassiveColors.sourceColor(passive);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      accentColor: color,
      showAccentBar: true,
      child: Column(
        children: [
          // ===================================================================
          // HEADER
          //
          // CERRADO:
          // - nombre
          // - descripción
          // - PASIVA
          // ===================================================================
          _PassiveHeader(
            passive: passive,
            color: color,
            sourceItem: widget.sourceItem,
            expanded: expanded,
            showPassiveBadge: widget.showPassiveBadge,
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
          ),

          // ===================================================================
          // CONTENIDO DESPLEGADO
          // ===================================================================
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _PassiveExpandedContent(
              passive: passive,
              color: color,
              isItemPassive: widget.isItemPassive,
              onToggle: widget.onToggle,
              onEdit: widget.onEdit,
              onDelete: widget.onDelete,

              onUseCharge: widget.onUseCharge,
              onRestoreCharges: widget.onRestoreCharges,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HEADER
// =============================================================================

class _PassiveHeader extends StatelessWidget {
  final CharacterPassive passive;

  final Color color;

  final bool expanded;

  final CharacterItem? sourceItem;

  final bool showPassiveBadge;

  final VoidCallback onTap;

  const _PassiveHeader({
    required this.passive,
    required this.color,
    required this.sourceItem,
    required this.expanded,
    required this.showPassiveBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================================================================
            // ICONO
            // =================================================================
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: PassiveColors.softBackground(
                  context,
                  color,
                  strength: 0.22,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.auto_awesome_rounded, color: color),
            ),

            const SizedBox(width: 12),

            // =================================================================
            // NOMBRE + DESCRIPCIÓN + PASIVA
            // =================================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===========================================================
                  // NOMBRE + BADGE
                  // ===========================================================
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Text(
                        passive.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      if (showPassiveBadge) _PassiveBadge(color: color),
                    ],
                  ),

                  // ===========================================================
                  // DESCRIPCIÓN
                  // ===========================================================
                  if (passive.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),

                    Text(
                      passive.description,
                      maxLines: expanded ? null : 2,
                      overflow: expanded ? null : TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (sourceItem != null) ...[
                    const SizedBox(height: 8),

                    InfoBadge(
                      icon: Icons.inventory_2_rounded,
                      text: sourceItem!.name,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // =================================================================
            // DESPLEGAR
            // =================================================================
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.keyboard_arrow_down_rounded, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// BADGE PASIVA
// =============================================================================

class _PassiveBadge extends StatelessWidget {
  final Color color;

  const _PassiveBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 13, color: color),

          const SizedBox(width: 4),

          Text(
            'PASIVA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CONTENIDO EXPANDIDO
// =============================================================================

class _PassiveExpandedContent extends StatelessWidget {
  final CharacterPassive passive;

  final Color color;

  final bool isItemPassive;

  final ValueChanged<bool>? onToggle;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onUseCharge;
  final VoidCallback? onRestoreCharges;

  const _PassiveExpandedContent({
    required this.passive,
    required this.color,
    required this.isItemPassive,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onUseCharge,
    required this.onRestoreCharges,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final effects = _buildEffects();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),

          const SizedBox(height: 14),

          // ===================================================================
          // PROCEDENCIA
          // ===================================================================
          _SectionLabel(
            icon: Icons.category_rounded,
            label: 'Procedencia',
            color: color,
          ),

          const SizedBox(height: 9),

          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              InfoBadge(
                icon: _sourceIcon(passive.sourceType),
                text: passive.sourceType.label,
                color: color,
                highlighted: true,
              ),

              if (isItemPassive)
                InfoBadge(
                  icon: Icons.inventory_2_rounded,
                  text: 'Objeto equipado',
                  color: color,
                ),

              InfoBadge(
                icon: passive.enabled
                    ? Icons.check_circle_rounded
                    : Icons.visibility_off_rounded,
                text: passive.enabled ? 'Activa' : 'Desactivada',
              ),
            ],
          ),

          // ===================================================================
          // CARGAS
          // ===================================================================
          if (passive.usesCharges) ...[
            const SizedBox(height: 18),

            _SectionLabel(
              icon: Icons.bolt_rounded,
              label: 'Cargas',
              color: color,
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: PassiveColors.softBackground(
                  context,
                  color,
                  strength: 0.12,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.battery_charging_full_rounded, color: color),

                      const SizedBox(width: 8),

                      Text(
                        '${passive.currentCharges}/${passive.maxCharges}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: color,
                            ),
                      ),
                    ],
                  ),

                  if (passive.rechargeDescription.isNotEmpty) ...[
                    const SizedBox(height: 6),

                    Text('Recuperación: ${passive.rechargeDescription}'),
                  ],

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: passive.currentCharges > 0
                              ? onUseCharge
                              : null,
                          icon: const Icon(Icons.remove_rounded),
                          label: const Text('Gastar'),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onRestoreCharges,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Recuperar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // ===================================================================
          // EFECTOS
          // ===================================================================
          if (effects.isNotEmpty) ...[
            const SizedBox(height: 18),

            _SectionLabel(
              icon: Icons.add_chart_rounded,
              label: 'Bonificaciones',
              color: color,
            ),

            const SizedBox(height: 9),

            Wrap(spacing: 8, runSpacing: 8, children: effects),
          ],

          // ===================================================================
          // SIN EFECTOS MECÁNICOS
          // ===================================================================
          if (effects.isEmpty) ...[
            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      'Esta pasiva no tiene bonificaciones numéricas.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ===================================================================
          // DESACTIVADA
          // ===================================================================
          if (!passive.enabled) ...[
            const SizedBox(height: 14),

            const PassiveDisabledBanner(),
          ],

          // ===================================================================
          // NOTAS
          // ===================================================================
          if (passive.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 18),

            _SectionLabel(
              icon: Icons.notes_rounded,
              label: 'Notas',
              color: color,
            ),

            const SizedBox(height: 9),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                passive.notes,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ),
          ],

          // ===================================================================
          // CONTROLES
          // ===================================================================
          if (!isItemPassive &&
              (onToggle != null || onEdit != null || onDelete != null)) ...[
            const SizedBox(height: 18),

            const Divider(height: 1),

            const SizedBox(height: 12),

            // ===============================================================
            // ACTIVAR / DESACTIVAR
            // ===============================================================
            if (onToggle != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: PassiveColors.softBackground(
                    context,
                    color,
                    strength: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: passive.enabled,
                  title: Text(
                    passive.enabled ? 'Pasiva activa' : 'Pasiva desactivada',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    passive.enabled
                        ? 'Sus bonificaciones se están aplicando.'
                        : 'Sus bonificaciones no se están aplicando.',
                  ),
                  secondary: Icon(
                    passive.enabled
                        ? Icons.check_circle_rounded
                        : Icons.visibility_off_rounded,
                    color: color,
                  ),
                  onChanged: onToggle,
                ),
              ),

            if (onEdit != null || onDelete != null) ...[
              const SizedBox(height: 10),

              Row(
                children: [
                  if (onEdit != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Editar'),
                      ),
                    ),

                  if (onEdit != null && onDelete != null)
                    const SizedBox(width: 10),

                  if (onDelete != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Eliminar'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // EFECTOS
  // ===========================================================================

  List<Widget> _buildEffects() {
    final effects = <Widget>[];

    // -------------------------------------------------------------------------
    // CA
    // -------------------------------------------------------------------------

    if (passive.armorClassBonus != 0) {
      effects.add(
        PassiveEffectBadge(
          icon: Icons.shield_rounded,
          label: '${_bonusText(passive.armorClassBonus)} CA',
          color: PassiveColors.armorClass,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // INICIATIVA
    // -------------------------------------------------------------------------

    if (passive.initiativeBonus != 0) {
      effects.add(
        PassiveEffectBadge(
          icon: Icons.bolt_rounded,
          label: '${_bonusText(passive.initiativeBonus)} iniciativa',
          color: PassiveColors.initiative,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // VELOCIDAD
    // -------------------------------------------------------------------------

    if (passive.speedBonus != 0) {
      effects.add(
        PassiveEffectBadge(
          icon: Icons.directions_run_rounded,
          label: '${_bonusText(passive.speedBonus)} pies',
          color: PassiveColors.speed,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // VIDA
    // -------------------------------------------------------------------------

    if (passive.maxHealthBonus != 0) {
      effects.add(
        PassiveEffectBadge(
          icon: Icons.favorite_rounded,
          label: '${_bonusText(passive.maxHealthBonus)} PG máx.',
          color: PassiveColors.health,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // ATAQUE
    // -------------------------------------------------------------------------

    if (passive.attackBonus != 0) {
      effects.add(
        PassiveEffectBadge(
          icon: Icons.gps_fixed_rounded,
          label: '${_bonusText(passive.attackBonus)} al golpe',
          color: PassiveColors.attack,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // MODIFICADORES DE ATRIBUTO
    // -------------------------------------------------------------------------

    for (final entry in passive.abilityModifierBonuses.entries) {
      if (entry.value == 0) {
        continue;
      }

      effects.add(
        PassiveEffectBadge(
          icon: Icons.psychology_rounded,
          label: '${_bonusText(entry.value)} ${entry.key.shortLabel}',
          color: PassiveColors.skill,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // SKILLS
    // -------------------------------------------------------------------------

    for (final entry in passive.skillBonuses.entries) {
      if (entry.value == 0) {
        continue;
      }

      effects.add(
        PassiveEffectBadge(
          icon: Icons.bar_chart_rounded,
          label: '${_bonusText(entry.value)} ${entry.key.label}',
          color: PassiveColors.skill,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // SALVACIONES
    // -------------------------------------------------------------------------

    for (final entry in passive.savingThrowBonuses.entries) {
      if (entry.value == 0) {
        continue;
      }

      effects.add(
        PassiveEffectBadge(
          icon: Icons.security_rounded,
          label: '${_bonusText(entry.value)} Salv. ${entry.key.shortLabel}',
          color: PassiveColors.savingThrow,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // DAÑO ADICIONAL
    // -------------------------------------------------------------------------

    for (final bonus in passive.damageBonuses) {
      if (!bonus.hasDamage) {
        continue;
      }

      effects.add(
        PassiveEffectBadge(
          icon: Icons.local_fire_department_rounded,
          label: _damageBonusLabel(bonus),
          color: PassiveColors.attack,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // DAÑO CRÍTICO
    // -------------------------------------------------------------------------

    for (final bonus in passive.criticalDamageBonuses) {
      if (!bonus.canTrigger) {
        continue;
      }

      effects.add(
        PassiveEffectBadge(
          icon: Icons.flash_on_rounded,
          label: _criticalDamageBonusLabel(bonus),
          color: PassiveColors.attack,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // CURACIÓN
    // -------------------------------------------------------------------------

    for (final bonus in passive.healingBonuses) {
      if (!bonus.hasHealing) {
        continue;
      }

      effects.add(
        PassiveEffectBadge(
          icon: Icons.favorite_rounded,
          label: _healingBonusLabel(bonus),
          color: PassiveColors.health,
        ),
      );
    }

    return effects;
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================
  static String _damageBonusLabel(DamageBonus bonus) {
    final pieces = <String>[];

    if (bonus.diceNotation.isNotEmpty) {
      pieces.add(bonus.diceNotation);
    }

    for (final entry in bonus.abilityModifierMultipliers.entries) {
      if (entry.value == 0) {
        continue;
      }

      if (entry.value == 1) {
        pieces.add(entry.key.shortLabel);
      } else {
        pieces.add('${entry.value}×${entry.key.shortLabel}');
      }
    }

    if (bonus.flatBonus != 0) {
      pieces.add(
        bonus.flatBonus > 0 ? '+${bonus.flatBonus}' : '${bonus.flatBonus}',
      );
    }

    var formula = pieces.isEmpty
        ? 'Daño adicional'
        : pieces.join(' + ').replaceAll('+ -', '- ');

    if (bonus.damageType.trim().isNotEmpty) {
      formula += ' ${bonus.damageType.trim()}';
    }

    if (bonus.name.trim().isNotEmpty) {
      return '${bonus.name}: $formula';
    }

    return formula;
  }

  static String _criticalDamageBonusLabel(CriticalDamageBonus bonus) {
    final pieces = <String>[];

    if (bonus.diceNotation.isNotEmpty) {
      pieces.add(bonus.diceNotation);
    }

    if (bonus.damageType.trim().isNotEmpty) {
      pieces.add(bonus.damageType.trim());
    }

    if (!bonus.alwaysTriggers) {
      pieces.add('${bonus.chancePercent}%');
    }

    final formula = pieces.isEmpty ? 'Daño crítico' : pieces.join(' · ');

    if (bonus.name.trim().isNotEmpty) {
      return '${bonus.name}: $formula';
    }

    return formula;
  }

  static String _healingBonusLabel(HealingBonus bonus) {
    final pieces = <String>[];

    if (bonus.diceNotation.isNotEmpty) {
      pieces.add(bonus.diceNotation);
    }

    for (final entry in bonus.abilityModifierMultipliers.entries) {
      if (entry.value == 0) {
        continue;
      }

      if (entry.value == 1) {
        pieces.add(entry.key.shortLabel);
      } else {
        pieces.add('${entry.value}×${entry.key.shortLabel}');
      }
    }

    if (bonus.flatBonus != 0) {
      pieces.add(
        bonus.flatBonus > 0 ? '+${bonus.flatBonus}' : '${bonus.flatBonus}',
      );
    }

    final formula = pieces.isEmpty
        ? 'Curación adicional'
        : pieces.join(' + ').replaceAll('+ -', '- ');

    if (bonus.name.trim().isNotEmpty) {
      return '${bonus.name}: $formula';
    }

    return formula;
  }

  static String _bonusText(int value) {
    return value >= 0 ? '+$value' : '$value';
  }

  static IconData _sourceIcon(PassiveSourceType source) {
    switch (source) {
      case PassiveSourceType.race:
        return Icons.diversity_3_rounded;

      case PassiveSourceType.classFeature:
        return Icons.military_tech_rounded;

      case PassiveSourceType.feat:
        return Icons.workspace_premium_rounded;

      case PassiveSourceType.item:
        return Icons.inventory_2_rounded;

      case PassiveSourceType.background:
        return Icons.history_edu_rounded;

      case PassiveSourceType.custom:
        return Icons.tune_rounded;
    }
  }
}

// =============================================================================
// TÍTULO INTERNO
// =============================================================================

class _SectionLabel extends StatelessWidget {
  final IconData icon;

  final String label;

  final Color color;

  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: color),
        ),

        const SizedBox(width: 8),

        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
