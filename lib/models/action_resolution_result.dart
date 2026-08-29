import 'ability.dart';
import 'action_attack_result.dart';
import 'action_chance_check.dart';
import 'action_cost.dart';
import 'action_critical_profile.dart';
import 'action_resolution_context.dart';
import 'action_target_result.dart';
import 'action_event_variables.dart';

class ActionResolutionResult {
  final CharacterAbility ability;

  final AbilityTargetResolutionMode targetResolutionMode;

  final List<ActionTargetResult> targetResults;

  final ActionAttackResult? attackResult;

  final ActionCriticalProfile criticalProfile;

  final List<ActionChanceResult> chanceResults;

  final Set<String> selectedOptionalGroupIds;

  final List<ActionCost> costs;

  final Map<String, Map<String, double>> externalVariablesByTargetId;

  final Map<String, List<ActionChanceResult>> chanceResultsByTargetId;

  const ActionResolutionResult({
    required this.ability,
    required this.targetResolutionMode,
    required this.targetResults,
    required this.criticalProfile,
    this.attackResult,
    this.chanceResults = const [],
    this.chanceResultsByTargetId = const {},
    this.selectedOptionalGroupIds = const {},
    this.costs = const [],
    this.externalVariablesByTargetId = const {},
  });

  List<ActionChanceResult> chanceResultsForTargetId(String targetId) {
    return chanceResultsByTargetId[targetId] ?? const <ActionChanceResult>[];
  }

  List<ActionChanceResult> chanceResultsForTarget(ActionTarget target) {
    return chanceResultsForTargetId(target.id);
  }

  bool get hasIndependentChanceResults {
    return chanceResultsByTargetId.values.any((results) => results.isNotEmpty);
  }

  // ===========================================================================
  // VARIABLES EXTERNAS
  // ===========================================================================

  Map<String, double> externalVariablesForTargetId(String targetId) {
    return externalVariablesByTargetId[targetId] ?? const <String, double>{};
  }

  Map<String, double> externalVariablesForTarget(ActionTarget target) {
    return externalVariablesForTargetId(target.id);
  }

  Map<String, double> eventVariablesForTarget(ActionTarget target) {
    final index = targetResults.indexWhere(
      (result) => result.target.id == target.id,
    );

    return {
      ...externalVariablesForTarget(target),

      ActionEventVariables.actionTargetCount: targetCount.toDouble(),

      ActionEventVariables.affectedActionTargetCount: affectedTargetCount
          .toDouble(),

      ActionEventVariables.externalAffectedTargetCount:
          externalAffectedTargetCount.toDouble(),

      ActionEventVariables.targetIndex: index >= 0 ? (index + 1).toDouble() : 0,

      ActionEventVariables.targetIsSelf: target.isSelf ? 1 : 0,

      ActionEventVariables.targetIsExternal: target.isExternal ? 1 : 0,
    };
  }

  double? externalValueForTargetId(String targetId, String variableName) {
    return externalVariablesByTargetId[targetId]?[variableName];
  }

  double? externalValueForTarget(ActionTarget target, String variableName) {
    return externalValueForTargetId(target.id, variableName);
  }

  bool? externalFlagForTarget(ActionTarget target, String variableName) {
    final value = externalValueForTarget(target, variableName);

    if (value == null) {
      return null;
    }

    return value != 0;
  }

  // ===========================================================================
  // CRÍTICO
  // ===========================================================================

  bool get critical {
    return attackResult?.critical ?? criticalProfile.forcedCritical;
  }

  ActionCriticalType get criticalType {
    final attack = attackResult;

    if (attack != null) {
      return attack.criticalType;
    }

    if (!criticalProfile.forcedCritical) {
      return ActionCriticalType.none;
    }

    return criticalProfile.empowered
        ? ActionCriticalType.empowered
        : ActionCriticalType.normal;
  }

  int get effectiveCriticalMinimumRoll {
    return criticalProfile.minimumNaturalRoll;
  }

  // ===========================================================================
  // OBJETIVOS
  // ===========================================================================

  int get targetCount => targetResults.length;

  int get affectedTargetCount {
    return targetResults.where((result) {
      return result.damage > 0 || result.healing > 0 || result.hasEffects;
    }).length;
  }

  int get externalAffectedTargetCount {
    return externalTargetResults.where((result) {
      return result.damage > 0 || result.healing > 0 || result.hasEffects;
    }).length;
  }

  bool get includesSelf {
    return targetResults.any((result) => result.target.isSelf);
  }

  List<ActionTargetResult> get selfTargetResults {
    return targetResults
        .where((result) => result.target.isSelf)
        .toList(growable: false);
  }

  List<ActionTargetResult> get externalTargetResults {
    return targetResults
        .where((result) => result.target.isExternal)
        .toList(growable: false);
  }

  ActionTargetResult? get selfResult {
    for (final result in targetResults) {
      if (result.target.isSelf) {
        return result;
      }
    }

    return null;
  }

  // ===========================================================================
  // TOTALES
  // ===========================================================================

  int get totalDamageAcrossTargets {
    return targetResults.fold<int>(0, (sum, result) => sum + result.damage);
  }

  int get totalHealingAcrossTargets {
    return targetResults.fold<int>(0, (sum, result) => sum + result.healing);
  }

  int get totalExternalDamage {
    return externalTargetResults.fold<int>(
      0,
      (sum, result) => sum + result.damage,
    );
  }

  int get totalExternalHealing {
    return externalTargetResults.fold<int>(
      0,
      (sum, result) => sum + result.healing,
    );
  }

  // ===========================================================================
  // RESULTADO GLOBAL
  // ===========================================================================

  bool get dealtDamage {
    return targetResults.any((result) => result.dealtDamage);
  }

  bool get healed {
    return targetResults.any((result) => result.healed);
  }

  bool get appliedEffects {
    return targetResults.any((result) => result.hasEffects);
  }

  // ===========================================================================
  // ATAQUES
  //
  // IMPORTANTE:
  // solo contamos resultados que realmente participaron en una tirada
  // de ataque. Un target auxiliar self no debe convertir un miss total en hit.
  // ===========================================================================

  List<ActionTargetResult> get attackTargetResults {
    return targetResults
        .where((result) => result.hasAttackResult)
        .toList(growable: false);
  }

  bool get hasAttackTargets {
    return attackTargetResults.isNotEmpty;
  }

  bool get hitAnyTarget {
    return attackTargetResults.any((result) => result.hit);
  }

  bool get missedAllTargets {
    final targets = attackTargetResults;

    return targets.isNotEmpty && targets.every((result) => result.missed);
  }

  int get hitTargetCount {
    return attackTargetResults.where((result) => result.hit).length;
  }

  int get missedTargetCount {
    return attackTargetResults.where((result) => result.missed).length;
  }
}
