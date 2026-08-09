import 'package:flutter/material.dart';

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

  final VoidCallback onEquip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onExport;
  final VoidCallback onSaveToLibrary;

  const ItemCard({
    super.key,
    required this.item,
    required this.onEquip,
    required this.onEdit,
    required this.onDelete,
    required this.onExport,
    required this.onSaveToLibrary,
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
              onEquip: widget.onEquip,
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
                      if (item.quantity > 1)
                        InfoBadge(
                          icon: Icons.layers_rounded,
                          text: 'x${item.quantity}',
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

  final VoidCallback onEquip;

  const _ItemExpandedContent({required this.item, required this.onEquip});

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

          // ===================================================================
          // EQUIPAR
          // ===================================================================
          if (item.type.isEquipable)
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
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline_rounded, size: 18),
                  SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'Este tipo de objeto no se puede equipar.',
                      textAlign: TextAlign.center,
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
