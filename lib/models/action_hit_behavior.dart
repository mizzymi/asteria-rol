enum ActionHitBehavior {
  /// El componente solo puede resolverse si el ataque impacta.
  ///
  /// Si la acción no utiliza tirada de ataque,
  /// este comportamiento no bloquea el componente.
  requireHit,

  /// El componente no depende del resultado hit/miss.
  ignoreHit,
}

extension ActionHitBehaviorData on ActionHitBehavior {
  String get label {
    switch (this) {
      case ActionHitBehavior.requireHit:
        return 'Requiere impacto';

      case ActionHitBehavior.ignoreHit:
        return 'No depende del impacto';
    }
  }

  String get description {
    switch (this) {
      case ActionHitBehavior.requireHit:
        return 'Si la acción utiliza ataque, este componente solo se resuelve al impactar.';

      case ActionHitBehavior.ignoreHit:
        return 'Este componente puede resolverse aunque el ataque falle.';
    }
  }
}
