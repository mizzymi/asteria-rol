import '../models/character.dart';
import '../models/passive.dart';
import '../models/character_effect.dart';

import '../models/formulas/character_formula_context.dart';

import 'formula_evaluator.dart';

class PassiveTriggerEngine {
  final Character character;

  final FormulaEvaluator evaluator;

  PassiveTriggerEngine({required this.character, FormulaEvaluator? evaluator})
    : evaluator = evaluator ?? const FormulaEvaluator();

  // ===========================================================================
  // DISPATCH
  // ===========================================================================

  void dispatch(
    PassiveTriggerEvent event, {
    Map<String, double> eventVariables = const {},
  }) {
    for (final passive in character.enabledPassives) {
      for (final trigger in passive.triggers) {
        if (trigger.event != event) {
          continue;
        }

        evaluateTrigger(passive, trigger, eventVariables: eventVariables);
      }
    }
  }

  // ===========================================================================
  // EVALUAR TRIGGER
  // ===========================================================================

  void evaluateTrigger(
    CharacterPassive passive,
    PassiveTrigger trigger, {
    Map<String, double> eventVariables = const {},
  }) {
    final conditionMet = _evaluateCondition(
      passive,
      trigger,
      eventVariables: eventVariables,
    );

    if (trigger.mode == PassiveTriggerMode.whileCondition) {
      _handlePersistentTrigger(
        passive,
        trigger,
        conditionMet: conditionMet,
        eventVariables: eventVariables,

        // Estamos procesando el evento real.
        // Una acción no persistente puede ejecutarse una vez.
        allowOneShotAction: true,
      );

      return;
    }

    if (!conditionMet) {
      return;
    }

    _executeTriggerAction(passive, trigger, eventVariables: eventVariables);
  }

  // ===========================================================================
  // REEVALUAR TRIGGERS PERSISTENTES
  // ===========================================================================

  void refreshPersistentTriggers({
    Map<String, double> eventVariables = const {},
  }) {
    for (final passive in character.enabledPassives) {
      for (final trigger in passive.triggers) {
        if (trigger.mode != PassiveTriggerMode.whileCondition) {
          continue;
        }

        final conditionMet = _evaluateCondition(
          passive,
          trigger,
          eventVariables: eventVariables,
        );

        _handlePersistentTrigger(
          passive,
          trigger,
          conditionMet: conditionMet,
          eventVariables: eventVariables,

          // Esto es solo una reevaluación del estado.
          // No repetimos heal/resource/damage/etc.
          allowOneShotAction: false,
        );
      }
    }
  }

  // ===========================================================================
  // CONDICIÓN
  // ===========================================================================

  bool _evaluateCondition(
    CharacterPassive passive,
    PassiveTrigger trigger, {
    Map<String, double> eventVariables = const {},
  }) {
    final condition = trigger.condition;

    if (condition == null || condition.expression.trim().isEmpty) {
      return true;
    }

    final result = evaluator.evaluate(
      condition,
      context: CharacterFormulaContext.fromCharacter(
        character,
        passive: passive,
        eventVariables: eventVariables,
      ),
    );

    if (!result.valid) {
      return false;
    }

    return result.value != 0;
  }

  // ===========================================================================
  // VALOR
  // ===========================================================================

  double _evaluateValue(
    CharacterPassive passive,
    PassiveTrigger trigger, {
    Map<String, double> eventVariables = const {},
  }) {
    final formula = trigger.valueFormula;

    if (formula == null || formula.expression.trim().isEmpty) {
      return 0;
    }

    final result = evaluator.evaluate(
      formula,
      context: CharacterFormulaContext.fromCharacter(
        character,
        passive: passive,
        eventVariables: eventVariables,
      ),
    );

    if (!result.valid) {
      return 0;
    }

    return result.value;
  }

  // ===========================================================================
  // TRIGGER PERSISTENTE
  // ===========================================================================

  void _handlePersistentTrigger(
    CharacterPassive passive,
    PassiveTrigger trigger, {
    required bool conditionMet,
    Map<String, double> eventVariables = const {},
    bool allowOneShotAction = false,
  }) {
    switch (trigger.actionType) {
      // =========================================================================
      // EFECTO REALMENTE PERSISTENTE
      //
      // Mientras la condición sea true:
      // existe exactamente una instancia.
      //
      // Cuando pasa a false:
      // se elimina exactamente esa instancia.
      // =========================================================================

      case PassiveTriggerActionType.applyEffect:
        _setTriggerEffectActive(passive, trigger, active: conditionMet);

        return;

      // =========================================================================
      // RESTO DE ACCIONES
      //
      // addResource / heal / damage / charges / counters...
      // no deben ejecutarse continuamente cada vez que hacemos
      // refreshPersistentTriggers().
      //
      // Solo se ejecutan una vez cuando estamos evaluando el evento original.
      // =========================================================================

      default:
        if (!conditionMet || !allowOneShotAction) {
          return;
        }

        _executeTriggerAction(passive, trigger, eventVariables: eventVariables);

        return;
    }
  }

  // ===========================================================================
  // EJECUTAR ACCIÓN
  // ===========================================================================

  void _executeTriggerAction(
    CharacterPassive passive,
    PassiveTrigger trigger, {
    Map<String, double> eventVariables = const {},
  }) {
    final value = _evaluateValue(
      passive,
      trigger,
      eventVariables: eventVariables,
    );

    switch (trigger.actionType) {
      // -----------------------------------------------------------------------
      // RECURSOS
      // -----------------------------------------------------------------------

      case PassiveTriggerActionType.addResource:
        final resourceId = trigger.targetId;

        if (resourceId == null || resourceId.isEmpty) {
          return;
        }

        final resource = character.resourceById(resourceId);

        if (resource == null) {
          return;
        }

        character.addResourceValue(
          resourceId,
          value.round(),
          dispatchTriggers: false,
        );

        character.refreshPassiveTriggers(
          eventVariables: {
            'current_resource':
                character.resourceById(resourceId)?.currentValue.toDouble() ??
                0,
          },
        );

        break;

      case PassiveTriggerActionType.subtractResource:
        final resourceId = trigger.targetId;

        if (resourceId == null || resourceId.isEmpty) {
          return;
        }

        final resource = character.resourceById(resourceId);

        if (resource == null) {
          return;
        }

        character.subtractResourceValue(
          resourceId,
          value.round(),
          dispatchTriggers: false,
        );

        character.refreshPassiveTriggers(
          eventVariables: {
            'current_resource':
                character.resourceById(resourceId)?.currentValue.toDouble() ??
                0,
          },
        );

        break;

      case PassiveTriggerActionType.setResource:
        final resourceId = trigger.targetId;

        if (resourceId == null || resourceId.isEmpty) {
          return;
        }

        final resource = character.resourceById(resourceId);

        if (resource == null) {
          return;
        }

        character.setResourceValue(
          resourceId,
          value.round(),
          dispatchTriggers: false,
        );

        character.refreshPassiveTriggers(
          eventVariables: {
            'current_resource':
                character.resourceById(resourceId)?.currentValue.toDouble() ??
                0,
          },
        );

        break;

      // -----------------------------------------------------------------------
      // CARGAS
      // -----------------------------------------------------------------------

      case PassiveTriggerActionType.addCharge:
        character.addPassiveCharges(
          passive.id,
          value.round(),
          dispatchTriggers: false,
        );

        character.refreshPassiveTriggers(
          eventVariables: {
            'current_charges': passive.currentCharges.toDouble(),
          },
        );

        break;

      case PassiveTriggerActionType.subtractCharge:
        character.subtractPassiveCharges(
          passive.id,
          value.round(),
          dispatchTriggers: false,
        );

        character.refreshPassiveTriggers(
          eventVariables: {
            'current_charges': passive.currentCharges.toDouble(),
          },
        );

        break;

      // -----------------------------------------------------------------------
      // CONTADORES
      // -----------------------------------------------------------------------

      case PassiveTriggerActionType.incrementCounter:
        final counterId = trigger.targetId;

        if (counterId == null || counterId.isEmpty) {
          return;
        }

        final amount = value.round();

        if (amount == 0) {
          return;
        }

        character.incrementCounter(counterId, amount, dispatchTriggers: false);

        refreshPersistentTriggers(
          eventVariables: {
            'current_counter': character.counterValue(counterId).toDouble(),
          },
        );

        break;

      case PassiveTriggerActionType.setCounter:
        final counterId = trigger.targetId;

        if (counterId == null || counterId.isEmpty) {
          return;
        }

        character.setCounter(counterId, value.round(), dispatchTriggers: false);

        refreshPersistentTriggers(
          eventVariables: {
            'current_counter': character.counterValue(counterId).toDouble(),
          },
        );

        break;

      // -----------------------------------------------------------------------
      // EFECTOS
      // -----------------------------------------------------------------------

      case PassiveTriggerActionType.applyEffect:
        _setTriggerEffectActive(passive, trigger, active: true);
        break;

      case PassiveTriggerActionType.removeEffect:
        _setTriggerEffectActive(passive, trigger, active: false);
        break;

      // -----------------------------------------------------------------------
      // VIDA / DAÑO
      // -----------------------------------------------------------------------

      case PassiveTriggerActionType.dealDamage:
        character.takeDamage(value.round(), dispatchTriggers: false);

        refreshPersistentTriggers();

        break;

      case PassiveTriggerActionType.heal:
        character.heal(value.round(), dispatchTriggers: false);

        refreshPersistentTriggers();

        break;
    }
  }

  // ===========================================================================
  // EFECTO PERSISTENTE
  // ===========================================================================

  void _setTriggerEffectActive(
    CharacterPassive passive,
    PassiveTrigger trigger, {
    required bool active,
  }) {
    final effectId = trigger.targetId;

    if (effectId == null || effectId.isEmpty) {
      return;
    }

    CharacterEffect? sourceEffect;

    for (final effect in passive.linkedEffects) {
      if (effect.id == effectId) {
        sourceEffect = effect;
        break;
      }
    }

    if (sourceEffect == null) {
      return;
    }

    final instanceId = 'trigger:${passive.id}:${trigger.id}:${sourceEffect.id}';

    final existingIndex = character.effects.indexWhere(
      (effect) => effect.id == instanceId,
    );

    // -----------------------------------------------------------------------
    // ACTIVAR
    // -----------------------------------------------------------------------

    if (active) {
      if (existingIndex >= 0) {
        character.effects[existingIndex].enabled = true;
        return;
      }

      final instance = CharacterEffect.fromMap(sourceEffect.toMap());

      instance.id = instanceId;
      instance.enabled = true;

      character.effects.add(instance);

      return;
    }

    // -----------------------------------------------------------------------
    // DESACTIVAR
    // -----------------------------------------------------------------------

    if (existingIndex >= 0) {
      character.effects.removeAt(existingIndex);
    }
  }
}
