class FormulaResourceValue {
  final double baseCurrentValue;
  final double? baseMaxValue;

  final double currentValue;
  final double? maxValue;

  const FormulaResourceValue({
    required this.baseCurrentValue,
    required this.baseMaxValue,
    required this.currentValue,
    required this.maxValue,
  });

  bool get hasMaximum {
    return maxValue != null;
  }

  bool get hasBaseMaximum {
    return baseMaxValue != null;
  }

  double? get percentage {
    final max = maxValue;

    if (max == null || max <= 0) {
      return null;
    }

    return (currentValue / max) * 100;
  }

  double? get basePercentage {
    final max = baseMaxValue;

    if (max == null || max <= 0) {
      return null;
    }

    return (baseCurrentValue / max) * 100;
  }
}

typedef FormulaCounterResolver = double? Function(String counterId);

typedef FormulaResourceResolver =
    FormulaResourceValue? Function(String resourceId);

class FormulaContext {
  final Map<String, double> variables;

  /// Recursos que ya han sido resueltos.
  final Map<String, FormulaResourceValue> resources;

  /// Resuelve valores efectivos.
  final FormulaResourceResolver? resourceResolver;

  /// Resuelve exclusivamente valores base.
  final FormulaResourceResolver? baseResourceResolver;

  final Map<String, double> counters;

  final FormulaCounterResolver? counterResolver;

  FormulaContext({
    Map<String, double> variables = const {},
    Map<String, FormulaResourceValue> resources = const {},
    Map<String, double> counters = const {},
    this.resourceResolver,
    this.baseResourceResolver,
    this.counterResolver,
  }) : variables = _normalizeVariables(variables),
       resources = Map<String, FormulaResourceValue>.from(resources),
       counters = Map<String, double>.from(counters);

  bool contains(String name) {
    return variables.containsKey(_normalize(name));
  }

  double? get(String name) {
    return variables[_normalize(name)];
  }

  double? getCounter(String id) {
    final existing = counters[id];

    if (existing != null) {
      return existing;
    }

    return counterResolver?.call(id);
  }

  // ===========================================================================
  // RECURSO EFECTIVO
  // ===========================================================================

  FormulaResourceValue? getResource(String id) {
    final existing = resources[id];

    if (existing != null) {
      return existing;
    }

    return resourceResolver?.call(id);
  }

  FormulaResourceValue? getEffectiveResource(String id) {
    return getResource(id);
  }

  // ===========================================================================
  // RECURSO BASE
  // ===========================================================================

  FormulaResourceValue? getBaseResource(String id) {
    return baseResourceResolver?.call(id);
  }

  // ===========================================================================
  // MERGE
  // ===========================================================================

  FormulaContext merge(Map<String, double> values) {
    final result = Map<String, double>.from(variables);

    for (final entry in values.entries) {
      result[_normalize(entry.key)] = entry.value;
    }

    return FormulaContext(
      variables: result,
      resources: resources,
      counters: counters,
      resourceResolver: resourceResolver,
      baseResourceResolver: baseResourceResolver,
      counterResolver: counterResolver,
    );
  }

  static Map<String, double> _normalizeVariables(Map<String, double> source) {
    return {
      for (final entry in source.entries) _normalize(entry.key): entry.value,
    };
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}

class FormulaResourceSnapshot {
  final double baseCurrentValue;
  final double? baseMaxValue;

  final double currentValue;
  final double? maxValue;

  const FormulaResourceSnapshot({
    required this.baseCurrentValue,
    required this.baseMaxValue,
    required this.currentValue,
    required this.maxValue,
  });
}

class FormulaContextException implements Exception {
  final String message;

  const FormulaContextException(this.message);

  @override
  String toString() {
    return message;
  }
}
