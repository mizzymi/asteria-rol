import 'dart:io';

import 'package:flutter/material.dart';

class AbilityImageSelector extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onPick;
  final VoidCallback? onRemove;
  final VoidCallback? onAdjustFraming;
  final double alignmentX;
  final double alignmentY;
  final IconData fallbackIcon;
  final String label;

  const AbilityImageSelector({
    super.key,
    required this.imagePath,
    required this.onPick,
    required this.fallbackIcon,
    required this.label,
    this.onRemove,
    this.onAdjustFraming,
    this.alignmentX = 0,
    this.alignmentY = 0,
  });

  bool get _hasImage => imagePath != null && imagePath!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final file = _hasImage ? File(imagePath!) : null;
    final exists = file?.existsSync() ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPick,
            child: AspectRatio(
              aspectRatio: 2.15,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (exists)
                    Image.file(
                      file!,
                      fit: BoxFit.cover,
                      alignment: Alignment(alignmentX, alignmentY),
                    )
                  else
                    Center(
                      child: Icon(
                        fallbackIcon,
                        size: 48,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  if (exists)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: 0),
                            Theme.of(
                              context,
                            ).colorScheme.scrim.withValues(alpha: 0.60),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            exists ? 'Cambiar imagen' : label,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: exists
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onInverseSurface
                                  : colors.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.photo_library_outlined,
                          size: 20,
                          color: exists
                              ? Theme.of(context).colorScheme.onInverseSurface
                              : colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (exists)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onAdjustFraming != null)
                TextButton.icon(
                  onPressed: onAdjustFraming,
                  icon: const Icon(Icons.crop_free_rounded, size: 18),
                  label: const Text('Ajustar encuadre'),
                ),
              if (onRemove != null)
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Quitar imagen'),
                ),
            ],
          ),
      ],
    );
  }
}
