import '../models/action_apply_result.dart';
import '../models/action_resolution_result.dart';
import '../models/character.dart';
import '../models/passive.dart';
import '../models/action_effect_result.dart';

class ActionResultApplier {
  final Character character;

  int _effectSequence = 0;

  ActionResultApplier({required this.character});

  void _applySelfEffect(ActionEffectResult effectResult) {
    final template = effectResult.template;

    final effect = template.copyWith(
      id: _newAppliedEffectId(template.id),
      enabled: true,
      currentDuration: template.hasDuration ? template.maxDuration : 0,
    );

    effect.normalizeDuration();

    character.addEffect(effect);

    character.normalizeHealth();
  }

  String _newAppliedEffectId(String templateId) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    final sequence = _effectSequence++;

    return '${templateId}_applied_${timestamp}_$sequence';
  }

  ActionApplyResult apply(ActionResolutionResult result) {
    final externalEffects = <ExternalActionEffect>[];

    var selfDamageApplied = 0;
    var selfHealingApplied = 0;

    var externalDamageDealt = 0;
    var externalHealingDealt = 0;

    var criticalDispatched = false;

    final externalDamageTargetCount = _externalDamageTargetCount(result);

    final externalHealingTargetCount = _externalHealingTargetCount(result);

    // =========================================================================
    // RESULTADOS POR OBJETIVO
    // =========================================================================

    for (final targetResult in result.targetResults) {
      final target = targetResult.target;

      // =======================================================================
      // SELF
      // =======================================================================

      if (target.isSelf) {
        selfDamageApplied += _applySelfDamage(targetResult.damage);

        selfHealingApplied += _applySelfHealing(targetResult.healing);

        for (final effectResult in targetResult.effects) {
          _applySelfEffect(effectResult);
        }

        continue;
      }

      // =======================================================================
      // OBJETIVO EXTERNO
      // =======================================================================

      final targetVariables = result.externalVariablesForTarget(target);

      // -----------------------------------------------------------------------
      // DAÑO
      // -----------------------------------------------------------------------

      if (targetResult.damage > 0) {
        externalDamageDealt += targetResult.damage;

        final eventVariables = <String, double>{
          ...targetVariables,

          'damage': targetResult.damage.toDouble(),

          // Total de objetivos externos dañados
          // por esta resolución completa.
          'target_count': externalDamageTargetCount.toDouble(),

          'target_is_self': 0,
          'target_is_external': 1,
        };

        character.dispatchPassiveTrigger(
          PassiveTriggerEvent.damageDealt,
          eventVariables: eventVariables,
        );

        // ---------------------------------------------------------------------
        // CRÍTICO
        //
        // Se dispara una vez POR OBJETIVO dañado.
        //
        // Así una condición como:
        //
        // target_wounded == 1
        //
        // se evalúa contra este objetivo concreto.
        // ---------------------------------------------------------------------

        if (result.critical) {
          final attackResult = result.attackResult;

          character.dispatchPassiveTrigger(
            PassiveTriggerEvent.criticalHit,
            eventVariables: {
              ...eventVariables,

              'critical': 1,

              'critical_range_min': result.effectiveCriticalMinimumRoll
                  .toDouble(),

              if (attackResult != null)
                'attack_roll': attackResult.naturalRoll.toDouble(),

              if (attackResult != null)
                'attack_total': attackResult.total.toDouble(),
            },
          );

          criticalDispatched = true;
        }
      }

      // -----------------------------------------------------------------------
      // CURACIÓN
      // -----------------------------------------------------------------------

      if (targetResult.healing > 0) {
        externalHealingDealt += targetResult.healing;

        character.dispatchPassiveTrigger(
          PassiveTriggerEvent.healingDealt,
          eventVariables: {
            ...targetVariables,

            'healing': targetResult.healing.toDouble(),

            'target_count': externalHealingTargetCount.toDouble(),

            'target_is_self': 0,
            'target_is_external': 1,
          },
        );
      }

      // -----------------------------------------------------------------------
      // EFECTOS EXTERNOS
      // -----------------------------------------------------------------------

      for (final effectResult in targetResult.effects) {
        externalEffects.add(
          ExternalActionEffect(
            targetId: target.id,
            targetLabel: target.label,
            effect: effectResult,
          ),
        );
      }
    }

    return ActionApplyResult(
      selfDamageApplied: selfDamageApplied,
      selfHealingApplied: selfHealingApplied,
      externalDamageDealt: externalDamageDealt,
      externalHealingDealt: externalHealingDealt,
      criticalDispatched: criticalDispatched,
      externalEffects: List.unmodifiable(externalEffects),
    );
  }

  // ===========================================================================
  // APLICACIÓN SOBRE NUESTRO PERSONAJE
  // ===========================================================================

  int _applySelfDamage(int amount) {
    if (amount <= 0) {
      return 0;
    }

    final before = character.currentHealth;

    character.takeDamage(amount, dispatchTriggers: false);

    final after = character.currentHealth;

    final applied = before - after;

    if (applied <= 0) {
      return 0;
    }

    character.dispatchPassiveTrigger(
      PassiveTriggerEvent.damageReceived,
      eventVariables: {
        'damage': applied.toDouble(),
        'health_before': before.toDouble(),
        'health_after': after.toDouble(),
      },
    );

    character.dispatchPassiveTrigger(
      PassiveTriggerEvent.healthChanged,
      eventVariables: {
        'amount': (-applied).toDouble(),
        'health_before': before.toDouble(),
        'health_after': after.toDouble(),
      },
    );

    return applied;
  }

  int _applySelfHealing(int amount) {
    if (amount <= 0) {
      return 0;
    }

    final before = character.currentHealth;

    character.heal(amount, dispatchTriggers: false);

    final after = character.currentHealth;

    final applied = after - before;

    if (applied <= 0) {
      return 0;
    }

    character.dispatchPassiveTrigger(
      PassiveTriggerEvent.healingReceived,
      eventVariables: {
        'healing': applied.toDouble(),
        'health_before': before.toDouble(),
        'health_after': after.toDouble(),
      },
    );

    character.dispatchPassiveTrigger(
      PassiveTriggerEvent.healthChanged,
      eventVariables: {
        'amount': applied.toDouble(),
        'health_before': before.toDouble(),
        'health_after': after.toDouble(),
      },
    );

    return applied;
  }

  // ===========================================================================
  // TARGET COUNTS
  // ===========================================================================

  int _externalDamageTargetCount(ActionResolutionResult result) {
    return result.externalTargetResults
        .where((targetResult) => targetResult.damage > 0)
        .length;
  }

  int _externalHealingTargetCount(ActionResolutionResult result) {
    return result.externalTargetResults
        .where((targetResult) => targetResult.healing > 0)
        .length;
  }
}
