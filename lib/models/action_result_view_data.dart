import 'action_apply_result.dart';
import 'action_attack_result.dart';
import 'action_cost.dart';
import 'action_critical_profile.dart';
import 'action_execution_result.dart';
import 'action_result_target_view_data.dart';

class ActionResultViewData {
  // ===========================================================================
  // ACCIÓN
  // ===========================================================================

  final String actionId;

  final String actionName;

  // ===========================================================================
  // ATAQUE
  //
  // null = esta acción no tuvo tirada de ataque.
  // ===========================================================================

  final ActionAttackResult? attackResult;

  // ===========================================================================
  // CRÍTICO
  //
  // Conservamos el perfil original del engine.
  // La UI puede explicarlo, pero nunca recalcularlo.
  // ===========================================================================

  final bool critical;

  final ActionCriticalProfile criticalProfile;

  // ===========================================================================
  // TARGETS
  // ===========================================================================

  final List<ActionResultTargetViewData> targets;

  // ===========================================================================
  // COSTES
  //
  // Son los costes definitivos de la resolución.
  // ===========================================================================

  final List<ActionCost> costs;

  // ===========================================================================
  // APLICACIÓN
  //
  // Sirve para distinguir:
  //
  // - lo realmente aplicado a self,
  // - los outcomes pendientes para targets externos.
  //
  // No debe utilizarse para reconstruir el resultado mecánico.
  // ===========================================================================

  final ActionApplyResult application;

  const ActionResultViewData({
    required this.actionId,
    required this.actionName,
    required this.attackResult,
    required this.critical,
    required this.criticalProfile,
    required this.targets,
    required this.costs,
    required this.application,
  });

  // ===========================================================================
  // FACTORY
  // ===========================================================================

  factory ActionResultViewData.fromExecution(
    ActionExecutionResult execution, {
    required String selfLabel,
  }) {
    final resolution = execution.resolution;

    return ActionResultViewData(
      actionId: resolution.ability.id,
      actionName: resolution.ability.name,

      attackResult: resolution.attackResult,

      critical: resolution.critical,

      criticalProfile: resolution.criticalProfile,

      targets: List<ActionResultTargetViewData>.unmodifiable(
        resolution.targetResults.map(
          (targetResult) => ActionResultTargetViewData.fromTargetResult(
            targetResult,
            selfLabel: selfLabel,
          ),
        ),
      ),

      costs: List<ActionCost>.unmodifiable(resolution.costs),

      application: execution.application,
    );
  }

  // ===========================================================================
  // ATAQUE
  // ===========================================================================

  bool get hasAttack {
    return attackResult != null;
  }

  int? get naturalAttackRoll {
    return attackResult?.naturalRoll;
  }

  int? get attackModifier {
    return attackResult?.modifier;
  }

  int? get attackTotal {
    return attackResult?.total;
  }

  // ===========================================================================
  // CRÍTICO
  //
  // Estos getters solamente exponen información ya presente.
  // ===========================================================================

  bool get isCritical {
    return critical;
  }

  bool get empoweredCritical {
    return critical && criticalProfile.empowered;
  }

  bool get normalCritical {
    return critical && !criticalProfile.empowered;
  }

  int get criticalMinimumRoll {
    return criticalProfile.minimumNaturalRoll;
  }

  // ===========================================================================
  // TARGETS
  // ===========================================================================

  bool get hasTargets {
    return targets.isNotEmpty;
  }

  int get targetCount {
    return targets.length;
  }

  List<ActionResultTargetViewData> get selfTargets {
    return targets.where((target) => target.isSelf).toList(growable: false);
  }

  List<ActionResultTargetViewData> get externalTargets {
    return targets.where((target) => target.isExternal).toList(growable: false);
  }

  int get hitTargetCount {
    return targets.where((target) => target.landedHit).length;
  }

  int get missedTargetCount {
    return targets.where((target) => target.missed).length;
  }

  // ===========================================================================
  // RESULTADOS
  // ===========================================================================

  int get totalResolvedDamage {
    return targets.fold<int>(0, (sum, target) => sum + target.damage);
  }

  int get totalResolvedHealing {
    return targets.fold<int>(0, (sum, target) => sum + target.healing);
  }

  int get totalResolvedEffects {
    return targets.fold<int>(0, (sum, target) => sum + target.effects.length);
  }

  bool get hasDamage {
    return totalResolvedDamage > 0;
  }

  bool get hasHealing {
    return totalResolvedHealing > 0;
  }

  bool get hasEffects {
    return totalResolvedEffects > 0;
  }

  // ===========================================================================
  // COSTES
  // ===========================================================================

  bool get hasCosts {
    return costs.isNotEmpty;
  }

  // ===========================================================================
  // APLICACIÓN
  // ===========================================================================

  bool get changedSelf {
    return application.changedSelf;
  }

  bool get hasPendingExternalApplication {
    return application.hasPendingExternalApplication;
  }

  bool get producedAnything {
    return changedSelf || hasPendingExternalApplication;
  }
}
