import 'package:flutter/material.dart';

import '../../models/character.dart';
import '../../models/character_effect.dart';
import '../../models/passive.dart';
import '../../models/skill.dart';

import '../../services/formula_display_formatter.dart';
import '../../services/passive_display_formatter.dart';

import '../passive_form/triggers/passive_trigger_labels.dart';

import '../common/app_card.dart';
import '../common/info_badge.dart';

class EffectCard extends StatefulWidget {
  final CharacterEffect effect;
  final Character? character;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  final ValueChanged<bool>? onToggle;

  final VoidCallback? onDecreaseDuration;
  final VoidCallback? onIncreaseDuration;
  final VoidCallback? onResetDuration;

  const EffectCard({
    super.key,
    required this.effect,
    this.character,
    this.onEdit,
    this.onDelete,
    this.onToggle,
    this.onDecreaseDuration,
    this.onIncreaseDuration,
    this.onResetDuration,
  });

  @override
  State<EffectCard> createState() => _EffectCardState();
}

class _EffectCardState extends State<EffectCard> {
  bool expanded = false;

  CharacterEffect get effect => widget.effect;

  Color get color {
    if (!effect.enabled) {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }

    if (effect.expired) {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }

    switch (effect.type) {
      case CharacterEffectType.buff:
        return Theme.of(context).colorScheme.tertiary;

      case CharacterEffectType.debuff:
        return Theme.of(context).colorScheme.error;

      case CharacterEffectType.condition:
        return Theme.of(context).colorScheme.primary;

      case CharacterEffectType.neutral:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      accentColor: color,
      showAccentBar: true,
      child: Column(
        children: [
          _EffectHeader(
            effect: effect,
            color: color,
            expanded: expanded,
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _EffectExpandedContent(
              effect: effect,
              character: widget.character,
              color: color,
              onEdit: widget.onEdit,
              onDelete: widget.onDelete,
              onToggle: widget.onToggle,
              onDecreaseDuration: widget.onDecreaseDuration,
              onIncreaseDuration: widget.onIncreaseDuration,
              onResetDuration: widget.onResetDuration,
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

class _EffectHeader extends StatelessWidget {
  final CharacterEffect effect;
  final Color color;
  final bool expanded;
  final VoidCallback onTap;

  const _EffectHeader({
    required this.effect,
    required this.color,
    required this.expanded,
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(_effectIcon(effect), color: color),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Text(
                        effect.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      _EffectBadge(
                        color: color,
                        text: effect.type.label.toUpperCase(),
                      ),
                    ],
                  ),

                  if (effect.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),

                    Text(
                      effect.description,
                      maxLines: expanded ? null : 2,
                      overflow: expanded ? null : TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      InfoBadge(
                        icon: Icons.timer_rounded,
                        text: effect.durationText,
                        color: color,
                        highlighted: true,
                      ),

                      if (!effect.enabled)
                        const InfoBadge(
                          icon: Icons.visibility_off_rounded,
                          text: 'Desactivado',
                        ),

                      if (effect.expired)
                        const InfoBadge(
                          icon: Icons.timer_off_rounded,
                          text: 'Expirado',
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

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
// BADGE
// =============================================================================

class _EffectBadge extends StatelessWidget {
  final Color color;
  final String text;

  const _EffectBadge({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }
}

// =============================================================================
// EXPANDIDO
// =============================================================================

class _EffectExpandedContent extends StatelessWidget {
  final CharacterEffect effect;
  final Character? character;
  final Color color;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  final ValueChanged<bool>? onToggle;

  final VoidCallback? onDecreaseDuration;
  final VoidCallback? onIncreaseDuration;
  final VoidCallback? onResetDuration;

  const _EffectExpandedContent({
    required this.effect,
    required this.character,
    required this.color,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    required this.onDecreaseDuration,
    required this.onIncreaseDuration,
    required this.onResetDuration,
  });

  @override
  Widget build(BuildContext context) {
    final bonuses = _buildBonuses();
    final advancedBonuses = _buildAdvancedBonuses();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),

          // ===================================================================
          // DURACIÓN
          // ===================================================================
          if (effect.hasDuration) ...[
            const SizedBox(height: 16),

            Text(
              'Duración',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: effect.currentDuration > 0
                            ? onDecreaseDuration
                            : null,
                        icon: const Icon(Icons.remove_rounded),
                      ),

                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              effect.durationText,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: color,
                                  ),
                            ),

                            if (effect.durationNote.trim().isNotEmpty)
                              Text(
                                effect.durationNote,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),

                      IconButton.filledTonal(
                        onPressed: onIncreaseDuration,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),

                  if (onResetDuration != null) ...[
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onResetDuration,
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Restablecer duración'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ===================================================================
          // BONIFICACIONES
          // ===================================================================
          if (bonuses.isNotEmpty || advancedBonuses.isNotEmpty) ...[
            const SizedBox(height: 18),

            Text(
              'Bonificaciones',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 10),

            if (bonuses.isNotEmpty)
              Wrap(spacing: 8, runSpacing: 8, children: bonuses),

            if (bonuses.isNotEmpty && advancedBonuses.isNotEmpty)
              const SizedBox(height: 10),

            if (advancedBonuses.isNotEmpty)
              Column(
                children: [
                  for (var i = 0; i < advancedBonuses.length; i++) ...[
                    advancedBonuses[i],
                    if (i < advancedBonuses.length - 1)
                      const SizedBox(height: 8),
                  ],
                ],
              ),
          ],

          // ===================================================================
          // NOTAS
          // ===================================================================
          if (effect.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(effect.notes),
            ),
          ],

          // ===================================================================
          // CONTROLES
          // ===================================================================
          if (onToggle != null || onEdit != null || onDelete != null) ...[
            const SizedBox(height: 18),

            const Divider(height: 1),

            const SizedBox(height: 12),

            if (onToggle != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: effect.enabled,
                title: Text(
                  effect.enabled ? 'Efecto activo' : 'Efecto desactivado',
                ),
                onChanged: onToggle,
              ),

            if (onEdit != null || onDelete != null)
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
      ),
    );
  }

  List<Widget> _buildBonuses() {
    final result = <Widget>[];

    if (effect.armorClassBonus != 0) {
      result.add(
        InfoBadge(
          icon: Icons.shield_rounded,
          text: '${_bonus(effect.armorClassBonus)} CA',
          highlighted: true,
        ),
      );
    }

    if (effect.initiativeBonus != 0) {
      result.add(
        InfoBadge(
          icon: Icons.bolt_rounded,
          text: '${_bonus(effect.initiativeBonus)} iniciativa',
          highlighted: true,
        ),
      );
    }

    if (effect.speedBonus != 0) {
      result.add(
        InfoBadge(
          icon: Icons.directions_run_rounded,
          text: '${_bonus(effect.speedBonus)} pies',
          highlighted: true,
        ),
      );
    }

    if (effect.maxHealthBonus != 0) {
      result.add(
        InfoBadge(
          icon: Icons.favorite_rounded,
          text: '${_bonus(effect.maxHealthBonus)} PG máx.',
          highlighted: true,
        ),
      );
    }

    if (effect.attackBonus != 0) {
      result.add(
        InfoBadge(
          icon: Icons.gps_fixed_rounded,
          text: '${_bonus(effect.attackBonus)} ataque',
          highlighted: true,
        ),
      );
    }

    for (final entry in effect.abilityModifierBonuses.entries) {
      if (entry.value == 0) {
        continue;
      }

      result.add(
        InfoBadge(
          icon: Icons.psychology_rounded,
          text: '${_bonus(entry.value)} ${entry.key.shortLabel}',
        ),
      );
    }

    for (final entry in effect.skillBonuses.entries) {
      if (entry.value == 0) {
        continue;
      }

      result.add(
        InfoBadge(
          icon: Icons.bar_chart_rounded,
          text: '${_bonus(entry.value)} ${entry.key.label}',
        ),
      );
    }

    for (final entry in effect.savingThrowBonuses.entries) {
      if (entry.value == 0) {
        continue;
      }

      result.add(
        InfoBadge(
          icon: Icons.security_rounded,
          text: '${_bonus(entry.value)} Salv. ${entry.key.shortLabel}',
        ),
      );
    }

    if (effect.criticalMinimumNaturalRoll < 20) {
      result.add(
        InfoBadge(
          icon: Icons.adjust_rounded,
          text: 'Crítico ${effect.criticalMinimumNaturalRoll}–20',
          highlighted: true,
        ),
      );
    }

    if (effect.empoweredCritical) {
      result.add(
        InfoBadge(
          icon: Icons.whatshot_rounded,
          text: 'Crítico potenciado: ${effect.empoweredCriticalFormula}',
          highlighted: true,
        ),
      );
    }

    return result;
  }

  List<Widget> _buildAdvancedBonuses() {
    final result = <Widget>[];

    for (final bonus in effect.damageBonuses) {
      if (!bonus.hasDamage) {
        continue;
      }

      result.add(
        _EffectMechanicTile(
          icon: Icons.local_fire_department_rounded,
          title: 'Daño adicional',
          text: PassiveDisplayFormatter.damageBonus(
            bonus,
            character: character,
          ),
          color: color,
        ),
      );
    }

    for (final bonus in effect.criticalDamageBonuses) {
      if (!bonus.canTrigger) {
        continue;
      }

      result.add(
        _EffectMechanicTile(
          icon: Icons.flash_on_rounded,
          title: 'Daño crítico adicional',
          text: PassiveDisplayFormatter.criticalDamageBonus(
            bonus,
            character: character,
          ),
          color: color,
        ),
      );
    }

    for (final bonus in effect.healingBonuses) {
      if (!bonus.hasHealing) {
        continue;
      }

      result.add(
        _EffectMechanicTile(
          icon: Icons.favorite_rounded,
          title: 'Curación adicional',
          text: PassiveDisplayFormatter.healingBonus(
            bonus,
            character: character,
          ),
          color: color,
        ),
      );
    }

    for (final trigger in effect.triggers) {
      if (!trigger.hasMechanicalEffects) {
        continue;
      }

      result.add(
        _EffectMechanicTile(
          icon: Icons.bolt_rounded,
          title: 'Trigger · ${trigger.event.label}',
          text: _triggerText(trigger),
          color: color,
        ),
      );
    }

    return result;
  }

  String _triggerText(CharacterEffectTrigger trigger) {
    final pieces = <String>[];

    pieces.add(
      trigger.target == PassiveTriggerTarget.self
          ? 'Objetivo: propio personaje'
          : 'Objetivo: objetivo de la acción',
    );

    switch (trigger.usageLimit) {
      case TriggerUsageLimit.unlimited:
        break;
      case TriggerUsageLimit.oncePerTurn:
        pieces.add('Una vez por turno');
        break;
      case TriggerUsageLimit.oncePerRound:
        pieces.add('Una vez por ronda');
        break;
    }

    if (trigger.mode == PassiveTriggerMode.whileCondition) {
      pieces.add('Mientras se cumpla');
    }

    if (trigger.hasCondition) {
      final formatted = FormulaDisplayFormatter.format(
        trigger.condition!.expression,
        character,
      );
      pieces.add('Si: $formatted');
    }

    for (final bonus in trigger.damageBonuses) {
      if (bonus.hasDamage) {
        pieces.add(
          'Daño: ${PassiveDisplayFormatter.damageBonus(bonus, character: character)}',
        );
      }
    }

    for (final bonus in trigger.healingBonuses) {
      if (bonus.hasHealing) {
        pieces.add(
          'Curación: ${PassiveDisplayFormatter.healingBonus(bonus, character: character)}',
        );
      }
    }

    for (final linked in trigger.linkedEffects) {
      final name = linked.name.trim();
      pieces.add('Efecto: ${name.isEmpty ? 'Efecto vinculado' : name}');
    }

    return pieces.join(' · ');
  }

  static String _bonus(int value) {
    return value >= 0 ? '+$value' : '$value';
  }
}

// =============================================================================
// ICONO
// =============================================================================

IconData _effectIcon(CharacterEffect effect) {
  if (effect.expired) {
    return Icons.timer_off_rounded;
  }

  if (!effect.enabled) {
    return Icons.visibility_off_rounded;
  }

  switch (effect.type) {
    case CharacterEffectType.buff:
      return Icons.trending_up_rounded;

    case CharacterEffectType.debuff:
      return Icons.trending_down_rounded;

    case CharacterEffectType.condition:
      return Icons.warning_amber_rounded;

    case CharacterEffectType.neutral:
      return Icons.auto_awesome_rounded;
  }
}

class _EffectMechanicTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;

  const _EffectMechanicTile({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
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
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
