import '../models/action_cost.dart';
import '../models/character.dart';
import '../models/ability.dart';

class ActionCostResolver {
  final Character character;

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

    if (includeResource && ability.usesResource) {
      final resourceId = ability.resourceId?.trim();

      if (resourceId != null && resourceId.isNotEmpty) {
        costs.add(
          ActionCost.resource(
            resourceId: resourceId,
            amount: ability.resourceCost,
          ),
        );
      }
    }

    if (includeUse && ability.hasLimitedUses) {
      costs.add(
        ActionCost.abilityUse(
          abilityId: ability.id,
          amount: 1,
          label: ability.name,
        ),
      );
    }

    return costs;
  }

  const ActionCostResolver({required this.character});

  CharacterAbility? _abilityById(String id) {
    for (final ability in character.availableAbilities) {
      if (ability.id == id) {
        return ability;
      }
    }

    return null;
  }

  // ===========================================================================
  // VALIDACIÓN
  // ===========================================================================

  ActionCostValidationResult validate(Iterable<ActionCost> costs) {
    final normalizedCosts = combineCosts(costs);

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
    final normalizedCosts = combineCosts(costs);

    final validation = validate(normalizedCosts);

    if (!validation.valid) {
      return validation;
    }

    for (final cost in normalizedCosts) {
      _applyCost(cost);
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

    if (resource.currentValue < cost.amount) {
      return ActionCostValidationResult.failure(
        'No tienes suficiente ${resource.name}. '
        'Necesitas ${cost.amount}.',
      );
    }

    return const ActionCostValidationResult.success();
  }

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

    if (passive.currentCharges < cost.amount) {
      return ActionCostValidationResult.failure(
        'No hay suficientes cargas de ${passive.name}. '
        'Necesitas ${cost.amount}.',
      );
    }

    return const ActionCostValidationResult.success();
  }

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

    if (ability.currentUses < cost.amount) {
      return ActionCostValidationResult.failure(
        'No quedan suficientes usos de ${ability.name}.',
      );
    }

    return const ActionCostValidationResult.success();
  }

  // ===========================================================================
  // APLICACIÓN
  // ===========================================================================

  void _applyCost(ActionCost cost) {
    switch (cost.type) {
      case ActionCostType.resource:
        final resource = character.resourceById(cost.sourceId);

        if (resource == null) {
          return;
        }

        character.consumeResource(resource, cost.amount);

        return;

      case ActionCostType.passiveCharge:
        character.subtractPassiveCharges(cost.sourceId, cost.amount);

        return;

      case ActionCostType.abilityUse:
        final ability = _abilityById(cost.sourceId);

        if (ability == null || !ability.hasLimitedUses) {
          return;
        }

        for (var i = 0; i < cost.amount; i++) {
          character.useCharacterAbility(ability);
        }

        return;
    }
  }

  // ===========================================================================
  // DEDUPLICACIÓN / AGRUPACIÓN
  // ===========================================================================

  List<ActionCost> combineCosts(Iterable<ActionCost> costs) {
    final totals = <String, int>{};
    final originals = <String, ActionCost>{};

    for (final cost in costs) {
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

    return result;
  }
}
