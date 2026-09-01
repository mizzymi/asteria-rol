import '../models/action_external_requirement.dart';

class ActionExternalRequirementParser {
  const ActionExternalRequirementParser();

  // ===========================================================================
  // ENTRY POINT
  // ===========================================================================

  List<ActionExternalRequirement> fromExpression(String expression) {
    final requirements = <ActionExternalRequirement>[];

    final normalized = expression.trim();

    if (normalized.isEmpty) {
      return const [];
    }

    // =========================================================================
    // BOOLEANOS DE TARGET
    // =========================================================================

    void addBooleanIfUsed({
      required String variableName,
      required String label,
    }) {
      if (!_expressionContainsVariable(normalized, variableName)) {
        return;
      }

      requirements.add(
        ActionExternalRequirement.boolean(
          variableName: variableName,
          label: label,
        ),
      );
    }

    addBooleanIfUsed(
      variableName: 'target_wounded',
      label: '¿El objetivo está herido?',
    );

    addBooleanIfUsed(
      variableName: 'target_full_health',
      label: '¿El objetivo está a vida completa?',
    );

    addBooleanIfUsed(
      variableName: 'target_below_half',
      label: '¿El objetivo está por debajo del 50% de vida?',
    );

    addBooleanIfUsed(
      variableName: 'target_at_or_below_half',
      label: '¿El objetivo está al 50% de vida o por debajo?',
    );

    addBooleanIfUsed(
      variableName: 'target_above_half',
      label: '¿El objetivo está por encima del 50% de vida?',
    );

    addBooleanIfUsed(
      variableName: 'target_at_or_above_half',
      label: '¿El objetivo está al 50% de vida o por encima?',
    );

    // -------------------------------------------------------------------------
    // TARGET TYPE
    //
    // Normalmente estas variables ya pueden conocerse directamente a partir
    // de ActionTarget, pero siguen siendo requirements válidos y el contexto
    // podrá resolverlos sin preguntar.
    // -------------------------------------------------------------------------

    addBooleanIfUsed(
      variableName: 'target_is_self',
      label: '¿El objetivo es tu personaje?',
    );

    addBooleanIfUsed(
      variableName: 'target_is_external',
      label: '¿El objetivo es externo?',
    );

    // =========================================================================
    // PORCENTAJE DE VIDA · SINTAXIS DIRECTA
    //
    // Soportamos:
    //
    // target_health_percent < 50
    // target_health_percent <= 50
    // target_health_percent > 50
    // target_health_percent >= 50
    //
    // Y también:
    //
    // target_health_percent_before < 50
    // etc.
    // =========================================================================

    requirements.addAll(
      _extractHealthPercentageRequirements(
        normalized,
        variableName: 'target_health_percent',
      ),
    );

    requirements.addAll(
      _extractHealthPercentageRequirements(
        normalized,
        variableName: 'target_health_percent_before',
      ),
    );

    // =========================================================================
    // PORCENTAJE DE VIDA · SINTAXIS NORMALIZADA
    //
    // Soportamos:
    //
    // target_health_percent_lt_50
    // target_health_percent_lte_50
    // target_health_percent_gt_50
    // target_health_percent_gte_50
    //
    // Y equivalentes con:
    //
    // target_health_percent_before_...
    // =========================================================================

    requirements.addAll(_extractNormalizedHealthRequirements(normalized));

    // =========================================================================
    // DEDUPLICAR
    // =========================================================================

    return ActionExternalRequirementSet(requirements).requirements;
  }

  // ===========================================================================
  // VARIABLE EXACTA
  // ===========================================================================

  bool _expressionContainsVariable(String expression, String variableName) {
    final pattern = RegExp(
      r'(^|[^A-Za-z0-9_])' + RegExp.escape(variableName) + r'([^A-Za-z0-9_]|$)',
    );

    return pattern.hasMatch(expression);
  }

  // ===========================================================================
  // PORCENTAJE NORMALIZADO
  //
  // Ejemplos:
  //
  // target_health_percent_lt_50
  // target_health_percent_lte_50
  // target_health_percent_gt_50
  // target_health_percent_gte_50
  //
  // target_health_percent_before_lt_50
  // ...
  // ===========================================================================

  List<ActionExternalRequirement> _extractNormalizedHealthRequirements(
    String expression,
  ) {
    final result = <ActionExternalRequirement>[];

    final pattern = RegExp(
      r'\b('
      r'target_health_percent'
      r'|target_health_percent_before'
      r')_'
      r'(lt|lte|gt|gte)_'
      r'(\d+(?:\.\d+)?)\b',
      caseSensitive: false,
    );

    for (final match in pattern.allMatches(expression)) {
      final variableName = match.group(1)?.toLowerCase();

      final operatorName = match.group(2)?.toLowerCase();

      final threshold = double.tryParse(match.group(3) ?? '');

      if (variableName == null || operatorName == null || threshold == null) {
        continue;
      }

      final safeThreshold = threshold.clamp(0.0, 100.0).toDouble();

      final thresholdText = _percentageThresholdText(safeThreshold);

      final before = variableName == 'target_health_percent_before';

      final labelPrefix = before ? '¿El objetivo estaba' : '¿El objetivo está';

      switch (operatorName) {
        case 'lt':
          result.add(
            ActionExternalRequirement.percentageBelow(
              variableName: variableName,
              threshold: safeThreshold,
              label:
                  '$labelPrefix por debajo del '
                  '$thresholdText% de vida?',
            ),
          );

          break;

        case 'lte':
          result.add(
            ActionExternalRequirement.percentageAtOrBelow(
              variableName: variableName,
              threshold: safeThreshold,
              label:
                  '$labelPrefix al '
                  '$thresholdText% de vida o por debajo?',
            ),
          );

          break;

        case 'gt':
          result.add(
            ActionExternalRequirement.percentageAbove(
              variableName: variableName,
              threshold: safeThreshold,
              label:
                  '$labelPrefix por encima del '
                  '$thresholdText% de vida?',
            ),
          );

          break;

        case 'gte':
          result.add(
            ActionExternalRequirement.percentageAtOrAbove(
              variableName: variableName,
              threshold: safeThreshold,
              label:
                  '$labelPrefix al '
                  '$thresholdText% de vida o por encima?',
            ),
          );

          break;
      }
    }

    return result;
  }

  // ===========================================================================
  // PORCENTAJE CON OPERADORES
  //
  // Ejemplos:
  //
  // target_health_percent < 50
  // target_health_percent <= 50
  // target_health_percent > 50
  // target_health_percent >= 50
  // ===========================================================================

  List<ActionExternalRequirement> _extractHealthPercentageRequirements(
    String expression, {
    required String variableName,
  }) {
    final result = <ActionExternalRequirement>[];

    final pattern = RegExp(
      '${RegExp.escape(variableName)}'
      r'\s*(<=|>=|<|>)\s*'
      r'(-?\d+(?:\.\d+)?)',
      caseSensitive: false,
    );

    for (final match in pattern.allMatches(expression)) {
      final operator = match.group(1);

      final rawThreshold = match.group(2);

      if (operator == null || rawThreshold == null) {
        continue;
      }

      final threshold = double.tryParse(rawThreshold);

      if (threshold == null) {
        continue;
      }

      final safeThreshold = threshold.clamp(0.0, 100.0).toDouble();

      final thresholdText = _percentageThresholdText(safeThreshold);

      final before = variableName == 'target_health_percent_before';

      final labelPrefix = before ? '¿El objetivo estaba' : '¿El objetivo está';

      switch (operator) {
        case '<':
          result.add(
            ActionExternalRequirement.percentageBelow(
              variableName: variableName,
              threshold: safeThreshold,
              label:
                  '$labelPrefix por debajo del '
                  '$thresholdText% de vida?',
            ),
          );

          break;

        case '<=':
          result.add(
            ActionExternalRequirement.percentageAtOrBelow(
              variableName: variableName,
              threshold: safeThreshold,
              label:
                  '$labelPrefix al '
                  '$thresholdText% de vida o por debajo?',
            ),
          );

          break;

        case '>':
          result.add(
            ActionExternalRequirement.percentageAbove(
              variableName: variableName,
              threshold: safeThreshold,
              label:
                  '$labelPrefix por encima del '
                  '$thresholdText% de vida?',
            ),
          );

          break;

        case '>=':
          result.add(
            ActionExternalRequirement.percentageAtOrAbove(
              variableName: variableName,
              threshold: safeThreshold,
              label:
                  '$labelPrefix al '
                  '$thresholdText% de vida o por encima?',
            ),
          );

          break;
      }
    }

    return result;
  }

  // ===========================================================================
  // LABEL DE PORCENTAJE
  // ===========================================================================

  String _percentageThresholdText(double threshold) {
    if (threshold == threshold.roundToDouble()) {
      return threshold.toInt().toString();
    }

    return threshold.toString();
  }
}
