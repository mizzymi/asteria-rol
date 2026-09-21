import 'dart:io';

import 'package:flutter/material.dart';

import '../../../services/item_image_service.dart';

class ItemImageSection extends StatelessWidget {
  final String imagePath;

  final ValueChanged<String> onImageChanged;

  const ItemImageSection({
    super.key,
    required this.imagePath,
    required this.onImageChanged,
  });

  Future<void> _selectImage(BuildContext context) async {
    final result = await ItemImageService.pickImage();

    if (result == null) {
      return;
    }

    onImageChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imagen',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 12),

        GestureDetector(
          onTap: () {
            _selectImage(context);
          },
          child: Container(
            width: double.infinity,
            height: 190,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(imagePath), fit: BoxFit.cover),

                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          color: Theme.of(
                            context,
                          ).colorScheme.scrim.withValues(alpha: 0.45),
                          child: Text(
                            'Toca para cambiar la imagen',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onInverseSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        size: 46,
                        color: theme.colorScheme.primary,
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Añadir imagen',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        'Selecciona una imagen de la galería',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
          ),
        ),

        if (hasImage) ...[
          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                onImageChanged('');
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Quitar imagen'),
            ),
          ),
        ],
      ],
    );
  }
}
