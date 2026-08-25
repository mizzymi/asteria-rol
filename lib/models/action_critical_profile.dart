enum ActionCriticalType { none, normal, empowered }

class ActionCriticalProfile {
  /// Valor natural mínimo del d20 que produce crítico.
  ///
  /// 20 = solo 20
  /// 19 = 19-20
  /// 18 = 18-20
  final int minimumNaturalRoll;

  /// Crítico independiente de la tirada natural.
  final bool forcedCritical;

  /// Si el crítico de esta acción utiliza la regla potenciada.
  final bool empowered;

  const ActionCriticalProfile({
    this.minimumNaturalRoll = 20,
    this.forcedCritical = false,
    this.empowered = false,
  });

  bool isCriticalRoll(int naturalRoll) {
    if (forcedCritical) {
      return true;
    }

    return naturalRoll >= minimumNaturalRoll;
  }

  ActionCriticalType criticalTypeFor(int naturalRoll) {
    if (!isCriticalRoll(naturalRoll)) {
      return ActionCriticalType.none;
    }

    return empowered ? ActionCriticalType.empowered : ActionCriticalType.normal;
  }

  static int effectiveMinimumRoll(
    Iterable<int> minimumRolls, {
    int baseMinimumRoll = 20,
  }) {
    var result = _normalizeMinimumRoll(baseMinimumRoll);

    for (final value in minimumRolls) {
      final normalized = _normalizeMinimumRoll(value);

      if (normalized < result) {
        result = normalized;
      }
    }

    return result;
  }

  static int _normalizeMinimumRoll(int value) {
    if (value < 1) {
      return 1;
    }

    if (value > 20) {
      return 20;
    }

    return value;
  }
}
