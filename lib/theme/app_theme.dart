import 'package:flutter/material.dart';

import 'accessibility_colors.dart';

class AppTheme {
  const AppTheme._();

  // La paleta real vive únicamente en el Theme. Los widgets consumen
  // ColorScheme y nunca necesitan conocer valores de color concretos.
  static const Color _purpleSeed = Color(0xFFB03CFF);

  static ColorScheme _purpleScheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: _purpleSeed,
      brightness: brightness,
    );

    final isDark = brightness == Brightness.dark;

    Color tint(Color source, double lightAmount, double darkAmount) {
      return Color.lerp(
            source,
            base.primary,
            isDark ? darkAmount : lightAmount,
          ) ??
          source;
    }

    Color boost(
      Color color, {
      double saturation = 0.0,
      double lightness = 0.0,
    }) {
      final hsl = HSLColor.fromColor(color);
      return hsl
          .withSaturation((hsl.saturation + saturation).clamp(0.0, 1.0))
          .withLightness((hsl.lightness + lightness).clamp(0.0, 1.0))
          .toColor();
    }

    final surface = tint(base.surface, 0.045, 0.08);
    final surfaceContainerLowest = tint(
      base.surfaceContainerLowest,
      0.055,
      0.08,
    );
    final surfaceContainerLow = tint(base.surfaceContainerLow, 0.075, 0.10);
    final surfaceContainer = tint(base.surfaceContainer, 0.10, 0.13);
    final surfaceContainerHigh = tint(base.surfaceContainerHigh, 0.125, 0.16);
    final surfaceContainerHighest = tint(
      base.surfaceContainerHighest,
      0.15,
      0.19,
    );

    final surfaces = <Color>[
      surface,
      surfaceContainerLowest,
      surfaceContainerLow,
      surfaceContainer,
      surfaceContainerHigh,
      surfaceContainerHighest,
    ];

    Color readableAccent(Color source) {
      return AccessibilityColors.ensureContrastAgainst(
        source,
        surfaces,
        minimum: 6.2,
      );
    }

    final primary = readableAccent(
      boost(
        base.primary,
        saturation: isDark ? 0.14 : 0.10,
        lightness: isDark ? 0.06 : -0.01,
      ),
    );
    final secondary = readableAccent(
      boost(
        base.secondary,
        saturation: isDark ? 0.12 : 0.08,
        lightness: isDark ? 0.05 : -0.01,
      ),
    );
    final tertiary = readableAccent(
      boost(
        base.tertiary,
        saturation: isDark ? 0.12 : 0.08,
        lightness: isDark ? 0.05 : -0.01,
      ),
    );
    final error = readableAccent(base.error);

    final primaryContainer = tint(base.primaryContainer, 0.18, 0.22);
    final secondaryContainer = tint(base.secondaryContainer, 0.14, 0.18);
    final tertiaryContainer = tint(base.tertiaryContainer, 0.14, 0.18);
    final errorContainer = base.errorContainer;

    final onSurface = AccessibilityColors.ensureContrastAgainst(
      base.onSurface,
      surfaces,
      minimum: 7.0,
    );
    final onSurfaceVariant = AccessibilityColors.ensureContrastAgainst(
      base.onSurfaceVariant,
      surfaces,
      minimum: 5.2,
    );

    return base.copyWith(
      primary: primary,
      onPrimary: AccessibilityColors.ensureContrast(
        base.onPrimary,
        primary,
        minimum: 5.0,
      ),
      primaryContainer: primaryContainer,
      onPrimaryContainer: AccessibilityColors.ensureContrast(
        base.onPrimaryContainer,
        primaryContainer,
        minimum: 5.0,
      ),
      secondary: secondary,
      onSecondary: AccessibilityColors.ensureContrast(
        base.onSecondary,
        secondary,
        minimum: 5.0,
      ),
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: AccessibilityColors.ensureContrast(
        base.onSecondaryContainer,
        secondaryContainer,
        minimum: 5.0,
      ),
      tertiary: tertiary,
      onTertiary: AccessibilityColors.ensureContrast(
        base.onTertiary,
        tertiary,
        minimum: 5.0,
      ),
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: AccessibilityColors.ensureContrast(
        base.onTertiaryContainer,
        tertiaryContainer,
        minimum: 5.0,
      ),
      error: error,
      onError: AccessibilityColors.ensureContrast(
        base.onError,
        error,
        minimum: 5.0,
      ),
      errorContainer: errorContainer,
      onErrorContainer: AccessibilityColors.ensureContrast(
        base.onErrorContainer,
        errorContainer,
        minimum: 5.0,
      ),
      surface: surface,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      inverseSurface: base.inverseSurface,
      onInverseSurface: AccessibilityColors.ensureContrast(
        base.onInverseSurface,
        base.inverseSurface,
        minimum: 7.0,
      ),
      inversePrimary: AccessibilityColors.ensureContrast(
        base.inversePrimary,
        base.inverseSurface,
        minimum: 5.0,
      ),
      outlineVariant: tint(base.outlineVariant, 0.18, 0.18),
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme scheme,
    required Brightness brightness,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,

      scaffoldBackgroundColor: scheme.surface,

      // =========================================================================
      // TEXTO
      // =========================================================================
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w900,
        ),

        displayMedium: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w900,
        ),

        displaySmall: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w900,
        ),

        headlineLarge: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w900,
        ),

        headlineMedium: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w900,
        ),

        headlineSmall: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w900,
        ),

        titleLarge: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
        ),

        titleMedium: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
        ),

        titleSmall: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
        ),

        bodyLarge: TextStyle(color: scheme.onSurface),

        bodyMedium: TextStyle(color: scheme.onSurface),

        bodySmall: TextStyle(color: scheme.onSurfaceVariant),

        labelLarge: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),

        labelMedium: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),

        labelSmall: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),

      // =========================================================================
      // APP BAR
      // =========================================================================
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainerLowest.withValues(
          alpha: brightness == Brightness.dark ? 0.94 : 0.90,
        ),
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.primary.withValues(alpha: 0.04),
        elevation: 0,
        centerTitle: false,

        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),

        iconTheme: IconThemeData(color: scheme.primary),

        actionsIconTheme: IconThemeData(color: scheme.primary),
      ),

      // =========================================================================
      // CARD
      // =========================================================================
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: brightness == Brightness.dark ? 1 : 0,
        margin: EdgeInsets.zero,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      // =========================================================================
      // DIALOG
      // =========================================================================
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.primary.withValues(alpha: 0.04),

        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),

        contentTextStyle: TextStyle(color: scheme.onSurface, fontSize: 14),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      // =========================================================================
      // BOTTOM SHEET
      // =========================================================================
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        surfaceTintColor: scheme.primary.withValues(alpha: 0.04),
        showDragHandle: true,

        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),

      // =========================================================================
      // INPUT
      // =========================================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,

        labelStyle: TextStyle(color: scheme.onSurfaceVariant),

        hintStyle: TextStyle(color: scheme.onSurfaceVariant),

        helperStyle: TextStyle(color: scheme.onSurfaceVariant),

        prefixIconColor: scheme.primary,
        suffixIconColor: scheme.primary,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),

      // =========================================================================
      // FILLED BUTTON
      // =========================================================================
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
          disabledForegroundColor: scheme.onSurfaceVariant,
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          elevation: brightness == Brightness.dark ? 1 : 0,

          minimumSize: const Size(0, 48),

          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      // =========================================================================
      // TONAL BUTTON
      // =========================================================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: scheme.onPrimaryContainer,
          backgroundColor: scheme.primaryContainer,
          disabledForegroundColor: scheme.onSurfaceVariant,
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          elevation: 0,

          textStyle: const TextStyle(fontWeight: FontWeight.w800),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // =========================================================================
      // OUTLINED
      // =========================================================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          disabledForegroundColor: scheme.onSurfaceVariant,

          side: BorderSide(color: scheme.outlineVariant),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      // =========================================================================
      // TEXT BUTTON
      // =========================================================================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          disabledForegroundColor: scheme.onSurfaceVariant,

          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      // =========================================================================
      // ICON BUTTON
      // =========================================================================
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.primary,
          backgroundColor: scheme.primaryContainer.withValues(
            alpha: brightness == Brightness.dark ? 0.78 : 0.72,
          ),
        ),
      ),

      // =========================================================================
      // SEGMENTED BUTTON
      // =========================================================================
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.onSurfaceVariant;
            }
            return states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.primary;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? scheme.primaryContainer
                : scheme.surfaceContainerLow;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),

      // =========================================================================
      // CHIP
      // =========================================================================
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,

        side: BorderSide(color: scheme.outlineVariant),

        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),

        secondaryLabelStyle: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      // =========================================================================
      // LIST TILE
      // =========================================================================
      listTileTheme: ListTileThemeData(
        textColor: scheme.onSurface,
        iconColor: scheme.primary,

        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),

        subtitleTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 14,
        ),
      ),

      // =========================================================================
      // CONTROLES / ACCIONES
      // =========================================================================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest;
        }),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant;
        }),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
        circularTrackColor: scheme.primaryContainer,
      ),

      // =========================================================================
      // DIVIDER
      // =========================================================================
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),

      // =========================================================================
      // NAVIGATION
      // =========================================================================
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,

        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.onPrimaryContainer);
          }

          return IconThemeData(color: scheme.onSurfaceVariant);
        }),

        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          );
        }),
      ),

      // =========================================================================
      // SNACKBAR
      // =========================================================================
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,

        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
    );
  }

  // ===========================================================================
  // LIGHT
  // ===========================================================================

  static ThemeData get light {
    final scheme = _purpleScheme(Brightness.light);
    return _buildTheme(scheme: scheme, brightness: Brightness.light);
  }

  // ===========================================================================
  // DARK
  //
  // Ya lo dejamos preparado aunque todavía no lo actives.
  // ===========================================================================

  static ThemeData get dark {
    final scheme = _purpleScheme(Brightness.dark);
    return _buildTheme(scheme: scheme, brightness: Brightness.dark);
  }
}
