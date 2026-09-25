import 'ability.dart';
import 'ability_effect_part.dart';
import 'dice_pool.dart';
import 'action_critical_profile.dart';
import 'action_hit_behavior.dart';
import '../services/formula_evaluator.dart';
import '../utils/formula_dice_helper.dart';
import 'formulas/character_formula.dart';
import 'formulas/formula_context.dart';

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

enum ActionDiceSourceType {
  ability,
  weapon,
  passive,
  effect,
  criticalBonus,
  feature,
}

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

  /// Modificador FINAL utilizado por el cálculo.
  ///
  /// Ejemplo:
  ///
  /// normal:
  /// +4 SAB
  ///
  /// crítico:
  /// modifier = 8
  final int modifier;

  /// Modificador original antes de transformaciones de crítico.
  ///
  /// Ejemplo:
  ///
  /// baseModifier = 4
  /// modifier = 8
  ///
  /// Permite mostrar:
  ///
  /// +4 SAB ×2
  final int? baseModifier;

  /// Procedencia visual del modificador.
  ///
  /// Ejemplos:
  /// SAB
  /// INT
  /// FUE
  /// Competencia
  final String modifierLabel;

  /// Valor fijo añadido sin tirada.
  ///
  /// Ejemplos:
  /// máximo automático de crítico,
  /// crítico potenciado, etc.
  final int automaticValue;

  /// Procedencia visual del valor automático.
  ///
  /// Ejemplos:
  /// Crítico
  /// Crítico potenciado
  final String automaticValueLabel;

  /// Fórmula aplicada cuando esta parte pertenece a un crítico potenciado.
  final String empoweredCriticalFormula;

  /// Turno actual para la variable TURNO.
  final int empoweredCriticalTurn;
  final int empoweredCriticalMaximum;
  final Map<String, double> empoweredCriticalResources;
  final Map<String, double> empoweredCriticalResourceMaximums;
  final Map<String, double> empoweredCriticalCounters;
  final int empoweredCriticalCharges;
  final int empoweredCriticalMaxCharges;

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
  /// El resultado final por target использует este dato para filtrar
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

    this.baseModifier,
    this.modifierLabel = '',

    this.abilityPart,
    this.kind = ActionDicePartKind.normal,

    this.automaticValue = 0,
    this.automaticValueLabel = '',
    this.empoweredCriticalFormula = '',
    this.empoweredCriticalTurn = 1,
    this.empoweredCriticalMaximum = 0,
    this.empoweredCriticalResources = const {},
    this.empoweredCriticalResourceMaximums = const {},
    this.empoweredCriticalCounters = const {},
    this.empoweredCriticalCharges = 0,
    this.empoweredCriticalMaxCharges = 0,

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
    return requiresRoll ||
        modifier != 0 ||
        automaticValue != 0 ||
        empoweredCriticalFormula.trim().isNotEmpty;
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

    if (modifier != 0) {
      final sign = modifier > 0 ? '+' : '-';
      final value = modifier.abs();

      final label = modifierLabel.trim();

      pieces.add(label.isNotEmpty ? '$sign$value $label' : '$sign$value');
    }

    if (automaticValue != 0) {
      final sign = automaticValue > 0 ? '+' : '-';
      final value = automaticValue.abs();

      final label = automaticValueLabel.trim();

      pieces.add(
        label.isNotEmpty ? '$sign$value $label' : '$sign$value automático',
      );
    }

    return pieces.join(' · ');
  }
}

// =============================================================================
// FORMULA EXTENSION
// =============================================================================

extension ActionDiceRequestPartFormula on ActionDiceRequestPart {
  static ActionDiceRequestPart fromFormula({
    required String id,
    required String effectId,
    required String effectName,
    required AbilityEffectType effectType,
    required String formulaExpression,
    required FormulaContext formulaContext,
    required ActionHitBehavior hitBehavior,
    ActionDiceSourceType sourceType = ActionDiceSourceType.feature,
    String sourceId = '',
    String sourceName = '',
    String damageType = '',
    String? customModifierLabel,
  }) {
    final extraction = FormulaDiceExtraction.extract(formulaExpression);

    int calculatedModifier = 0;
    if (extraction.cleanedExpression.trim().isNotEmpty) {
      final evalResult = const FormulaEvaluator().evaluate(
        CharacterFormula(expression: extraction.cleanedExpression),
        context: formulaContext,
      );

      if (evalResult.valid) {
        calculatedModifier = evalResult.value.round();
      }
    }

    return ActionDiceRequestPart(
      id: id,
      effectId: effectId,
      effectName: effectName,
      effectType: effectType,
      dicePools: extraction.dicePools,
      modifier: calculatedModifier,
      modifierLabel:
          customModifierLabel ?? (calculatedModifier != 0 ? 'Mod' : ''),
      hitBehavior: hitBehavior,
      sourceType: sourceType,
      sourceId: sourceId,
      sourceName: sourceName,
      damageType: damageType,
    );
  }
}

class ActionPhysicalDiceInput {
  final String requestPartId;

  final List<List<int>> rolls;

  const ActionPhysicalDiceInput({
    required this.requestPartId,
    required this.rolls,
  });
}
