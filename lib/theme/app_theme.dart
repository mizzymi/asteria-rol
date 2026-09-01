import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // ===========================================================================
  // PALETA BASE
  // ===========================================================================

  static const Color primary = Color(0xFF9B6CE8);

  static const Color secondary = Color(0xFF4D8FE8);

  static const Color tertiary = Color(0xFFE45AA7);

  static const Color success = Color(0xFF55B96B);

  static const Color warning = Color(0xFFF29E4C);

  static const Color danger = Color(0xFFE85D68);

  static const Color info = Color(0xFF42B8C8);

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
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,

        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),

        iconTheme: IconThemeData(color: scheme.onSurface),

        actionsIconTheme: IconThemeData(color: scheme.onSurface),
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
        surfaceTintColor: Colors.transparent,

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
        surfaceTintColor: Colors.transparent,
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

        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,

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
          foregroundColor: scheme.onSurface,
          backgroundColor: scheme.surfaceContainerHigh,

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
          foregroundColor: scheme.onSurface,
          backgroundColor: scheme.surfaceContainerLow,
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
        iconColor: scheme.onSurfaceVariant,

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
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          secondary: secondary,
          tertiary: tertiary,

          surface: const Color(0xFFFFFBFF),

          surfaceContainerLowest: const Color(0xFFFFFFFF),

          surfaceContainerLow: const Color(0xFFFFF7FF),

          surfaceContainer: const Color(0xFFF9F2FF),

          surfaceContainerHigh: const Color(0xFFF4EBFF),

          surfaceContainerHighest: const Color(0xFFEFE4FA),

          onSurface: const Color(0xFF1E1A22),

          onSurfaceVariant: const Color(0xFF6C6371),

          outline: const Color(0xFFC8BBD6),

          outlineVariant: const Color(0xFFE5DAEE),

          error: danger,
        );

    return _buildTheme(scheme: scheme, brightness: Brightness.light);
  }

  // ===========================================================================
  // DARK
  //
  // Ya lo dejamos preparado aunque todavía no lo actives.
  // ===========================================================================

  static ThemeData get dark {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFFC9A9FF),
          secondary: const Color(0xFF9AB7FF),
          tertiary: const Color(0xFFFF9ED2),

          surface: const Color(0xFF151218),

          surfaceContainerLowest: const Color(0xFF100D12),

          surfaceContainerLow: const Color(0xFF1C1820),

          surfaceContainer: const Color(0xFF231E28),

          surfaceContainerHigh: const Color(0xFF2A2430),

          surfaceContainerHighest: const Color(0xFF332C3A),

          onSurface: const Color(0xFFF4EDF7),

          onSurfaceVariant: const Color(0xFFD1C5D6),

          outline: const Color(0xFF8C7F92),

          outlineVariant: const Color(0xFF4B424F),

          error: const Color(0xFFFF8A95),
        );

    return _buildTheme(scheme: scheme, brightness: Brightness.dark);
  }
}
