import 'character_effect.dart';

class ActionEffectResult {
  /// Plantilla del efecto definida en la habilidad.
  ///
  /// No debe añadirse directamente al Character porque su ID pertenece
  /// a la definición, no a la instancia aplicada.
  final CharacterEffect template;

  const ActionEffectResult({required this.template});

  String get name => template.name;

  String get description => template.description;
}
