import '../models/character.dart';
import '../models/passive.dart';
import '../models/character_effect.dart';
import '../models/formulas/formula_context.dart';
import '../models/formulas/character_formula_context.dart';

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

  // ===========================================================================
  // DISPATCH
  // ===========================================================================

  void dispatch(
    PassiveTriggerEvent event, {
    Map<String, double> eventVariables = const {},
  }) {
    final runtime = _runtime;

    // ===========================================================================
    // PROTECCIÓN DE PROFUNDIDAD
    // ===========================================================================

    if (runtime.dispatchDepth >= _PassiveTriggerRuntime.maximumDispatchDepth) {
      return;
    }

    runtime.dispatchDepth++;

    try {
      // -------------------------------------------------------------------------
      // SNAPSHOT
      //
      // Un trigger puede modificar efectos/pasivas durante su ejecución.
      // Trabajamos con una copia para no modificar la colección que recorremos.
      // -------------------------------------------------------------------------

      final passives = character.enabledPassives.toList(growable: false);

      for (final passive in passives) {
        final triggers = List<PassiveTrigger>.from(passive.triggers);

        for (final trigger in triggers) {
          if (trigger.event != event) {
            continue;
          }

          // ---------------------------------------------------------------------
          // CLAVE DE REENTRADA
          //
          // El mismo trigger no puede volver a entrar mientras todavía se está
          // ejecutando.
          // ---------------------------------------------------------------------

          final triggerKey = '${passive.id}:${trigger.id}:${event.name}';

          if (runtime.activeTriggerKeys.contains(triggerKey)) {
            continue;
          }

          runtime.activeTriggerKeys.add(triggerKey);

          try {
            evaluateTrigger(passive, trigger, eventVariables: eventVariables);
          } finally {
            runtime.activeTriggerKeys.remove(triggerKey);
          }
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

    if (trigger.actionType != PassiveTriggerActionType.applyEffect) {
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
  }) {
    // ===========================================================================
    // TRIGGER REALMENTE PERSISTENTE
    //
    // Un whileCondition representa ESTADO persistente.
    //
    // Por tanto NO utiliza variables transitorias del evento actual como:
    //
    // damage
    // healing
    // resource_change
    // charges_change
    // counter_change
    //
    // La condición se evalúa únicamente contra el estado actual del Character.
    // ===========================================================================

    if (_supportsPersistentTrigger(trigger)) {
      final conditionMet = _evaluateCondition(passive, trigger);

      _setTriggerEffectActive(passive, trigger, active: conditionMet);

      return;
    }

    // ===========================================================================
    // TRIGGER NORMAL
    //
    // Estos sí pueden utilizar el contexto concreto del evento.
    // ===========================================================================

    final conditionMet = _evaluateCondition(
      passive,
      trigger,
      eventVariables: eventVariables,
    );

    if (!conditionMet) {
      return;
    }

    _executeTriggerAction(passive, trigger, eventVariables: eventVariables);
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

        final amount = value.round();

        if (amount == 0) {
          return;
        }

        character.addResourceValue(resourceId, amount, dispatchTriggers: true);

        break;

      case PassiveTriggerActionType.subtractResource:
        final resourceId = trigger.targetId;

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

        break;

      case PassiveTriggerActionType.setResource:
        final resourceId = trigger.targetId;

        if (resourceId == null || resourceId.isEmpty) {
          return;
        }

        character.setResourceValue(
          resourceId,
          value.round(),
          dispatchTriggers: true,
        );

        break;

      // -----------------------------------------------------------------------
      // CARGAS
      // -----------------------------------------------------------------------

      case PassiveTriggerActionType.addCharge:
        final amount = value.round();

        if (amount == 0) {
          return;
        }

        character.addPassiveCharges(passive.id, amount, dispatchTriggers: true);

        break;

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

        character.incrementCounter(counterId, amount, dispatchTriggers: true);

        break;

      case PassiveTriggerActionType.setCounter:
        final counterId = trigger.targetId;

        if (counterId == null || counterId.isEmpty) {
          return;
        }

        character.setCounter(counterId, value.round(), dispatchTriggers: true);

        break;

      // -----------------------------------------------------------------------
      // EFECTOS
      // -----------------------------------------------------------------------

      case PassiveTriggerActionType.applyEffect:
        _applyOneShotTriggerEffect(passive, trigger);

        break;

      case PassiveTriggerActionType.removeEffect:
        _removeSelectedEffect(trigger);

        break;

      // -----------------------------------------------------------------------
      // VIDA / DAÑO
      // -----------------------------------------------------------------------

      case PassiveTriggerActionType.dealDamage:
        final amount = value.round();

        if (amount <= 0) {
          return;
        }

        character.takeDamage(amount, dispatchTriggers: true);

        break;

      case PassiveTriggerActionType.heal:
        final amount = value.round();

        if (amount <= 0) {
          return;
        }

        character.heal(amount, dispatchTriggers: true);

        break;
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
  ) {
    final sourceEffect = _findLinkedEffectTemplate(passive, trigger.targetId);

    if (sourceEffect == null) {
      return;
    }

    final instance = CharacterEffect.fromMap(sourceEffect.toMap());

    instance.id =
        'trigger:${passive.id}:${trigger.id}:${sourceEffect.id}:'
        '${DateTime.now().microsecondsSinceEpoch}';

    instance.enabled = true;

    instance.resetDuration();

    character.addEffect(
      instance,
      refreshTriggers: false,
      dispatchHealthTriggers: false,
    );
  }

  void _removeSelectedEffect(PassiveTrigger trigger) {
    final effectId = trigger.targetId?.trim();

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
    final sourceEffect = _findLinkedEffectTemplate(passive, trigger.targetId);

    if (sourceEffect == null) {
      return false;
    }

    // ===========================================================================
    // ID ÚNICO DE RUNTIME
    // ===========================================================================

    final instanceId = 'trigger:${passive.id}:${trigger.id}:${sourceEffect.id}';

    final existingIndex = character.effects.indexWhere(
      (effect) => effect.id == instanceId,
    );

    // ===========================================================================
    // DESACTIVAR
    // ===========================================================================

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

    // ===========================================================================
    // YA EXISTE
    // ===========================================================================

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

    // ===========================================================================
    // CREAR INSTANCIA
    // ===========================================================================

    final instance = CharacterEffect.fromMap(sourceEffect.toMap());

    instance.id = instanceId;
    instance.enabled = true;

    // La duración de un whileCondition depende exclusivamente
    // de la condición, no de la duración configurada en la plantilla.
    instance.durationType = CharacterEffectDurationType.permanent;

    instance.maxDuration = 0;
    instance.currentDuration = 0;
    instance.minuteRoundProgress = 0;

    character.addEffect(
      instance,
      refreshTriggers: false,
      dispatchHealthTriggers: false,
    );

    return true;
  }
}

class _PassiveTriggerRuntime {
  // ===========================================================================
  // TRIGGERS ACTIVOS
  // ===========================================================================

  final Set<String> activeTriggerKeys = <String>{};

  // ===========================================================================
  // PROFUNDIDAD DE DISPATCH
  // ===========================================================================

  int dispatchDepth = 0;

  static const int maximumPersistentRefreshPasses = 32;

  static const int maximumDispatchDepth = 64;

  // ===========================================================================
  // REFRESH PERSISTENTE PENDIENTE
  //
  // Permite agrupar múltiples cambios ocurridos dentro de una cadena de
  // triggers y reevaluar los whileCondition una sola vez al terminar.
  // ===========================================================================

  bool persistentRefreshPending = false;
}
