import 'character_effect.dart';
import 'action_hit_behavior.dart';

enum ActionLinkedEffectTarget {
  /// Se aplica al objetivo normal de la acción.
  actionTarget,

  /// Se aplica únicamente al personaje que ejecuta la acción.
  self,

  /// Se aplica únicamente a objetivos externos.
  externalTargets,
}

// =============================================================================
// COMPORTAMIENTO ANTE SALVACIÓN
// =============================================================================

enum ActionLinkedEffectSaveBehavior {
  /// El efecto vinculado ignora completamente la salvación.
  ///
  /// Útil para:
  /// - buffs sobre uno mismo
  /// - efectos que ocurren igualmente
  ignore,

  /// Sigue el resultado definido por el AbilityEffect asociado.
  ///
  /// Si la salvación tiene:
  ///
  /// full -> aplica
  /// half -> aplica
  /// none -> no aplica
  followSource,

  /// Si el objetivo supera la salvación, el efecto NO se aplica,
  /// independientemente de que el daño sea full / half / none.
  ///
  /// Útil para:
  ///
  /// "TS DES:
  ///  éxito -> mitad de daño pero NO queda derribado"
  preventOnSuccess,
}

extension ActionLinkedEffectTargetData on ActionLinkedEffectTarget {
  String get label {
    switch (this) {
      case ActionLinkedEffectTarget.actionTarget:
        return 'Objetivo de la acción';

      case ActionLinkedEffectTarget.self:
        return 'Uno mismo';

      case ActionLinkedEffectTarget.externalTargets:
        return 'Objetivos externos';
    }
  }

  String get description {
    switch (this) {
      case ActionLinkedEffectTarget.actionTarget:
        return 'Sigue los objetivos normales de la acción.';

      case ActionLinkedEffectTarget.self:
        return 'Se aplica al personaje que ejecuta la acción.';

      case ActionLinkedEffectTarget.externalTargets:
        return 'Solo se aplica a enemigos u otros objetivos externos.';
    }
  }
}

extension ActionLinkedEffectSaveBehaviorData on ActionLinkedEffectSaveBehavior {
  String get label {
    switch (this) {
      case ActionLinkedEffectSaveBehavior.ignore:
        return 'Ignorar salvación';

      case ActionLinkedEffectSaveBehavior.followSource:
        return 'Seguir resultado de salvación';

      case ActionLinkedEffectSaveBehavior.preventOnSuccess:
        return 'No aplicar si supera la salvación';
    }
  }

  String get description {
    switch (this) {
      case ActionLinkedEffectSaveBehavior.ignore:
        return 'El efecto se aplica aunque el objetivo supere la salvación.';

      case ActionLinkedEffectSaveBehavior.followSource:
        return 'Solo se evita si la salvación asociada indica que no hay efecto.';

      case ActionLinkedEffectSaveBehavior.preventOnSuccess:
        return 'Cualquier salvación exitosa impide aplicar este efecto.';
    }
  }
}

class ActionLinkedEffect {
  /// Plantilla que se instanciará al resolver la acción.
  CharacterEffect effect;

  /// A quién se aplica.
  ActionLinkedEffectTarget target;

  /// Comportamiento explícito respecto al hit/miss.
  ///
  /// Es nullable únicamente por compatibilidad con datos anteriores.
  ///
  /// Cuando es null:
  /// - self ignora hit/miss.
  /// - actionTarget y externalTargets requieren hit.
  ///
  /// Esto reproduce exactamente el comportamiento histórico.
  ActionHitBehavior? hitBehavior;

  /// ID del AbilityEffect que origina este efecto vinculado.
  ///
  /// Ejemplo:
  ///
  /// ability.effects:
  ///
  /// - fuego
  /// - veneno
  ///
  /// linkedEffect:
  ///
  /// "Envenenado"
  /// sourceEffectId = veneno.id
  ///
  /// Así una salvación del efecto fuego no puede cancelar Envenenado.
  ///
  /// null significa que el efecto vinculado no está asociado
  /// explícitamente a ningún AbilityEffect.
  String? sourceEffectId;

  /// Cómo debe reaccionar ante una salvación exitosa.
  ActionLinkedEffectSaveBehavior saveBehavior;

  ActionLinkedEffect({
    required this.effect,
    this.target = ActionLinkedEffectTarget.actionTarget,
    this.hitBehavior,
    this.sourceEffectId,
    this.saveBehavior = ActionLinkedEffectSaveBehavior.followSource,
  });

  // ===========================================================================
  // SOURCE
  // ===========================================================================

  bool get hasSourceEffect {
    return sourceEffectId?.trim().isNotEmpty == true;
  }

  String? get normalizedSourceEffectId {
    final value = sourceEffectId?.trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  ActionHitBehavior get effectiveHitBehavior {
    final explicit = hitBehavior;

    if (explicit != null) {
      return explicit;
    }

    switch (target) {
      case ActionLinkedEffectTarget.self:
        return ActionHitBehavior.ignoreHit;

      case ActionLinkedEffectTarget.actionTarget:
      case ActionLinkedEffectTarget.externalTargets:
        return ActionHitBehavior.requireHit;
    }
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'effect': effect.toMap(),
      'target': target.name,
      'hitBehavior': hitBehavior?.name,
      'sourceEffectId': sourceEffectId,
      'saveBehavior': saveBehavior.name,
    };
  }

  factory ActionLinkedEffect.fromMap(Map<dynamic, dynamic> map) {
    final rawEffect = map['effect'];

    if (rawEffect is! Map) {
      throw const FormatException('ActionLinkedEffect sin efecto válido.');
    }

    return ActionLinkedEffect(
      effect: CharacterEffect.fromMap(Map<dynamic, dynamic>.from(rawEffect)),

      target: ActionLinkedEffectTarget.values.firstWhere(
        (value) => value.name == map['target']?.toString(),
        orElse: () => ActionLinkedEffectTarget.actionTarget,
      ),

      hitBehavior: _hitBehaviorFromMap(map['hitBehavior']),

      sourceEffectId: map['sourceEffectId']?.toString(),

      saveBehavior: ActionLinkedEffectSaveBehavior.values.firstWhere(
        (value) => value.name == map['saveBehavior']?.toString(),
        // Compatibilidad con datos anteriores.
        orElse: () => ActionLinkedEffectSaveBehavior.followSource,
      ),
    );
  }
}

ActionHitBehavior? _hitBehaviorFromMap(dynamic rawValue) {
  final stored = rawValue?.toString();

  if (stored == null || stored.isEmpty) {
    return null;
  }

  for (final value in ActionHitBehavior.values) {
    if (value.name == stored) {
      return value;
    }
  }

  return null;
}