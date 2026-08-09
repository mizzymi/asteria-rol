import 'package:flutter/material.dart';

import '../../models/passive.dart';
import '../../models/skill.dart';

import '../common/app_card.dart';
import '../common/info_badge.dart';
import 'passive_colors.dart';
import 'passive_effect_badge.dart';
import 'passive_disabled_banner.dart';

class PassiveCard extends StatefulWidget {
  final CharacterPassive passive;

  final bool isItemPassive;

  final ValueChanged<bool>? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PassiveCard({
    super.key,
    required this.passive,
    required this.isItemPassive,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
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
          _PassiveHeader(
            passive: passive,
            color: color,
            isItemPassive: widget.isItemPassive,
            expanded: expanded,
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
            onToggle: widget.onToggle,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _PassiveExpandedContent(passive: passive),
          ),
        ],
      ),
    );
  }
}

class _PassiveHeader extends StatelessWidget {
  final CharacterPassive passive;
  final Color color;

  final bool isItemPassive;
  final bool expanded;

  final VoidCallback onTap;

  final ValueChanged<bool>? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PassiveHeader({
    required this.passive,
    required this.color,
    required this.isItemPassive,
    required this.expanded,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
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

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passive.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  if (passive.description.isNotEmpty) ...[
                    const SizedBox(height: 5),

                    Text(
                      passive.description,
                      maxLines: expanded ? null : 2,
                      overflow: expanded ? null : TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  const SizedBox(height: 7),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      InfoBadge(
                        icon: Icons.category_rounded,
                        text: passive.sourceType.label,
                        color: color,
                      ),

                      if (isItemPassive)
                        const InfoBadge(
                          icon: Icons.inventory_2_rounded,
                          text: 'Objeto',
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isItemPassive)
                  Switch(value: passive.enabled, onChanged: onToggle)
                else
                  Icon(Icons.inventory_2_rounded, color: color),

                if (!isItemPassive)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;

                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ];
                    },
                  ),

                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PassiveExpandedContent extends StatelessWidget {
  final CharacterPassive passive;

  const _PassiveExpandedContent({required this.passive});

  @override
  Widget build(BuildContext context) {
    final effects = <Widget>[];

    if (passive.armorClassBonus != 0) {
      effects.add(
        PassiveEffectBadge(
          icon: Icons.shield_rounded,
          label: '${_bonusText(passive.armorClassBonus)} CA',
          color: PassiveColors.armorClass,
        ),
      );
    }

    if (passive.initiativeBonus != 0) {
      effects.add(
        PassiveEffectBadge(
          icon: Icons.bolt_rounded,
          label: '${_bonusText(passive.initiativeBonus)} iniciativa',
          color: PassiveColors.initiative,
        ),
      );
    }

    if (passive.speedBonus != 0) {
      effects.add(
        PassiveEffectBadge(
          icon: Icons.directions_run_rounded,
          label: '${_bonusText(passive.speedBonus)} pies',
          color: PassiveColors.speed,
        ),
      );
    }

    if (passive.maxHealthBonus != 0) {
      effects.add(
        PassiveEffectBadge(
          icon: Icons.favorite_rounded,
          label: '${_bonusText(passive.maxHealthBonus)} PG máx.',
          color: PassiveColors.health,
        ),
      );
    }

    if (passive.attackBonus != 0) {
      effects.add(
        PassiveEffectBadge(
          icon: Icons.gps_fixed_rounded,
          label: '${_bonusText(passive.attackBonus)} al golpe',
          color: PassiveColors.attack,
        ),
      );
    }

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),

          if (effects.isNotEmpty) ...[
            const SizedBox(height: 14),

            Wrap(spacing: 8, runSpacing: 8, children: effects),
          ],

          if (!passive.enabled) ...[
            const SizedBox(height: 14),

            const PassiveDisabledBanner(),
          ],

          if (passive.notes.isNotEmpty) ...[
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded, size: 18),

                  const SizedBox(width: 8),

                  Expanded(child: Text(passive.notes)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _bonusText(int value) {
    return value >= 0 ? '+$value' : '$value';
  }
}
