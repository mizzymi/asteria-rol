import '../models/action_critical_profile.dart';
import '../models/dice_pool.dart';

class ActionCriticalDiceTransformation {
  final List<DicePool> dicePools;

  final int modifier;

  final int automaticValue;

  const ActionCriticalDiceTransformation({
    required this.dicePools,
    required this.modifier,
    required this.automaticValue,
  });
}

class ActionCriticalDiceTransformer {
  const ActionCriticalDiceTransformer._();

  static ActionCriticalDiceTransformation transform({
    required List<DicePool> dicePools,
    required int baseModifier,
    required ActionCriticalType criticalType,
  }) {
    final pools = List<DicePool>.unmodifiable(dicePools);

    switch (criticalType) {
      // =======================================================================
      // NORMAL
      // =======================================================================

      case ActionCriticalType.none:
        return ActionCriticalDiceTransformation(
          dicePools: pools,
          modifier: baseModifier,
          automaticValue: 0,
        );

      // =======================================================================
      // CRÍTICO NORMAL
      //
      // tirada normal
      // + máximo automático de los dados
      // + modificador x2
      // =======================================================================

      case ActionCriticalType.normal:
        return ActionCriticalDiceTransformation(
          dicePools: pools,
          modifier: baseModifier * 2,
          automaticValue: _maximumDiceValue(dicePools),
        );

      // =======================================================================
      // CRÍTICO POTENCIADO
      //
      // (máximo de dados + modificador) x2
      //
      // Todo es automático.
      // =======================================================================

      case ActionCriticalType.empowered:
        final maximum = _maximumDiceValue(dicePools);

        return ActionCriticalDiceTransformation(
          dicePools: const [],
          modifier: 0,
          automaticValue: (maximum + baseModifier) * 2,
        );
    }
  }

  static int _maximumDiceValue(Iterable<DicePool> pools) {
    return pools.fold<int>(0, (sum, pool) => sum + pool.maximum);
  }
}
