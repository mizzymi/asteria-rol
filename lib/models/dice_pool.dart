import 'dart:math';

class DicePool {
  int count;
  int sides;

  DicePool({this.count = 1, this.sides = 6});

  int get maximum => count * sides;

  String get notation => '${count}d$sides';

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

class DiceGroupRoll {
  final DicePool pool;
  final List<int> rolls;

  const DiceGroupRoll({required this.pool, required this.rolls});

  int get total {
    return rolls.fold(0, (sum, value) => sum + value);
  }

  int get maximum => pool.maximum;
}

class DiceCalculationResult {
  final List<DiceGroupRoll> groups;
  final int modifier;
  final bool critical;

  const DiceCalculationResult({
    required this.groups,
    required this.modifier,
    this.critical = false,
  });

  int get rolledTotal {
    return groups.fold(0, (sum, group) => sum + group.total);
  }

  int get maximumDiceTotal {
    return groups.fold(0, (sum, group) => sum + group.maximum);
  }

  int get total {
    if (critical) {
      return maximumDiceTotal + rolledTotal + modifier;
    }

    return rolledTotal + modifier;
  }
}

class DicePoolRoller {
  static final Random _random = Random();

  static DiceCalculationResult roll({
    required List<DicePool> pools,
    int modifier = 0,
    bool critical = false,
  }) {
    final groups = pools.map((pool) {
      final rolls = List<int>.generate(
        pool.count,
        (_) => _random.nextInt(pool.sides) + 1,
      );

      return DiceGroupRoll(pool: pool, rolls: rolls);
    }).toList();

    return DiceCalculationResult(
      groups: groups,
      modifier: modifier,
      critical: critical,
    );
  }
}
