import '../models/action_apply_result.dart';
import '../models/action_event_variables.dart';
import '../models/character.dart';
import '../models/character_effect.dart';
import '../models/external_action_outcome.dart';
import '../models/passive.dart';

class ExternalActionApplier {
  final Character character;

  int _effectSequence = 0;

  ExternalActionApplier({required this.character});

  ExternalActionOutcome apply(ExternalTargetOutcome outcome) {
    final healthBefore = character.currentHealth;

    // =========================================================================
    // DAÑO
    // =========================================================================

    final damageResult = _applyDamage(outcome.damage);

    final damageApplied = damageResult.applied;

    final killed = damageResult.killed;

    // =========================================================================
    // CURACIÓN
    // =========================================================================

    final healingApplied = _applyHealing(outcome.healing);

    // =========================================================================
    // EFECTOS
    // =========================================================================

    final appliedEffectIds = <String>{};

    for (final effectResult in outcome.effects) {
      final template = effectResult.template;

      final templateId = template.id.trim();

      if (templateId.isEmpty) {
        continue;
      }

      final effect = CharacterEffect.fromMap(template.toMap());

      effect.id = _newAppliedEffectId(templateId);

      effect.enabled = true;

      effect.resetDuration();

      character.addEffect(
        effect,
        refreshTriggers: false,
        dispatchHealthTriggers: false,
      );

      appliedEffectIds.add(templateId);

      character.dispatchPassiveTrigger(
        PassiveTriggerEvent.effectReceived,
        eventVariables: {
          ActionEventVariables.effectReceived: 1,
          ActionEventVariables.effectApplied: 1,
          ActionEventVariables.effectResolved: 1,
          ActionEventVariables.effectConfirmed: 1,

          'effect_$templateId': 1,
        },
      );
    }

    for (final template in outcome.passiveEffects) {
      final templateId = template.id.trim();

      if (templateId.isEmpty) {
        continue;
      }

      final effect = CharacterEffect.fromMap(template.toMap());

      effect.id = _newAppliedEffectId(templateId);

      effect.enabled = true;
      effect.resetDuration();

      character.addEffect(
        effect,
        refreshTriggers: false,
        dispatchHealthTriggers: false,
      );

      appliedEffectIds.add(templateId);

      character.dispatchPassiveTrigger(
        PassiveTriggerEvent.effectReceived,
        eventVariables: {
          ActionEventVariables.effectReceived: 1,

          ActionEventVariables.effectApplied: 1,

          ActionEventVariables.effectResolved: 1,

          ActionEventVariables.effectConfirmed: 1,

          'effect_$templateId': 1,
        },
      );
    }

    // =========================================================================
    // RESULTADO REAL
    // =========================================================================

    final healthAfter = character.currentHealth;

    return ExternalActionOutcome(
      targetId: outcome.targetId,

      damageApplied: damageApplied,

      healingApplied: healingApplied,

      appliedEffectIds: Set<String>.unmodifiable(appliedEffectIds),

      killed: killed,

      healthBefore: healthBefore,

      healthAfter: healthAfter,
    );
  }

  // ===========================================================================
  // DAÑO RECIBIDO
  // ===========================================================================

  ({int applied, bool killed}) _applyDamage(int amount) {
    if (amount <= 0) {
      return (applied: 0, killed: false);
    }

    final before = character.currentHealth;

    character.takeDamage(amount, dispatchTriggers: false);

    final after = character.currentHealth;

    final applied = before - after;

    if (applied <= 0) {
      return (applied: 0, killed: false);
    }

    final killed = before > 0 && after <= 0;

    final healthVariables = <String, double>{
      ActionEventVariables.healthBefore: before.toDouble(),

      ActionEventVariables.healthAfter: after.toDouble(),
    };

    // ===========================================================================
    // DAÑO RECIBIDO
    // ===========================================================================

    character.dispatchPassiveTrigger(
      PassiveTriggerEvent.damageReceived,
      eventVariables: {
        ...healthVariables,

        ActionEventVariables.damage: applied.toDouble(),

        ActionEventVariables.damageApplied: applied.toDouble(),

        ActionEventVariables.damageConfirmed: 1,
      },
    );

    // ===========================================================================
    // CAMBIO DE VIDA
    // ===========================================================================

    character.dispatchPassiveTrigger(
      PassiveTriggerEvent.healthChanged,
      eventVariables: {
        ...healthVariables,

        ActionEventVariables.healthChange: (-applied).toDouble(),
      },
    );

    // ===========================================================================
    // MUERTE
    // ===========================================================================

    if (killed) {
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

    return (applied: applied, killed: killed);
  }

  // ===========================================================================
  // CURACIÓN RECIBIDA
  // ===========================================================================

  int _applyHealing(int amount) {
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

    final healthVariables = <String, double>{
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

        ActionEventVariables.healingApplied: applied.toDouble(),

        ActionEventVariables.healingConfirmed: 1,
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

  String _newAppliedEffectId(String templateId) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    final sequence = _effectSequence++;

    return '${templateId}_external_'
        '${timestamp}_$sequence';
  }
}
