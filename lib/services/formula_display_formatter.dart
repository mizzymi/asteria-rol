import '../models/character.dart';

class FormulaDisplayFormatter {
  const FormulaDisplayFormatter._();

  static String format(String expression, Character? character) {
    if (character == null || expression.trim().isEmpty) {
      return expression;
    }

    var result = expression;

    // =========================================================================
    // CONTADORES
    // =========================================================================

    for (final counter in character.counters) {
      result = result.replaceAll(
        'counter(${counter.id})',
        'counter(${counter.name})',
      );
    }

    // =========================================================================
    // RECURSOS
    // =========================================================================

    for (final resource in character.resources) {
      result = result
          .replaceAll('resource(${resource.id})', 'resource(${resource.name})')
          .replaceAll(
            'resourceMax(${resource.id})',
            'resourceMax(${resource.name})',
          )
          .replaceAll(
            'resourcePercent(${resource.id})',
            'resourcePercent(${resource.name})',
          )
          .replaceAll(
            'resourceBase(${resource.id})',
            'resourceBase(${resource.name})',
          )
          .replaceAll(
            'resourceBaseMax(${resource.id})',
            'resourceBaseMax(${resource.name})',
          )
          .replaceAll(
            'resourceBasePercent(${resource.id})',
            'resourceBasePercent(${resource.name})',
          );
    }

    return result;
  }
}
