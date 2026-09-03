import 'ability.dart';
import 'action_content.dart';

class Consumable {
  /// Texto mostrado al utilizar el objeto.
  ///
  /// Ejemplos:
  /// - Usar
  /// - Beber
  /// - Comer
  /// - Lanzar
  String useText;

  /// Efectos mecánicos producidos por el consumible.
  ///
  /// IMPORTANTE:
  /// Esto NO convierte al consumible en una CharacterAbility.
  ///
  /// AbilityEffect se reutiliza únicamente como modelo de efecto
  /// mientras terminamos de generalizar los componentes del Action Engine.
  List<AbilityEffect> effects;

  Consumable({this.useText = 'Usar', List<AbilityEffect>? effects})
    : effects = effects ?? [];

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  String get effectiveUseText {
    final value = useText.trim();

    return value.isEmpty ? 'Usar' : value;
  }

  bool get hasEffects {
    return effects.any((effect) => effect.hasEffect);
  }

  bool get isEmpty {
    return !hasEffects;
  }

  bool get dealsDamage {
    return effects.any(
      (effect) => effect.effectType == AbilityEffectType.damage,
    );
  }

  bool get heals {
    return effects.any(
      (effect) => effect.effectType == AbilityEffectType.healing,
    );
  }

  // ===========================================================================
  // ACTION ENGINE
  // ===========================================================================

  /// Convierte el contenido del consumible al formato genérico
  /// entendido por el Action Engine.
  ///
  /// No se crea ninguna CharacterAbility temporal.
  ActionContent toActionContent() {
    return ActionContent(effects: List<AbilityEffect>.unmodifiable(effects));
  }

  // ===========================================================================
  // COPY
  // ===========================================================================

  Consumable copy() {
    return Consumable(
      useText: useText,
      effects: effects
          .map((effect) => AbilityEffect.fromMap(effect.toMap()))
          .toList(),
    );
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'useText': useText,
      'effects': effects.map((effect) => effect.toMap()).toList(),
    };
  }

  factory Consumable.fromMap(Map<dynamic, dynamic> map) {
    final effects = <AbilityEffect>[];

    final rawEffects = map['effects'];

    if (rawEffects is List) {
      for (final rawEffect in rawEffects) {
        if (rawEffect is! Map) {
          continue;
        }

        try {
          effects.add(
            AbilityEffect.fromMap(Map<dynamic, dynamic>.from(rawEffect)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    return Consumable(
      useText: map['useText']?.toString() ?? 'Usar',

      effects: effects,
    );
  }
}
