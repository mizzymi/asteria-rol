import 'action_effect_result.dart';

class ExternalActionEffect {
  final String targetId;

  final String? targetLabel;

  final ActionEffectResult effect;

  const ExternalActionEffect({
    required this.targetId,
    required this.effect,
    this.targetLabel,
  });
}

class ActionApplyResult {
  final int selfDamageApplied;

  final int selfHealingApplied;

  final int externalDamageDealt;

  final int externalHealingDealt;

  final bool criticalDispatched;

  final List<ExternalActionEffect> externalEffects;

  const ActionApplyResult({
    this.selfDamageApplied = 0,
    this.selfHealingApplied = 0,
    this.externalDamageDealt = 0,
    this.externalHealingDealt = 0,
    this.criticalDispatched = false,
    this.externalEffects = const [],
  });

  bool get producedExternalEffects {
    return externalEffects.isNotEmpty;
  }

  bool get changedSelf {
    return selfDamageApplied > 0 || selfHealingApplied > 0;
  }

  bool get producedExternalDamage {
    return externalDamageDealt > 0;
  }

  bool get producedExternalHealing {
    return externalHealingDealt > 0;
  }
}
