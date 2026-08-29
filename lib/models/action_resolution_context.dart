import 'formulas/character_formula.dart';

import '../services/resource_modifier_resolver.dart';

import 'character.dart';
import 'passive.dart';
import 'action_external_requirement.dart';
import 'ability_effect_part.dart';

import '../services/formula_evaluator.dart';

import 'formulas/character_formula_context.dart';
import 'formulas/formula_context.dart';

enum ActionTargetKind { self, external }

class ActionTarget {
  final String id;

  final ActionTargetKind kind;

  final String? label;

  const ActionTarget({required this.id, required this.kind, this.label});

  const ActionTarget.self()
    : id = 'self',
      kind = ActionTargetKind.self,
      label = null;

  bool get isSelf {
    return kind == ActionTargetKind.self;
  }

  bool get isExternal {
    return kind == ActionTargetKind.external;
  }
}

class ExternalPercentageAnswerResolver {
  const ExternalPercentageAnswerResolver();

  Map<String, double> resolve({
    required List<ActionExternalRequirement> requirements,
    required Map<String, bool> answers,
  }) {
    final result = <String, double>{};

    final percentageRequirements = requirements.where(
      (requirement) => requirement.isPercentageRequirement,
    );

    for (final requirement in percentageRequirements) {
      final directAnswer = answers[requirement.normalizedVariableName];

      if (directAnswer != null) {
        result[requirement.normalizedVariableName] = directAnswer ? 1 : 0;

        continue;
      }

      final inferred = _inferAnswer(
        requirement: requirement,
        requirements: percentageRequirements.toList(),
        answers: answers,
      );

      if (inferred != null) {
        result[requirement.normalizedVariableName] = inferred ? 1 : 0;
      }
    }

    return result;
  }

  bool? _inferAnswer({
    required ActionExternalRequirement requirement,
    required List<ActionExternalRequirement> requirements,
    required Map<String, bool> answers,
  }) {
    final threshold = requirement.threshold;

    if (threshold == null) {
      return null;
    }

    for (final answeredRequirement in requirements) {
      if (answeredRequirement.variableName
          .trim()
          .toLowerCase() !=
          requirement.variableName
              .trim()
              .toLowerCase()) {
        continue;
      }

      final answeredThreshold = answeredRequirement.threshold;

      if (answeredThreshold == null) {
        continue;
      }

      final answer = answers[answeredRequirement.normalizedVariableName];

      if (answer == null) {
        continue;
      }

      final inferred = _inferBetweenRequirements(
        requested: requirement,
        requestedThreshold: threshold,
        answered: answeredRequirement,
        answeredThreshold: answeredThreshold,
        answer: answer,
      );

      if (inferred != null) {
        return inferred;
      }
    }

    return null;
  }

  bool? _inferBetweenRequirements({
    required ActionExternalRequirement requested,
    required double requestedThreshold,
    required ActionExternalRequirement answered,
    required double answeredThreshold,
    required bool answer,
  }) {
    // =======================================================================
    // MISMA FAMILIA: POR DEBAJO
    // =======================================================================

    if (requested.isBelowPercentageRequirement &&
        answered.isBelowPercentageRequirement) {
      // HP < 25 = true
      // implica HP < 50 = true.
      if (answer && answeredThreshold <= requestedThreshold) {
        return true;
      }

      // HP < 75 = false
      // implica HP < 50 = false.
      if (!answer && answeredThreshold >= requestedThreshold) {
        return false;
      }
    }

    // =======================================================================
    // MISMA FAMILIA: POR ENCIMA
    // =======================================================================

    if (requested.isAbovePercentageRequirement &&
        answered.isAbovePercentageRequirement) {
      // HP > 75 = true
      // implica HP > 50 = true.
      if (answer && answeredThreshold >= requestedThreshold) {
        return true;
      }

      // HP > 25 = false
      // implica HP > 50 = false.
      if (!answer && answeredThreshold <= requestedThreshold) {
        return false;
      }
    }

    // =======================================================================
    // INFERENCIAS CRUZADAS SEGURAS
    // =======================================================================

    final requestedOperator = requested.percentageOperator;

    final answeredOperator = answered.percentageOperator;

    // !(HP < 50) => HP >= 50
    if (!answer &&
        answeredOperator == '<' &&
        requestedOperator == '>=' &&
        answeredThreshold == requestedThreshold) {
      return true;
    }

    // !(HP >= 50) => HP < 50
    if (!answer &&
        answeredOperator == '>=' &&
        requestedOperator == '<' &&
        answeredThreshold == requestedThreshold) {
      return true;
    }

    // !(HP <= 50) => HP > 50
    if (!answer &&
        answeredOperator == '<=' &&
        requestedOperator == '>' &&
        answeredThreshold == requestedThreshold) {
      return true;
    }

    // !(HP > 50) => HP <= 50
    if (!answer &&
        answeredOperator == '>' &&
        requestedOperator == '<=' &&
        answeredThreshold == requestedThreshold) {
      return true;
    }

    return null;
  }
}

class ExternalPercentageQuestionPlanner {
  const ExternalPercentageQuestionPlanner();

  List<ActionExternalRequirement> order(
    Iterable<ActionExternalRequirement> requirements,
  ) {
    final percentageRequirements = requirements
        .where((requirement) => requirement.isPercentageRequirement)
        .toList();

    percentageRequirements.sort((a, b) {
      final aThreshold = a.threshold ?? double.infinity;

      final bThreshold = b.threshold ?? double.infinity;

      // Para preguntas de "por debajo",
      // preguntamos de menor a mayor:
      //
      // <25 → <50 → <75
      //
      if (a.isBelowPercentageRequirement && b.isBelowPercentageRequirement) {
        return aThreshold.compareTo(bThreshold);
      }

      // Para "por encima":
      //
      // >75 → >50 → >25
      //
      // así las respuestas permiten inferir
      // rápidamente umbrales inferiores.
      if (a.isAbovePercentageRequirement && b.isAbovePercentageRequirement) {
        return bThreshold.compareTo(aThreshold);
      }

      return aThreshold.compareTo(bThreshold);
    });

    return List.unmodifiable(percentageRequirements);
  }
}

class ActionResolutionContext {
  final Character character;

  final List<ActionTarget> targets;

  final Map<String, double> _externalVariables;

  final Map<String, Map<String, double>> _targetExternalVariables;

  final Set<String> _selectedOptionalGroupIds;

  final Map<String, Set<String>> _targetSelectedOptionalGroupIds;

  ActionResolutionContext({
    required this.character,
    List<ActionTarget> targets = const [],
    Map<String, double> externalVariables = const {},
    Map<String, Map<String, double>> targetExternalVariables = const {},
    Set<String> selectedOptionalGroupIds = const {},
    Map<String, Set<String>> targetSelectedOptionalGroupIds = const {},
  }) : targets = List<ActionTarget>.unmodifiable(targets),
       _externalVariables = Map<String, double>.from(externalVariables),
       _targetExternalVariables = _copyTargetExternalVariables(
         targetExternalVariables,
       ),
       _selectedOptionalGroupIds = Set<String>.from(selectedOptionalGroupIds),
       _targetSelectedOptionalGroupIds = _copyTargetOptionalGroups(
         targetSelectedOptionalGroupIds,
       );

  void registerTargetHealthThresholdAnswer(
    ActionTarget target, {
    required String operator,
    required double threshold,
    required bool answer,
  }) {
    setTargetHealthThresholdAnswer(
      target,
      operator: operator,
      threshold: threshold,
      answer: answer,
    );
  }

  void populateKnownTargetVariables() {
    for (final target in targets) {
      setTargetExternalFlag(target.id, 'target_is_self', target.isSelf);

      setTargetExternalFlag(target.id, 'target_is_external', target.isExternal);

      if (!target.isSelf) {
        continue;
      }

      setTargetHealth(
        target,
        currentHealth: character.currentHealth,
        maxHealth: character.maxHealth,
      );
    }
  }

  Map<String, Map<String, double>> snapshotTargetExternalVariables() {
    final result = <String, Map<String, double>>{};

    for (final entry in _targetExternalVariables.entries) {
      result[entry.key] = Map<String, double>.unmodifiable(
        Map<String, double>.from(entry.value),
      );
    }

    return Map<String, Map<String, double>>.unmodifiable(result);
  }

  // ===========================================================================
  // COPIA DEFENSIVA
  // ===========================================================================

  void applyExternalRequirementAnswer(
    ActionExternalRequirement requirement,
    bool answer,
  ) {
    setExternalFlag(requirement.normalizedVariableName, answer);
  }

  static Map<String, Set<String>> _copyTargetOptionalGroups(
    Map<String, Set<String>> source,
  ) {
    final result = <String, Set<String>>{};

    for (final entry in source.entries) {
      final targetId = entry.key.trim();

      if (targetId.isEmpty) {
        continue;
      }

      result[targetId] = entry.value
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet();
    }

    return result;
  }

  Set<String> selectedOptionalGroupIdsForTarget(String targetId) {
    final values = _targetSelectedOptionalGroupIds[targetId.trim()];

    if (values == null) {
      return const {};
    }

    return Set<String>.unmodifiable(values);
  }

  bool isOptionalGroupSelectedForTarget(String targetId, String groupId) {
    final normalizedTargetId = targetId.trim();
    final normalizedGroupId = groupId.trim();

    if (normalizedTargetId.isEmpty || normalizedGroupId.isEmpty) {
      return false;
    }

    return _targetSelectedOptionalGroupIds[normalizedTargetId]?.contains(
          normalizedGroupId,
        ) ??
        false;
  }

  void setOptionalGroupSelectedForTarget(
    String targetId,
    String groupId,
    bool selected,
  ) {
    final normalizedTargetId = targetId.trim();
    final normalizedGroupId = groupId.trim();

    if (normalizedTargetId.isEmpty || normalizedGroupId.isEmpty) {
      return;
    }

    if (selected) {
      final groups = _targetSelectedOptionalGroupIds.putIfAbsent(
        normalizedTargetId,
        () => <String>{},
      );

      groups.add(normalizedGroupId);

      return;
    }

    final groups = _targetSelectedOptionalGroupIds[normalizedTargetId];

    if (groups == null) {
      return;
    }

    groups.remove(normalizedGroupId);

    if (groups.isEmpty) {
      _targetSelectedOptionalGroupIds.remove(normalizedTargetId);
    }
  }

  // ===========================================================================
  // VARIABLES EXTERNAS POR OBJETIVO
  // ===========================================================================

  Map<String, double> targetExternalVariables(String targetId) {
    final values = _targetExternalVariables[targetId.trim()];

    if (values == null) {
      return const {};
    }

    return Map<String, double>.unmodifiable(values);
  }

  Map<String, double> externalVariablesForTarget(ActionTarget target) {
    return targetExternalVariables(target.id);
  }

  double? externalValueForTarget(ActionTarget target, String name) {
    return targetExternalValue(target.id, name);
  }

  bool? externalFlagForTarget(ActionTarget target, String name) {
    return targetExternalFlag(target.id, name);
  }

  void setExternalValueForTarget(
    ActionTarget target,
    String name,
    double value,
  ) {
    setTargetExternalValue(target.id, name, value);
  }

  void setExternalFlagForTarget(ActionTarget target, String name, bool value) {
    setTargetExternalFlag(target.id, name, value);
  }

  bool containsTargetExternalVariable(String targetId, String name) {
    final variables = _targetExternalVariables[targetId.trim()];

    if (variables == null) {
      return false;
    }

    return variables.containsKey(_normalize(name));
  }

  double? targetExternalValue(String targetId, String name) {
    return _targetExternalVariables[targetId.trim()]?[_normalize(name)];
  }

  void setTargetExternalValue(String targetId, String name, double value) {
    final normalizedTargetId = targetId.trim();

    if (normalizedTargetId.isEmpty) {
      return;
    }

    final variables = _targetExternalVariables.putIfAbsent(
      normalizedTargetId,
      () => <String, double>{},
    );

    variables[_normalize(name)] = value;
  }

  void setTargetExternalFlag(String targetId, String name, bool value) {
    setTargetExternalValue(targetId, name, value ? 1 : 0);
  }

  void setTargetHealthPercent(ActionTarget target, double percent) {
    final safePercent = percent.clamp(0.0, 100.0).toDouble();

    // Porcentaje exacto conocido.
    setTargetExternalValue(target.id, 'target_health_percent', safePercent);

    // Estado previo a ejecutar la acción.
    setTargetExternalValue(
      target.id,
      'target_health_percent_before',
      safePercent,
    );

    // Herido = no está a vida completa.
    setTargetExternalFlag(target.id, 'target_wounded', safePercent < 100.0);

    setTargetExternalFlag(
      target.id,
      'target_full_health',
      safePercent >= 100.0,
    );

    setTargetExternalFlag(target.id, 'target_below_half', safePercent < 50.0);

    setTargetExternalFlag(
      target.id,
      'target_at_or_below_half',
      safePercent <= 50.0,
    );

    setTargetExternalFlag(target.id, 'target_above_half', safePercent > 50.0);

    setTargetExternalFlag(
      target.id,
      'target_at_or_above_half',
      safePercent >= 50.0,
    );

    setTargetExternalFlag(target.id, 'target_is_self', target.isSelf);

    setTargetExternalFlag(target.id, 'target_is_external', target.isExternal);
  }

  void setTargetHealth(
    ActionTarget target, {
    required int currentHealth,
    required int maxHealth,
  }) {
    if (maxHealth <= 0) {
      return;
    }

    final safeCurrent = currentHealth.clamp(0, maxHealth);

    setTargetExternalValue(target.id, 'target_health', safeCurrent.toDouble());

    setTargetExternalValue(
      target.id,
      'target_health_before',
      safeCurrent.toDouble(),
    );

    setTargetExternalValue(
      target.id,
      'target_max_health',
      maxHealth.toDouble(),
    );

    final percent = (safeCurrent / maxHealth) * 100.0;

    setTargetHealthPercent(target, percent);
  }

  bool? targetExternalFlag(String targetId, String name) {
    final value = targetExternalValue(targetId, name);

    if (value == null) {
      return null;
    }

    return value != 0;
  }

  void removeTargetExternalVariable(String targetId, String name) {
    final variables = _targetExternalVariables[targetId.trim()];

    if (variables == null) {
      return;
    }

    variables.remove(_normalize(name));

    if (variables.isEmpty) {
      _targetExternalVariables.remove(targetId.trim());
    }
  }

  void applyExternalValues(Map<String, double> values) {
    for (final entry in values.entries) {
      setExternalValue(entry.key, entry.value);
    }
  }

  bool evaluateCondition(
    CharacterFormula? condition, {
    CharacterPassive? passive,
    ActionTarget? target,
    Map<String, double> eventVariables = const {},
  }) {
    if (condition == null ||
        condition.expression.trim().isEmpty ||
        condition.expression.trim() == '0') {
      return true;
    }

    final result = const FormulaEvaluator().evaluate(
      condition,
      context: buildFormulaContext(
        passive: passive,
        target: target,
        eventVariables: eventVariables,
      ),
    );

    if (!result.valid) {
      return false;
    }

    return result.value != 0;
  }

  bool isAbilityEffectPartAvailable(
    AbilityEffectPart part, {
    CharacterPassive? passive,
    ActionTarget? target,
    Map<String, double> eventVariables = const {},
  }) {
    if (!part.hasCondition) {
      return true;
    }

    return evaluateCondition(
      part.condition,
      passive: passive,
      target: target,
      eventVariables: eventVariables,
    );
  }

  bool shouldUseAbilityEffectPart(
    AbilityEffectPart part, {
    CharacterPassive? passive,
    ActionTarget? target,
    Map<String, double> eventVariables = const {},
  }) {
    final available = isAbilityEffectPartAvailable(
      part,
      passive: passive,
      target: target,
      eventVariables: eventVariables,
    );

    if (!available) {
      return false;
    }

    if (!part.optional) {
      return true;
    }

    final groupId = part.effectiveOptionalGroupId;

    if (target != null) {
      return isOptionalGroupSelectedForTarget(target.id, groupId);
    }

    return isOptionalGroupSelected(groupId);
  }

  // ===========================================================================
  // COMPONENTES OPCIONALES
  // ===========================================================================

  Set<String> get selectedOptionalGroupIds {
    return Set<String>.unmodifiable(_selectedOptionalGroupIds);
  }

  bool isOptionalGroupSelected(String groupId) {
    return _selectedOptionalGroupIds.contains(groupId.trim());
  }

  void selectOptionalGroup(String groupId) {
    final normalized = groupId.trim();

    if (normalized.isEmpty) {
      return;
    }

    _selectedOptionalGroupIds.add(normalized);
  }

  void deselectOptionalGroup(String groupId) {
    _selectedOptionalGroupIds.remove(groupId.trim());
  }

  void setOptionalGroupSelected(String groupId, bool selected) {
    if (selected) {
      selectOptionalGroup(groupId);
    } else {
      deselectOptionalGroup(groupId);
    }
  }

  // ===========================================================================
  // OBJETIVOS
  // ===========================================================================

  bool get includesSelf {
    return targets.any((target) => target.isSelf);
  }

  List<ActionTarget> get externalTargets {
    return targets.where((target) => target.isExternal).toList(growable: false);
  }

  int get externalTargetCount {
    return externalTargets.length;
  }

  int get targetCount {
    return targets.length;
  }

  bool get hasExternalTargets {
    return externalTargetCount > 0;
  }

  ActionTarget? targetById(String id) {
    final normalized = id.trim();

    for (final target in targets) {
      if (target.id == normalized) {
        return target;
      }
    }

    return null;
  }

  // ===========================================================================
  // VARIABLES TEMPORALES EXTERNAS
  // ===========================================================================

  Map<String, double> get externalVariables {
    return Map<String, double>.unmodifiable(_externalVariables);
  }

  bool containsExternalVariable(String name) {
    return _externalVariables.containsKey(_normalize(name));
  }

  double? externalValue(String name) {
    return _externalVariables[_normalize(name)];
  }

  void setExternalValue(String name, double value) {
    _externalVariables[_normalize(name)] = value;
  }

  void setExternalFlag(String name, bool value) {
    setExternalValue(name, value ? 1 : 0);
  }

  bool? externalFlag(String name) {
    final value = externalValue(name);

    if (value == null) {
      return null;
    }

    return value != 0;
  }

  void removeExternalVariable(String name) {
    _externalVariables.remove(_normalize(name));
  }

  static String targetHealthThresholdVariable({
    required String operator,
    required double threshold,
  }) {
    final cleanThreshold = threshold == threshold.roundToDouble()
        ? threshold.toInt().toString()
        : threshold.toString();

    final operatorName = switch (operator.trim()) {
      '<' => 'lt',
      '<=' => 'lte',
      '>' => 'gt',
      '>=' => 'gte',
      '==' => 'eq',
      _ => 'unknown',
    };

    return 'target_health_percent_'
        '${operatorName}_'
        '$cleanThreshold';
  }

  void setTargetHealthThresholdAnswer(
    ActionTarget target, {
    required String operator,
    required double threshold,
    required bool answer,
  }) {
    final variable = targetHealthThresholdVariable(
      operator: operator,
      threshold: threshold,
    );

    setTargetExternalFlag(target.id, variable, answer);
  }

  bool? targetHealthThresholdAnswer(
    ActionTarget target, {
    required String operator,
    required double threshold,
  }) {
    final variable = targetHealthThresholdVariable(
      operator: operator,
      threshold: threshold,
    );

    return targetExternalFlag(target.id, variable);
  }

  bool? evaluateKnownTargetHealthThreshold(
    ActionTarget target, {
    required String operator,
    required double threshold,
  }) {
    // ===========================================================================
    // 1. PORCENTAJE EXACTO CONOCIDO
    // ===========================================================================

    final exact = targetExternalValue(target.id, 'target_health_percent');

    if (exact != null) {
      switch (operator.trim()) {
        case '<':
          return exact < threshold;

        case '<=':
          return exact <= threshold;

        case '>':
          return exact > threshold;

        case '>=':
          return exact >= threshold;

        case '==':
          return exact == threshold;

        default:
          return null;
      }
    }

    // ===========================================================================
    // 2. RESPUESTA DIRECTA YA CONOCIDA
    // ===========================================================================

    final direct = targetHealthThresholdAnswer(
      target,
      operator: operator,
      threshold: threshold,
    );

    if (direct != null) {
      return direct;
    }

    // ===========================================================================
    // 3. RECONSTRUIR REQUIREMENTS YA CONOCIDOS
    // ===========================================================================

    final knownVariables = targetExternalVariables(target.id);

    final requirements = <ActionExternalRequirement>[];

    final answers = <String, bool>{};

    for (final entry in knownVariables.entries) {
      final requirement = ActionExternalRequirement.tryParsePercentageVariable(
        entry.key,
      );

      if (requirement == null) {
        continue;
      }

      requirements.add(requirement);

      answers[requirement.normalizedVariableName] = entry.value != 0;
    }

    // ===========================================================================
    // 4. REQUIREMENT SOLICITADO
    // ===========================================================================

    final requestedVariable = targetHealthThresholdVariable(
      operator: operator,
      threshold: threshold,
    );

    final requestedRequirement =
        ActionExternalRequirement.tryParsePercentageVariable(requestedVariable);

    if (requestedRequirement == null) {
      return null;
    }

    // ===========================================================================
    // 5. INFERENCIA
    // ===========================================================================

    final resolved = const ExternalPercentageAnswerResolver().resolve(
      requirements: [...requirements, requestedRequirement],
      answers: answers,
    );

    final inferred = resolved[requestedRequirement.normalizedVariableName];

    if (inferred == null) {
      return null;
    }

    return inferred != 0;
  }

  // ===========================================================================
  // CONTEXTO DE FÓRMULAS
  // ===========================================================================

  FormulaContext buildFormulaContext({
    CharacterPassive? passive,
    ActionTarget? target,
    Map<String, double> eventVariables = const {},
  }) {
    final resourceResolver = ResourceModifierResolver(character: character);

    final extraVariables = <String, double>{..._externalVariables};

    if (target != null) {
      final targetVariables = _targetExternalVariables[target.id];

      if (targetVariables != null) {
        extraVariables.addAll(targetVariables);
      }

      extraVariables['target_is_self'] = target.isSelf ? 1 : 0;

      extraVariables['target_is_external'] = target.isExternal ? 1 : 0;
    }

    return CharacterFormulaContext.fromCharacter(
      character,
      passive: passive,
      eventVariables: eventVariables,
      extraVariables: extraVariables,

      resourceResolver: (resourceId) {
        final resource = character.resourceById(resourceId);

        if (resource == null) {
          return null;
        }

        final snapshot = resourceResolver.resolveSnapshot(resource);

        return FormulaResourceValue(
          baseCurrentValue: snapshot.baseCurrentValue,
          baseMaxValue: snapshot.baseMaxValue,
          currentValue: snapshot.currentValue,
          maxValue: snapshot.maxValue,
        );
      },

      baseResourceResolver: (resourceId) {
        final resource = character.resourceById(resourceId);

        if (resource == null) {
          return null;
        }

        final baseMax = resource.hasMaximum
            ? resource.maxValue.toDouble()
            : null;

        return FormulaResourceValue(
          baseCurrentValue: resource.currentValue.toDouble(),
          baseMaxValue: baseMax,
          currentValue: resource.currentValue.toDouble(),
          maxValue: baseMax,
        );
      },
    );
  }

  void applyTargetExternalRequirementAnswer(
    String targetId,
    ActionExternalRequirement requirement,
    bool answer,
  ) {
    setTargetExternalFlag(targetId, requirement.normalizedVariableName, answer);
  }

  void applyTargetExternalValues(String targetId, Map<String, double> values) {
    for (final entry in values.entries) {
      setTargetExternalValue(targetId, entry.key, entry.value);
    }
  }

  // ===========================================================================
  // NORMALIZACIÓN
  // ===========================================================================

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  static Map<String, Map<String, double>> _copyTargetExternalVariables(
    Map<String, Map<String, double>> source,
  ) {
    final result = <String, Map<String, double>>{};

    for (final entry in source.entries) {
      final targetId = entry.key.trim();

      if (targetId.isEmpty) {
        continue;
      }

      result[targetId] = Map<String, double>.from(
        entry.value.map((key, value) => MapEntry(_normalize(key), value)),
      );
    }

    return result;
  }
}
