import 'package:flutter/material.dart';

import '../../models/journal_entry.dart';

import '../common/app_card.dart';
import '../common/info_badge.dart';

import 'journal_colors.dart';

class JournalEntryCard extends StatefulWidget {
  final JournalEntry entry;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const JournalEntryCard({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<JournalEntryCard> createState() => _JournalEntryCardState();
}

class _JournalEntryCardState extends State<JournalEntryCard> {
  bool expanded = false;

  JournalEntry get entry => widget.entry;

  @override
  Widget build(BuildContext context) {
    final color = JournalColors.color(context, entry.type);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      accentColor: color,
      emphasized: entry.important,
      showAccentBar: entry.important,
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
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: JournalColors.background(
                        context,
                        entry.type,
                        strength: 0.22,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(JournalColors.icon(entry.type), color: color),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),

                            if (entry.important)
                              Icon(Icons.star_rounded, color: color),
                          ],
                        ),

                        const SizedBox(height: 7),

                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            InfoBadge(
                              icon: JournalColors.icon(entry.type),
                              text: entry.type.label,
                              color: color,
                              highlighted: true,
                            ),

                            if (entry.dateText.isNotEmpty)
                              InfoBadge(
                                icon: Icons.calendar_today_rounded,
                                text: entry.dateText,
                              ),

                            if (entry.sessionText.isNotEmpty)
                              InfoBadge(
                                icon: Icons.tag_rounded,
                                text: entry.sessionText,
                              ),
                          ],
                        ),

                        if (entry.content.isNotEmpty) ...[
                          const SizedBox(height: 8),

                          Text(
                            entry.content,
                            maxLines: expanded ? null : 3,
                            overflow: expanded ? null : TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 4),

                  Column(
                    children: [
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              widget.onEdit();
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
            secondChild: _ExpandedContent(
              entry: entry,
              color: color,
              onEdit: widget.onEdit,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedContent extends StatelessWidget {
  final JournalEntry entry;
  final Color color;
  final VoidCallback onEdit;

  const _ExpandedContent({
    required this.entry,
    required this.color,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),

          if (entry.notes.isNotEmpty) ...[
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded, size: 18, color: color),

                  const SizedBox(width: 8),

                  Expanded(child: Text(entry.notes)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Editar entrada'),
            ),
          ),
        ],
      ),
    );
  }
}
