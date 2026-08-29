import 'package:flutter/material.dart';

class ActionSectionCard extends StatelessWidget {
  final String? title;
  final String? subtitle;

  final IconData? icon;

  final Widget child;

  final EdgeInsetsGeometry padding;

  const ActionSectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null || icon != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: theme.colorScheme.primary),

                    const SizedBox(width: 8),
                  ],

                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),

              if (subtitle?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 3),

                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: 12),
            ],

            child,
          ],
        ),
      ),
    );
  }
}
