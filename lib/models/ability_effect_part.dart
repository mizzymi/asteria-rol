import 'dice_pool.dart';
import 'skill.dart';

class AbilityEffectPart {
  String id;

  List<DicePool> dicePools;

  Map<AbilityType, int> abilityModifierMultipliers;

  /// ID del recurso -> multiplicador.
  ///
  /// Ejemplo:
  ///
  /// mana: 1
  /// = suma el Maná actual una vez.
  ///
  /// rage: 2
  /// = suma 2 × Furia actual.
  ///
  /// IMPORTANTE:
  /// Esto NO consume ni modifica el recurso.
  Map<String, int> resourceValueMultipliers;

  int flatBonus;

  String typeName;

  AbilityEffectPart({
    required this.id,
    List<DicePool>? dicePools,
    Map<AbilityType, int>? abilityModifierMultipliers,
    Map<String, int>? resourceValueMultipliers,
    this.flatBonus = 0,
    this.typeName = '',
  }) : dicePools = dicePools ?? [],
       abilityModifierMultipliers = abilityModifierMultipliers ?? {},
       resourceValueMultipliers = resourceValueMultipliers ?? {};

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool get hasValue {
    return dicePools.isNotEmpty ||
        flatBonus != 0 ||
        abilityModifierMultipliers.values.any((value) => value != 0) ||
        resourceValueMultipliers.values.any((value) => value != 0);
  }

  String get diceNotation {
    return dicePools.map((pool) => pool.notation).join(' + ');
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,

      'dicePools': dicePools.map((pool) => pool.toMap()).toList(),

      'abilityModifierMultipliers': {
        for (final entry in abilityModifierMultipliers.entries)
          entry.key.name: entry.value,
      },

      'resourceValueMultipliers': {
        for (final entry in resourceValueMultipliers.entries)
          entry.key: entry.value,
      },

      'flatBonus': flatBonus,

      'typeName': typeName,
    };
  }

  factory AbilityEffectPart.fromMap(Map<dynamic, dynamic> map) {
    // =========================================================================
    // DADOS
    // =========================================================================

    final pools = <DicePool>[];

    final rawPools = map['dicePools'];

    if (rawPools is List) {
      for (final rawPool in rawPools) {
        if (rawPool is! Map) {
          continue;
        }

        try {
          pools.add(DicePool.fromMap(Map<dynamic, dynamic>.from(rawPool)));
        } catch (_) {
          continue;
        }
      }
    }

    // =========================================================================
    // MODIFICADORES DE ATRIBUTO
    // =========================================================================

    final multipliers = <AbilityType, int>{};

    final rawMultipliers = map['abilityModifierMultipliers'];

    if (rawMultipliers is Map) {
      final rawMap = Map<dynamic, dynamic>.from(rawMultipliers);

      for (final ability in AbilityType.values) {
        final value = (rawMap[ability.name] as num?)?.toInt() ?? 0;

        if (value != 0) {
          multipliers[ability] = value;
        }
      }
    }

    // =========================================================================
    // VALORES DE RECURSOS
    // =========================================================================

    final resourceValueMultipliers = <String, int>{};

    final rawResourceMultipliers = map['resourceValueMultipliers'];

    if (rawResourceMultipliers is Map) {
      for (final entry in rawResourceMultipliers.entries) {
        final resourceId = entry.key.toString();

        final multiplier = (entry.value as num?)?.toInt() ?? 0;

        if (resourceId.isEmpty || multiplier == 0) {
          continue;
        }

        resourceValueMultipliers[resourceId] = multiplier;
      }
    }

    // =========================================================================
    // RESULTADO
    // =========================================================================

    return AbilityEffectPart(
      id: map['id']?.toString() ?? '',

      dicePools: pools,

      abilityModifierMultipliers: multipliers,

      resourceValueMultipliers: resourceValueMultipliers,

      flatBonus: (map['flatBonus'] as num?)?.toInt() ?? 0,

      typeName: map['typeName']?.toString() ?? '',
    );
  }
}
