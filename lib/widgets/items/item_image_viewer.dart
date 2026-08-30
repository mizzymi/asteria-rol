import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/item.dart';

class ItemImageViewer extends StatelessWidget {
  final CharacterItem item;

  const ItemImageViewer({super.key, required this.item});

  static Future<void> show(BuildContext context, CharacterItem item) {
    if (item.imagePath.isEmpty) {
      return Future.value();
    }

    return Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        pageBuilder: (_, _, _) {
          return ItemImageViewer(item: item);
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
                      tag: 'item-image-${item.id}',
                      child: Image.file(
                        File(item.imagePath),
                        fit: BoxFit.contain,
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
                item.name,
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
