import 'package:flutter/material.dart';

import '../../theme/accessibility_colors.dart';

class InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  final bool highlighted;

  final Color? color;

  const InfoBadge({
    super.key,
    required this.icon,
    required this.text,
    this.highlighted = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final accent = color ?? theme.colorScheme.primary;

    final background = color != null
        ? Color.lerp(
            theme.colorScheme.surface,
            accent,
            highlighted ? 0.26 : 0.15,
          )!
        : highlighted
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHigh;

    final preferredForeground = color != null
        ? accent
        : highlighted
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    final foreground = AccessibilityColors.ensureContrast(
      preferredForeground,
      background,
      minimum: 5.0,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: color != null
            ? Border.all(color: accent.withValues(alpha: 0.22))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),

          const SizedBox(width: 6),

          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
