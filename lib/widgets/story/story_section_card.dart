import 'package:flutter/material.dart';

import '../common/app_card.dart';
import 'story_colors.dart';

class StorySectionCard extends StatefulWidget {
  final IconData icon;
  final Color color;

  final String title;
  final String value;
  final String emptyText;

  final VoidCallback onEdit;

  const StorySectionCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.emptyText,
    required this.onEdit,
  });

  @override
  State<StorySectionCard> createState() => _StorySectionCardState();
}

class _StorySectionCardState extends State<StorySectionCard> {
  bool expanded = false;

  bool get hasContent => widget.value.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      accentColor: widget.color,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (!hasContent) {
                widget.onEdit();
                return;
              }

              setState(() {
                expanded = !expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: StoryColors.background(
                        context,
                        widget.color,
                        strength: 0.24,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: widget.color),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: widget.color,
                          ),
                        ),

                        const SizedBox(height: 6),

                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            hasContent ? widget.value : widget.emptyText,
                            maxLines: expanded
                                ? null
                                : hasContent
                                ? 3
                                : 2,
                            overflow: expanded ? null : TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.45,
                              color: hasContent
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                              fontStyle: hasContent
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  Column(
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: widget.onEdit,
                        icon: Icon(
                          Icons.edit_rounded,
                          size: 19,
                          color: widget.color,
                        ),
                      ),

                      if (hasContent)
                        AnimatedRotation(
                          turns: expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: widget.color,
                          ),
                        ),
                    ],
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
