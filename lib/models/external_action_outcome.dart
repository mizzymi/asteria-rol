class ExternalActionOutcome {
  final String targetId;

  /// Daño realmente aplicado por el objetivo externo.
  final int damageApplied;

  /// Curación realmente aplicada por el objetivo externo.
  final int healingApplied;

  /// IDs de los efectos realmente aplicados.
  final Set<String> appliedEffectIds;

  final bool killed;

  final int? healthBefore;

  final int? healthAfter;

  const ExternalActionOutcome({
    required this.targetId,
    this.damageApplied = 0,
    this.healingApplied = 0,
    this.appliedEffectIds = const {},
    this.killed = false,
    this.healthBefore,
    this.healthAfter,
  });

  int get effectsApplied {
    return appliedEffectIds.length;
  }

  bool get tookDamage {
    return damageApplied > 0;
  }

  bool get receivedHealing {
    return healingApplied > 0;
  }

  bool get receivedEffects {
    return appliedEffectIds.isNotEmpty;
  }

  bool get hasHealthInformation {
    return healthBefore != null || healthAfter != null;
  }

  bool get hasCompleteHealthInformation {
    return healthBefore != null && healthAfter != null;
  }

  bool get changedHealth {
    return damageApplied > 0 ||
        healingApplied > 0 ||
        (healthBefore != null &&
            healthAfter != null &&
            healthBefore != healthAfter);
  }

  bool get changedAnything {
    return changedHealth || receivedEffects || killed;
  }

  bool appliedEffect(String effectId) {
    return appliedEffectIds.contains(effectId);
  }
}
