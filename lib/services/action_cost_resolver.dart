import '../models/action_cost.dart';
import '../models/character.dart';
import '../models/ability.dart';
import '../models/passive.dart';
import '../models/character_resource.dart';

class ActionCostResolver {
  final Character character;

  const ActionCostResolver({required this.character});

  // ===========================================================================
  // COSTES DE HABILIDAD
  // ===========================================================================

  List<ActionCost> costsForAbility(
    String abilityId, {
    bool includeResource = true,
    bool includeUse = true,
  }) {
    final ability = _abilityById(abilityId);

    if (ability == null) {
      return const [];
    }

    final costs = <ActionCost>[];

    // -------------------------------------------------------------------------
    // RECURSO
    // -------------------------------------------------------------------------

    if (includeResource && ability.usesResource && ability.resourceCost > 0) {
      final resourceId = ability.resourceId?.trim();

      if (resourceId != null && resourceId.isNotEmpty) {
        costs.add(
          ActionCost.resource(
            resourceId: resourceId,
            amount: ability.resourceCost,
            label: character.resourceById(resourceId)?.name,
          ),
        );
      }
    }

    // -------------------------------------------------------------------------
    // USO
    // -------------------------------------------------------------------------

    if (includeUse && ability.hasLimitedUses) {
      costs.add(
        ActionCost.abilityUse(
          abilityId: ability.id,
          amount: 1,
          label: ability.name,
        ),
      );
    }

    return List<ActionCost>.unmodifiable(costs);
  }

  // ===========================================================================
  // LOOKUPS
  // ===========================================================================

  CharacterAbility? _abilityById(String id) {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    for (final ability in character.availableAbilities) {
      if (ability.id == normalizedId) {
        return ability;
      }
    }

    return null;
  }

  // ===========================================================================
  // VALIDACIÓN COMPLETA
  // ===========================================================================

  ActionCostValidationResult validate(Iterable<ActionCost> costs) {
    final rawCosts = List<ActionCost>.from(costs);

    // -------------------------------------------------------------------------
    // 1. VALIDAR ESTRUCTURA ORIGINAL
    //
    // IMPORTANTE:
    // no combinamos antes de esto porque combineCosts no debe ocultar
    // accidentalmente un coste mal formado.
    // -------------------------------------------------------------------------

    for (final cost in rawCosts) {
      if (!cost.isValid) {
        return const ActionCostValidationResult.failure(
          'Uno de los costes de la acción no es válido.',
        );
      }
    }

    // -------------------------------------------------------------------------
    // 2. COMBINAR COSTES IGUALES
    //
    // Ejemplo:
    //
    // parte A → 2 maná
    // parte B → 3 maná
    //
    // Resultado:
    // 5 maná
    // -------------------------------------------------------------------------

    final normalizedCosts = combineCosts(rawCosts);

    // -------------------------------------------------------------------------
    // 3. VALIDAR DISPONIBILIDAD
    // -------------------------------------------------------------------------

    for (final cost in normalizedCosts) {
      final result = _validateCost(cost);

      if (!result.valid) {
        return result;
      }
    }

    return const ActionCostValidationResult.success();
  }

  // ===========================================================================
  // PAGO ATÓMICO
  // ===========================================================================

  ActionCostValidationResult pay(Iterable<ActionCost> costs) {
    final rawCosts = List<ActionCost>.from(costs);

    // ===========================================================================
    // 1. VALIDAR TODO
    // ===========================================================================

    final validation = validate(rawCosts);

    if (!validation.valid) {
      return validation;
    }

    final normalizedCosts = combineCosts(rawCosts);

    // ===========================================================================
    // 2. PRE-RESOLVER TODAS LAS FUENTES
    //
    // Todavía NO mutamos nada.
    //
    // De esta manera no existe ningún return de error una vez iniciado
    // el pago real.
    // ===========================================================================

    final resourceCosts = <_ResolvedResourceCost>[];

    final passiveChargeCosts = <_ResolvedPassiveChargeCost>[];

    final abilityUseCosts = <_ResolvedAbilityUseCost>[];

    for (final cost in normalizedCosts) {
      switch (cost.type) {
        case ActionCostType.resource:
          final resource = character.resourceById(cost.sourceId);

          if (resource == null) {
            return const ActionCostValidationResult.failure(
              'El recurso requerido ha desaparecido durante el pago.',
            );
          }

          resourceCosts.add(
            _ResolvedResourceCost(cost: cost, resource: resource),
          );

          break;

        case ActionCostType.passiveCharge:
          final passive = character.passiveById(cost.sourceId);

          if (passive == null) {
            return const ActionCostValidationResult.failure(
              'La pasiva requerida ha desaparecido durante el pago.',
            );
          }

          passiveChargeCosts.add(
            _ResolvedPassiveChargeCost(cost: cost, passive: passive),
          );

          break;

        case ActionCostType.abilityUse:
          final ability = _abilityById(cost.sourceId);

          if (ability == null) {
            return const ActionCostValidationResult.failure(
              'La habilidad requerida ha desaparecido durante el pago.',
            );
          }

          abilityUseCosts.add(
            _ResolvedAbilityUseCost(cost: cost, ability: ability),
          );

          break;
      }
    }

    // ===========================================================================
    // 3. REGISTRAR CAMBIOS PARA TRIGGERS
    // ===========================================================================

    final resourceChanges = <_ResourceCostChange>[];

    final chargeChanges = <_PassiveChargeCostChange>[];

    // ===========================================================================
    // 4. PAGAR RECURSOS EN SILENCIO
    // ===========================================================================

    for (final resolved in resourceCosts) {
      final resource = resolved.resource;
      final cost = resolved.cost;

      final before = resource.currentValue;

      character.spendResource(
        resource.id,
        cost.amount,
        dispatchTriggers: false,
      );

      final after = resource.currentValue;

      resourceChanges.add(
        _ResourceCostChange(
          resourceId: resource.id,
          before: before,
          after: after,
        ),
      );
    }

    // ===========================================================================
    // 5. PAGAR CARGAS EN SILENCIO
    // ===========================================================================

    for (final resolved in passiveChargeCosts) {
      final passive = resolved.passive;
      final cost = resolved.cost;

      final before = passive.currentCharges;

      character.spendPassiveCharges(
        passive.id,
        cost.amount,
        dispatchTriggers: false,
      );

      final after = passive.currentCharges;

      chargeChanges.add(
        _PassiveChargeCostChange(
          passiveId: passive.id,
          before: before,
          after: after,
        ),
      );
    }

    // ===========================================================================
    // 6. PAGAR USOS DE HABILIDAD
    // ===========================================================================

    for (final resolved in abilityUseCosts) {
      character.spendAbilityUses(resolved.ability, resolved.cost.amount);
    }

    // ===========================================================================
    // 7. TODOS LOS COSTES YA ESTÁN PAGADOS
    //
    // Solo ahora permitimos que los triggers reaccionen.
    // ===========================================================================

    for (final change in resourceChanges) {
      if (change.before == change.after) {
        continue;
      }

      character.dispatchPassiveTrigger(
        PassiveTriggerEvent.resourceChanged,
        eventVariables: {
          'previous_resource': change.before.toDouble(),

          'current_resource': change.after.toDouble(),

          'resource_change': (change.after - change.before).toDouble(),

          'resource_${change.resourceId}': 1,

          'resource_spent': change.after < change.before ? 1 : 0,

          'resource_gained': change.after > change.before ? 1 : 0,
        },
      );
    }

    for (final change in chargeChanges) {
      if (change.before == change.after) {
        continue;
      }

      character.dispatchPassiveTrigger(
        PassiveTriggerEvent.chargeChanged,
        eventVariables: {
          'previous_charges': change.before.toDouble(),

          'current_charges': change.after.toDouble(),

          'charges_change': (change.after - change.before).toDouble(),

          'passive_${change.passiveId}': 1,

          'charge_spent': change.after < change.before ? 1 : 0,

          'charge_gained': change.after > change.before ? 1 : 0,
        },
      );
    }

    return const ActionCostValidationResult.success();
  }

  // ===========================================================================
  // VALIDACIÓN INDIVIDUAL
  // ===========================================================================

  ActionCostValidationResult _validateCost(ActionCost cost) {
    if (!cost.isValid) {
      return const ActionCostValidationResult.failure('El coste no es válido.');
    }

    switch (cost.type) {
      case ActionCostType.resource:
        return _validateResourceCost(cost);

      case ActionCostType.passiveCharge:
        return _validatePassiveChargeCost(cost);

      case ActionCostType.abilityUse:
        return _validateAbilityUseCost(cost);
    }
  }

  // ===========================================================================
  // RESOURCE
  // ===========================================================================

  ActionCostValidationResult _validateResourceCost(ActionCost cost) {
    final resource = character.resourceById(cost.sourceId);

    if (resource == null) {
      return ActionCostValidationResult.failure(
        cost.label == null
            ? 'El recurso requerido ya no existe.'
            : 'El recurso "${cost.label}" ya no existe.',
      );
    }

    if (!resource.spendable) {
      return ActionCostValidationResult.failure(
        '${resource.name} no puede utilizarse como coste.',
      );
    }

    if (!character.canSpendResource(resource.id, cost.amount)) {
      return ActionCostValidationResult.failure(
        '${cost.label ?? resource.name}: recurso insuficiente.',
      );
    }

    return const ActionCostValidationResult.success();
  }

  // ===========================================================================
  // PASSIVE CHARGE
  // ===========================================================================

  ActionCostValidationResult _validatePassiveChargeCost(ActionCost cost) {
    final passive = character.passiveById(cost.sourceId);

    if (passive == null) {
      return ActionCostValidationResult.failure(
        cost.label == null
            ? 'La pasiva requerida ya no existe.'
            : 'La pasiva "${cost.label}" ya no existe.',
      );
    }

    if (!passive.hasCharges) {
      return ActionCostValidationResult.failure(
        '${passive.name} no utiliza cargas.',
      );
    }

    if (!character.canSpendPassiveCharges(passive.id, cost.amount)) {
      return ActionCostValidationResult.failure(
        'No hay suficientes cargas de ${passive.name}. '
        'Necesitas ${cost.amount}.',
      );
    }

    return const ActionCostValidationResult.success();
  }

  // ===========================================================================
  // ABILITY USE
  // ===========================================================================

  ActionCostValidationResult _validateAbilityUseCost(ActionCost cost) {
    final ability = _abilityById(cost.sourceId);

    if (ability == null) {
      return ActionCostValidationResult.failure(
        cost.label == null
            ? 'La habilidad requerida ya no existe.'
            : 'La habilidad "${cost.label}" ya no existe.',
      );
    }

    if (!ability.hasLimitedUses) {
      return const ActionCostValidationResult.success();
    }

    if (!character.canSpendAbilityUses(ability, cost.amount)) {
      return ActionCostValidationResult.failure(
        'No quedan suficientes usos de '
        '${ability.name}. '
        'Necesitas ${cost.amount}.',
      );
    }

    return const ActionCostValidationResult.success();
  }

  // ===========================================================================
  // AGRUPACIÓN
  // ===========================================================================

  List<ActionCost> combineCosts(Iterable<ActionCost> costs) {
    final totals = <String, int>{};

    final originals = <String, ActionCost>{};

    for (final cost in costs) {
      // -----------------------------------------------------------------------
      // Aquí asumimos costes estructuralmente válidos.
      //
      // validate() es quien se responsabiliza de rechazarlos.
      // -----------------------------------------------------------------------

      if (!cost.isValid) {
        continue;
      }

      final key = '${cost.type.name}:${cost.sourceId}';

      totals[key] = (totals[key] ?? 0) + cost.amount;

      originals.putIfAbsent(key, () => cost);
    }

    final result = <ActionCost>[];

    for (final entry in totals.entries) {
      final original = originals[entry.key];

      if (original == null) {
        continue;
      }

      result.add(
        ActionCost(
          type: original.type,

          sourceId: original.sourceId,

          amount: entry.value,

          label: original.label,
        ),
      );
    }

    return List<ActionCost>.unmodifiable(result);
  }
}

// =============================================================================
// INTERNAL TRANSACTION RECORDS
// =============================================================================

class _ResourceCostChange {
  final String resourceId;

  final int before;
  final int after;

  const _ResourceCostChange({
    required this.resourceId,
    required this.before,
    required this.after,
  });
}

class _PassiveChargeCostChange {
  final String passiveId;

  final int before;
  final int after;

  const _PassiveChargeCostChange({
    required this.passiveId,
    required this.before,
    required this.after,
  });
}

class _ResolvedResourceCost {
  final ActionCost cost;
  final CharacterResource resource;

  const _ResolvedResourceCost({required this.cost, required this.resource});
}

class _ResolvedPassiveChargeCost {
  final ActionCost cost;
  final CharacterPassive passive;

  const _ResolvedPassiveChargeCost({required this.cost, required this.passive});
}

class _ResolvedAbilityUseCost {
  final ActionCost cost;
  final CharacterAbility ability;

  const _ResolvedAbilityUseCost({required this.cost, required this.ability});
}
