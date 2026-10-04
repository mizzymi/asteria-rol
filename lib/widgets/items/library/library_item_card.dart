import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/item_definition.dart';
import '../../../models/item_library_entry.dart';

import '../../common/app_card.dart';
import '../../common/info_badge.dart';

import '../item_ability_preview.dart';
import '../item_passive_preview.dart';
import '../../../theme/item_type_colors.dart';

import 'export_item_button.dart';

class LibraryItemCard extends StatefulWidget {
  final ItemLibraryEntry entry;

  final VoidCallback? onAdd;

  final VoidCallback onEdit;

  final VoidCallback onShare;

  final VoidCallback onDelete;

  const LibraryItemCard({
    super.key,
    required this.entry,
    this.onAdd,
    required this.onEdit,
    required this.onShare,
    required this.onDelete,
  });

  @override
  State<LibraryItemCard> createState() {
    return _LibraryItemCardState();
  }
}

class _LibraryItemCardState extends State<LibraryItemCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.entry.definition;

    final color = ItemTypeColors.of(context, item.type);

    final theme = Theme.of(context);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      accentColor: color,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DefinitionImage(definition: item, color: color),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            InfoBadge(
                              icon: ItemTypeColors.icon(item.type),
                              text: item.type.label,
                              color: color,
                              highlighted: true,
                            ),

                            if (item.weapon != null)
                              InfoBadge(
                                icon: Icons.gavel_rounded,
                                text:
                                    '${item.weapon!.damages.length} '
                                    'daño'
                                    '${item.weapon!.damages.length == 1 ? '' : 's'}',
                              ),

                            if (item.consumable != null)
                              InfoBadge(
                                icon: Icons.science_rounded,
                                text:
                                    '${item.consumable!.effects.length} '
                                    'efecto'
                                    '${item.consumable!.effects.length == 1 ? '' : 's'}',
                              ),

                            if (item.passives.isNotEmpty)
                              InfoBadge(
                                icon: Icons.auto_awesome_rounded,
                                text: '${item.passives.length}',
                              ),

                            if (item.abilities.isNotEmpty)
                              InfoBadge(
                                icon: Icons.flash_on_rounded,
                                text: '${item.abilities.length}',
                              ),

                            if (item.stackable)
                              const InfoBadge(
                                icon: Icons.layers_rounded,
                                text: 'Apilable',
                              ),
                          ],
                        ),

                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 8),

                          Text(
                            item.description,
                            maxLines: expanded ? null : 2,
                            overflow: expanded ? null : TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 4),

                  Column(
                    children: [
                      PopupMenuButton<String>(
                        tooltip: 'Opciones',
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              widget.onEdit();
                              break;

                            case 'share':
                              widget.onShare();
                              break;

                            case 'delete':
                              widget.onDelete();
                              break;
                          }
                        },
                        itemBuilder: (_) {
                          return const [
                            PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.edit_rounded),
                                title: Text('Editar'),
                              ),
                            ),

                            PopupMenuItem(
                              value: 'share',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.share_rounded),
                                title: Text('Compartir'),
                              ),
                            ),

                            PopupMenuDivider(),

                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.delete_outline_rounded),
                                title: Text('Eliminar'),
                              ),
                            ),
                          ];
                        },
                      ),

                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,

            firstChild: const SizedBox(width: double.infinity),

            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),

                  // =============================================================
                  // EQUIPMENT
                  // =============================================================
                  if (item.equipmentSlotIds.isNotEmpty) ...[
                    const SizedBox(height: 16),

                    _SectionTitle(
                      icon: Icons.checkroom_rounded,
                      title: 'Equipamiento',
                      color: color,
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.equipmentSlotIds
                          .map(
                            (slot) => InfoBadge(
                              icon: Icons.inventory_2_outlined,
                              text: slot,
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  // =============================================================
                  // ARMOR
                  // =============================================================
                  if (item.armor != null) ...[
                    const SizedBox(height: 16),

                    _SectionTitle(
                      icon: Icons.shield_rounded,
                      title: 'Armadura',
                      color: color,
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        InfoBadge(
                          icon: Icons.shield_outlined,
                          text: 'CA ${item.armor!.baseArmorClass}',
                        ),

                        InfoBadge(
                          icon: Icons.category_rounded,
                          text: item.armor!.category.label,
                        ),
                      ],
                    ),
                  ],

                  // =============================================================
                  // WEAPON
                  // =============================================================
                  if (item.type == ItemType.weapon && item.weapon != null) ...[
                    const SizedBox(height: 16),

                    _SectionTitle(
                      icon: Icons.gavel_rounded,
                      title: 'Arma',
                      color: color,
                    ),

                    const SizedBox(height: 10),

                    _WeaponLibraryPreview(definition: item, color: color),
                  ],

                  // =============================================================
                  // CONSUMABLE
                  // =============================================================
                  if (item.type == ItemType.consumable &&
                      item.consumable != null) ...[
                    const SizedBox(height: 16),

                    _SectionTitle(
                      icon: Icons.science_rounded,
                      title: 'Consumible',
                      count: item.consumable!.effects.length,
                      color: color,
                    ),

                    const SizedBox(height: 10),

                    _ConsumableLibraryPreview(definition: item, color: color),
                  ],

                  // =============================================================
                  // PASSIVES
                  // =============================================================
                  if (item.passives.isNotEmpty) ...[
                    const SizedBox(height: 16),

                    _SectionTitle(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Pasivas',
                      count: item.passives.length,
                      color: color,
                    ),

                    const SizedBox(height: 10),

                    ...item.passives.map(
                      (passive) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ItemPassivePreview(passive: passive),
                      ),
                    ),
                  ],

                  // =============================================================
                  // ABILITIES
                  // =============================================================
                  if (item.abilities.isNotEmpty) ...[
                    const SizedBox(height: 16),

                    _SectionTitle(
                      icon: Icons.flash_on_rounded,
                      title: 'Habilidades',
                      count: item.abilities.length,
                      color: color,
                    ),

                    const SizedBox(height: 10),

                    ...item.abilities.map(
                      (ability) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ItemAbilityPreview(ability: ability),
                      ),
                    ),
                  ],

                  // =============================================================
                  // CALCULATOR
                  // =============================================================
                  if (item.calculable) ...[
                    const SizedBox(height: 16),

                    _SectionTitle(
                      icon: Icons.calculate_rounded,
                      title: 'Calculadora',
                      count: item.calculationCosts.length,
                      color: color,
                    ),

                    const SizedBox(height: 8),

                    if (item.calculationCosts.isEmpty)
                      Text(
                        'Sin costes configurados.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      ...item.calculationCosts.map(
                        (cost) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${cost.quantityPerUnit} × ${cost.itemId}',
                          ),
                        ),
                      ),
                  ],

                  // =============================================================
                  // NOTES
                  // =============================================================
                  if (item.notes.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),

                    _SectionTitle(
                      icon: Icons.notes_rounded,
                      title: 'Notas',
                      color: color,
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        item.notes,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  if (widget.onAdd != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: widget.onAdd,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Añadir al personaje'),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Editar objeto'),
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: ExportItemButton(onPressed: widget.onShare),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DEFINITION IMAGE
// =============================================================================

class _DefinitionImage extends StatelessWidget {
  final ItemDefinition definition;
  final Color color;

  const _DefinitionImage({required this.definition, required this.color});

  @override
  Widget build(BuildContext context) {
    final imagePath = definition.imagePath;
    final hasImage =
        imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    return GestureDetector(
      onTap: hasImage
          ? () {
              _showImage(context, imagePath);
            }
          : null,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: ItemTypeColors.background(
            context,
            definition.type,
            strength: 0.22,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Image.file(File(imagePath), fit: BoxFit.cover)
            : Icon(
                ItemTypeColors.icon(definition.type),
                color: color,
                size: 30,
              ),
      ),
    );
  }

  Future<void> _showImage(BuildContext context, String imagePath) {
    if (imagePath.isEmpty) {
      return Future.value();
    }

    return Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Theme.of(
          context,
        ).colorScheme.scrim.withValues(alpha: 0.92),
        pageBuilder: (_, _, _) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.scrim,
            body: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 5,
                        child: Center(
                          child: Image.file(
                            File(imagePath),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filled(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Text(
                      definition.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// WEAPON
// =============================================================================

class _WeaponLibraryPreview extends StatelessWidget {
  final ItemDefinition definition;

  final Color color;

  const _WeaponLibraryPreview({required this.definition, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final weapon = definition.weapon;

    if (weapon == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gps_fixed_rounded, size: 18, color: color),

              const SizedBox(width: 7),

              Text(
                'Ataque',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),

              const Spacer(),

              Text(
                weapon.attackAbility.name,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              InfoBadge(
                icon: Icons.verified_rounded,
                text: weapon.proficient ? 'Competente' : 'No competente',
              ),

              if (weapon.magicBonus != 0)
                InfoBadge(
                  icon: Icons.auto_awesome_rounded,
                  text:
                      '${weapon.magicBonus > 0 ? '+' : ''}'
                      '${weapon.magicBonus} mágico',
                ),
            ],
          ),

          if (weapon.damages.isNotEmpty) ...[
            const SizedBox(height: 12),

            ...weapon.damages.map((damage) {
              final pieces = <String>[];

              if (damage.diceNotation.isNotEmpty) {
                pieces.add(damage.diceNotation);
              }

              if (damage.addAbilityModifier) {
                pieces.add(damage.abilityType.name);
              }

              if (damage.bonus != 0) {
                pieces.add(
                  damage.bonus > 0 ? '+${damage.bonus}' : '${damage.bonus}',
                );
              }

              final formula = pieces.join(' + ').replaceAll('+ -', '- ');

              return Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.casino_rounded, size: 17, color: color),

                    const SizedBox(width: 7),

                    Expanded(
                      child: Text(
                        damage.damageType.trim().isNotEmpty
                            ? '$formula · ${damage.damageType}'
                            : formula,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// CONSUMABLE
// =============================================================================

class _ConsumableLibraryPreview extends StatelessWidget {
  final ItemDefinition definition;

  final Color color;

  const _ConsumableLibraryPreview({
    required this.definition,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final consumable = definition.consumable;

    if (consumable == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_rounded, size: 18, color: color),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  consumable.useText.trim().isNotEmpty
                      ? consumable.useText
                      : 'Usar',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          if (consumable.effects.isEmpty) ...[
            const SizedBox(height: 8),

            Text(
              'Sin efectos configurados',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),

            ...consumable.effects.map((effect) {
              final pieces = <String>[];

              if (effect.diceNotation.isNotEmpty) {
                pieces.add(effect.diceNotation);
              }

              for (final entry in effect.abilityModifierMultipliers.entries) {
                if (entry.value == 0) {
                  continue;
                }

                if (entry.value == 1) {
                  pieces.add(entry.key.name);
                } else {
                  pieces.add(
                    '${entry.value}×'
                    '${entry.key.name}',
                  );
                }
              }

              if (effect.effectBonus != 0) {
                pieces.add(
                  effect.effectBonus > 0
                      ? '+${effect.effectBonus}'
                      : '${effect.effectBonus}',
                );
              }

              final formula = pieces.isEmpty
                  ? effect.effectType.name
                  : pieces.join(' + ');

              return Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      effect.heals
                          ? Icons.favorite_rounded
                          : effect.dealsDamage
                          ? Icons.bolt_rounded
                          : Icons.auto_awesome_rounded,
                      size: 17,
                      color: color,
                    ),

                    const SizedBox(width: 7),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            effect.effectTypeName.trim().isNotEmpty
                                ? '$formula · '
                                      '${effect.effectTypeName}'
                                : formula,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          if (effect.name.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),

                            Text(
                              effect.name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// SECTION TITLE
// =============================================================================

class _SectionTitle extends StatelessWidget {
  final IconData icon;

  final String title;

  final int? count;

  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),

        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }
}
