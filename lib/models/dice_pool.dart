import 'dart:math';

class DicePool {
  int count;
  int sides;

  DicePool({this.count = 1, this.sides = 6});

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  int get maximum {
    return count * sides;
  }

  String get notation {
    return '${count}d$sides';
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {'count': count, 'sides': sides};
  }

  factory DicePool.fromMap(Map<dynamic, dynamic> map) {
    return DicePool(
      count: (map['count'] as num?)?.toInt() ?? 1,
      sides: (map['sides'] as num?)?.toInt() ?? 6,
    );
  }
}

// =============================================================================
// GRUPO DE DADOS
// =============================================================================

class DiceGroupRoll {
  final DicePool pool;

  final List<int> rolls;

  const DiceGroupRoll({required this.pool, required this.rolls});

  // ===========================================================================
  // RESULTADO REAL
  // ===========================================================================

  int get total {
    return rolls.fold<int>(0, (sum, value) => sum + value);
  }

  // ===========================================================================
  // MÁXIMO POSIBLE
  // ===========================================================================

  int get maximum {
    return pool.maximum;
  }
}

// =============================================================================
// RESULTADO COMPLETO
// =============================================================================

class DiceCalculationResult {
  final List<DiceGroupRoll> groups;

  final int modifier;

  const DiceCalculationResult({required this.groups, required this.modifier});

  int get rolledTotal {
    return groups.fold<int>(0, (sum, group) => sum + group.total);
  }

  int get maximumDiceTotal {
    return groups.fold<int>(0, (sum, group) => sum + group.maximum);
  }

  int get total {
    return rolledTotal + modifier;
  }
}

// =============================================================================
// ROLLER
// =============================================================================

class DicePoolRoller {
  static final Random _random = Random();

  static DiceCalculationResult roll({
    required List<DicePool> pools,
    int modifier = 0,
  }) {
    final groups = pools.map((pool) {
      final rolls = List<int>.generate(
        pool.count,
        (_) => _random.nextInt(pool.sides) + 1,
      );

      return DiceGroupRoll(pool: pool, rolls: rolls);
    }).toList();

    return DiceCalculationResult(groups: groups, modifier: modifier);
  }
}
