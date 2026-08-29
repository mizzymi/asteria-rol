import '../models/action_event_variables.dart';
import '../models/action_apply_result.dart';
import '../models/action_resolution_result.dart';
import '../models/action_target_result.dart';
import '../models/character.dart';
import '../models/passive.dart';
import '../models/action_effect_result.dart';
import '../models/external_action_outcome.dart';

class ActionResultApplier {
  final Character character;

  int _effectSequence = 0;

  ActionResultApplier({required this.character});

  // ===========================================================================
  // VALIDACIÓN
  //
  // Esta validación puede ejecutarse ANTES de pagar los costes.
  //
  // apply() vuelve a ejecutarla de forma defensiva por si en el futuro
  // aparece otro caller distinto de ActionResolver.commitResolution().
  // ===========================================================================

  void validate(ActionResolutionResult result) {
    _validateSelfEffects(result);
  }

  void _validateSelfEffects(ActionResolutionResult result) {
    for (final targetResult in result.targetResults) {
      if (!targetResult.target.isSelf) {
        continue;
      }

      for (final effectResult in targetResult.effects) {
        final template = effectResult.template;

        if (template.id.trim().isEmpty) {
          throw StateError('No se puede aplicar un efecto sin ID.');
        }
      }
    }
  }

  void dispatchExternalOutcome({
    required ActionResolutionResult result,
    required ExternalActionOutcome outcome,
  }) {
    ActionTargetResult? resolvedTarget;

    for (final targetResult in result.externalTargetResults) {
      if (targetResult.target.id == outcome.targetId) {
        resolvedTarget = targetResult;
        break;
      }
    }

    if (resolvedTarget == null) {
      return;
    }

    final targetVariables = result.eventVariablesForTarget(
      resolvedTarget.target,
    );

    final outcomeVariables = <String, double>{
      ...targetVariables,

      ActionEventVariables.resolvedDamage: resolvedTarget.damage.toDouble(),

      ActionEventVariables.resolvedHealing: resolvedTarget.healing.toDouble(),

      ActionEventVariables.resolvedEffectCount: resolvedTarget.effects.length
          .toDouble(),

      ActionEventVariables.damageApplied: outcome.damageApplied.toDouble(),

      ActionEventVariables.healingApplied: outcome.healingApplied.toDouble(),

      ActionEventVariables.effectsApplied: outcome.effectsApplied.toDouble(),

      ActionEventVariables.damageConfirmed: outcome.damageApplied > 0 ? 1 : 0,

      ActionEventVariables.healingConfirmed: outcome.healingApplied > 0 ? 1 : 0,

      ActionEventVariables.externalHealthChanged: outcome.changedHealth ? 1 : 0,

      ActionEventVariables.externalChangedAnything: outcome.changedAnything
          ? 1
          : 0,

      if (outcome.healthBefore != null)
        ActionEventVariables.targetHealthBefore: outcome.healthBefore!
            .toDouble(),

      if (outcome.healthAfter != null)
        ActionEventVariables.targetHealthAfter: outcome.healthAfter!.toDouble(),

      for (final effectId in outcome.appliedEffectIds) 'effect_$effectId': 1,
    };

    // ===========================================================================
    // DAÑO REALMENTE APLICADO
    // ===========================================================================

    if (outcome.damageApplied > 0) {
      character.dispatchPassiveTrigger(
        PassiveTriggerEvent.damageDealt,
        eventVariables: {
          ...outcomeVariables,

          ActionEventVariables.damage: outcome.damageApplied.toDouble(),

          ActionEventVariables.damageResolved: resolvedTarget.damage > 0
              ? 1
              : 0,

          ActionEventVariables.damageConfirmed: 1,
        },
      );
    }

    // ===========================================================================
    // CURACIÓN REALMENTE APLICADA
    // ===========================================================================

    if (outcome.healingApplied > 0) {
      character.dispatchPassiveTrigger(
        PassiveTriggerEvent.healingDealt,
        eventVariables: {
          ...outcomeVariables,

          ActionEventVariables.healing: outcome.healingApplied.toDouble(),

          ActionEventVariables.healingResolved: resolvedTarget.healing > 0
              ? 1
              : 0,

          ActionEventVariables.healingConfirmed: 1,
        },
      );
    }

    // ===========================================================================
    // EFECTOS REALMENTE APLICADOS
    // ===========================================================================

    if (outcome.receivedEffects) {
      for (final effectId in outcome.appliedEffectIds) {
        character.dispatchPassiveTrigger(
          PassiveTriggerEvent.effectApplied,
          eventVariables: {
            ...outcomeVariables,

            ActionEventVariables.effectApplied: 1,

            ActionEventVariables.effectResolved:
                resolvedTarget.effects.isNotEmpty ? 1 : 0,

            ActionEventVariables.effectConfirmed: 1,

            'effect_$effectId': 1,
          },
        );
      }
    }

    // ===========================================================================
    // ENEMY KILLED
    // ===========================================================================

    if (outcome.killed) {
      character.dispatchPassiveTrigger(
        PassiveTriggerEvent.enemyKilled,
        eventVariables: {
          ...outcomeVariables,

          ActionEventVariables.enemyKilled: 1,

          ActionEventVariables.damage: outcome.damageApplied.toDouble(),
        },
      );
    }
  }

  // ===========================================================================
  // EFECTOS SELF
  // ===========================================================================

  void _applySelfEffect(ActionEffectResult effectResult) {
    final template = effectResult.template;

    if (template.id.trim().isEmpty) {
      throw StateError('No se puede aplicar un efecto sin ID.');
    }

    final effect = template.copyWith(
      id: _newAppliedEffectId(template.id),
      enabled: true,
      currentDuration: template.hasDuration ? template.maxDuration : 0,
    );

    effect.normalizeDuration();

    character.addEffect(
      effect,
      refreshTriggers: false,
      dispatchHealthTriggers: false,
    );
  }

  String _newAppliedEffectId(String templateId) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    final sequence = _effectSequence++;

    return '${templateId}_applied_${timestamp}_$sequence';
  }

  // ===========================================================================
  // APPLY
  // ===========================================================================

  ActionApplyResult apply(ActionResolutionResult result) {
    // Validación defensiva.
    //
    // Normalmente commitResolution() ya habrá llamado validate()
    // antes de pagar los costes.
    validate(result);

    final externalTargetOutcomes = <ExternalTargetOutcome>[];

    var selfDamageApplied = 0;
    var selfHealingApplied = 0;
    var selfEffectsApplied = 0;

    var criticalDispatched = false;

    // ===========================================================================
    // RESULTADOS POR TARGET
    // ===========================================================================

    for (final targetResult in result.targetResults) {
      final target = targetResult.target;

      // Contexto común del target:
      //
      // externalVariables
      // action_target_count
      // affected_action_target_count
      // external_affected_target_count
      // target_index
      // target_is_self
      // target_is_external
      final targetVariables = result.eventVariablesForTarget(target);

      // =========================================================================
      // ATAQUE HIT / MISS / CRITICAL
      //
      // Los eventos de ataque pertenecen al resultado del ataque,
      // independientemente de que el target sea self o externo.
      // =========================================================================

      if (result.attackResult != null && targetResult.hasAttackResult) {
        final attackVariables = <String, double>{
          ...targetVariables,

          ActionEventVariables.attackRoll: result.attackResult!.naturalRoll
              .toDouble(),

          ActionEventVariables.attackTotal: result.attackResult!.total
              .toDouble(),

          ActionEventVariables.critical: result.critical ? 1 : 0,
        };

        if (targetResult.hit) {
          character.dispatchPassiveTrigger(
            PassiveTriggerEvent.attackHit,
            eventVariables: attackVariables,
          );

          // Una acción crítica se despacha una sola vez,
          // aunque tenga varios targets.
          if (result.critical && !criticalDispatched) {
            character.dispatchPassiveTrigger(
              PassiveTriggerEvent.criticalHit,
              eventVariables: attackVariables,
            );

            criticalDispatched = true;
          }
        } else {
          character.dispatchPassiveTrigger(
            PassiveTriggerEvent.attackMiss,
            eventVariables: attackVariables,
          );
        }
      }

      // =========================================================================
      // SELF
      // =========================================================================

      if (target.isSelf) {
        selfDamageApplied += _applySelfDamage(
          targetResult.damage,
          targetVariables: targetVariables,
        );

        selfHealingApplied += _applySelfHealing(
          targetResult.healing,
          targetVariables: targetVariables,
        );

        for (final effectResult in targetResult.effects) {
          _applySelfEffect(effectResult);

          selfEffectsApplied++;

          final effectId = effectResult.template.id.trim();

          character.dispatchPassiveTrigger(
            PassiveTriggerEvent.effectReceived,
            eventVariables: {
              ...targetVariables,

              ActionEventVariables.effectReceived: 1,

              ActionEventVariables.effectApplied: 1,

              ActionEventVariables.effectResolved: 1,

              ActionEventVariables.effectConfirmed: 1,

              if (effectId.isNotEmpty) 'effect_$effectId': 1,
            },
          );
        }

        continue;
      }

      // =========================================================================
      // TARGET EXTERNO
      // =========================================================================

      final targetEffects = List<ActionEffectResult>.unmodifiable(
        targetResult.effects,
      );

      if (targetResult.damage > 0 ||
          targetResult.healing > 0 ||
          targetEffects.isNotEmpty) {
        externalTargetOutcomes.add(
          ExternalTargetOutcome(
            targetId: target.id,
            targetLabel: target.label,
            damage: targetResult.damage,
            healing: targetResult.healing,
            effects: targetEffects,
          ),
        );
      }
    }

    // ===========================================================================
    // RESULTADO FINAL DE APLICACIÓN
    // ===========================================================================

    return ActionApplyResult(
      selfDamageApplied: selfDamageApplied,
      selfHealingApplied: selfHealingApplied,
      selfEffectsApplied: selfEffectsApplied,
      externalTargetOutcomes: List<ExternalTargetOutcome>.unmodifiable(
        externalTargetOutcomes,
      ),

      criticalDispatched: criticalDispatched,
    );
  }

  // ===========================================================================
  // APLICACIÓN SOBRE NUESTRO PERSONAJE
  // ===========================================================================

  int _applySelfDamage(
    int amount, {
    required Map<String, double> targetVariables,
  }) {
    if (amount <= 0) {
      return 0;
    }

    final before = character.currentHealth;

    // El ActionResultApplier controla manualmente los triggers
    // para poder añadir todo el contexto de la acción.
    character.takeDamage(amount, dispatchTriggers: false);

    final after = character.currentHealth;

    final applied = before - after;

    if (applied <= 0) {
      return 0;
    }

    // =========================================================================
    // CONTEXTO COMÚN DE VIDA
    // =========================================================================

    final healthVariables = <String, double>{
      ...targetVariables,

      ActionEventVariables.healthBefore: before.toDouble(),

      ActionEventVariables.healthAfter: after.toDouble(),
    };

    // =========================================================================
    // DAÑO RECIBIDO
    // =========================================================================

    character.dispatchPassiveTrigger(
      PassiveTriggerEvent.damageReceived,
      eventVariables: {
        ...healthVariables,

        ActionEventVariables.damage: applied.toDouble(),
      },
    );

    // =========================================================================
    // CAMBIO DE VIDA
    // =========================================================================

    character.dispatchPassiveTrigger(
      PassiveTriggerEvent.healthChanged,
      eventVariables: {
        ...healthVariables,

        ActionEventVariables.healthChange: (-applied).toDouble(),
      },
    );

    // =========================================================================
    // MUERTE
    //
    // Únicamente cuando cruza:
    //
    // > 0
    // ↓
    // 0
    // =========================================================================

    if (before > 0 && after <= 0) {
      character.dispatchPassiveTrigger(
        PassiveTriggerEvent.characterDied,
        eventVariables: {
          ...healthVariables,

          ActionEventVariables.damage: applied.toDouble(),

          ActionEventVariables.death: 1,

          ActionEventVariables.round: character.combatRound.toDouble(),

          ActionEventVariables.turnActive: character.turnActive ? 1 : 0,
        },
      );
    }

    return applied;
  }

  int _applySelfHealing(
    int amount, {
    required Map<String, double> targetVariables,
  }) {
    if (amount <= 0) {
      return 0;
    }

    final before = character.currentHealth;

    // Igual que en daño:
    // los triggers los despachamos nosotros con contexto completo.
    character.heal(amount, dispatchTriggers: false);

    final after = character.currentHealth;

    final applied = after - before;

    if (applied <= 0) {
      return 0;
    }

    // =========================================================================
    // CONTEXTO COMÚN DE VIDA
    // =========================================================================

    final healthVariables = <String, double>{
      ...targetVariables,

      ActionEventVariables.healthBefore: before.toDouble(),

      ActionEventVariables.healthAfter: after.toDouble(),
    };

    // =========================================================================
    // CURACIÓN RECIBIDA
    // =========================================================================

    character.dispatchPassiveTrigger(
      PassiveTriggerEvent.healingReceived,
      eventVariables: {
        ...healthVariables,

        ActionEventVariables.healing: applied.toDouble(),
      },
    );

    // =========================================================================
    // CAMBIO DE VIDA
    // =========================================================================

    character.dispatchPassiveTrigger(
      PassiveTriggerEvent.healthChanged,
      eventVariables: {
        ...healthVariables,

        ActionEventVariables.healthChange: applied.toDouble(),
      },
    );

    return applied;
  }
}
