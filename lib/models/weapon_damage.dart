import 'skill.dart';
import 'dice_pool.dart';

class WeaponDamage {
  String id;

  String name;

  List<DicePool> dicePools;

  /// Dados adicionales que SOLO se tiran en un crítico.
  ///
  /// Ejemplo:
  /// Daño normal: 1d8
  /// Crítico extra: 2d6
  List<DicePool> criticalDicePools;

  bool addAbilityModifier;

  AbilityType abilityType;

  int bonus;

  String damageType;

  WeaponDamage({
    required this.id,
    this.name = '',
    List<DicePool>? dicePools,
    List<DicePool>? criticalDicePools,
    this.addAbilityModifier = false,
    this.abilityType = AbilityType.strength,
    this.bonus = 0,
    this.damageType = '',
  }) : dicePools = dicePools ?? [DicePool(count: 1, sides: 6)],
       criticalDicePools = criticalDicePools ?? [];

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool get hasDamage {
    return dicePools.isNotEmpty ||
        criticalDicePools.isNotEmpty ||
        bonus != 0 ||
        addAbilityModifier;
  }

  String get diceNotation {
    if (dicePools.isEmpty) {
      return '';
    }

    return dicePools.map((pool) => '${pool.count}d${pool.sides}').join(' + ');
  }

  String get criticalDiceNotation {
    if (criticalDicePools.isEmpty) {
      return '';
    }

    return criticalDicePools
        .map((pool) => '${pool.count}d${pool.sides}')
        .join(' + ');
  }

  bool get hasCriticalDamage {
    return criticalDicePools.isNotEmpty;
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,

      'dicePools': dicePools
          .map((pool) => {'count': pool.count, 'sides': pool.sides})
          .toList(),

      'criticalDicePools': criticalDicePools
          .map((pool) => {'count': pool.count, 'sides': pool.sides})
          .toList(),

      'addAbilityModifier': addAbilityModifier,
      'abilityType': abilityType.name,
      'bonus': bonus,
      'damageType': damageType,
    };
  }

  factory WeaponDamage.fromMap(Map<dynamic, dynamic> map) {
    final dicePools = <DicePool>[];
    final criticalDicePools = <DicePool>[];

    final rawDicePools = map['dicePools'];

    if (rawDicePools is List) {
      for (final rawPool in rawDicePools) {
        if (rawPool == null) {
          continue;
        }

        try {
          final poolMap = Map<dynamic, dynamic>.from(rawPool);

          dicePools.add(
            DicePool(
              count: (poolMap['count'] as num?)?.toInt() ?? 1,
              sides: (poolMap['sides'] as num?)?.toInt() ?? 6,
            ),
          );
        } catch (_) {
          continue;
        }
      }
    }

    final rawCriticalDicePools = map['criticalDicePools'];

    if (rawCriticalDicePools is List) {
      for (final rawPool in rawCriticalDicePools) {
        if (rawPool == null) {
          continue;
        }

        try {
          final poolMap = Map<dynamic, dynamic>.from(rawPool);

          criticalDicePools.add(
            DicePool(
              count: (poolMap['count'] as num?)?.toInt() ?? 1,
              sides: (poolMap['sides'] as num?)?.toInt() ?? 6,
            ),
          );
        } catch (_) {
          continue;
        }
      }
    }

    return WeaponDamage(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      dicePools: dicePools,
      criticalDicePools: criticalDicePools,
      addAbilityModifier: map['addAbilityModifier'] as bool? ?? false,
      abilityType: AbilityType.values.firstWhere(
        (value) => value.name == map['abilityType']?.toString(),
        orElse: () => AbilityType.strength,
      ),
      bonus: (map['bonus'] as num?)?.toInt() ?? 0,
      damageType: map['damageType']?.toString() ?? '',
    );
  }
}
