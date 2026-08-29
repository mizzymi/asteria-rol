import 'package:flutter/material.dart';

class ActionDialogScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  final Widget child;

  final String primaryLabel;
  final VoidCallback? onPrimary;

  final String secondaryLabel;
  final VoidCallback? onSecondary;

  final double maxWidth;
  final double maxHeight;

  const ActionDialogScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.subtitle,
    this.secondaryLabel = 'Cancelar',
    this.onSecondary,
    this.maxWidth = 600,
    this.maxHeight = 760,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 10, 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: theme.colorScheme.primary),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        if (subtitle?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 2),

                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: onSecondary,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),

            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSecondary,
                      child: Text(secondaryLabel),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onPrimary,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(primaryLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
