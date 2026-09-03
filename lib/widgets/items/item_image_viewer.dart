import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/item.dart';

class ItemImageViewer extends StatelessWidget {
  final ItemDefinition definition;

  const ItemImageViewer({super.key, required this.definition});

  static Future<void> show(BuildContext context, ItemDefinition definition) {
    if (definition.imagePath.isEmpty) {
      return Future.value();
    }

    return Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        pageBuilder: (_, _, _) {
          return ItemImageViewer(definition: definition);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: Center(
                    child: Hero(
                      tag: 'item-image-${definition.id}',
                      child: Image.file(
                        File(definition.imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ),

            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Text(
                definition.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
