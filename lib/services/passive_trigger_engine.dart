import '../models/character.dart';
import '../models/passive.dart';
import '../models/character_effect.dart';
import '../models/formulas/formula_context.dart';
import '../models/formulas/character_formula_context.dart';
import '../models/dice_pool.dart';
import '../models/action_trigger_context.dart';
import '../models/passive_trigger_external_result.dart';

import 'resource_modifier_resolver.dart';
import 'formula_evaluator.dart';

class PassiveTriggerEngine {
  final Character character;

  final FormulaEvaluator evaluator;

  // ===========================================================================
  // RUNTIME DE DISPATCH
  //
  // Todas las instancias de PassiveTriggerEngine que trabajen sobre el mismo
  // Character comparten este runtime.
  //
  // Esto es importante porque Character.dispatchPassiveTrigger() crea un engine
  // nuevo en cada evento.
  // ===========================================================================

  static final Expando<_PassiveTriggerRuntime> _runtimeByCharacter =
      Expando<_PassiveTriggerRuntime>('passive_trigger_runtime');

  PassiveTriggerEngine({required this.character, FormulaEvaluator? evaluator})
    : evaluator = evaluator ?? const FormulaEvaluator();

  _PassiveTriggerRuntime get _runtime {
    var runtime = _runtimeByCharacter[character];

    if (runtime != null) {
      return runtime;
    }

    runtime = _PassiveTriggerRuntime();

    _runtimeByCharacter[character] = runtime;

    return runtime;
  }

  bool canUseTrigger(CharacterPassive passive, PassiveTrigger trigger) {
    switch (trigger.usageLimit) {
      // =========================================================================
      // SIN LÍMITE
      // =========================================================================

      case TriggerUsageLimit.unlimited:
        return true;

      // =========================================================================
      // UNA VEZ POR TURNO
      // =========================================================================

      case TriggerUsageLimit.oncePerTurn:
        final key = _usageKey(passive, trigger);

        final lastUsed = _runtime.lastUsedTurnByTriggerKey[key];

        return lastUsed != character.combatTurnSequence;

      // =========================================================================
      // UNA VEZ POR RONDA
      // =========================================================================

      case TriggerUsageLimit.oncePerRound:
        final key = _usageKey(passive, trigger);

        final lastUsed = _runtime.lastUsedRoundByTriggerKey[key];

        return lastUsed != character.combatRound;
    }
  }

  void consumeTriggerUsage(CharacterPassive passive, PassiveTrigger trigger) {
    final key = _usageKey(passive, trigger);

    switch (trigger.usageLimit) {
      case TriggerUsageLimit.unlimited:
        return;

      case TriggerUsageLimit.oncePerTurn:
        _runtime.lastUsedTurnByTriggerKey[key] = character.combatTurnSequence;

        return;

      case TriggerUsageLimit.oncePerRound:
        _runtime.lastUsedRoundByTriggerKey[key] = character.combatRound;

        return;
    }
  }

  String _usageKey(CharacterPassive passive, PassiveTrigger trigger) {
    return '${passive.id}:${trigger.id}';
  }

  bool _isTriggerActive(CharacterPassive passive, PassiveTrigger trigger) {
    final key = _usageKey(passive, trigger);

    return _runtime.activeTriggerKeys.contains(key);
  }

  bool _beginTriggerExecution(
    CharacterPassive passive,
    PassiveTrigger trigger,
  ) {
    final key = _usageKey(passive, trigger);

    if (_runtime.activeTriggerKeys.contains(key)) {
      return false;
    }

    _runtime.activeTriggerKeys.add(key);

    return true;
  }

  void _endTriggerExecution(CharacterPassive passive, PassiveTrigger trigger) {
    final key = _usageKey(passive, trigger);

    _runtime.activeTriggerKeys.remove(key);
  }
  // ===========================================================================
  // DISPATCH
  // ===========================================================================

  void dispatch(
    PassiveTriggerEvent event, {
    Map<String, double> eventVariables = const {},
    ActionTriggerContext? actionContext,
  }) {
    final runtime = _runtime;

    if (runtime.dispatchDepth >= _PassiveTriggerRuntime.maximumDispatchDepth) {
      return;
    }

    runtime.dispatchDepth++;

    try {
      final passives = character.enabledPassives.toList(growable: false);

      for (final passive in passives) {
        final triggers = List<PassiveTrigger>.from(passive.triggers);

        for (final trigger in triggers) {
          if (trigger.event != event) {
            continue;
          }

          evaluateTrigger(
            passive,
            trigger,
            eventVariables: eventVariables,
            actionContext: actionContext,
          );
        }
      }
    } finally {
      runtime.dispatchDepth--;
    }
  }

  bool _supportsPersistentTrigger(PassiveTrigger trigger) {
    if (trigger.mode != PassiveTriggerMode.whileCondition) {
      return false;
    }

    if (!trigger.targetsSelf) {
      return false;
    }

    if (trigger.actions.length != 1) {
      return false;
    }

    final action = trigger.actions.first;

    if (action.type != PassiveTriggerActionType.applyEffect) {
      return false;
    }

    switch (trigger.event) {
      case PassiveTriggerEvent.healthChanged:
      case PassiveTriggerEvent.resourceChanged:
      case PassiveTriggerEvent.chargeChanged:
      case PassiveTriggerEvent.counterChanged:
        return true;

      default:
        return false;
    }
  }

  // ===========================================================================
  // EVALUAR TRIGGER
  // ===========================================================================

  void evaluateTrigger(
    CharacterPassive passive,
    PassiveTrigger trigger, {
    Map<String, double> eventVariables = const {},
    ActionTriggerContext? actionContext,
  }) {
    // ===========================================================================
    // EXTERNOS
    //
    // Los actionTarget se resuelven mediante ActionResolver / ActionResolutionFlow.
    // Este engine solo ejecuta mecánicamente triggers sobre self.
    // ===========================================================================

    if (trigger.targetsActionTarget) {
      return;
    }

    if (_isTriggerActive(passive, trigger)) {
      return;
    }

    // ===========================================================================
    // PERSISTENTES
    // ===========================================================================

    if (_supportsPersistentTrigger(trigger)) {
      final conditionMet = _evaluateCondition(passive, trigger);

      _setTriggerEffectActive(passive, trigger, active: conditionMet);

      return;
    }

    // ===========================================================================
    // LÍMITE
    // ===========================================================================

    if (!canUseTrigger(passive, trigger)) {
      return;
    }

    // ===========================================================================
    // CONDICIÓN
    // ===========================================================================

    final conditionMet = _evaluateCondition(
      passive,
      trigger,
      eventVariables: eventVariables,
    );

    if (!conditionMet) {
      return;
    }

    // ===========================================================================
    // ACCIONES SELF
    // ===========================================================================

    if (!_beginTriggerExecution(passive, trigger)) {
      return;
    }

    try {
      _executeTriggerActions(
        passive,
        trigger,
        eventVariables: eventVariables,
        actionContext: actionContext,
      );

      consumeTriggerUsage(passive, trigger);
    } finally {
      _endTriggerExecution(passive, trigger);
    }
  }

  bool consumeExternalTriggerResult(PassiveTriggerExternalResult result) {
    final resolutionId = result.resolutionId.trim();

    if (resolutionId.isEmpty) {
      return false;
    }

    final runtime = _runtime;

    if (!runtime.consumedExternalResultIds.add(resolutionId)) {
      return false;
    }

    CharacterPassive? passive;

    for (final candidate in character.enabledPassives) {
      if (candidate.id == result.passiveId) {
        passive = candidate;
        break;
      }
    }

    if (passive == null) {
      runtime.consumedExternalResultIds.remove(resolutionId);

      return false;
    }

    PassiveTrigger? trigger;

    for (final candidate in passive.triggers) {
      if (candidate.id == result.triggerId) {
        trigger = candidate;
        break;
      }
    }

    if (trigger == null) {
      runtime.consumedExternalResultIds.remove(resolutionId);

      return false;
    }

    consumeTriggerUsage(passive, trigger);

    return true;
  }

  // ===========================================================================
  // REEVALUAR TRIGGERS PERSISTENTES
  // ===========================================================================

  void refreshPersistentTriggers() {
    final runtime = _runtime;

    // ===========================================================================
    // REFRESH APLAZADO DURANTE DISPATCH
    // ===========================================================================

    if (runtime.dispatchDepth > 0) {
      runtime.persistentRefreshPending = true;

      return;
    }

    runtime.persistentRefreshPending = false;

    // ===========================================================================
    // CONVERGENCIA
    //
    // Un efecto persistente puede modificar el estado del personaje y provocar
    // que cambie la condición de otro trigger persistente.
    //
    // Repetimos hasta que una pasada completa no produzca cambios.
    // ===========================================================================
    for (
      var pass = 0;
      pass < _PassiveTriggerRuntime.maximumPersistentRefreshPasses;
      pass++
    ) {
      var changed = false;

      final passives = character.enabledPassives.toList(growable: false);

      for (final passive in passives) {
        final triggers = List<PassiveTrigger>.from(passive.triggers);

        for (final trigger in triggers) {
          if (!_supportsPersistentTrigger(trigger)) {
            continue;
          }

          final conditionMet = _evaluateCondition(passive, trigger);

          final triggerChanged = _setTriggerEffectActive(
            passive,
            trigger,
            active: conditionMet,
          );

          if (triggerChanged) {
            changed = true;
          }
        }
      }

      // Ya alcanzamos un estado estable.
      if (!changed) {
        return;
      }
    }

    // Si llegamos aquí existe probablemente una combinación de
    // condiciones persistentes que oscila entre estados.
    //
    // No seguimos ejecutando para evitar un bucle infinito.
  }

  // ===========================================================================
  // CONDICIÓN
  // ===========================================================================

  FormulaContext _buildFormulaContext(
    CharacterPassive passive, {
    Map<String, double> eventVariables = const {},
  }) {
    final resourceResolver = ResourceModifierResolver(character: character);

    return CharacterFormulaContext.fromCharacter(
      character,
      passive: passive,
      eventVariables: eventVariables,

      resourceResolver: (resourceId) {
        final resource = character.resourceById(resourceId);

        if (resource == null) {
          return null;
        }

        final snapshot = resourceResolver.resolveSnapshot(resource);

        return FormulaResourceValue(
          baseCurrentValue: snapshot.baseCurrentValue,

          baseMaxValue: snapshot.baseMaxValue,

          currentValue: snapshot.currentValue,

          maxValue: snapshot.maxValue,
        );
      },

      baseResourceResolver: (resourceId) {
        final resource = character.resourceById(resourceId);

        if (resource == null) {
          return null;
        }

        final baseMax = resource.hasMaximum
            ? resource.maxValue.toDouble()
            : null;

        return FormulaResourceValue(
          baseCurrentValue: resource.currentValue.toDouble(),

          baseMaxValue: baseMax,

          currentValue: resource.currentValue.toDouble(),

          maxValue: baseMax,
        );
      },
    );
  }

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
      context: _buildFormulaContext(passive, eventVariables: eventVariables),
    );

    if (!result.valid) {
      return false;
    }

    return result.value != 0;
  }

  // ===========================================================================
  // VALOR
  // ===========================================================================

  double _evaluateActionValue(
    CharacterPassive passive,
    PassiveTriggerAction action, {
    Map<String, double> eventVariables = const {},
  }) {
    final formula = action.valueFormula;

    if (formula == null || formula.expression.trim().isEmpty) {
      return 0;
    }

    final result = evaluator.evaluate(
      formula,
      context: _buildFormulaContext(passive, eventVariables: eventVariables),
    );

    if (!result.valid) {
      return 0;
    }

    return result.value;
  }

  // ===========================================================================
  // EJECUTAR ACCIÓN
  // ===========================================================================

  void _executeTriggerActions(
    CharacterPassive passive,
    PassiveTrigger trigger, {
    Map<String, double> eventVariables = const {},
    ActionTriggerContext? actionContext,
  }) {
    // ===========================================================================
    // SELF
    // ===========================================================================

    for (final action in trigger.actions) {
      _executeSelfAction(
        passive,
        trigger,
        action,
        eventVariables: eventVariables,
      );
    }
  }

  void _executeSelfAction(
    CharacterPassive passive,
    PassiveTrigger trigger,
    PassiveTriggerAction action, {
    Map<String, double> eventVariables = const {},
  }) {
    final value = _evaluateActionValue(
      passive,
      action,
      eventVariables: eventVariables,
    );

    switch (action.type) {
      // =========================================================================
      // RECURSOS
      // =========================================================================

      case PassiveTriggerActionType.addResource:
        final resourceId = action.resourceId;

        if (resourceId == null || resourceId.isEmpty) {
          return;
        }

        final amount = value.round();

        if (amount == 0) {
          return;
        }

        character.addResourceValue(resourceId, amount, dispatchTriggers: true);

        return;

      case PassiveTriggerActionType.subtractResource:
        final resourceId = action.resourceId;

        if (resourceId == null || resourceId.isEmpty) {
          return;
        }

        final amount = value.round();

        if (amount <= 0) {
          return;
        }

        character.subtractResourceValue(
          resourceId,
          amount,
          dispatchTriggers: true,
        );

        return;

      case PassiveTriggerActionType.setResource:
        final resourceId = action.resourceId;

        if (resourceId == null || resourceId.isEmpty) {
          return;
        }

        character.setResourceValue(
          resourceId,
          value.round(),
          dispatchTriggers: true,
        );

        return;

      // =========================================================================
      // CARGAS
      // =========================================================================

      case PassiveTriggerActionType.addCharge:
        final amount = value.round();

        if (amount == 0) {
          return;
        }

        character.addPassiveCharges(passive.id, amount, dispatchTriggers: true);

        return;

      case PassiveTriggerActionType.subtractCharge:
        final amount = value.round();

        if (amount <= 0) {
          return;
        }

        character.subtractPassiveCharges(
          passive.id,
          amount,
          dispatchTriggers: true,
        );

        return;

      // =========================================================================
      // CONTADORES
      // =========================================================================

      case PassiveTriggerActionType.incrementCounter:
        final counterId = action.counterId;

        if (counterId == null || counterId.isEmpty) {
          return;
        }

        final amount = value.round();

        if (amount == 0) {
          return;
        }

        character.incrementCounter(counterId, amount, dispatchTriggers: true);

        return;

      case PassiveTriggerActionType.setCounter:
        final counterId = action.counterId;

        if (counterId == null || counterId.isEmpty) {
          return;
        }

        character.setCounter(counterId, value.round(), dispatchTriggers: true);

        return;

      // =========================================================================
      // EFECTOS
      // =========================================================================

      case PassiveTriggerActionType.applyEffect:
        _applyOneShotTriggerEffect(passive, trigger, action);

        return;

      case PassiveTriggerActionType.removeEffect:
        _removeSelectedEffect(action);

        return;

      // =========================================================================
      // DAÑO
      // =========================================================================

      case PassiveTriggerActionType.dealDamage:
        final amount = _resolveTriggerActionAmount(
          passive,
          action,
          eventVariables: eventVariables,
        );

        if (amount <= 0) {
          return;
        }

        character.takeDamage(amount, dispatchTriggers: true);

        return;

      // =========================================================================
      // CURACIÓN
      // =========================================================================

      case PassiveTriggerActionType.heal:
        final amount = _resolveTriggerActionAmount(
          passive,
          action,
          eventVariables: eventVariables,
        );

        if (amount <= 0) {
          return;
        }

        character.heal(amount, dispatchTriggers: true);

        return;
    }
  }

  void removeRuntimeEffectsForPassive(
    String passiveId, {
    bool refreshTriggers = true,
  }) {
    final prefix = 'trigger:$passiveId:';

    final idsToRemove = character.effects
        .where((effect) => effect.id.startsWith(prefix))
        .map((effect) => effect.id)
        .toList(growable: false);

    if (idsToRemove.isEmpty) {
      return;
    }

    for (final effectId in idsToRemove) {
      character.removeEffect(
        effectId,
        refreshTriggers: false,
        dispatchHealthTriggers: false,
      );
    }

    character.normalizeHealth();

    if (refreshTriggers) {
      character.refreshPassiveTriggers();
    }
  }

  // ===========================================================================
  // EFECTO PERSISTENTE
  // ===========================================================================

  CharacterEffect? _findLinkedEffectTemplate(
    CharacterPassive passive,
    String? effectId,
  ) {
    final id = effectId?.trim();

    if (id == null || id.isEmpty) {
      return null;
    }

    for (final effect in passive.linkedEffects) {
      if (effect.id == id) {
        return effect;
      }
    }

    return null;
  }

  void _applyOneShotTriggerEffect(
    CharacterPassive passive,
    PassiveTrigger trigger,
    PassiveTriggerAction action,
  ) {
    final templateId = action.effectId?.trim();

    if (templateId == null || templateId.isEmpty) {
      return;
    }

    final sourceEffect = _findLinkedEffectTemplate(passive, templateId);

    if (sourceEffect == null) {
      return;
    }

    final instance = CharacterEffect.fromMap(sourceEffect.toMap());

    instance.id =
        'trigger:${passive.id}:'
        '${trigger.id}:'
        '${sourceEffect.id}:'
        '${DateTime.now().microsecondsSinceEpoch}';

    instance.enabled = true;

    instance.resetDuration();

    character.applyReceivedEffect(
      instance,
      templateId: templateId,
      refreshTriggers: false,
      dispatchHealthTriggers: false,
      eventVariables: {
        'trigger_source_passive': 1,
        'source_passive_${passive.id}': 1,
        'passive_trigger_${trigger.id}': 1,
      },
    );
  }

  int _resolveTriggerActionAmount(
    CharacterPassive passive,
    PassiveTriggerAction action, {
    Map<String, double> eventVariables = const {},
  }) {
    final modifier = _evaluateActionValue(
      passive,
      action,
      eventVariables: eventVariables,
    ).round();

    if (!action.hasDice) {
      return modifier;
    }

    final roll = DicePoolRoller.roll(
      pools: action.dicePools,
      modifier: modifier,
    );

    return roll.total;
  }

  void _removeSelectedEffect(PassiveTriggerAction action) {
    final effectId = action.effectId?.trim();

    if (effectId == null || effectId.isEmpty) {
      return;
    }

    character.removeEffect(
      effectId,
      refreshTriggers: false,
      dispatchHealthTriggers: false,
    );
  }

  bool _setTriggerEffectActive(
    CharacterPassive passive,
    PassiveTrigger trigger, {
    required bool active,
  }) {
    if (trigger.actions.length != 1) {
      return false;
    }

    final action = trigger.actions.first;

    if (action.type != PassiveTriggerActionType.applyEffect) {
      return false;
    }

    final templateId = action.effectId?.trim();

    if (templateId == null || templateId.isEmpty) {
      return false;
    }

    final sourceEffect = _findLinkedEffectTemplate(passive, templateId);

    if (sourceEffect == null) {
      return false;
    }

    final instanceId =
        'trigger:${passive.id}:'
        '${trigger.id}:'
        '${sourceEffect.id}';

    final existingIndex = character.effects.indexWhere(
      (effect) => effect.id == instanceId,
    );

    if (!active) {
      if (existingIndex < 0) {
        return false;
      }

      character.removeEffect(
        instanceId,
        refreshTriggers: false,
        dispatchHealthTriggers: false,
      );

      return true;
    }

    if (existingIndex >= 0) {
      final existing = character.effects[existingIndex];

      var changed = false;

      if (!existing.enabled) {
        existing.enabled = true;
        changed = true;
      }

      if (existing.durationType != CharacterEffectDurationType.permanent) {
        existing.durationType = CharacterEffectDurationType.permanent;

        changed = true;
      }

      if (existing.maxDuration != 0) {
        existing.maxDuration = 0;
        changed = true;
      }

      if (existing.currentDuration != 0) {
        existing.currentDuration = 0;
        changed = true;
      }

      if (existing.minuteRoundProgress != 0) {
        existing.minuteRoundProgress = 0;

        changed = true;
      }

      if (changed) {
        character.normalizeHealth();
      }

      return changed;
    }

    final instance = CharacterEffect.fromMap(sourceEffect.toMap());

    instance.id = instanceId;
    instance.enabled = true;

    instance.durationType = CharacterEffectDurationType.permanent;

    instance.maxDuration = 0;
    instance.currentDuration = 0;
    instance.minuteRoundProgress = 0;

    character.applyReceivedEffect(
      instance,
      templateId: templateId,
      refreshTriggers: false,
      dispatchHealthTriggers: false,
      eventVariables: {
        'trigger_source_passive': 1,
        'source_passive_${passive.id}': 1,
        'passive_trigger_${trigger.id}': 1,
      },
    );

    return true;
  }
}

class _PassiveTriggerRuntime {
  final Set<String> consumedExternalResultIds = <String>{};

  // ===========================================================================
  // TRIGGERS ACTIVOS
  // ===========================================================================

  final Set<String> activeTriggerKeys = <String>{};

  /// Último turno en el que se consumió cada trigger.
  final Map<String, int> lastUsedTurnByTriggerKey = <String, int>{};

  /// Última ronda en la que se consumió cada trigger.
  final Map<String, int> lastUsedRoundByTriggerKey = <String, int>{};

  // ===========================================================================
  // PROFUNDIDAD DE DISPATCH
  // ===========================================================================

  int dispatchDepth = 0;

  static const int maximumPersistentRefreshPasses = 32;

  static const int maximumDispatchDepth = 16;

  // ===========================================================================
  // REFRESH PERSISTENTE PENDIENTE
  //
  // Permite agrupar múltiples cambios ocurridos dentro de una cadena de
  // triggers y reevaluar los whileCondition una sola vez al terminar.
  // ===========================================================================

  bool persistentRefreshPending = false;
}
