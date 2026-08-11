import 'package:flutter/material.dart';
import 'package:rol/widgets/abilities/ability_effect_card.dart';

import 'ability_attribute_colors.dart';
import '../../models/ability.dart';
import '../../models/character.dart';
import '../../models/item.dart';
import '../../models/skill.dart';

import 'ability_action_badge.dart';

import '../common/app_card.dart';
import '../common/info_badge.dart';
import '../common/section_header.dart';

class AbilityCard extends StatefulWidget {
  final CharacterAbility ability;
  final Character character;
  final CharacterItem? sourceItem;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  final VoidCallback onUse;
  final VoidCallback onAttack;
  final VoidCallback onResolveEffects;

  const AbilityCard({
    super.key,
    required this.ability,
    required this.character,
    required this.sourceItem,
    required this.onEdit,
    required this.onDelete,
    required this.onRestore,
    required this.onUse,
    required this.onAttack,
    required this.onResolveEffects,
  });

  @override
  State<AbilityCard> createState() => _AbilityCardState();
}

class _AbilityCardState extends State<AbilityCard> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    final attributeColor = AbilityAttributeColors.color(
      widget.ability.abilityType,
    );
    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      accentColor: attributeColor,
      showAccentBar: true,
      child: Column(
        children: [
          _CompactAbilityHeader(
            ability: widget.ability,
            sourceItem: widget.sourceItem,
            expanded: expanded,
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
            onRestore: widget.onRestore,
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,

            firstChild: const SizedBox(width: double.infinity),

            secondChild: _ExpandedAbilityContent(
              ability: widget.ability,
              character: widget.character,
              onUse: widget.onUse,
              onAttack: widget.onAttack,
              onResolveEffects: widget.onResolveEffects,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CABECERA COMPACTA
// =============================================================================

class _CompactAbilityHeader extends StatelessWidget {
  final CharacterAbility ability;
  final CharacterItem? sourceItem;

  final bool expanded;
  final VoidCallback onTap;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const _CompactAbilityHeader({
    required this.ability,
    required this.sourceItem,
    required this.expanded,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attributeColor = AbilityAttributeColors.color(ability.abilityType);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
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
                color: AbilityAttributeColors.strongBackground(
                  context,
                  ability.abilityType,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(_abilityIcon, color: attributeColor),
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
                        ability.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      AbilityActionBadge(type: ability.actionType),
                    ],
                  ),

                  if (ability.description.isNotEmpty) ...[
                    const SizedBox(height: 5),

                    Text(
                      ability.description,
                      maxLines: expanded ? null : 2,
                      overflow: expanded ? null : TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
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

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sourceItem == null)
                  PopupMenuButton<String>(
                    tooltip: 'Opciones',
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;

                        case 'restore':
                          onRestore?.call();
                          break;

                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar'),
                          ),

                        if (onRestore != null)
                          const PopupMenuItem(
                            value: 'restore',
                            child: Text('Restaurar usos'),
                          ),

                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar'),
                          ),
                      ];
                    },
                  )
                else
                  const SizedBox(height: 40),

                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData get _abilityIcon {
    if (ability.heals && !ability.dealsDamage) {
      return Icons.favorite_rounded;
    }

    if (ability.requiresAttackRoll) {
      return Icons.gps_fixed_rounded;
    }

    if (ability.effects.any((effect) => effect.usesSavingThrow)) {
      return Icons.shield_rounded;
    }

    return Icons.auto_awesome_rounded;
  }
}

// =============================================================================
// CONTENIDO DESPLEGADO
// =============================================================================

class _ExpandedAbilityContent extends StatelessWidget {
  final CharacterAbility ability;
  final Character character;

  final VoidCallback onUse;
  final VoidCallback onAttack;
  final VoidCallback onResolveEffects;

  const _ExpandedAbilityContent({
    required this.ability,
    required this.character,
    required this.onUse,
    required this.onAttack,
    required this.onResolveEffects,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),

          const SizedBox(height: 16),

          _AbilityMeta(ability: ability, character: character),

          if (ability.effects.isNotEmpty) ...[
            const SizedBox(height: 20),

            SectionHeader(
              icon: Icons.auto_awesome_motion_rounded,
              title: ability.effects.length == 1 ? 'Efecto' : 'Efectos',
              subtitle: ability.effects.length == 1
                  ? 'Resultado de la habilidad'
                  : '${ability.effects.length} efectos',
            ),

            const SizedBox(height: 12),

            ...ability.effects.map(
              (effect) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AbilityEffectCard(
                  ability: ability,
                  effect: effect,
                  character: character,
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),

          _AbilityActions(
            ability: ability,
            onAttack: onAttack,
            onResolveEffects: onResolveEffects,
          ),

          if (ability.hasLimitedUses) ...[
            const SizedBox(height: 18),

            _AbilityUses(ability: ability, onUse: onUse),
          ],

          if (ability.notes.isNotEmpty) ...[
            const SizedBox(height: 14),

            _NotesSection(notes: ability.notes),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// META
// =============================================================================

class _AbilityMeta extends StatelessWidget {
  final CharacterAbility ability;
  final Character character;

  const _AbilityMeta({required this.ability, required this.character});

  String bonusText(int value) {
    return value >= 0 ? '+$value' : '$value';
  }

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      InfoBadge(
        icon: Icons.psychology_rounded,
        text: ability.abilityType.shortLabel,
        color: AbilityAttributeColors.color(ability.abilityType),
        highlighted: true,
      ),
    ];

    if (ability.requiresAttackRoll) {
      final attackBonus = character.characterAbilityAttackBonus(ability);

      badges.add(
        InfoBadge(
          icon: Icons.gps_fixed_rounded,
          text: '${bonusText(attackBonus)} al golpe',
          highlighted: true,
        ),
      );
    }

    if (ability.hasLimitedUses) {
      badges.add(
        InfoBadge(
          icon: Icons.repeat_rounded,
          text: '${ability.currentUses}/${ability.maxUses} usos',
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: badges);
  }
}

// =============================================================================
// ACCIONES
// =============================================================================

class _AbilityActions extends StatelessWidget {
  final CharacterAbility ability;

  final VoidCallback onAttack;
  final VoidCallback onResolveEffects;

  const _AbilityActions({
    required this.ability,
    required this.onAttack,
    required this.onResolveEffects,
  });

  @override
  Widget build(BuildContext context) {
    final hasEffects = ability.effects.any((effect) => effect.hasEffect);

    if (ability.requiresAttackRoll) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onAttack,
          icon: const Icon(Icons.casino_rounded),
          label: const Text('Atacar'),
        ),
      );
    }

    if (hasEffects) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onResolveEffects,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Resolver efectos'),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// =============================================================================
// USOS
// =============================================================================

class _AbilityUses extends StatelessWidget {
  final CharacterAbility ability;
  final VoidCallback onUse;

  const _AbilityUses({required this.ability, required this.onUse});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final progress = ability.maxUses == 0
        ? 0.0
        : (ability.currentUses / ability.maxUses).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.repeat_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),

              const SizedBox(width: 7),

              const Expanded(
                child: Text(
                  'Usos disponibles',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),

              Text(
                '${ability.currentUses}/${ability.maxUses}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(minHeight: 7, value: progress),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: ability.currentUses > 0 ? onUse : null,
              icon: const Icon(Icons.remove_circle_outline_rounded),
              label: const Text('Gastar 1 uso'),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// NOTAS
// =============================================================================

class _NotesSection extends StatelessWidget {
  final String notes;

  const _NotesSection({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notes_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              notes,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
