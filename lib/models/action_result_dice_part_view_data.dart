import 'ability.dart';
import 'action_dice_request.dart';
import 'action_dice_result.dart';
import 'action_result_dice_group_view_data.dart';

class ActionResultDicePartViewData {
  // ===========================================================================
  // IDENTIDAD
  // ===========================================================================

  final String id;

  final String effectId;

  final String effectName;

  final AbilityEffectType effectType;

  // ===========================================================================
  // ORIGEN
  // ===========================================================================

  final ActionDiceSourceType sourceType;

  final String sourceId;

  final String sourceName;

  // ===========================================================================
  // DAÑO
  // ===========================================================================

  final String damageType;

  // ===========================================================================
  // CÁLCULO YA RESUELTO
  // ===========================================================================

  /// Notación original de los dados.
  ///
  /// Ejemplo:
  /// 2d6 + 1d8
  final String diceNotation;

  /// Modificador aplicado dentro del DiceCalculationResult.
  final int modifier;

  final int? baseModifier;

  final String modifierLabel;

  /// Valor automático añadido por el engine.
  ///
  /// Especialmente útil para críticos.
  final int automaticValue;

  final String automaticValueLabel;

  /// Total producido por la parte.
  ///
  /// YA está resuelto.
  final int total;

  // ===========================================================================
  // ESTADO
  // ===========================================================================

  final bool requiredRoll;

  final List<ActionResultDiceGroupViewData> rollGroups;

  final bool criticalExtra;

  const ActionResultDicePartViewData({
    required this.id,
    required this.effectId,
    required this.effectName,
    required this.effectType,
    required this.sourceType,
    required this.sourceId,
    required this.sourceName,
    required this.damageType,
    required this.diceNotation,

    required this.modifier,
    required this.baseModifier,
    required this.modifierLabel,

    required this.automaticValue,
    required this.automaticValueLabel,

    required this.total,
    required this.requiredRoll,
    required this.rollGroups,
    required this.criticalExtra,
  });

  // ===========================================================================
  // FACTORY
  // ===========================================================================

  factory ActionResultDicePartViewData.fromPartResult(
    ActionDicePartResult result,
  ) {
    final request = result.request;

    return ActionResultDicePartViewData(
      id: request.id,

      effectId: request.effectId,
      effectName: request.effectName,
      effectType: request.effectType,

      sourceType: request.sourceType,
      sourceId: request.sourceId,
      sourceName: request.sourceName,

      damageType: request.damageType,

      diceNotation: request.diceNotation,

      modifier: request.modifier,
      baseModifier: request.baseModifier,
      modifierLabel: request.modifierLabel,

      automaticValue: request.automaticValue,
      automaticValueLabel: request.automaticValueLabel,

      total: result.total,

      requiredRoll: request.requiresRoll,

      rollGroups: List<ActionResultDiceGroupViewData>.unmodifiable(
        result.result.groups.map(ActionResultDiceGroupViewData.fromGroup),
      ),

      criticalExtra: request.isCriticalExtra,
    );
  }

  // ===========================================================================
  // PRESENTACIÓN
  // ===========================================================================

  bool get hasDice {
    return diceNotation.isNotEmpty;
  }

  bool get hasRolledDice {
    return rollGroups.any((group) => group.hasRolls);
  }

  bool get isAutomaticOnly {
    return !hasRolledDice && modifier == 0 && automaticValue != 0;
  }

  bool get isModifierOnly {
    return !hasRolledDice && modifier != 0 && automaticValue == 0;
  }

  bool get hasNonDiceValue {
    return modifier != 0 || automaticValue != 0;
  }

  bool get hasCalculationText {
    return calculationText.isNotEmpty;
  }

  bool get hasModifier {
    return modifier != 0;
  }

  bool get hasBaseModifier {
    return baseModifier != null && baseModifier != 0;
  }

  bool get hasModifierLabel {
    return modifierLabel.trim().isNotEmpty;
  }

  bool get hasAutomaticValue {
    return automaticValue != 0;
  }

  bool get hasAutomaticValueLabel {
    return automaticValueLabel.trim().isNotEmpty;
  }

  bool get hasSourceName {
    return sourceName.trim().isNotEmpty;
  }

  bool get hasDamageType {
    return damageType.trim().isNotEmpty;
  }

  bool get hasEffectName {
    return effectName.trim().isNotEmpty;
  }

  bool get hasRollDetails {
    return rollGroups.any((group) => group.hasRolls);
  }

  bool get modifierWasTransformed {
    final base = baseModifier;

    if (base == null || base == 0) {
      return false;
    }

    return modifier != base;
  }

  bool get modifierWasDoubled {
    final base = baseModifier;

    if (base == null || base == 0) {
      return false;
    }

    return modifier == base * 2;
  }

  String get modifierText {
    if (modifier == 0) {
      return '';
    }

    final label = modifierLabel.trim();

    final base = baseModifier;

    // =========================================================================
    // CRÍTICO NORMAL
    //
    // Ejemplo:
    //
    // baseModifier = 4
    // modifier = 8
    //
    // Mostrar:
    // +4 SAB ×2
    // =========================================================================

    if (base != null && base != 0 && modifierWasDoubled) {
      final sign = base > 0 ? '+' : '-';

      return label.isNotEmpty
          ? '$sign${base.abs()} $label ×2'
          : '$sign${base.abs()} ×2';
    }

    // =========================================================================
    // NORMAL
    // =========================================================================

    final sign = modifier > 0 ? '+' : '-';

    return label.isNotEmpty
        ? '$sign${modifier.abs()} $label'
        : '$sign${modifier.abs()}';
  }

  String get automaticValueText {
    if (automaticValue == 0) {
      return '';
    }

    final sign = automaticValue > 0 ? '+' : '-';

    final label = automaticValueLabel.trim();

    return label.isNotEmpty
        ? '$sign${automaticValue.abs()} $label'
        : '$sign${automaticValue.abs()} automático';
  }

  // ===========================================================================
  // LABEL
  //
  // Solo presentación.
  // No altera ninguna mecánica.
  // ===========================================================================

  String get primaryLabel {
    if (criticalExtra) {
      if (sourceName.trim().isNotEmpty) {
        return sourceName;
      }

      return 'Daño crítico adicional';
    }

    if (effectName.trim().isNotEmpty) {
      return effectName;
    }

    if (sourceName.trim().isNotEmpty) {
      return sourceName;
    }

    return 'Componente';
  }

  // ===========================================================================
  // TEXTO DEL CÁLCULO
  //
  // Importante:
  //
  // Esto NO recalcula el total.
  //
  // Solo reconstruye una representación textual utilizando
  // valores que el engine ya dejó dentro del request.
  // ===========================================================================

  String get calculationText {
    final pieces = <String>[];

    final modifierPart = modifierText;

    if (modifierPart.isNotEmpty) {
      pieces.add(modifierPart);
    }

    final automaticPart = automaticValueText;

    if (automaticPart.isNotEmpty) {
      pieces.add(automaticPart);
    }

    return pieces.join(' · ');
  }

  String get sourceTypeLabel {
    switch (sourceType) {
      case ActionDiceSourceType.ability:
        return 'Habilidad';

      case ActionDiceSourceType.weapon:
        return 'Arma';

      case ActionDiceSourceType.passive:
        return 'Pasiva';

      case ActionDiceSourceType.effect:
        return 'Efecto';

      case ActionDiceSourceType.criticalBonus:
        return 'Bonus crítico';

      case ActionDiceSourceType.feature:
        return 'Característica';
    }
  }

  String get effectiveSourceLabel {
    final name = sourceName.trim();

    if (name.isEmpty) {
      return sourceTypeLabel;
    }

    return '$sourceTypeLabel · $name';
  }

  String get kindLabel {
    if (criticalExtra) {
      return 'Daño crítico adicional';
    }

    switch (effectType) {
      case AbilityEffectType.damage:
        return 'Daño';

      case AbilityEffectType.healing:
        return 'Curación';

      case AbilityEffectType.mitigation:
        return 'Mitigación';

      case AbilityEffectType.none:
        return 'Componente';
    }
  }
}
