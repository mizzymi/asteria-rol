import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // La paleta real vive únicamente en el Theme. Los widgets consumen
  // ColorScheme y nunca necesitan conocer valores de color concretos.
  static const Color _purpleSeed = Color(0xFFA855F7);

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

    final primary = isDark
        ? HSLColor.fromColor(base.primary)
              .withSaturation(
                (HSLColor.fromColor(base.primary).saturation + 0.08).clamp(
                  0.0,
                  1.0,
                ),
              )
              .withLightness(
                (HSLColor.fromColor(base.primary).lightness + 0.04).clamp(
                  0.0,
                  1.0,
                ),
              )
              .toColor()
        : base.primary;

    return base.copyWith(
      primary: primary,
      surface: tint(base.surface, 0.050, 0.10),
      surfaceContainerLowest: tint(base.surfaceContainerLowest, 0.060, 0.10),
      surfaceContainerLow: tint(base.surfaceContainerLow, 0.095, 0.14),
      surfaceContainer: tint(base.surfaceContainer, 0.125, 0.18),
      surfaceContainerHigh: tint(base.surfaceContainerHigh, 0.155, 0.22),
      surfaceContainerHighest: tint(base.surfaceContainerHighest, 0.190, 0.26),
      outlineVariant: tint(base.outlineVariant, 0.22, 0.22),
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
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surface.withValues(alpha: 0),
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
        elevation: 0,
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
        surfaceTintColor: scheme.surface.withValues(alpha: 0),

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
        surfaceTintColor: scheme.surface.withValues(alpha: 0),
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

          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      // =========================================================================
      // ICON BUTTON
      // =========================================================================
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.primary,
          backgroundColor: scheme.primaryContainer.withValues(alpha: 0.55),
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
        backgroundColor: scheme.surface,
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
