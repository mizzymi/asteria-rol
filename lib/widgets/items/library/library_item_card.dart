import 'package:flutter/material.dart';

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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
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

                            if (item.quantity > 1)
                              InfoBadge(
                                icon: Icons.layers_rounded,
                                text: 'x${item.quantity}',
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
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // ===========================================================
                  // AÑADIR AL PERSONAJE
                  //
                  // Solo aparece en ItemLibraryMode.select
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
