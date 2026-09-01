import 'action_linked_effect.dart';
import 'character_effect.dart';

class ActionEffectResult {
  /// Definición del vínculo que sobrevivió a la resolución.
  final ActionLinkedEffect linkedEffect;

  const ActionEffectResult({required this.linkedEffect});

  CharacterEffect get template {
    return linkedEffect.effect;
  }

  String get name => template.name;

  String get description => template.description;

  String? get sourceEffectId {
    return linkedEffect.normalizedSourceEffectId;
  }

  ActionLinkedEffectTarget get target {
    return linkedEffect.target;
  }

  ActionLinkedEffectSaveBehavior get saveBehavior {
    return linkedEffect.saveBehavior;
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {'linkedEffect': linkedEffect.toMap()};
  }

  factory ActionEffectResult.fromMap(Map<dynamic, dynamic> map) {
    final rawLinkedEffect = map['linkedEffect'];

    if (rawLinkedEffect is! Map) {
      throw StateError('ActionEffectResult inválido: falta linkedEffect.');
    }

    return ActionEffectResult(
      linkedEffect: ActionLinkedEffect.fromMap(
        Map<dynamic, dynamic>.from(rawLinkedEffect),
      ),
    );
  }
}
