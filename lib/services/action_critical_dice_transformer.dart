import '../models/action_critical_profile.dart';
import '../models/dice_pool.dart';
import '../models/empowered_critical_formula.dart';

class ActionCriticalDiceTransformation {
  final List<DicePool> dicePools;
  final int modifier;
  final int automaticValue;
  final String empoweredFormula;
  final int empoweredTurn;
  final int empoweredMaximum;

  const ActionCriticalDiceTransformation({
    required this.dicePools,
    required this.modifier,
    required this.automaticValue,
    this.empoweredFormula = '',
    this.empoweredTurn = 1,
    this.empoweredMaximum = 0,
  });
}

class ActionCriticalDiceTransformer {
  const ActionCriticalDiceTransformer._();

  static ActionCriticalDiceTransformation transform({
    required List<DicePool> dicePools,
    required int baseModifier,
    required ActionCriticalType criticalType,
    int empoweredMultiplier = 2,
    String empoweredFormula = '',
    int currentTurn = 1,
  }) {
    final pools = List<DicePool>.unmodifiable(dicePools);

    switch (criticalType) {
      case ActionCriticalType.none:
        return ActionCriticalDiceTransformation(
          dicePools: pools,
          modifier: baseModifier,
          automaticValue: 0,
        );

      case ActionCriticalType.normal:
        return ActionCriticalDiceTransformation(
          dicePools: pools,
          modifier: baseModifier * 2,
          automaticValue: _maximumDiceValue(dicePools),
        );

      case ActionCriticalType.empowered:
        final legacyMultiplier = empoweredMultiplier.clamp(2, 10).toInt();
        final formula = empoweredFormula.trim().isEmpty
            ? '(MAX + MOD) * $legacyMultiplier'
            : empoweredFormula.trim();

        return ActionCriticalDiceTransformation(
          // Solo pedimos tirar los dados cuando la fórmula usa TIRADA.
          dicePools: EmpoweredCriticalFormula.needsRoll(formula)
              ? pools
              : const [],
          modifier: 0,
          automaticValue: 0,
          empoweredFormula: formula,
          empoweredTurn: currentTurn <= 0 ? 1 : currentTurn,
          empoweredMaximum: _maximumDiceValue(dicePools),
        );
    }
  }

  static int _maximumDiceValue(Iterable<DicePool> pools) {
    return pools.fold<int>(0, (sum, pool) => sum + pool.maximum);
  }
}
