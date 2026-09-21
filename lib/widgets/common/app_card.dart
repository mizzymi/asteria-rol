import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;

  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  final VoidCallback? onTap;

  final bool emphasized;

  final Color? accentColor;

  final bool showAccentBar;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.emphasized = false,
    this.accentColor,
    this.showAccentBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final baseAccent = accentColor ?? theme.colorScheme.primary;

    // =========================================================================
    // FONDO
    // =========================================================================

    final backgroundColor = accentColor != null
        ? Color.lerp(
            theme.colorScheme.surface,
            baseAccent,
            emphasized ? 0.18 : 0.10,
          )!
        : emphasized
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
        : theme.colorScheme.surfaceContainerLow;

    // =========================================================================
    // BORDE
    // =========================================================================

    final borderColor = accentColor != null
        ? baseAccent.withValues(alpha: 0.25)
        : emphasized
        ? theme.colorScheme.primary.withValues(alpha: 0.20)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.45);

    // =========================================================================
    // CONTENIDO
    // =========================================================================

    final paddedContent = Padding(padding: padding, child: child);

    Widget content;

    if (showAccentBar && accentColor != null) {
      /*
       * Stack funciona mejor aquí que Row + stretch.
       *
       * El contenido determina la altura real de la tarjeta
       * y la barra simplemente ocupa esa altura.
       */
      content = Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: paddedContent,
          ),

          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: ColoredBox(color: baseAccent),
          ),
        ],
      );
    } else {
      content = paddedContent;
    }

    // =========================================================================
    // CLICK
    // =========================================================================

    final interactiveContent = onTap == null
        ? content
        : Material(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0),
            child: InkWell(onTap: onTap, child: content),
          );

    // =========================================================================
    // CARD
    // =========================================================================

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: interactiveContent,
    );
  }
}
