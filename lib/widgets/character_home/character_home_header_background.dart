import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'character_home_background_images.dart';

class CharacterHomeHeaderBackground extends StatelessWidget {
  final double height;

  const CharacterHomeHeaderBackground({
    super.key,
    this.height = 320,
  });

  static final Uint8List _lightBytes = base64Decode(
    characterHomeLightBackgroundBase64,
  );
  static final Uint8List _darkBytes = base64Decode(
    characterHomeDarkBackgroundBase64,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final fadeColor = isDark
        ? (Color.lerp(colors.surface, colors.primary, 0.18) ?? colors.surface)
        : colors.surface;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            isDark ? _darkBytes : _lightBytes,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.56, 0.82, 1.0],
                colors: [
                  colors.surface.withValues(alpha: 0.02),
                  fadeColor.withValues(alpha: 0.10),
                  fadeColor.withValues(alpha: 0.72),
                  fadeColor,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
