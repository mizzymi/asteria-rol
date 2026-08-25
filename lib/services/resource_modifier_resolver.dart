import '../models/character.dart';
import '../models/character_resource.dart';
import '../models/passive.dart';
import '../models/formulas/formula_issue.dart';
import '../models/passive_resource_modifier.dart';

import '../models/formulas/character_formula_context.dart';
import '../models/formulas/formula_modifier.dart';
import '../models/formulas/formula_context.dart';

import 'formula_evaluator.dart';

class ResourceModifierResolver {
  final Character character;

  final FormulaEvaluator evaluator;

  final List<String> _resolutionStack = [];

  final Map<String, FormulaResourceSnapshot> _resolvedSnapshots = {};

  final List<FormulaIssue> _issues = [];

  List<FormulaIssue> get issues => List.unmodifiable(_issues);

  ResourceModifierResolver({
    required this.character,
    FormulaEvaluator? evaluator,
  }) : evaluator = evaluator ?? const FormulaEvaluator();

  FormulaResourceSnapshot _buildBaseSnapshot(CharacterResource resource) {
    final baseCurrent = resource.currentValue.toDouble();

    final baseMax = resource.hasMaximum ? resource.maxValue.toDouble() : null;

    return FormulaResourceSnapshot(
      baseCurrentValue: baseCurrent,
      baseMaxValue: baseMax,
      currentValue: baseCurrent,
      maxValue: baseMax,
    );
  }

  FormulaResourceSnapshot resolveSnapshot(CharacterResource resource) {
    final cached = _resolvedSnapshots[resource.id];

    if (cached != null) {
      return cached;
    }

    final current = resolveCurrent(resource);

    final max = resolveMax(resource);

    final snapshot = FormulaResourceSnapshot(
      baseCurrentValue: resource.currentValue.toDouble(),
      baseMaxValue: resource.hasMaximum ? resource.maxValue.toDouble() : null,
      currentValue: current.toDouble(),
      maxValue: max?.toDouble(),
    );

    _resolvedSnapshots[resource.id] = snapshot;

    return snapshot;
  }

  Map<String, FormulaResourceSnapshot> buildResolvedSnapshots() {
    clearIssues();

    final result = <String, FormulaResourceSnapshot>{};

    for (final resource in character.resources) {
      try {
        result[resource.id] = resolveSnapshot(resource);
      } on FormulaContextException catch (error) {
        _issues.add(
          FormulaIssue(passiveId: '', modifierId: '', message: error.message),
        );

        result[resource.id] = _buildBaseSnapshot(resource);
      }
    }

    return result;
  }

  // ===========================================================================
  // CURRENT
  // ===========================================================================

  int resolveCurrent(CharacterResource resource) {
    return _resolve(resource: resource, target: PassiveResourceTarget.current);
  }

  // ===========================================================================
  // MAX
  // ===========================================================================

  int? resolveMax(CharacterResource resource) {
    if (!resource.hasMaximum) {
      return null;
    }

    return _resolve(resource: resource, target: PassiveResourceTarget.max);
  }

  // ===========================================================================
  // RESOLVE
  // ===========================================================================

  int _resolve({
    required CharacterResource resource,
    required PassiveResourceTarget target,
  }) {
    final resolveKey = '${resource.id}:${target.name}';

    if (_resolutionStack.contains(resolveKey)) {
      final startIndex = _resolutionStack.indexOf(resolveKey);

      final cycle = [..._resolutionStack.sublist(startIndex), resolveKey];

      throw FormulaContextException(
        'Dependencia circular detectada: ${cycle.join(' → ')}',
      );
    }

    _resolutionStack.add(resolveKey);

    try {
      double value;

      switch (target) {
        case PassiveResourceTarget.current:
          value = resource.currentValue.toDouble();
          break;

        case PassiveResourceTarget.max:
          value = resource.maxValue.toDouble();
          break;
      }

      for (final passive in character.enabledPassives) {
        for (final modifier in passive.resourceModifiers) {
          if (modifier.resourceId != resource.id) {
            continue;
          }

          if (modifier.target != target) {
            continue;
          }

          // =====================================================================
          // SNAPSHOT DE RECURSOS
          // =====================================================================

          final snapshots = <String, FormulaResourceSnapshot>{
            ..._resolvedSnapshots,
          };

          // =====================================================================
          // EVALUAR FÓRMULA
          // =====================================================================

          final formulaResult = evaluator.evaluate(
            modifier.formula,
            context: CharacterFormulaContext.fromCharacter(
              character,
              passive: passive,
              resourceSnapshots: snapshots,
              resourceResolver: _resolveFormulaResource,
              baseResourceResolver: _resolveBaseFormulaResource,
            ),
          );

          if (!formulaResult.valid) {
            _issues.add(
              FormulaIssue(
                passiveId: passive.id,
                modifierId: modifier.id,
                message:
                    formulaResult.error ?? 'Error desconocido en la fórmula',
              ),
            );

            continue;
          }

          final modifierValue = formulaResult.value;

          // =====================================================================
          // APLICAR OPERACIÓN
          // =====================================================================

          switch (modifier.operation) {
            case FormulaModifierOperation.add:
              value += modifierValue;
              break;

            case FormulaModifierOperation.subtract:
              value -= modifierValue;
              break;

            case FormulaModifierOperation.set:
              value = modifierValue;
              break;
          }
        }
      }

      // =======================================================================
      // NORMALIZAR
      // =======================================================================

      if (value < 0) {
        value = 0;
      }

      // =======================================================================
      // LIMITAR ACTUAL AL MÁXIMO EFECTIVO
      // =======================================================================

      if (target == PassiveResourceTarget.current && resource.hasMaximum) {
        final effectiveMax = resolveMax(resource);

        if (effectiveMax != null && value > effectiveMax) {
          value = effectiveMax.toDouble();
        }
      }

      return value.round();
    } finally {
      if (_resolutionStack.isNotEmpty && _resolutionStack.last == resolveKey) {
        _resolutionStack.removeLast();
      } else {
        _resolutionStack.remove(resolveKey);
      }
    }
  }

  void clearIssues() {
    _issues.clear();
  }

  FormulaResourceValue? _resolveBaseFormulaResource(String resourceId) {
    final resource = character.resourceById(resourceId);

    if (resource == null) {
      return null;
    }

    final baseMax = resource.hasMaximum ? resource.maxValue.toDouble() : null;

    return FormulaResourceValue(
      baseCurrentValue: resource.currentValue.toDouble(),
      baseMaxValue: baseMax,
      currentValue: resource.currentValue.toDouble(),
      maxValue: baseMax,
    );
  }

  FormulaResourceValue? _resolveFormulaResource(String resourceId) {
    final resource = character.resourceById(resourceId);

    if (resource == null) {
      return null;
    }

    final snapshot = resolveSnapshot(resource);

    return FormulaResourceValue(
      baseCurrentValue: snapshot.baseCurrentValue,
      baseMaxValue: snapshot.baseMaxValue,
      currentValue: snapshot.currentValue,
      maxValue: snapshot.maxValue,
    );
  }
}
