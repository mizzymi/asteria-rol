import 'dice_pool.dart';

class CriticalDamageBonus {
  String id;

  String name;

  List<DicePool> dicePools;

  /// 0 - 100
  int chancePercent;

  String damageType;

  String description;

  CriticalDamageBonus({
    required this.id,
    this.name = '',
    List<DicePool>? dicePools,
    this.chancePercent = 100,
    this.damageType = '',
    this.description = '',
  }) : dicePools = dicePools ?? [] {
    normalize();
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool get alwaysTriggers {
    return chancePercent >= 100;
  }

  bool get canTrigger {
    return chancePercent > 0 &&
        dicePools.isNotEmpty;
  }

  String get diceNotation {
    return dicePools
        .map(
          (pool) => pool.notation,
    )
        .join(' + ');
  }

  void normalize() {
    if (chancePercent < 0) {
      chancePercent = 0;
    }

    if (chancePercent > 100) {
      chancePercent = 100;
    }
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,

      'dicePools': dicePools
          .map(
            (pool) => pool.toMap(),
      )
          .toList(),

      'chancePercent':
      chancePercent,

      'damageType':
      damageType,

      'description':
      description,
    };
  }

  factory CriticalDamageBonus.fromMap(
      Map<dynamic, dynamic> map,
      ) {
    final dicePools =
    <DicePool>[];

    final rawPools =
    map['dicePools'];

    if (rawPools is List) {
      for (final rawPool
      in rawPools) {
        if (rawPool is! Map) {
          continue;
        }

        try {
          dicePools.add(
            DicePool.fromMap(
              Map<dynamic, dynamic>.from(
                rawPool,
              ),
            ),
          );
        } catch (_) {
          continue;
        }
      }
    }

    return CriticalDamageBonus(
      id:
      map['id']?.toString() ??
          '',

      name:
      map['name']?.toString() ??
          '',

      dicePools:
      dicePools,

      chancePercent:
      (map['chancePercent'] as num?)
          ?.toInt() ??
          100,

      damageType:
      map['damageType']
          ?.toString() ??
          '',

      description:
      map['description']
          ?.toString() ??
          '',
    );
  }
}