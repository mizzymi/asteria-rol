import 'dart:math' as math;

import '../models/formulas/character_formula.dart';
import '../models/formulas/formula_result.dart';
import '../models/formulas/formula_context.dart';

class FormulaEvaluator {
  const FormulaEvaluator();

  FormulaResult evaluate(CharacterFormula formula, {FormulaContext? context}) {
    final expression = formula.expression.trim();

    final resolvedContext = context ?? FormulaContext();

    if (expression.isEmpty) {
      return FormulaResult.failure('La fórmula está vacía');
    }

    try {
      final parser = _FormulaParser(expression, resolvedContext);

      final result = parser.parse();

      if (result.isNaN) {
        return FormulaResult.failure(
          'La fórmula produjo un resultado inválido',
        );
      }

      if (result.isInfinite) {
        return FormulaResult.failure('La fórmula produjo un valor infinito');
      }

      return FormulaResult.success(result);
    } on FormulaException catch (error) {
      return FormulaResult.failure(error.message);
    } on FormulaContextException catch (error) {
      return FormulaResult.failure(error.message);
    } catch (_) {
      return FormulaResult.failure('No se pudo calcular la fórmula');
    }
  }
}

// =============================================================================
// EXCEPTION
// =============================================================================

class FormulaException implements Exception {
  final String message;

  const FormulaException(this.message);

  @override
  String toString() {
    return message;
  }
}

// =============================================================================
// PARSER
// =============================================================================

class _FormulaParser {
  final String source;

  final FormulaContext context;

  int position = 0;

  _FormulaParser(this.source, this.context);

  double parse() {
    final result = _parseOr(evaluate: true);

    _skipWhitespace();

    if (!_isAtEnd) {
      throw FormulaException('Símbolo inesperado "$_currentCharacter"');
    }

    return result;
  }

  double _parseVariable(String name) {
    switch (name) {
      case 'true':
        return 1;

      case 'false':
        return 0;
    }

    final value = context.get(name);

    if (value == null) {
      throw FormulaException('Variable desconocida "$name"');
    }

    return value;
  }

  double _parseOr({required bool evaluate}) {
    var left = _parseAnd(evaluate: evaluate);

    while (true) {
      _skipWhitespace();

      if (!_matchKeyword('or')) {
        break;
      }

      final shouldEvaluateRight = evaluate && left == 0;

      final right = _parseAnd(evaluate: shouldEvaluateRight);

      if (evaluate) {
        left = (left != 0 || right != 0) ? 1 : 0;
      }
    }

    return evaluate ? left : 0;
  }

  double _parseAnd({required bool evaluate}) {
    var left = _parseNot(evaluate: evaluate);

    while (true) {
      _skipWhitespace();

      if (!_matchKeyword('and')) {
        break;
      }

      final shouldEvaluateRight = evaluate && left != 0;

      final right = _parseNot(evaluate: shouldEvaluateRight);

      if (evaluate) {
        left = (left != 0 && right != 0) ? 1 : 0;
      }
    }

    return evaluate ? left : 0;
  }

  double _parseNot({required bool evaluate}) {
    _skipWhitespace();

    if (_matchKeyword('not')) {
      final value = _parseNot(evaluate: evaluate);

      if (!evaluate) {
        return 0;
      }

      return value == 0 ? 1 : 0;
    }

    return _parseComparison(evaluate: evaluate);
  }

  double _parseComparison({required bool evaluate}) {
    var left = _parseExpression(evaluate: evaluate);

    while (true) {
      _skipWhitespace();

      if (_matchString('>=')) {
        final right = _parseExpression(evaluate: evaluate);

        if (evaluate) {
          left = left >= right ? 1 : 0;
        }

        continue;
      }

      if (_matchString('<=')) {
        final right = _parseExpression(evaluate: evaluate);

        if (evaluate) {
          left = left <= right ? 1 : 0;
        }

        continue;
      }

      if (_matchString('==')) {
        final right = _parseExpression(evaluate: evaluate);

        if (evaluate) {
          left = left == right ? 1 : 0;
        }

        continue;
      }

      if (_matchString('!=')) {
        final right = _parseExpression(evaluate: evaluate);

        if (evaluate) {
          left = left != right ? 1 : 0;
        }

        continue;
      }

      if (_match('>')) {
        final right = _parseExpression(evaluate: evaluate);

        if (evaluate) {
          left = left > right ? 1 : 0;
        }

        continue;
      }

      if (_match('<')) {
        final right = _parseExpression(evaluate: evaluate);

        if (evaluate) {
          left = left < right ? 1 : 0;
        }

        continue;
      }

      break;
    }

    return evaluate ? left : 0;
  }

  // ===========================================================================
  // EXPRESSION
  //
  // + -
  // ===========================================================================

  double _parseExpression({required bool evaluate}) {
    var value = _parseTerm(evaluate: evaluate);

    while (true) {
      _skipWhitespace();

      if (_match('+')) {
        final right = _parseTerm(evaluate: evaluate);

        if (evaluate) {
          value += right;
        }

        continue;
      }

      if (_match('-')) {
        final right = _parseTerm(evaluate: evaluate);

        if (evaluate) {
          value -= right;
        }

        continue;
      }

      break;
    }

    return evaluate ? value : 0;
  }

  // ===========================================================================
  // TERM
  //
  // * /
  // ===========================================================================

  double _parseTerm({required bool evaluate}) {
    var value = _parseUnary(evaluate: evaluate);

    while (true) {
      _skipWhitespace();

      if (_match('*')) {
        final right = _parseUnary(evaluate: evaluate);

        if (evaluate) {
          value *= right;
        }

        continue;
      }

      if (_match('/')) {
        final divisor = _parseUnary(evaluate: evaluate);

        if (evaluate) {
          if (divisor == 0) {
            throw const FormulaException('No se puede dividir entre 0');
          }

          value /= divisor;
        }

        continue;
      }

      break;
    }

    return evaluate ? value : 0;
  }

  // ===========================================================================
  // UNARY
  //
  // +5
  // -5
  // ===========================================================================

  double _parseUnary({required bool evaluate}) {
    _skipWhitespace();

    if (_match('+')) {
      return _parseUnary(evaluate: evaluate);
    }

    if (_match('-')) {
      final value = _parseUnary(evaluate: evaluate);

      return evaluate ? -value : 0;
    }

    return _parsePrimary(evaluate: evaluate);
  }

  // ===========================================================================
  // PRIMARY
  //
  // números
  // ()
  // funciones
  // ===========================================================================

  double _parsePrimary({required bool evaluate}) {
    _skipWhitespace();

    if (_isAtEnd) {
      throw const FormulaException('La fórmula está incompleta');
    }

    // -------------------------------------------------------------------------
    // PARÉNTESIS
    // -------------------------------------------------------------------------

    if (_match('(')) {
      final value = _parseOr(evaluate: evaluate);

      _skipWhitespace();

      if (!_match(')')) {
        throw const FormulaException('Falta cerrar un paréntesis');
      }

      return evaluate ? value : 0;
    }

    // -------------------------------------------------------------------------
    // NÚMERO
    // -------------------------------------------------------------------------

    if (_isDigit(_currentCharacter) || _currentCharacter == '.') {
      return _parseNumber();
    }

    // -------------------------------------------------------------------------
    // FUNCIÓN
    // -------------------------------------------------------------------------

    if (_isIdentifierStart(_currentCharacter)) {
      final identifier = _parseIdentifier();

      _skipWhitespace();

      // Si después viene "("
      // interpretamos que es una función.

      if (_peek('(')) {
        return _parseFunction(identifier, evaluate: evaluate);
      }

      if (!evaluate) {
        return 0;
      }

      return _parseVariable(identifier);
    }

    throw FormulaException('No se esperaba "$_currentCharacter"');
  }

  // ===========================================================================
  // NUMBER
  // ===========================================================================

  double _parseNumber() {
    final start = position;

    var hasDecimalPoint = false;

    while (!_isAtEnd) {
      final character = _currentCharacter;

      if (_isDigit(character)) {
        position++;
        continue;
      }

      if (character == '.') {
        if (hasDecimalPoint) {
          break;
        }

        hasDecimalPoint = true;
        position++;
        continue;
      }

      break;
    }

    final text = source.substring(start, position);

    final value = double.tryParse(text);

    if (value == null) {
      throw FormulaException('Número inválido "$text"');
    }

    return value;
  }

  // ===========================================================================
  // IDENTIFIER
  // ===========================================================================

  String _parseIdentifier() {
    final start = position;

    while (!_isAtEnd) {
      final character = _currentCharacter;

      if (_isIdentifierPart(character)) {
        position++;
        continue;
      }

      break;
    }

    return source.substring(start, position).toLowerCase();
  }

  // ===========================================================================
  // FUNCTIONS
  // ===========================================================================

  double _parseFunction(String name, {required bool evaluate}) {
    _skipWhitespace();

    if (!_match('(')) {
      throw FormulaException('Se esperaba "(" después de "$name"');
    }

    switch (name) {
      case 'rounddown':
        return _parseSingleArgumentFunction(
          name,
          (value) => value.floorToDouble(),
          evaluate: evaluate,
        );

      case 'roundup':
        return _parseSingleArgumentFunction(
          name,
          (value) => value.ceilToDouble(),
          evaluate: evaluate,
        );

      case 'round':
        return _parseSingleArgumentFunction(
          name,
          (value) => value.roundToDouble(),
          evaluate: evaluate,
        );

      case 'abs':
        return _parseSingleArgumentFunction(
          name,
          (value) => value.abs(),
          evaluate: evaluate,
        );

      case 'min':
        return _parseTwoArgumentFunction(name, math.min, evaluate: evaluate);

      case 'max':
        return _parseTwoArgumentFunction(name, math.max, evaluate: evaluate);

      case 'if':
        return _parseIfFunction(evaluate: evaluate);

      case 'resource':
        return _parseResourceCurrent(evaluate: evaluate);

      case 'resourcemax':
        return _parseResourceMax(evaluate: evaluate);

      case 'resourcepercent':
        return _parseResourcePercent(evaluate: evaluate);

      case 'resourcebase':
        return _parseResourceBaseCurrent(evaluate: evaluate);

      case 'resourcebasemax':
        return _parseResourceBaseMax(evaluate: evaluate);

      case 'resourcebasepercent':
        return _parseResourceBasePercent(evaluate: evaluate);

      case 'counter':
        return _parseCounter(evaluate: evaluate);

      default:
        throw FormulaException('Función desconocida "$name"');
    }
  }

  double _parseCounter({required bool evaluate}) {
    final counterId = _parseIdArgument('counter');

    if (!evaluate) {
      return 0;
    }

    final value = context.getCounter(counterId);

    if (value == null) {
      throw FormulaException('No existe el contador "$counterId"');
    }

    return value;
  }

  String _parseIdArgument(String functionName) {
    _skipWhitespace();

    if (_isAtEnd) {
      throw FormulaException('$functionName necesita un identificador');
    }

    final start = position;

    while (!_isAtEnd) {
      if (_currentCharacter == ')') {
        break;
      }

      position++;
    }

    if (_isAtEnd) {
      throw FormulaException('Falta cerrar $functionName(...)');
    }

    final id = source.substring(start, position).trim();

    if (id.isEmpty) {
      throw FormulaException('$functionName necesita un identificador');
    }

    if (!_match(')')) {
      throw FormulaException('Falta cerrar $functionName(...)');
    }

    return id;
  }

  double _parseIfFunction({required bool evaluate}) {
    final condition = _parseOr(evaluate: evaluate);

    _skipWhitespace();

    if (!_match(',')) {
      throw const FormulaException(
        'if necesita una condición, un valor verdadero y un valor falso',
      );
    }

    final conditionIsTrue = evaluate && condition != 0;

    final whenTrue = _parseOr(evaluate: evaluate && conditionIsTrue);

    _skipWhitespace();

    if (!_match(',')) {
      throw const FormulaException('if necesita tres valores');
    }

    final whenFalse = _parseOr(evaluate: evaluate && !conditionIsTrue);

    _skipWhitespace();

    if (!_match(')')) {
      throw const FormulaException('Falta cerrar if(...)');
    }

    if (!evaluate) {
      return 0;
    }

    return conditionIsTrue ? whenTrue : whenFalse;
  }

  double _parseSingleArgumentFunction(
    String name,
    double Function(double) operation, {
    required bool evaluate,
  }) {
    final value = _parseOr(evaluate: evaluate);

    _skipWhitespace();

    if (!_match(')')) {
      throw FormulaException('Falta cerrar $name(...)');
    }

    if (!evaluate) {
      return 0;
    }

    return operation(value);
  }

  double _parseTwoArgumentFunction(
    String name,
    num Function(num, num) operation, {
    required bool evaluate,
  }) {
    final first = _parseOr(evaluate: evaluate);

    _skipWhitespace();

    if (!_match(',')) {
      throw FormulaException('$name necesita dos valores separados por coma');
    }

    final second = _parseOr(evaluate: evaluate);

    _skipWhitespace();

    if (!_match(')')) {
      throw FormulaException('Falta cerrar $name(...)');
    }

    if (!evaluate) {
      return 0;
    }

    return operation(first, second).toDouble();
  }

  double _parseResourceCurrent({required bool evaluate}) {
    final resourceId = _parseIdArgument('resource');

    if (!evaluate) {
      return 0;
    }

    final resource = context.getResource(resourceId);

    if (resource == null) {
      throw FormulaException('No existe el recurso "$resourceId"');
    }

    return resource.currentValue;
  }

  double _parseResourceMax({required bool evaluate}) {
    final resourceId = _parseIdArgument('resourceMax');

    if (!evaluate) {
      return 0;
    }

    final resource = context.getResource(resourceId);

    if (resource == null) {
      throw FormulaException('No existe el recurso "$resourceId"');
    }

    final maxValue = resource.maxValue;

    if (maxValue == null) {
      throw FormulaException('El recurso "$resourceId" no tiene máximo');
    }

    return maxValue;
  }

  double _parseResourcePercent({required bool evaluate}) {
    final resourceId = _parseIdArgument('resourcePercent');

    if (!evaluate) {
      return 0;
    }

    final resource = context.getResource(resourceId);

    if (resource == null) {
      throw FormulaException('No existe el recurso "$resourceId"');
    }

    final percentage = resource.percentage;

    if (percentage == null) {
      throw FormulaException('El recurso "$resourceId" no tiene máximo');
    }

    return percentage;
  }

  double _parseResourceBaseCurrent({required bool evaluate}) {
    final resourceId = _parseIdArgument('resourceBase');

    if (!evaluate) {
      return 0;
    }

    final resource = context.getBaseResource(resourceId);

    if (resource == null) {
      throw FormulaException('No existe el recurso "$resourceId"');
    }

    return resource.baseCurrentValue;
  }

  double _parseResourceBaseMax({required bool evaluate}) {
    final resourceId = _parseIdArgument('resourceBaseMax');

    if (!evaluate) {
      return 0;
    }

    final resource = context.getBaseResource(resourceId);

    if (resource == null) {
      throw FormulaException('No existe el recurso "$resourceId"');
    }

    final maxValue = resource.baseMaxValue;

    if (maxValue == null) {
      throw FormulaException('El recurso "$resourceId" no tiene máximo');
    }

    return maxValue;
  }

  double _parseResourceBasePercent({required bool evaluate}) {
    final resourceId = _parseIdArgument('resourceBasePercent');

    if (!evaluate) {
      return 0;
    }

    final resource = context.getBaseResource(resourceId);

    if (resource == null) {
      throw FormulaException('No existe el recurso "$resourceId"');
    }

    final percentage = resource.basePercentage;

    if (percentage == null) {
      throw FormulaException('El recurso "$resourceId" no tiene máximo');
    }

    return percentage;
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool get _isAtEnd {
    return position >= source.length;
  }

  String get _currentCharacter {
    if (_isAtEnd) {
      return '';
    }

    return source[position];
  }

  bool _match(String expected) {
    if (_isAtEnd) {
      return false;
    }

    if (source[position] != expected) {
      return false;
    }

    position++;

    return true;
  }

  bool _peek(String expected) {
    if (_isAtEnd) {
      return false;
    }

    return source[position] == expected;
  }

  bool _matchString(String expected) {
    if (position + expected.length > source.length) {
      return false;
    }

    final candidate = source.substring(position, position + expected.length);

    if (candidate != expected) {
      return false;
    }

    position += expected.length;

    return true;
  }

  bool _matchKeyword(String keyword) {
    _skipWhitespace();

    final end = position + keyword.length;

    if (end > source.length) {
      return false;
    }

    final candidate = source.substring(position, end).toLowerCase();

    if (candidate != keyword) {
      return false;
    }

    /*
   * Evita detectar:
   *
   * android
   *
   * como:
   *
   * and
   */
    if (end < source.length) {
      final next = source[end];

      if (_isIdentifierPart(next)) {
        return false;
      }
    }

    if (position > 0) {
      final previous = source[position - 1];

      if (_isIdentifierPart(previous)) {
        return false;
      }
    }

    position = end;

    return true;
  }

  void _skipWhitespace() {
    while (!_isAtEnd) {
      final character = source[position];

      if (character == ' ' ||
          character == '\n' ||
          character == '\t' ||
          character == '\r') {
        position++;
        continue;
      }

      break;
    }
  }

  bool _isDigit(String character) {
    if (character.isEmpty) {
      return false;
    }

    final code = character.codeUnitAt(0);

    return code >= 48 && code <= 57;
  }

  bool _isIdentifierStart(String character) {
    if (character.isEmpty) {
      return false;
    }

    final code = character.codeUnitAt(0);

    final lowercase = code >= 97 && code <= 122;

    final uppercase = code >= 65 && code <= 90;

    return lowercase || uppercase || character == '_';
  }

  bool _isIdentifierPart(String character) {
    return _isIdentifierStart(character) || _isDigit(character);
  }
}
