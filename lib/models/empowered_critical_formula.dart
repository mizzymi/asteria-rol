class EmpoweredCriticalFormula {
  static const String defaultExpression = '(MAX + MOD) * 2';

  static bool needsRoll(String expression) {
    final upper = expression.toUpperCase();
    return upper.contains('TIRADA') || upper.contains('ROLL');
  }

  static int evaluate(
    String expression, {
    required int roll,
    required int max,
    required int modifier,
    required int turn,
    Map<String, double> resources = const {},
    Map<String, double> resourceMaximums = const {},
    Map<String, double> counters = const {},
    int charges = 0,
    int maxCharges = 0,
  }) {
    var normalized = expression
        .toUpperCase()
        .replaceAll('DAÑO MÁXIMO', 'MAX')
        .replaceAll('DANO MAXIMO', 'MAX')
        .replaceAll('DAÑO MAX', 'MAX')
        .replaceAll('DANO MAX', 'MAX')
        .replaceAll('MAX_DADOS', 'MAX')
        .replaceAll('DADOS_MAX', 'MAX')
        .replaceAll('ROLL', 'TIRADA')
        .replaceAll('MODIFICADOR', 'MOD')
        .replaceAll('TURNO_ACTUAL', 'TURNO')
        .replaceAll('MAX_CARGAS', 'CARGAS_MAX')
        .replaceAll('CHARGES_MAX', 'CARGAS_MAX')
        .replaceAll('CHARGES', 'CARGAS')
        .replaceAll('×', '*');

    normalized = _replaceLookupFunctions(
      normalized,
      resources: resources,
      resourceMaximums: resourceMaximums,
      counters: counters,
    );

    try {
      final parser = _CriticalFormulaParser(
        normalized,
        variables: {
          'TIRADA': roll.toDouble(),
          'MAX': max.toDouble(),
          'MOD': modifier.toDouble(),
          'TURNO': (turn <= 0 ? 1 : turn).toDouble(),
          'CARGAS': charges.toDouble(),
          'CARGAS_MAX': maxCharges.toDouble(),
        },
      );
      final value = parser.parse();
      if (!value.isFinite) return 0;
      return value.round();
    } catch (_) {
      return max + modifier;
    }
  }

  static String _replaceLookupFunctions(
    String source, {
    required Map<String, double> resources,
    required Map<String, double> resourceMaximums,
    required Map<String, double> counters,
  }) {
    var result = source;

    result = _replaceNamedLookup(
      result,
      functionNames: const ['RECURSO_MAX', 'RESOURCE_MAX'],
      values: resourceMaximums,
    );
    result = _replaceNamedLookup(
      result,
      functionNames: const ['RECURSO', 'RESOURCE'],
      values: resources,
    );
    result = _replaceNamedLookup(
      result,
      functionNames: const ['CONTADOR', 'COUNTER'],
      values: counters,
    );

    return result;
  }

  static String _replaceNamedLookup(
    String source, {
    required List<String> functionNames,
    required Map<String, double> values,
  }) {
    var result = source;
    final normalizedValues = <String, double>{
      for (final entry in values.entries)
        _normalizeLookupKey(entry.key): entry.value,
    };

    for (final functionName in functionNames) {
      final pattern = RegExp(
        '$functionName\\s*\\(\\s*(?:["\']([^"\']+)["\']|([^\\)]+))\\s*\\)',
        caseSensitive: false,
      );

      result = result.replaceAllMapped(pattern, (match) {
        final rawKey = (match.group(1) ?? match.group(2) ?? '').trim();
        final value = normalizedValues[_normalizeLookupKey(rawKey)] ?? 0;
        return value.toString();
      });
    }

    return result;
  }

  static String _normalizeLookupKey(String value) {
    return value.trim().toLowerCase();
  }
}

class _CriticalFormulaParser {
  final String source;
  final Map<String, double> variables;
  int index = 0;

  _CriticalFormulaParser(this.source, {required this.variables});

  double parse() {
    final value = _expression();
    _spaces();
    if (index != source.length) throw const FormatException('Fórmula inválida');
    return value;
  }

  double _expression() {
    var value = _term();
    while (true) {
      _spaces();
      if (_eat('+')) {
        value += _term();
      } else if (_eat('-')) {
        value -= _term();
      } else {
        return value;
      }
    }
  }

  double _term() {
    var value = _factor();
    while (true) {
      _spaces();
      if (_eat('*')) {
        value *= _factor();
      } else if (_eat('/')) {
        final divisor = _factor();
        if (divisor == 0) throw const FormatException('División por cero');
        value /= divisor;
      } else {
        return value;
      }
    }
  }

  double _factor() {
    _spaces();
    if (_eat('+')) return _factor();
    if (_eat('-')) return -_factor();
    if (_eat('(')) {
      final value = _expression();
      _spaces();
      if (!_eat(')')) throw const FormatException('Falta )');
      return value;
    }

    if (index < source.length && _isLetter(source.codeUnitAt(index))) {
      final start = index;
      while (index < source.length &&
          (_isLetter(source.codeUnitAt(index)) ||
              source.codeUnitAt(index) == 95)) {
        index++;
      }
      final name = source.substring(start, index);
      final value = variables[name];
      if (value == null) throw FormatException('Variable desconocida: $name');
      return value;
    }

    final start = index;
    while (index < source.length) {
      final c = source.codeUnitAt(index);
      if ((c >= 48 && c <= 57) || c == 46 || c == 44) {
        index++;
      } else {
        break;
      }
    }
    if (start == index) throw const FormatException('Número esperado');
    return double.parse(source.substring(start, index).replaceAll(',', '.'));
  }

  bool _eat(String token) {
    if (index < source.length && source[index] == token) {
      index++;
      return true;
    }
    return false;
  }

  void _spaces() {
    while (index < source.length && source[index].trim().isEmpty) {
      index++;
    }
  }

  bool _isLetter(int c) => (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
}
