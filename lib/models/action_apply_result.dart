import 'action_effect_result.dart';
import 'character_effect.dart';
import 'passive_trigger_external_result.dart';
import 'character_effect_trigger_external_result.dart';

class ExternalTargetOutcome {
  final String targetId;
  final String? targetLabel;

  final int damage;
  final int healing;

  /// Efectos procedentes directamente de la habilidad.
  final List<ActionEffectResult> effects;

  /// Efectos producidos por triggers externos.
  ///
  /// El nombre se mantiene por compatibilidad,
  /// aunque ahora pueden proceder tanto de pasivas
  /// como de CharacterEffectTrigger.
  final List<CharacterEffect> passiveEffects;

  /// Resultados producidos por PassiveTrigger.
  final List<PassiveTriggerExternalResult> triggerResults;

  /// Resultados producidos por CharacterEffectTrigger.
  final List<CharacterEffectTriggerExternalResult> effectTriggerResults;

  const ExternalTargetOutcome({
    required this.targetId,
    this.targetLabel,
    this.damage = 0,
    this.healing = 0,
    this.effects = const [],
    this.passiveEffects = const [],
    this.triggerResults = const [],
    this.effectTriggerResults = const [],
  });

  bool get hasDamage => damage > 0;

  bool get hasHealing => healing > 0;

  bool get hasPendingEffects {
    return effects.isNotEmpty || passiveEffects.isNotEmpty;
  }

  bool get hasPassiveTriggerResults {
    return triggerResults.isNotEmpty;
  }

  bool get hasEffectTriggerResults {
    return effectTriggerResults.isNotEmpty;
  }

  bool get hasTriggerResults {
    return hasPassiveTriggerResults || hasEffectTriggerResults;
  }

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
    return effects.isNotEmpty || passiveEffects.isNotEmpty;
  }

  bool get changedAnything {
    return dealtDamage || healed || hasEffects;
  }

  int get effectCount {
    return effects.length + passiveEffects.length;
  }

  Map<String, dynamic> toMap() {
    return {
      'targetId': targetId,
      'targetLabel': targetLabel,
      'damage': damage,
      'healing': healing,

      'effects': effects.map((effect) => effect.toMap()).toList(),

      'passiveEffects': passiveEffects.map((effect) => effect.toMap()).toList(),

      'triggerResults': triggerResults.map((result) => result.toMap()).toList(),

      'effectTriggerResults': effectTriggerResults
          .map((result) => result.toMap())
          .toList(),
    };
  }

  factory ExternalTargetOutcome.fromMap(Map<dynamic, dynamic> map) {
    final effects = <ActionEffectResult>[];
    final passiveEffects = <CharacterEffect>[];
    final triggerResults = <PassiveTriggerExternalResult>[];
    final effectTriggerResults = <CharacterEffectTriggerExternalResult>[];

    // ===========================================================================
    // EFFECTS DE LA ACCIÓN
    // ===========================================================================

    final rawEffects = map['effects'];

    if (rawEffects is List) {
      for (final rawEffect in rawEffects) {
        if (rawEffect is! Map) {
          continue;
        }

        try {
          effects.add(
            ActionEffectResult.fromMap(Map<dynamic, dynamic>.from(rawEffect)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    // ===========================================================================
    // EFFECTS PROCEDENTES DE TRIGGERS
    // ===========================================================================

    final rawPassiveEffects = map['passiveEffects'];

    if (rawPassiveEffects is List) {
      for (final rawEffect in rawPassiveEffects) {
        if (rawEffect is! Map) {
          continue;
        }

        try {
          passiveEffects.add(
            CharacterEffect.fromMap(Map<dynamic, dynamic>.from(rawEffect)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    // ===========================================================================
    // TRIGGERS DE PASIVAS
    // ===========================================================================

    final rawTriggerResults = map['triggerResults'];

    if (rawTriggerResults is List) {
      for (final rawResult in rawTriggerResults) {
        if (rawResult is! Map) {
          continue;
        }

        try {
          triggerResults.add(
            PassiveTriggerExternalResult.fromMap(
              Map<dynamic, dynamic>.from(rawResult),
            ),
          );
        } catch (_) {
          continue;
        }
      }
    }

    // ===========================================================================
    // TRIGGERS DE CHARACTER EFFECTS
    // ===========================================================================

    final rawEffectTriggerResults = map['effectTriggerResults'];

    if (rawEffectTriggerResults is List) {
      for (final rawResult in rawEffectTriggerResults) {
        if (rawResult is! Map) {
          continue;
        }

        try {
          effectTriggerResults.add(
            CharacterEffectTriggerExternalResult.fromMap(
              Map<dynamic, dynamic>.from(rawResult),
            ),
          );
        } catch (_) {
          continue;
        }
      }
    }

    // ===========================================================================
    // RESULTADO
    // ===========================================================================

    return ExternalTargetOutcome(
      targetId: map['targetId']?.toString() ?? '',

      targetLabel: map['targetLabel']?.toString(),

      damage: (map['damage'] as num?)?.toInt() ?? 0,

      healing: (map['healing'] as num?)?.toInt() ?? 0,

      effects: List<ActionEffectResult>.unmodifiable(effects),

      passiveEffects: List<CharacterEffect>.unmodifiable(passiveEffects),

      triggerResults: List<PassiveTriggerExternalResult>.unmodifiable(
        triggerResults,
      ),

      effectTriggerResults:
          List<CharacterEffectTriggerExternalResult>.unmodifiable(
            effectTriggerResults,
          ),
    );
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

  int get pendingExternalDamage {
    return externalTargetOutcomes.fold<int>(
      0,
      (sum, outcome) => sum + outcome.damage,
    );
  }

  int get pendingExternalHealing {
    return externalTargetOutcomes.fold<int>(
      0,
      (sum, outcome) => sum + outcome.healing,
    );
  }

  bool get producedExternalDamage {
    return pendingExternalDamage > 0;
  }

  bool get producedExternalHealing {
    return pendingExternalHealing > 0;
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

  bool get producedExternalEffects {
    return externalEffectCount > 0;
  }

  bool get affectedExternalTargets {
    return externalAffectedTargetCount > 0;
  }

  bool get hasPendingExternalOutcome {
    return affectedExternalTargets;
  }

  bool get hasPendingExternalApplication {
    return hasPendingExternalOutcome;
  }

  // ===========================================================================
  // GLOBAL
  // ===========================================================================

  bool get producedAnything {
    return changedSelf || hasPendingExternalOutcome;
  }
}
