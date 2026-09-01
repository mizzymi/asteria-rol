import '../models/character.dart';
import '../models/character_effect.dart';
import '../models/passive.dart';
import '../models/formulas/formula_context.dart';
import '../models/formulas/character_formula_context.dart';
import '../models/dice_pool.dart';
import '../models/damage_bonus.dart';
import '../models/healing_bonus.dart';
import '../models/action_trigger_context.dart';
import '../models/character_effect_trigger_external_result.dart';

import 'formula_evaluator.dart';
import 'resource_modifier_resolver.dart';

class CharacterEffectTriggerEngine {
  final Character character;

  final FormulaEvaluator evaluator;

  static final Expando<_CharacterEffectTriggerRuntime> _runtimeByCharacter =
      Expando<_CharacterEffectTriggerRuntime>(
        'character_effect_trigger_runtime',
      );

  CharacterEffectTriggerEngine({
    required this.character,
    FormulaEvaluator? evaluator,
  }) : evaluator = evaluator ?? const FormulaEvaluator();

  String _usageKey(CharacterEffect effect, CharacterEffectTrigger trigger) {
    return '${effect.id}:${trigger.id}';
  }

  bool _isTriggerActive(
    CharacterEffect effect,
    CharacterEffectTrigger trigger,
  ) {
    final key = _usageKey(effect, trigger);

    return _runtime.activeTriggerKeys.contains(key);
  }

  bool _beginTriggerExecution(
    CharacterEffect effect,
    CharacterEffectTrigger trigger,
  ) {
    final key = _usageKey(effect, trigger);

    if (_runtime.activeTriggerKeys.contains(key)) {
      return false;
    }

    _runtime.activeTriggerKeys.add(key);

    return true;
  }

  void _endTriggerExecution(
    CharacterEffect effect,
    CharacterEffectTrigger trigger,
  ) {
    final key = _usageKey(effect, trigger);

    _runtime.activeTriggerKeys.remove(key);
  }

  bool consumeExternalTriggerResult(
    CharacterEffectTriggerExternalResult result,
  ) {
    final resolutionId = result.resolutionId.trim();

    if (resolutionId.isEmpty) {
      return false;
    }

    final runtime = _runtime;

    if (!runtime.consumedExternalResultIds.add(resolutionId)) {
      return false;
    }

    CharacterEffect? sourceEffect;

    for (final candidate in character.effects) {
      if (candidate.id == result.sourceEffectId) {
        sourceEffect = candidate;
        break;
      }
    }

    if (sourceEffect == null) {
      runtime.consumedExternalResultIds.remove(resolutionId);

      return false;
    }

    CharacterEffectTrigger? trigger;

    for (final candidate in sourceEffect.triggers) {
      if (candidate.id == result.triggerId) {
        trigger = candidate;
        break;
      }
    }

    if (trigger == null) {
      runtime.consumedExternalResultIds.remove(resolutionId);

      return false;
    }

    consumeTriggerUsage(sourceEffect, trigger);

    return true;
  }

  bool canUseTrigger(CharacterEffect effect, CharacterEffectTrigger trigger) {
    final key = _usageKey(effect, trigger);

    switch (trigger.usageLimit) {
      case TriggerUsageLimit.unlimited:
        return true;

      case TriggerUsageLimit.oncePerTurn:
        final lastUsed = _runtime.lastUsedTurnByTriggerKey[key];

        return lastUsed != character.combatTurnSequence;

      case TriggerUsageLimit.oncePerRound:
        final lastUsed = _runtime.lastUsedRoundByTriggerKey[key];

        return lastUsed != character.combatRound;
    }
  }

  void consumeTriggerUsage(
    CharacterEffect effect,
    CharacterEffectTrigger trigger,
  ) {
    final key = _usageKey(effect, trigger);

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

  _CharacterEffectTriggerRuntime get _runtime {
    var runtime = _runtimeByCharacter[character];

    if (runtime != null) {
      return runtime;
    }

    runtime = _CharacterEffectTriggerRuntime();

    _runtimeByCharacter[character] = runtime;

    return runtime;
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

    if (runtime.dispatchDepth >=
        _CharacterEffectTriggerRuntime.maximumDispatchDepth) {
      return;
    }

    runtime.dispatchDepth++;

    try {
      final effects = character.effects
          .where((effect) => effect.enabled && !effect.expired)
          .toList(growable: false);

      for (final effect in effects) {
        final triggers = List<CharacterEffectTrigger>.from(effect.triggers);

        for (final trigger in triggers) {
          if (trigger.event != event) {
            continue;
          }

          _evaluateTrigger(
            effect,
            trigger,
            eventVariables: eventVariables,
            actionContext: actionContext,
          );
        }
      }
    } finally {
      runtime.dispatchDepth--;

      if (runtime.dispatchDepth == 0 && runtime.persistentRefreshPending) {
        runtime.persistentRefreshPending = false;

        refreshPersistentTriggers();
      }
    }
  }

  // ===========================================================================
  // EVALUAR
  // ===========================================================================

  void _evaluateTrigger(
    CharacterEffect sourceEffect,
    CharacterEffectTrigger trigger, {
    Map<String, double> eventVariables = const {},
    ActionTriggerContext? actionContext,
  }) {
    // ===========================================================================
    // TARGET EXTERNO
    // ===========================================================================

    if (trigger.targetsActionTarget) {
      return;
    }

    // ===========================================================================
    // REENTRADA
    // ===========================================================================

    if (_isTriggerActive(sourceEffect, trigger)) {
      return;
    }

    // ===========================================================================
    // MODO
    // ===========================================================================

    switch (trigger.mode) {
      case PassiveTriggerMode.once:
        _evaluateOnceTrigger(
          sourceEffect,
          trigger,
          eventVariables: eventVariables,
        );

        return;

      case PassiveTriggerMode.whileCondition:
        _evaluatePersistentTrigger(
          sourceEffect,
          trigger,
          eventVariables: eventVariables,
        );

        return;
    }
  }

  void _evaluateOnceTrigger(
    CharacterEffect sourceEffect,
    CharacterEffectTrigger trigger, {
    Map<String, double> eventVariables = const {},
  }) {
    // ===========================================================================
    // LÍMITE
    // ===========================================================================

    if (!canUseTrigger(sourceEffect, trigger)) {
      return;
    }

    // ===========================================================================
    // CONDICIÓN
    // ===========================================================================

    if (!_evaluateCondition(trigger, eventVariables: eventVariables)) {
      return;
    }

    // ===========================================================================
    // RESERVAR
    // ===========================================================================

    if (!_beginTriggerExecution(sourceEffect, trigger)) {
      return;
    }

    try {
      _executeSelfTrigger(
        sourceEffect,
        trigger,
        eventVariables: eventVariables,
      );

      consumeTriggerUsage(sourceEffect, trigger);
    } finally {
      _endTriggerExecution(sourceEffect, trigger);
    }
  }

  void _evaluatePersistentTrigger(
    CharacterEffect sourceEffect,
    CharacterEffectTrigger trigger, {
    Map<String, double> eventVariables = const {},
  }) {
    // ===========================================================================
    // SOLO EFECTOS PERSISTENTES
    //
    // Daño y curación no se ejecutan en este modo.
    // ===========================================================================

    if (!trigger.supportsPersistentMode) {
      return;
    }

    final conditionMet = _evaluateCondition(
      trigger,
      eventVariables: eventVariables,
    );

    final key = _usageKey(sourceEffect, trigger);

    final maintainedIds = _runtime.maintainedEffectIdsByTriggerKey[key];

    // ===========================================================================
    // LIMPIAR IDS QUE YA NO EXISTEN
    // ===========================================================================

    if (maintainedIds != null && maintainedIds.isNotEmpty) {
      maintainedIds.removeWhere(
        (id) => !character.effects.any((effect) => effect.id == id),
      );

      if (maintainedIds.isEmpty) {
        _runtime.maintainedEffectIdsByTriggerKey.remove(key);
      }
    }

    final refreshedIds = _runtime.maintainedEffectIdsByTriggerKey[key];

    final currentlyActive = refreshedIds != null && refreshedIds.isNotEmpty;

    // ===========================================================================
    // FALSE + INACTIVO
    // ===========================================================================

    if (!conditionMet && !currentlyActive) {
      return;
    }

    // ===========================================================================
    // TRUE + ACTIVO
    //
    // Ya está mantenido. No duplicamos efectos.
    // ===========================================================================

    if (conditionMet && currentlyActive) {
      return;
    }

    // ===========================================================================
    // TRUE + INACTIVO
    //
    // Transición de entrada.
    // ===========================================================================

    if (conditionMet) {
      _activatePersistentTrigger(
        sourceEffect,
        trigger,
        eventVariables: eventVariables,
      );

      return;
    }

    // ===========================================================================
    // FALSE + ACTIVO
    //
    // Transición de salida.
    // ===========================================================================

    _deactivatePersistentTrigger(sourceEffect, trigger);
  }

  void _activatePersistentTrigger(
    CharacterEffect sourceEffect,
    CharacterEffectTrigger trigger, {
    Map<String, double> eventVariables = const {},
  }) {
    if (!_beginTriggerExecution(sourceEffect, trigger)) {
      return;
    }

    try {
      final key = _usageKey(sourceEffect, trigger);

      final createdIds = <String>{};

      for (final template in trigger.linkedEffects) {
        final instanceId = _applyPersistentLinkedEffect(
          sourceEffect,
          trigger,
          template,
        );

        if (instanceId == null) {
          continue;
        }

        createdIds.add(instanceId);
      }

      if (createdIds.isEmpty) {
        return;
      }

      _runtime.maintainedEffectIdsByTriggerKey[key] = createdIds;
    } finally {
      _endTriggerExecution(sourceEffect, trigger);
    }
  }

  String? _applyPersistentLinkedEffect(
    CharacterEffect sourceEffect,
    CharacterEffectTrigger trigger,
    CharacterEffect template,
  ) {
    final templateId = template.id.trim();

    if (templateId.isEmpty) {
      return null;
    }

    final instance = CharacterEffect.fromMap(template.toMap());

    instance.id =
        'effect-trigger-persistent:'
        '${sourceEffect.id}:'
        '${trigger.id}:'
        '$templateId:'
        '${DateTime.now().microsecondsSinceEpoch}';

    instance.enabled = true;

    instance.resetDuration();

    character.applyReceivedEffect(
      instance,
      templateId: templateId,
      refreshTriggers: false,
      dispatchHealthTriggers: false,
      eventVariables: {
        'trigger_source_effect': 1,
        'persistent_effect_trigger': 1,
        'source_effect_${sourceEffect.id}': 1,
        'effect_trigger_${trigger.id}': 1,
      },
    );

    return instance.id;
  }

  void _deactivatePersistentTrigger(
    CharacterEffect sourceEffect,
    CharacterEffectTrigger trigger,
  ) {
    if (!_beginTriggerExecution(sourceEffect, trigger)) {
      return;
    }

    try {
      final key = _usageKey(sourceEffect, trigger);

      final maintainedIds = _runtime.maintainedEffectIdsByTriggerKey[key];

      if (maintainedIds == null || maintainedIds.isEmpty) {
        _runtime.maintainedEffectIdsByTriggerKey.remove(key);

        return;
      }

      character.effects.removeWhere(
        (effect) => maintainedIds.contains(effect.id),
      );

      _runtime.maintainedEffectIdsByTriggerKey.remove(key);
    } finally {
      _endTriggerExecution(sourceEffect, trigger);
    }
  }

  void refreshPersistentTriggers({
    Map<String, double> eventVariables = const {},
  }) {
    final runtime = _runtime;

    // ===========================================================================
    // APLAZAR DURANTE DISPATCH
    // ===========================================================================

    if (runtime.dispatchDepth > 0) {
      runtime.persistentRefreshPending = true;
      return;
    }

    runtime.persistentRefreshPending = false;

    // ===========================================================================
    // CONVERGENCIA
    // ===========================================================================

    for (
      var pass = 0;
      pass < _CharacterEffectTriggerRuntime.maximumPersistentRefreshPasses;
      pass++
    ) {
      final before = _persistentStateSignature();

      final effects = character.effects
          .where((effect) => effect.enabled && !effect.expired)
          .toList(growable: false);

      for (final sourceEffect in effects) {
        final triggers = List<CharacterEffectTrigger>.from(
          sourceEffect.triggers,
        );

        for (final trigger in triggers) {
          if (!trigger.maintainsWhileCondition) {
            continue;
          }

          if (trigger.targetsActionTarget) {
            continue;
          }

          _evaluatePersistentTrigger(
            sourceEffect,
            trigger,
            eventVariables: eventVariables,
          );
        }
      }

      _cleanupOrphanPersistentState();

      final after = _persistentStateSignature();

      if (before == after) {
        return;
      }
    }
  }

  String _persistentStateSignature() {
    final entries = _runtime.maintainedEffectIdsByTriggerKey.entries.map((
      entry,
    ) {
      final ids = entry.value.toList()..sort();

      return '${entry.key}:${ids.join(",")}';
    }).toList()..sort();

    return entries.join('|');
  }

  void _cleanupOrphanPersistentState() {
    final validTriggerKeys = <String>{};

    for (final effect in character.effects) {
      if (!effect.enabled || effect.expired) {
        continue;
      }

      for (final trigger in effect.triggers) {
        if (!trigger.maintainsWhileCondition) {
          continue;
        }

        if (trigger.targetsActionTarget) {
          continue;
        }

        validTriggerKeys.add(_usageKey(effect, trigger));
      }
    }

    final staleKeys = _runtime.maintainedEffectIdsByTriggerKey.keys
        .where((key) => !validTriggerKeys.contains(key))
        .toList(growable: false);

    for (final key in staleKeys) {
      final maintainedIds = _runtime.maintainedEffectIdsByTriggerKey[key];

      if (maintainedIds != null && maintainedIds.isNotEmpty) {
        character.effects.removeWhere(
          (effect) => maintainedIds.contains(effect.id),
        );
      }

      _runtime.maintainedEffectIdsByTriggerKey.remove(key);
    }
  }

  // ===========================================================================
  // CONTEXTO
  // ===========================================================================

  FormulaContext _buildFormulaContext({
    Map<String, double> eventVariables = const {},
  }) {
    final resourceResolver = ResourceModifierResolver(character: character);

    return CharacterFormulaContext.fromCharacter(
      character,
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

  // ===========================================================================
  // CONDICIÓN
  // ===========================================================================

  bool _evaluateCondition(
    CharacterEffectTrigger trigger, {
    Map<String, double> eventVariables = const {},
  }) {
    final condition = trigger.condition;

    if (condition == null || condition.expression.trim().isEmpty) {
      return true;
    }

    final result = evaluator.evaluate(
      condition,
      context: _buildFormulaContext(eventVariables: eventVariables),
    );

    if (!result.valid) {
      return false;
    }

    return result.value != 0;
  }

  // ===========================================================================
  // EJECUCIÓN SELF
  // ===========================================================================

  void _executeSelfTrigger(
    CharacterEffect sourceEffect,
    CharacterEffectTrigger trigger, {
    Map<String, double> eventVariables = const {},
  }) {
    for (final bonus in trigger.damageBonuses) {
      final amount = _resolveDamageBonus(bonus, eventVariables: eventVariables);

      if (amount <= 0) {
        continue;
      }

      character.takeDamage(amount, dispatchTriggers: true);
    }

    for (final bonus in trigger.healingBonuses) {
      final amount = _resolveHealingBonus(
        bonus,
        eventVariables: eventVariables,
      );

      if (amount <= 0) {
        continue;
      }

      character.heal(amount, dispatchTriggers: true);
    }

    for (final template in trigger.linkedEffects) {
      _applyLinkedEffect(sourceEffect, trigger, template);
    }
  }

  // ===========================================================================
  // DAÑO
  // ===========================================================================

  int _resolveDamageBonus(
    DamageBonus bonus, {
    Map<String, double> eventVariables = const {},
  }) {
    final context = _buildFormulaContext(eventVariables: eventVariables);

    final modifier = character.damageBonusModifier(
      bonus,
      formulaContext: context,
    );

    return DicePoolRoller.roll(
      pools: bonus.dicePools,
      modifier: modifier,
    ).total;
  }

  // ===========================================================================
  // CURACIÓN
  // ===========================================================================

  int _resolveHealingBonus(
    HealingBonus bonus, {
    Map<String, double> eventVariables = const {},
  }) {
    final context = _buildFormulaContext(eventVariables: eventVariables);

    final modifier = character.healingBonusModifier(
      bonus,
      formulaContext: context,
    );

    return DicePoolRoller.roll(
      pools: bonus.dicePools,
      modifier: modifier,
    ).total;
  }

  // ===========================================================================
  // EFECTO VINCULADO
  // ===========================================================================

  void _applyLinkedEffect(
    CharacterEffect sourceEffect,
    CharacterEffectTrigger trigger,
    CharacterEffect template,
  ) {
    final templateId = template.id.trim();

    if (templateId.isEmpty) {
      return;
    }

    final instance = CharacterEffect.fromMap(template.toMap());

    instance.id =
        'effect-trigger:'
        '${sourceEffect.id}:'
        '${trigger.id}:'
        '$templateId:'
        '${DateTime.now().microsecondsSinceEpoch}';

    instance.enabled = true;

    instance.resetDuration();

    character.applyReceivedEffect(
      instance,
      templateId: templateId,
      refreshTriggers: false,
      dispatchHealthTriggers: false,
      eventVariables: {
        'trigger_source_effect': 1,
        'source_effect_${sourceEffect.id}': 1,
        'effect_trigger_${trigger.id}': 1,
      },
    );
  }
}

class _CharacterEffectTriggerRuntime {
  final Set<String> consumedExternalResultIds = <String>{};

  final Map<String, int> lastUsedTurnByTriggerKey = <String, int>{};

  final Map<String, int> lastUsedRoundByTriggerKey = <String, int>{};

  final Set<String> activeTriggerKeys = <String>{};

  final Map<String, Set<String>> maintainedEffectIdsByTriggerKey =
      <String, Set<String>>{};

  int dispatchDepth = 0;

  bool persistentRefreshPending = false;

  static const int maximumDispatchDepth = 16;

  static const int maximumPersistentRefreshPasses = 32;
}
