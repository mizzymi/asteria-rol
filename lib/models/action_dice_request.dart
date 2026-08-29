import 'ability.dart';
import 'ability_effect_part.dart';
import 'dice_pool.dart';
import 'action_critical_profile.dart';
import 'action_hit_behavior.dart';

// =============================================================================
// TIPO DE PARTE
// =============================================================================

enum ActionDicePartKind {
  normal,

  /// Daño/curación/etc. añadido específicamente por el crítico.
  criticalExtra,
}

// =============================================================================
// ORIGEN
// =============================================================================

enum ActionDiceSourceType { ability, passive, effect, criticalBonus }

// =============================================================================
// REQUEST
// =============================================================================

class ActionDiceRequest {
  final List<ActionDiceRequestPart> parts;

  final ActionCriticalProfile criticalProfile;

  const ActionDiceRequest({
    this.parts = const [],
    this.criticalProfile = const ActionCriticalProfile(),
  });

  bool get isEmpty {
    return parts.isEmpty;
  }

  bool get isNotEmpty {
    return parts.isNotEmpty;
  }

  // ===========================================================================
  // DADOS
  // ===========================================================================

  int get totalDiceCount {
    return parts.fold<int>(0, (total, part) => total + part.totalDiceCount);
  }

  bool get requiresRoll {
    return parts.any((part) => part.requiresRoll);
  }

  bool get hasAutomaticValues {
    return parts.any((part) => part.automaticValue != 0);
  }

  bool get hasModifiers {
    return parts.any((part) => part.modifier != 0);
  }

  // ===========================================================================
  // PARTES POR EFECTO
  // ===========================================================================

  List<ActionDiceRequestPart> partsForEffect(String effectId) {
    return parts
        .where((part) => part.effectId == effectId)
        .toList(growable: false);
  }
}

// =============================================================================
// REQUEST PART
// =============================================================================

class ActionDiceRequestPart {
  final String id;

  // ===========================================================================
  // EFECTO
  // ===========================================================================

  /// ID del AbilityEffect al que pertenece esta parte.
  final String effectId;

  /// Nombre visual del efecto.
  final String effectName;

  final AbilityEffectType effectType;

  /// Parte concreta del nuevo sistema de AbilityEffect.
  ///
  /// Puede ser null para partes generadas por:
  /// - pasivas
  /// - efectos activos
  /// - bonus de crítico
  final AbilityEffectPart? abilityPart;

  // ===========================================================================
  // CÁLCULO
  // ===========================================================================

  final List<DicePool> dicePools;

  /// Modificador añadido al resultado de los dados.
  ///
  /// Ejemplo:
  ///
  /// 2d6 + 5
  ///
  /// modifier = 5
  final int modifier;

  /// Cantidad fija añadida al total sin necesidad de tirada.
  ///
  /// Se utiliza especialmente para mecánicas como:
  ///
  /// crítico potenciado
  /// → máximo automático + tirada
  final int automaticValue;

  final ActionDicePartKind kind;

  // ===========================================================================
  // ORIGEN
  // ===========================================================================

  /// De dónde procede mecánicamente esta parte.
  final ActionDiceSourceType sourceType;

  /// ID del origen.
  ///
  /// Ejemplos:
  ///
  /// ability.id
  /// passive.id
  /// effect.id
  /// criticalBonus.id
  final String sourceId;

  /// Nombre visual del origen.
  final String sourceName;

  // ===========================================================================
  // DAÑO
  // ===========================================================================

  /// Tipo de daño, cuando corresponda.
  ///
  /// Ejemplos:
  ///
  /// Fuego
  /// Cortante
  /// Radiante
  final String damageType;

  /// Política de esta parte respecto al resultado del ataque.
  ///
  /// El resultado final por target utiliza este dato para filtrar
  /// una tirada shared sin tener que volver a interpretar su procedencia.
  final ActionHitBehavior hitBehavior;

  const ActionDiceRequestPart({
    required this.id,
    required this.effectId,
    required this.effectName,
    required this.effectType,
    required this.dicePools,
    required this.modifier,
    required this.hitBehavior,
    this.abilityPart,
    this.kind = ActionDicePartKind.normal,
    this.automaticValue = 0,
    this.sourceType = ActionDiceSourceType.ability,
    this.sourceId = '',
    this.sourceName = '',
    this.damageType = '',
  });

  // ===========================================================================
  // ESTADO
  // ===========================================================================

  bool get requiresRoll {
    return dicePools.any((pool) => pool.count > 0);
  }

  bool get hasDice {
    return requiresRoll;
  }

  bool get hasModifier {
    return modifier != 0;
  }

  bool get hasAutomaticValue {
    return automaticValue != 0;
  }

  /// La parte aporta algo al resultado aunque no tenga dados.
  bool get hasValue {
    return requiresRoll || modifier != 0 || automaticValue != 0;
  }

  bool get isCriticalExtra {
    return kind == ActionDicePartKind.criticalExtra;
  }

  // ===========================================================================
  // DADOS
  // ===========================================================================

  int get totalDiceCount {
    return dicePools.fold<int>(0, (total, pool) {
      if (pool.count <= 0) {
        return total;
      }

      return total + pool.count;
    });
  }

  String get diceNotation {
    return dicePools
        .where((pool) => pool.count > 0)
        .map((pool) => pool.notation)
        .join(' + ');
  }

  // ===========================================================================
  // TEXTO DE CÁLCULO
  //
  // Útil para dialogs y desglose.
  //
  // Ejemplo:
  //
  // 2d6 + 5 + 12 automático
  // ===========================================================================

  String get calculationText {
    final pieces = <String>[];

    if (diceNotation.isNotEmpty) {
      pieces.add(diceNotation);
    }

    if (modifier != 0) {
      if (pieces.isEmpty) {
        pieces.add('$modifier');
      } else {
        pieces.add(modifier > 0 ? '+ $modifier' : '- ${modifier.abs()}');
      }
    }

    if (automaticValue != 0) {
      if (pieces.isEmpty) {
        pieces.add('$automaticValue');
      } else {
        pieces.add(
          automaticValue > 0
              ? '+ $automaticValue'
              : '- ${automaticValue.abs()}',
        );
      }
    }

    if (pieces.isEmpty) {
      return '0';
    }

    return pieces.join(' ');
  }
}
