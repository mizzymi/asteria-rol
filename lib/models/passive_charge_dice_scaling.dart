import 'dice_pool.dart';

class PassiveChargeDiceScaling {
  final bool enabled;

  /// Dados añadidos POR CADA carga considerada.
  ///
  /// Ejemplo:
  /// [1d4] por carga.
  final List<DicePool> dicePoolsPerCharge;

  /// Máximo de cargas que pueden contribuir.
  ///
  /// 0 = sin límite.
  final int maxCharges;

  /// Mínimo necesario para aportar algo.
  final int minimumCharges;

  const PassiveChargeDiceScaling({
    this.enabled = false,
    this.dicePoolsPerCharge = const [],
    this.maxCharges = 0,
    this.minimumCharges = 1,
  });

  bool get hasScaling {
    return enabled && dicePoolsPerCharge.any((pool) => pool.count > 0);
  }

  int effectiveCharges(int currentCharges) {
    if (!hasScaling) {
      return 0;
    }

    if (currentCharges < minimumCharges) {
      return 0;
    }

    if (maxCharges > 0) {
      return currentCharges.clamp(0, maxCharges);
    }

    return currentCharges;
  }

  List<DicePool> scaledDicePools(int currentCharges) {
    final charges = effectiveCharges(currentCharges);

    if (charges <= 0) {
      return const [];
    }

    return dicePoolsPerCharge
        .where((pool) => pool.count > 0 && pool.sides > 0)
        .map((pool) => DicePool(count: pool.count * charges, sides: pool.sides))
        .toList(growable: false);
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,

      'dicePoolsPerCharge': dicePoolsPerCharge
          .map((pool) => pool.toMap())
          .toList(),

      'maxCharges': maxCharges,

      'minimumCharges': minimumCharges,
    };
  }

  factory PassiveChargeDiceScaling.fromMap(Map<dynamic, dynamic> map) {
    final pools = <DicePool>[];

    final rawPools = map['dicePoolsPerCharge'];

    if (rawPools is List) {
      for (final rawPool in rawPools) {
        if (rawPool is! Map) {
          continue;
        }

        pools.add(DicePool.fromMap(Map<dynamic, dynamic>.from(rawPool)));
      }
    }

    return PassiveChargeDiceScaling(
      enabled: map['enabled'] as bool? ?? false,

      dicePoolsPerCharge: List<DicePool>.unmodifiable(pools),

      maxCharges: (map['maxCharges'] as num?)?.toInt() ?? 0,

      minimumCharges: (map['minimumCharges'] as num?)?.toInt() ?? 1,
    );
  }
}
