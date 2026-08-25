import 'ability.dart';
import 'action_attack_result.dart';
import 'action_chance_check.dart';
import 'action_cost.dart';
import 'action_critical_profile.dart';
import 'action_resolution_context.dart';
import 'action_target_result.dart';

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

  const ActionResolutionResult({
    required this.ability,
    required this.targetResolutionMode,
    required this.targetResults,
    required this.criticalProfile,
    this.attackResult,
    this.chanceResults = const [],
    this.selectedOptionalGroupIds = const {},
    this.costs = const [],
    this.externalVariablesByTargetId = const {},
  });

  Map<String, double> externalVariablesForTargetId(
      String targetId,
      ) {
    return externalVariablesByTargetId[targetId] ??
        const <String, double>{};
  }

  Map<String, double> externalVariablesForTarget(
      ActionTarget target,
      ) {
    return externalVariablesForTargetId(
      target.id,
    );
  }

  double? externalValueForTargetId(
      String targetId,
      String variableName,
      ) {
    return externalVariablesByTargetId[targetId]
    ?[variableName];
  }

  double? externalValueForTarget(
      ActionTarget target,
      String variableName,
      ) {
    return externalValueForTargetId(
      target.id,
      variableName,
    );
  }

  bool? externalFlagForTarget(
      ActionTarget target,
      String variableName,
      ) {
    final value = externalValueForTarget(
      target,
      variableName,
    );

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

  bool get includesSelf {
    return targetResults.any((result) => result.target.isSelf);
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
  // TOTALES VISUALES
  // ===========================================================================

  int get totalDamageAcrossTargets {
    return targetResults.fold<int>(0, (sum, result) => sum + result.damage);
  }

  int get totalHealingAcrossTargets {
    return targetResults.fold<int>(0, (sum, result) => sum + result.healing);
  }

  bool get dealtDamage {
    return targetResults.any((result) => result.dealtDamage);
  }

  bool get healed {
    return targetResults.any((result) => result.healed);
  }
}
