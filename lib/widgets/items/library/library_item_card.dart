import 'package:flutter/material.dart';
import 'package:rol/models/ability.dart';
import 'package:rol/models/skill.dart';

import '../../../models/item_library_entry.dart';
import '../../../models/item.dart';

import '../../common/app_card.dart';
import '../../common/info_badge.dart';

import '../item_ability_preview.dart';
import '../item_image.dart';
import '../item_image_viewer.dart';
import '../item_passive_preview.dart';
import '../item_type_colors.dart';

import 'export_item_button.dart';

class LibraryItemCard extends StatefulWidget {
  final ItemLibraryEntry entry;

  /// Solo existe cuando la biblioteca se abre
  /// para seleccionar un objeto para un personaje.
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
  State<LibraryItemCard> createState() => _LibraryItemCardState();
}

class _LibraryItemCardState extends State<LibraryItemCard> {
  bool expanded = false;

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final item = widget.entry.item;

    final color = ItemTypeColors.color(item.type);

    final theme = Theme.of(context);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      accentColor: color,
      child: Column(
        children: [
          // ===================================================================
          // HEADER
          // ===================================================================
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
                  // ===========================================================
                  // IMAGEN
                  // ===========================================================
                  ItemImage(
                    item: item,
                    size: 62,
                    onTap: item.hasImage
                        ? () {
                            ItemImageViewer.show(context, item);
                          }
                        : null,
                  ),

                  const SizedBox(width: 12),

                  // ===========================================================
                  // INFORMACIÓN
                  // ===========================================================
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
                            // =================================================
                            // TIPO
                            // =================================================
                            InfoBadge(
                              icon: ItemTypeColors.icon(item.type),
                              text: item.type.label,
                              color: color,
                              highlighted: true,
                            ),

                            // =================================================
                            // CANTIDAD
                            // =================================================
                            if (item.quantity > 1)
                              InfoBadge(
                                icon: Icons.layers_rounded,
                                text: 'x${item.quantity}',
                              ),

                            // =================================================
                            // ARMA
                            // =================================================
                            if (item.weapon != null)
                              InfoBadge(
                                icon: Icons.gavel_rounded,
                                text:
                                    '${item.weapon!.damages.length} daño${item.weapon!.damages.length == 1 ? '' : 's'}',
                              ),

                            // =================================================
                            // CONSUMIBLE
                            // =================================================
                            if (item.consumable != null)
                              InfoBadge(
                                icon: Icons.science_rounded,
                                text:
                                    '${item.consumable!.effects.length} efecto${item.consumable!.effects.length == 1 ? '' : 's'}',
                              ),

                            // =================================================
                            // PASIVAS
                            // =================================================
                            if (item.passives.isNotEmpty)
                              InfoBadge(
                                icon: Icons.auto_awesome_rounded,
                                text: '${item.passives.length}',
                              ),

                            // =================================================
                            // HABILIDADES
                            // =================================================
                            if (item.abilities.isNotEmpty)
                              InfoBadge(
                                icon: Icons.flash_on_rounded,
                                text: '${item.abilities.length}',
                              ),
                          ],
                        ),

                        // =====================================================
                        // DESCRIPCIÓN
                        // =====================================================
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

                  // ===========================================================
                  // OPCIONES
                  // ===========================================================
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

          // ===================================================================
          // CONTENIDO EXPANDIDO
          // ===================================================================
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

                  // ===========================================================
                  // ARMA
                  // ===========================================================
                  if (item.type == ItemType.weapon && item.weapon != null) ...[
                    const SizedBox(height: 16),

                    _SectionTitle(
                      icon: Icons.gavel_rounded,
                      title: 'Arma',
                      color: color,
                    ),

                    const SizedBox(height: 10),

                    _WeaponLibraryPreview(item: item, color: color),
                  ],

                  // ===========================================================
                  // CONSUMIBLE
                  // ===========================================================
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

                    _ConsumableLibraryPreview(item: item, color: color),
                  ],

                  // ===========================================================
                  // PASIVAS
                  // ===========================================================
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

                  // ===========================================================
                  // HABILIDADES
                  // ===========================================================
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

                  // ===========================================================
                  // NOTAS
                  // ===========================================================
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

                  // ===========================================================
                  // AÑADIR AL PERSONAJE
                  // ===========================================================
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

                  // ===========================================================
                  // EDITAR
                  // ===========================================================
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Editar objeto'),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ===========================================================
                  // COMPARTIR
                  // ===========================================================
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
// PREVIEW ARMA
// =============================================================================

class _WeaponLibraryPreview extends StatelessWidget {
  final CharacterItem item;
  final Color color;

  const _WeaponLibraryPreview({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final weapon = item.weapon;

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
                      '${weapon.magicBonus > 0 ? '+' : ''}${weapon.magicBonus} mágico',
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
// PREVIEW CONSUMIBLE
// =============================================================================

class _ConsumableLibraryPreview extends StatelessWidget {
  final CharacterItem item;
  final Color color;

  const _ConsumableLibraryPreview({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final consumable = item.consumable;

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

              if (item.quantity > 1)
                Text(
                  'x${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
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
                  pieces.add(entry.key.shortLabel);
                } else {
                  pieces.add('${entry.value}×${entry.key.shortLabel}');
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
                  ? effect.effectType.label
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
                                ? '$formula · ${effect.effectTypeName}'
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
// TÍTULO DE SECCIÓN
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
