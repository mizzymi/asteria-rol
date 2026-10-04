import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AsteriaVisualTheme {
  asteria,
  rainbow,
}

extension AsteriaVisualThemeData on AsteriaVisualTheme {
  String get label {
    switch (this) {
      case AsteriaVisualTheme.asteria:
        return 'Asteria';
      case AsteriaVisualTheme.rainbow:
        return 'Rainbow';
    }
  }

  String get description {
    switch (this) {
      case AsteriaVisualTheme.asteria:
        return 'Tema actual de Asteria, con modo claro y oscuro.';
      case AsteriaVisualTheme.rainbow:
        return 'Cada sección usa un color distinto. Recursos y atributos mantienen sus colores actuales.';
    }
  }
}

class ThemePreferenceService {
  ThemePreferenceService._();

  static const _key = 'asteria_visual_theme';

  static final ValueNotifier<AsteriaVisualTheme> current =
      ValueNotifier<AsteriaVisualTheme>(AsteriaVisualTheme.asteria);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    current.value = AsteriaVisualTheme.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => AsteriaVisualTheme.asteria,
    );
  }

  static Future<void> setTheme(AsteriaVisualTheme theme) async {
    current.value = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, theme.name);
  }
}
