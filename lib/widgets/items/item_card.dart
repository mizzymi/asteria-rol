import 'package:flutter/material.dart';

import '../../utils/number_format.dart';

import '../../models/character.dart';
import '../../models/item.dart';

import '../common/app_card.dart';
import '../common/info_badge.dart';

import 'item_extended_content.dart';
import 'item_image.dart';
import 'item_image_viewer.dart';
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
            secondChild: ItemExtendedContent(
              item: item,
              character: widget.character,
              onEquip: widget.onEquip,
              onWeaponAttack: widget.onWeaponAttack,
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
                      InfoBadge(
                        icon: ItemTypeColors.icon(item.type),
                        text: item.type.label,
                        color: color,
                        highlighted: true,
                      ),

                      if (item.quantity > 1 || item.calculable)
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: item.calculable ? onQuickQuantityEdit : null,
                          child: InfoBadge(
                            icon: Icons.layers_rounded,
                            text: '×${formatThousands(item.quantity)}',
                            color: item.calculable ? color : null,
                            highlighted: item.calculable,
                          ),
                        ),

                      if (item.equipped)
                        InfoBadge(
                          icon: Icons.check_circle_rounded,
                          text: 'Equipado',
                          color: color,
                          highlighted: true,
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
