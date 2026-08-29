import 'dice_pool.dart';
import 'skill.dart';
import 'action_external_requirement.dart';
import 'formulas/character_formula.dart';
import 'action_cost.dart';
import 'action_hit_behavior.dart';

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

  // ===========================================================================
  // COSTES
  // ===========================================================================

  /// Costes adicionales de esta parte.
  ///
  /// Normalmente se utilizan con componentes opcionales.
  /// Solo se pagan si la parte acaba participando realmente.
  List<ActionCost>? _costs;

  List<ActionCost> get costs {
    return _costs ??= <ActionCost>[];
  }

  set costs(List<ActionCost> value) {
    _costs = value;
  }

  // ===========================================================================
  // CONDICIÓN
  // ===========================================================================

  CharacterFormula? condition;

  List<ActionExternalRequirement> externalRequirements;

  // ===========================================================================
  // OPCIONALIDAD
  // ===========================================================================

  bool optional;

  /// Permite que varias partes dependan de una misma elección.
  ///
  /// Si está vacío, la propia `id` de la parte actúa como grupo.
  String optionalGroupId;

  /// Texto que podrá mostrar la UI cuando pregunte si se utiliza.
  String optionalLabel;

  // ===========================================================================
  // HIT / MISS
  // ===========================================================================

  /// Define si esta parte depende del impacto de la acción.
  ///
  /// En una acción sin tirada de ataque, `requireHit` no bloquea nada.
  ///
  /// Se utiliza `requireHit` por defecto para conservar el comportamiento
  /// histórico de las habilidades ofensivas: hasta ahora el Flow eliminaba
  /// todas las partes cuando el ataque fallaba.
  ActionHitBehavior hitBehavior;

  bool participatesInCritical;

  AbilityEffectPart({
    required this.id,
    List<DicePool>? dicePools,
    Map<AbilityType, int>? abilityModifierMultipliers,
    Map<String, int>? resourceValueMultipliers,
    this.flatBonus = 0,
    this.typeName = '',
    List<ActionCost>? costs,
    this.condition,
    List<ActionExternalRequirement>? externalRequirements,
    this.optional = false,
    this.optionalGroupId = '',
    this.optionalLabel = '',
    this.hitBehavior = ActionHitBehavior.requireHit,
    this.participatesInCritical = true,
  }) : dicePools = dicePools ?? [],
       abilityModifierMultipliers = abilityModifierMultipliers ?? {},
       resourceValueMultipliers = resourceValueMultipliers ?? {},
       externalRequirements = List<ActionExternalRequirement>.from(
         externalRequirements ?? const [],
       ),
       _costs = List<ActionCost>.from(costs ?? const []);

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

  bool get hasCondition {
    return condition != null &&
        condition!.expression.trim().isNotEmpty &&
        condition!.expression.trim() != '0';
  }

  bool get hasExternalRequirements {
    return externalRequirements.isNotEmpty;
  }

  String get effectiveOptionalGroupId {
    final explicitId = optionalGroupId.trim();

    if (explicitId.isNotEmpty) {
      return explicitId;
    }

    return id;
  }

  String get effectiveOptionalLabel {
    final explicitLabel = optionalLabel.trim();

    if (explicitLabel.isNotEmpty) {
      return explicitLabel;
    }

    final explicitType = typeName.trim();

    if (explicitType.isNotEmpty) {
      return explicitType;
    }

    return 'Componente opcional';
  }

  bool get hasCosts => costs.isNotEmpty;

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

      'costs': costs.map((cost) => cost.toMap()).toList(),

      'condition': condition?.toMap(),

      'externalRequirements': externalRequirements
          .map((requirement) => requirement.toMap())
          .toList(),

      'optional': optional,

      'optionalGroupId': optionalGroupId,

      'optionalLabel': optionalLabel,

      'participatesInCritical': participatesInCritical,
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

    final externalRequirements = <ActionExternalRequirement>[];

    final rawExternalRequirements = map['externalRequirements'];

    if (rawExternalRequirements is List) {
      for (final rawRequirement in rawExternalRequirements) {
        if (rawRequirement is! Map) {
          continue;
        }

        try {
          externalRequirements.add(
            ActionExternalRequirement.fromMap(
              Map<dynamic, dynamic>.from(rawRequirement),
            ),
          );
        } catch (_) {
          continue;
        }
      }
    }

    final costs = <ActionCost>[];

    final rawCosts = map['costs'];

    if (rawCosts is List) {
      for (final rawCost in rawCosts) {
        if (rawCost is! Map) {
          continue;
        }

        try {
          final cost = ActionCost.fromMap(Map<dynamic, dynamic>.from(rawCost));

          if (cost.isValid) {
            costs.add(cost);
          }
        } catch (_) {
          continue;
        }
      }
    }

    final rawCondition = map['condition'];

    final condition = rawCondition is Map
        ? CharacterFormula.fromMap(Map<dynamic, dynamic>.from(rawCondition))
        : null;

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

      costs: costs,

      condition: condition,

      externalRequirements: externalRequirements,

      optional: map['optional'] as bool? ?? false,

      optionalGroupId: map['optionalGroupId']?.toString() ?? '',

      optionalLabel: map['optionalLabel']?.toString() ?? '',

      hitBehavior: ActionHitBehavior.values.firstWhere(
        (value) => value.name == map['hitBehavior']?.toString(),
        orElse: () => ActionHitBehavior.requireHit,
      ),

      participatesInCritical: map['participatesInCritical'] as bool? ?? true,
    );
  }
}
