import 'package:flutter/material.dart';
import 'package:rol/models/ability.dart';
import 'package:rol/models/skill.dart';

import '../../models/character.dart';
import '../../models/item.dart';

import '../common/app_card.dart';
import '../common/info_badge.dart';
import '../common/section_header.dart';

import 'item_ability_preview.dart';
import 'item_image.dart';
import 'item_image_viewer.dart';
import 'item_passive_preview.dart';
import 'item_type_colors.dart';

class ItemCard extends StatefulWidget {
  final CharacterItem item;

  final Character character;

  final VoidCallback onEquip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onExport;
  final VoidCallback onSaveToLibrary;

  final VoidCallback? onWeaponAttack;
  final VoidCallback? onWeaponDamage;
  final VoidCallback? onConsumableUse;
  final VoidCallback? onQuickQuantityEdit;

  const ItemCard({
    super.key,
    required this.item,
    required this.character,
    required this.onEquip,
    required this.onEdit,
    required this.onDelete,
    required this.onExport,
    required this.onSaveToLibrary,
    this.onWeaponAttack,
    this.onWeaponDamage,
    this.onConsumableUse,
    this.onQuickQuantityEdit,
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool expanded = false;

  CharacterItem get item => widget.item;

  @override
  Widget build(BuildContext context) {
    final color = ItemTypeColors.color(item.type);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      accentColor: color,
      showAccentBar: item.equipped,
      emphasized: item.equipped,
      child: Column(
        children: [
          // ===================================================================
          // CABECERA
          // ===================================================================
          _ItemHeader(
            item: item,
            expanded: expanded,
            color: color,
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
            onImageTap: item.hasImage
                ? () {
                    ItemImageViewer.show(context, item);
                  }
                : null,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
            onExport: widget.onExport,
            onSaveToLibrary: widget.onSaveToLibrary,
            onQuickQuantityEdit: widget.onQuickQuantityEdit,
          ),

          // ===================================================================
          // CONTENIDO DESPLEGABLE
          // ===================================================================
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _ItemExpandedContent(
              item: item,
              character: widget.character,
              onEquip: widget.onEquip,
              onWeaponAttack: widget.onWeaponAttack,
              onWeaponDamage: widget.onWeaponDamage,
              onConsumableUse: widget.onConsumableUse,
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

class _ItemHeader extends StatelessWidget {
  final CharacterItem item;

  final bool expanded;

  final Color color;

  final VoidCallback onTap;

  final VoidCallback? onImageTap;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onExport;
  final VoidCallback onSaveToLibrary;
  final VoidCallback? onQuickQuantityEdit;

  const _ItemHeader({
    required this.item,
    required this.expanded,
    required this.color,
    required this.onTap,
    required this.onImageTap,
    required this.onEdit,
    required this.onDelete,
    required this.onExport,
    required this.onSaveToLibrary,
    this.onQuickQuantityEdit,
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
            // IMAGEN
            // =================================================================
            ItemImage(item: item, size: 62, onTap: onImageTap),

            const SizedBox(width: 12),

            // =================================================================
            // INFORMACIÓN
            // =================================================================
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

                  const SizedBox(height: 5),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // =======================================================
                      // TIPO
                      // =======================================================
                      InfoBadge(
                        icon: ItemTypeColors.icon(item.type),
                        text: item.type.label,
                        color: color,
                        highlighted: true,
                      ),

                      // =======================================================
                      // CANTIDAD
                      // =======================================================
                      if (item.quantity > 1 || item.calculable)
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: item.calculable
                              ? onQuickQuantityEdit
                              : null,
                          child: InfoBadge(
                            icon: Icons.layers_rounded,
                            text: 'x${item.quantity}',
                            color: item.calculable
                                ? color
                                : null,
                            highlighted: item.calculable,
                          ),
                        ),

                      // =======================================================
                      // EQUIPADO
                      // =======================================================
                      if (item.equipped)
                        InfoBadge(
                          icon: Icons.check_circle_rounded,
                          text: 'Equipado',
                          color: color,
                          highlighted: true,
                        ),

                      // =======================================================
                      // PASIVAS
                      // =======================================================
                      if (item.passives.isNotEmpty)
                        InfoBadge(
                          icon: Icons.auto_awesome_rounded,
                          text: '${item.passives.length}',
                        ),

                      // =======================================================
                      // HABILIDADES
                      // =======================================================
                      if (item.abilities.isNotEmpty)
                        InfoBadge(
                          icon: Icons.flash_on_rounded,
                          text: '${item.abilities.length}',
                        ),
                    ],
                  ),

                  // ===========================================================
                  // DESCRIPCIÓN
                  // ===========================================================
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 8),

                    Text(
                      item.description,
                      maxLines: expanded ? null : 2,
                      overflow: expanded ? null : TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 4),

            // =================================================================
            // ACCIONES
            // =================================================================
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PopupMenuButton<String>(
                  tooltip: 'Opciones',
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;

                      case 'library':
                        onSaveToLibrary();
                        break;

                      case 'export':
                        onExport();
                        break;

                      case 'delete':
                        onDelete();
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
                        value: 'library',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.library_add_rounded),
                          title: Text('Guardar en biblioteca'),
                        ),
                      ),

                      PopupMenuItem(
                        value: 'export',
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

                // =============================================================
                // FLECHA
                // =============================================================
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
}

// =============================================================================
// CONTENIDO DESPLEGADO
// =============================================================================

class _ItemExpandedContent extends StatelessWidget {
  final CharacterItem item;

  final Character character;

  final VoidCallback onEquip;

  final VoidCallback? onWeaponAttack;
  final VoidCallback? onWeaponDamage;
  final VoidCallback? onConsumableUse;

  const _ItemExpandedContent({
    required this.item,
    required this.character,
    required this.onEquip,
    this.onWeaponAttack,
    this.onWeaponDamage,
    this.onConsumableUse,
  });

  CharacterItem? _findCostItem(String templateId) {
    for (final candidate in character.items) {
      final key = candidate.templateId.trim().isNotEmpty
          ? candidate.templateId
          : candidate.id;

      if (key == templateId) {
        return candidate;
      }
    }

    return null;
  }

  int _availableQuantity(String templateId) {
    var total = 0;

    for (final candidate in character.items) {
      final key = candidate.templateId.trim().isNotEmpty
          ? candidate.templateId
          : candidate.id;

      if (key == templateId) {
        total += candidate.quantity;
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = ItemTypeColors.color(item.type);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),

          // ===========================================================================
          // INFORMACIÓN DEL ARMA
          // ===========================================================================
          if (item.type == ItemType.weapon) ...[
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Color.lerp(theme.colorScheme.surface, color, 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color.lerp(theme.colorScheme.surface, color, 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.gavel_rounded, color: color),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Arma',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 3),

                        if (item.weapon != null)
                          ...item.weapon!.damages.map(
                            (damage) => Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                '${damage.diceNotation} ${damage.damageType}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          // ===================================================================
          // INFORMACIÓN DE ARMADURA
          // ===================================================================
          if (item.type == ItemType.armor && item.armorCategory != null) ...[
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Color.lerp(theme.colorScheme.surface, color, 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color.lerp(theme.colorScheme.surface, color, 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.shield_rounded, color: color),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Armadura ${item.armorCategory!.label.toLowerCase()}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          'CA base ${item.armorBaseClass}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ===========================================================================
          // INFORMACIÓN DEL CONSUMIBLE
          // ===========================================================================
          if (item.type == ItemType.consumable && item.consumable != null) ...[
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Color.lerp(theme.colorScheme.surface, color, 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.20)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color.lerp(theme.colorScheme.surface, color, 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.science_rounded, color: color),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consumible',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          '${item.quantity} ${item.quantity == 1 ? 'unidad' : 'unidades'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),

                        if (item.consumable!.effects.isNotEmpty) ...[
                          const SizedBox(height: 8),

                          ...item.consumable!.effects.map((effect) {
                            final pieces = <String>[];

                            if (effect.diceNotation.isNotEmpty) {
                              pieces.add(effect.diceNotation);
                            }

                            for (final entry
                                in effect.abilityModifierMultipliers.entries) {
                              if (entry.value == 0) {
                                continue;
                              }

                              if (entry.value == 1) {
                                pieces.add(entry.key.shortLabel);
                              } else {
                                pieces.add(
                                  '${entry.value}×${entry.key.shortLabel}',
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
                                ? effect.effectType.label
                                : pieces.join(' + ');

                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    effect.heals
                                        ? Icons.favorite_rounded
                                        : Icons.bolt_rounded,
                                    size: 17,
                                    color: color,
                                  ),

                                  const SizedBox(width: 6),

                                  Expanded(
                                    child: Text(
                                      effect.effectTypeName.isNotEmpty
                                          ? '$formula · ${effect.effectTypeName}'
                                          : formula,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
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
                  ),
                ],
              ),
            ),
          ],

          // ===========================================================================
          // CALCULADORA
          // ===========================================================================
          if (item.calculable && item.calculationCosts.isNotEmpty) ...[
            const SizedBox(height: 16),

            _CalculationPreview(item: item, character: character),
          ],

          // ===========================================================================
          // ACCIONES DEL ARMA
          // ===========================================================================
          if (item.isWeapon &&
              item.equipped &&
              (onWeaponAttack != null || onWeaponDamage != null)) ...[
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onWeaponAttack,
                    icon: const Icon(Icons.gps_fixed_rounded),
                    label: const Text('Atacar'),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onWeaponDamage,
                    icon: const Icon(Icons.casino_rounded),
                    label: const Text('Daño'),
                  ),
                ),
              ],
            ),
          ],

          // ===========================================================================
          // ACCIONES DEL CONSUMIBLE
          // ===========================================================================
          if (item.type == ItemType.consumable &&
              item.consumable != null &&
              onConsumableUse != null) ...[
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: item.quantity > 0 ? onConsumableUse : null,

                icon: const Icon(Icons.science_rounded),

                label: Text(
                  item.quantity <= 0
                      ? 'Agotado'
                      : item.consumable!.useText.trim().isNotEmpty
                      ? item.consumable!.useText
                      : 'Usar',
                ),
              ),
            ),
          ],

          // ===================================================================
          // PASIVAS
          // ===================================================================
          if (item.passives.isNotEmpty) ...[
            const SizedBox(height: 18),

            SectionHeader(
              icon: Icons.auto_awesome_rounded,
              title: item.passives.length == 1 ? 'Pasiva' : 'Pasivas',
              subtitle: 'Bonificaciones mientras el objeto esté equipado',
            ),

            const SizedBox(height: 10),

            ...item.passives.map(
              (passive) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ItemPassivePreview(passive: passive),
              ),
            ),
          ],

          // ===================================================================
          // HABILIDADES
          // ===================================================================
          if (item.abilities.isNotEmpty) ...[
            const SizedBox(height: 18),

            SectionHeader(
              icon: Icons.flash_on_rounded,
              title: item.abilities.length == 1 ? 'Habilidad' : 'Habilidades',
              subtitle: 'Disponibles mientras el objeto esté equipado',
            ),

            const SizedBox(height: 10),

            ...item.abilities.map(
              (ability) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ItemAbilityPreview(ability: ability),
              ),
            ),
          ],

          // ===================================================================
          // NOTAS
          // ===================================================================
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 14),

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),

                  const SizedBox(width: 8),

                  Expanded(child: Text(item.notes)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // ===========================================================================
          // EQUIPAR
          // ===========================================================================
          if (item.type.isEquipable) ...[
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: item.equipped
                  ? FilledButton.tonalIcon(
                      onPressed: onEquip,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Equipado · Desequipar'),
                    )
                  : FilledButton.icon(
                      onPressed: onEquip,
                      icon: const Icon(Icons.inventory_2_rounded),
                      label: const Text('Equipar'),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CalculationPreview extends StatelessWidget {
  final CharacterItem item;

  final Character character;

  const _CalculationPreview({required this.item, required this.character});

  CharacterItem? _findItem(String templateId) {
    for (final candidate in character.items) {
      final key = candidate.templateId.trim().isNotEmpty
          ? candidate.templateId
          : candidate.id;

      if (key == templateId) {
        return candidate;
      }
    }

    return null;
  }

  int _available(String templateId) {
    var total = 0;

    for (final candidate in character.items) {
      final key = candidate.templateId.trim().isNotEmpty
          ? candidate.templateId
          : candidate.id;

      if (key == templateId) {
        total += candidate.quantity;
      }
    }

    return total;
  }

  int get maximum {
    int? result;

    for (final cost in item.calculationCosts) {
      if (cost.quantityPerUnit <= 0) {
        continue;
      }

      final available = _available(cost.itemId);

      final possible = available ~/ cost.quantityPerUnit;

      if (result == null || possible < result) {
        result = possible;
      }
    }

    return result ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = ItemTypeColors.color(item.type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color.lerp(theme.colorScheme.surface, color, 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color.lerp(theme.colorScheme.surface, color, 0.20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calculate_rounded, color: color),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calculadora',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Coste por unidad',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ...item.calculationCosts.map((cost) {
            final costItem = _findItem(cost.itemId);

            final available = _available(cost.itemId);

            final enough = available >= cost.quantityPerUnit;

            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, size: 18),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          costItem?.name ?? 'Objeto no disponible',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),

                        Text(
                          'Tienes $available',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: enough
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '×${cost.quantityPerUnit}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            );
          }),

          const Divider(height: 24),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Puedes obtener',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      '$maximum ${maximum == 1 ? 'unidad' : 'unidades'}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                maximum > 0 ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: maximum > 0 ? color : theme.colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
