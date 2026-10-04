import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../theme/asteria_semantic_colors.dart';
import 'character_home_background_images.dart';

class CharacterHomeHeaderBackground extends StatelessWidget {
  final double height;

  const CharacterHomeHeaderBackground({super.key, this.height = 320});

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
    final semantic =
        theme.extension<AsteriaSemanticColors>() ??
        AsteriaSemanticColors.asteria(colors);

    final fadeColor = isDark
        ? (Color.lerp(colors.surface, colors.primary, 0.10) ?? colors.surface)
        : colors.surface;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (semantic.isRainbow)
            Image.asset(
              isDark
                  ? 'assets/rainbowthemedark.png'
                  : 'assets/rainbowthemelight.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            )
          else
            Image.memory(
              isDark ? _darkBytes : _lightBytes,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: isDark
                  ? colors.surface.withValues(
                      alpha: semantic.isRainbow ? 0.06 : 0.14,
                    )
                  : colors.surface.withValues(alpha: 0.00),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.28, 0.58, 0.82, 1.0],
                colors: isDark
                    ? [
                        colors.surface.withValues(
                          alpha: semantic.isRainbow ? 0.10 : 0.22,
                        ),
                        colors.surface.withValues(
                          alpha: semantic.isRainbow ? 0.16 : 0.30,
                        ),
                        fadeColor.withValues(
                          alpha: semantic.isRainbow ? 0.42 : 0.54,
                        ),
                        fadeColor.withValues(alpha: 0.88),
                        colors.surface,
                      ]
                    : [
                        colors.surface.withValues(alpha: 0.01),
                        colors.surface.withValues(alpha: 0.02),
                        fadeColor.withValues(
                          alpha: semantic.isRainbow ? 0.06 : 0.10,
                        ),
                        fadeColor.withValues(
                          alpha: semantic.isRainbow ? 0.64 : 0.72,
                        ),
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
