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

    var damageApplied = 0;

    if (outcome.damage > 0) {
      final before = character.currentHealth;

      character.takeDamage(outcome.damage, dispatchTriggers: true);

      damageApplied = before - character.currentHealth;
    }

    // =========================================================================
    // CURACIÓN
    // =========================================================================

    var healingApplied = 0;

    if (outcome.healing > 0) {
      final before = character.currentHealth;

      character.heal(outcome.healing, dispatchTriggers: true);

      healingApplied = character.currentHealth - before;
    }

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

      character.addEffect(effect, refreshTriggers: false);

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
      effectsApplied: appliedEffectIds.length,
      appliedEffectIds: Set<String>.unmodifiable(appliedEffectIds),
      killed: healthBefore > 0 && healthAfter <= 0,
      healthBefore: healthBefore,
      healthAfter: healthAfter,
    );
  }

  String _newAppliedEffectId(String templateId) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    final sequence = _effectSequence++;

    return '${templateId}_external_'
        '${timestamp}_$sequence';
  }
}
