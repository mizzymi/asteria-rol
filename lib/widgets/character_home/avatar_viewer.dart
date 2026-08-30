import 'dart:io';

import 'package:flutter/material.dart';

class AvatarViewer extends StatelessWidget {
  final String imagePath;
  final String heroTag;

  const AvatarViewer({
    super.key,
    required this.imagePath,
    required this.heroTag,
  });

  static Future<void> show(
    BuildContext context, {
    required String imagePath,
    required String heroTag,
  }) {
    final file = File(imagePath);

    if (!file.existsSync()) {
      return Future.value();
    }

    return Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        pageBuilder: (_, _, _) {
          return AvatarViewer(imagePath: imagePath, heroTag: heroTag);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Center(
                  child: Hero(
                    tag: heroTag,
                    child: Image.file(file, fit: BoxFit.contain),
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
          ],
        ),
      ),
    );
  }
}
