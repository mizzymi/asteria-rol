import 'action_effect_result.dart';

class ExternalTargetOutcome {
  final String targetId;

  final String? targetLabel;

  /// Daño resuelto por la acción para este objetivo externo.
  ///
  /// No implica que el objetivo externo lo haya aplicado todavía.
  final int damage;

  /// Curación resuelta por la acción para este objetivo externo.
  ///
  /// No implica que el objetivo externo la haya aplicado todavía.
  final int healing;

  /// Efectos que deben aplicarse al objetivo externo.
  ///
  /// Todavía no representan confirmación de aplicación remota.
  final List<ActionEffectResult> effects;

  const ExternalTargetOutcome({
    required this.targetId,
    this.targetLabel,
    this.damage = 0,
    this.healing = 0,
    this.effects = const [],
  });

  bool get hasDamage => damage > 0;

  bool get hasHealing => healing > 0;

  bool get hasPendingEffects => effects.isNotEmpty;

  bool get hasPendingApplication {
    return hasDamage || hasHealing || hasPendingEffects;
  }

  String get effectiveTargetLabel {
    final label = targetLabel?.trim();

    if (label == null || label.isEmpty) {
      return 'Objetivo';
    }

    return label;
  }

  bool get dealtDamage {
    return damage > 0;
  }

  bool get healed {
    return healing > 0;
  }

  bool get hasEffects {
    return effects.isNotEmpty;
  }

  bool get changedAnything {
    return dealtDamage || healed || hasEffects;
  }

  int get effectCount {
    return effects.length;
  }
}

class ActionApplyResult {
  /// Daño realmente aplicado al propio Character.
  final int selfDamageApplied;

  /// Curación realmente aplicada al propio Character.
  final int selfHealingApplied;

  /// Número de efectos realmente añadidos al propio Character.
  final int selfEffectsApplied;

  final bool criticalDispatched;

  final List<ExternalTargetOutcome> externalTargetOutcomes;

  const ActionApplyResult({
    this.selfDamageApplied = 0,
    this.selfHealingApplied = 0,
    this.selfEffectsApplied = 0,
    this.criticalDispatched = false,
    this.externalTargetOutcomes = const [],
  });

  int get affectedTargetCount {
    var count = externalAffectedTargetCount;

    if (changedSelf) {
      count++;
    }

    return count;
  }

  // ===========================================================================
  // SELF
  // ===========================================================================

  bool get changedSelf {
    return selfDamageApplied > 0 ||
        selfHealingApplied > 0 ||
        selfEffectsApplied > 0;
  }

  bool get damagedSelf {
    return selfDamageApplied > 0;
  }

  bool get appliedSelfEffects {
    return selfEffectsApplied > 0;
  }

  bool get healedSelf {
    return selfHealingApplied > 0;
  }

  // ===========================================================================
  // EXTERNOS
  // ===========================================================================

  int get externalDamageDealt {
    return externalTargetOutcomes.fold<int>(
      0,
      (sum, outcome) => sum + outcome.damage,
    );
  }

  int get externalHealingDealt {
    return externalTargetOutcomes.fold<int>(
      0,
      (sum, outcome) => sum + outcome.healing,
    );
  }

  int get externalDamageTargetCount {
    return externalTargetOutcomes
        .where((outcome) => outcome.dealtDamage)
        .length;
  }

  int get externalHealingTargetCount {
    return externalTargetOutcomes.where((outcome) => outcome.healed).length;
  }

  int get externalAffectedTargetCount {
    return externalTargetOutcomes
        .where((outcome) => outcome.changedAnything)
        .length;
  }

  int get externalEffectCount {
    return externalTargetOutcomes.fold<int>(
      0,
      (sum, outcome) => sum + outcome.effectCount,
    );
  }

  bool get producedExternalDamage {
    return externalDamageDealt > 0;
  }

  bool get producedExternalHealing {
    return externalHealingDealt > 0;
  }

  bool get producedExternalEffects {
    return externalEffectCount > 0;
  }

  bool get affectedExternalTargets {
    return externalAffectedTargetCount > 0;
  }

  bool get hasExternalReportedOutcome {
    return affectedExternalTargets;
  }

  bool get hasPendingExternalApplication {
    return hasExternalReportedOutcome;
  }

  // ===========================================================================
  // GLOBAL
  // ===========================================================================

  bool get changedAnything {
    return changedSelf || affectedExternalTargets;
  }
}
