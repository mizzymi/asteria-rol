import '../models/character.dart';
import '../models/character_effect.dart';
import '../models/critical_damage_bonus.dart';
import '../models/damage_bonus.dart';
import '../models/healing_bonus.dart';
import '../models/passive.dart';
import '../models/passive_resource_modifier.dart';
import '../models/skill.dart';
import '../models/dice_pool.dart';
import '../models/formulas/formula_modifier.dart';

import '../widgets/passive_form/triggers/passive_trigger_labels.dart';

import 'formula_display_formatter.dart';

class PassiveDisplayFormatter {
  const PassiveDisplayFormatter._();

  // ===========================================================================
  // DAMAGE BONUS
  // ===========================================================================

  static String damageBonus(DamageBonus bonus, {Character? character}) {
    var result = _bonusValue(
      dicePools: bonus.dicePools,
      multipliers: bonus.abilityModifierMultipliers,
      flat: bonus.flatBonus,
      formula: bonus.formula?.expression,
      character: character,
    );

    final damageType = bonus.damageType.trim();

    if (damageType.isNotEmpty) {
      result += ' · $damageType';
    }

    final name = bonus.name.trim();

    if (name.isNotEmpty) {
      return '$name · $result';
    }

    return result;
  }

  // ===========================================================================
  // CRITICAL DAMAGE BONUS
  // ===========================================================================

  static String criticalDamageBonus(
    CriticalDamageBonus bonus, {
    Character? character,
  }) {
    var result = _bonusValue(
      dicePools: bonus.dicePools,
      multipliers: bonus.abilityModifierMultipliers,
      flat: bonus.flatBonus,
      formula: bonus.formula?.expression,
      character: character,
    );

    final damageType = bonus.damageType.trim();

    if (damageType.isNotEmpty) {
      result += ' · $damageType';
    }

    if (!bonus.alwaysTriggers) {
      result += ' · ${bonus.chancePercent}%';
    }

    final name = bonus.name.trim();

    if (name.isNotEmpty) {
      return '$name · $result';
    }

    return result;
  }

  // ===========================================================================
  // HEALING BONUS
  // ===========================================================================

  static String healingBonus(HealingBonus bonus, {Character? character}) {
    final result = _bonusValue(
      dicePools: bonus.dicePools,
      multipliers: bonus.abilityModifierMultipliers,
      flat: bonus.flatBonus,
      formula: bonus.formula?.expression,
      character: character,
    );

    final name = bonus.name.trim();

    if (name.isNotEmpty) {
      return '$name · $result';
    }

    return result;
  }

  // ===========================================================================
  // RESOURCE MODIFIER
  // ===========================================================================

  static String resourceModifier(
    PassiveResourceModifier modifier, {
    required Character? character,
  }) {
    final resource = character?.resourceById(modifier.resourceId);

    final resourceName = resource?.name.trim().isNotEmpty == true
        ? resource!.name.trim()
        : 'Recurso desconocido';

    final targetText = switch (modifier.target) {
      PassiveResourceTarget.current => 'Actual',
      PassiveResourceTarget.max => 'Máximo',
    };

    final operationText = switch (modifier.operation) {
      FormulaModifierOperation.add => '+',
      FormulaModifierOperation.subtract => '-',
      FormulaModifierOperation.set => '=',
    };

    final expression = FormulaDisplayFormatter.format(
      modifier.formula.expression,
      character,
    );

    return '$resourceName · '
        '$targetText · '
        '$operationText '
        '${expression.trim().isEmpty ? '0' : expression}';
  }

  // ===========================================================================
  // TRIGGER
  // ===========================================================================

  static String trigger(
    PassiveTrigger trigger, {
    required Character? character,
    List<CharacterEffect> linkedEffects = const [],
  }) {
    final pieces = <String>[];

    // ===========================================================================
    // EVENTO
    // ===========================================================================

    pieces.add(trigger.event.label);

    // ===========================================================================
    // DESTINO
    // ===========================================================================

    pieces.add(
      trigger.target == PassiveTriggerTarget.self
          ? 'Objetivo: propio personaje'
          : 'Objetivo: objetivo de la acción',
    );

    // ===========================================================================
    // LÍMITE
    // ===========================================================================

    switch (trigger.usageLimit) {
      case TriggerUsageLimit.unlimited:
        break;

      case TriggerUsageLimit.oncePerTurn:
        pieces.add('Una vez por turno');
        break;

      case TriggerUsageLimit.oncePerRound:
        pieces.add('Una vez por ronda');
        break;
    }

    // ===========================================================================
    // SALVACIÓN
    // ===========================================================================

    final savingThrow = trigger.savingThrow;

    if (savingThrow != null && savingThrow.dc > 0) {
      pieces.add(
        'Salvación ${savingThrow.ability.shortLabel} · CD ${savingThrow.dc}',
      );
    }

    // ===========================================================================
    // ACCIONES
    // ===========================================================================

    for (final action in trigger.actions) {
      pieces.add(
        _triggerActionText(
          action,
          character: character,
          linkedEffects: linkedEffects,
        ),
      );
    }

    // ===========================================================================
    // CONDICIÓN
    // ===========================================================================

    final conditionExpression = trigger.condition?.expression.trim();

    if (conditionExpression != null && conditionExpression.isNotEmpty) {
      final condition = FormulaDisplayFormatter.format(
        conditionExpression,
        character,
      );

      pieces.add('Si: $condition');
    }

    // ===========================================================================
    // MODO
    // ===========================================================================

    if (trigger.mode == PassiveTriggerMode.whileCondition) {
      pieces.add('Mientras se cumpla');
    }

    // ===========================================================================
    // CUSTOM EVENT
    // ===========================================================================

    if (trigger.event == PassiveTriggerEvent.custom) {
      final customEvent = trigger.customEvent?.trim();

      if (customEvent != null && customEvent.isNotEmpty) {
        pieces.add(customEvent);
      }
    }

    return pieces.join(' · ');
  }

  // ===========================================================================
  // TRIGGER TARGET
  // ===========================================================================

  static String _triggerActionTargetName(
    PassiveTriggerAction action, {
    required String targetId,
    required Character? character,
    required List<CharacterEffect> linkedEffects,
  }) {
    switch (action.type) {
      // =========================================================================
      // RESOURCE
      // =========================================================================

      case PassiveTriggerActionType.addResource:
      case PassiveTriggerActionType.subtractResource:
      case PassiveTriggerActionType.setResource:
        final resource = character?.resourceById(targetId);

        if (resource != null) {
          final name = resource.name.trim();

          if (name.isNotEmpty) {
            return name;
          }
        }

        return targetId;

      // =========================================================================
      // COUNTER
      // =========================================================================

      case PassiveTriggerActionType.incrementCounter:
      case PassiveTriggerActionType.setCounter:
        final counter = character?.counterById(targetId);

        if (counter != null) {
          final name = counter.name.trim();

          if (name.isNotEmpty) {
            return name;
          }

          return counter.id;
        }

        return targetId;

      // =========================================================================
      // EFFECT
      // =========================================================================

      case PassiveTriggerActionType.applyEffect:
      case PassiveTriggerActionType.removeEffect:
        for (final effect in linkedEffects) {
          if (effect.id != targetId) {
            continue;
          }

          final name = effect.name.trim();

          return name.isEmpty ? effect.id : name;
        }

        final effect = character?.effectById(targetId);

        if (effect != null) {
          final name = effect.name.trim();

          return name.isEmpty ? effect.id : name;
        }

        return targetId;

      // =========================================================================
      // SIN TARGET ID ESPECIAL
      // =========================================================================

      case PassiveTriggerActionType.addCharge:
      case PassiveTriggerActionType.subtractCharge:
      case PassiveTriggerActionType.dealDamage:
      case PassiveTriggerActionType.heal:
        return targetId;
    }
  }

  static String _triggerActionText(
    PassiveTriggerAction action, {
    required Character? character,
    required List<CharacterEffect> linkedEffects,
  }) {
    final pieces = <String>[];

    pieces.add(action.type.label);

    // ===========================================================================
    // TARGET ID ESPECÍFICO
    // ===========================================================================

    final targetId = action.targetId?.trim();

    if (targetId != null && targetId.isNotEmpty) {
      pieces.add(
        _triggerActionTargetName(
          action,
          targetId: targetId,
          character: character,
          linkedEffects: linkedEffects,
        ),
      );
    }

    // ===========================================================================
    // DADOS
    // ===========================================================================

    if (action.hasDice) {
      pieces.add(action.diceNotation);
    }

    // ===========================================================================
    // VALOR / FÓRMULA
    // ===========================================================================

    final valueExpression = action.valueFormula?.expression.trim();

    if (valueExpression != null && valueExpression.isNotEmpty) {
      final value = FormulaDisplayFormatter.format(valueExpression, character);

      pieces.add('Valor: $value');
    }

    // ===========================================================================
    // TIPO DE DAÑO
    // ===========================================================================

    if (action.hasDamageType) {
      pieces.add(action.damageType.trim());
    }

    return pieces.join(' · ');
  }

  // ===========================================================================
  // BONUS VALUE
  // ===========================================================================

  static String _bonusValue({
    required List<DicePool> dicePools,
    required Map<AbilityType, int> multipliers,
    required int flat,
    required String? formula,
    required Character? character,
  }) {
    final pieces = <String>[];

    // -------------------------------------------------------------------------
    // DADOS
    // -------------------------------------------------------------------------

    for (final pool in dicePools) {
      final count = pool.count;
      final sides = pool.sides;

      if (count <= 0 || sides <= 0) {
        continue;
      }

      pieces.add('${count}d$sides');
    }

    // -------------------------------------------------------------------------
    // ATRIBUTOS
    // -------------------------------------------------------------------------

    for (final entry in multipliers.entries) {
      final multiplier = entry.value;

      if (multiplier == 0) {
        continue;
      }

      if (multiplier == 1) {
        pieces.add(entry.key.shortLabel);

        continue;
      }

      if (multiplier == -1) {
        pieces.add('-${entry.key.shortLabel}');

        continue;
      }

      pieces.add('$multiplier×${entry.key.shortLabel}');
    }

    // -------------------------------------------------------------------------
    // FIJO
    // -------------------------------------------------------------------------

    if (flat != 0) {
      pieces.add(flat > 0 ? '+$flat' : '$flat');
    }

    // -------------------------------------------------------------------------
    // FÓRMULA
    // -------------------------------------------------------------------------

    final formulaExpression = formula?.trim();

    if (formulaExpression != null && formulaExpression.isNotEmpty) {
      final formatted = FormulaDisplayFormatter.format(
        formulaExpression,
        character,
      );

      pieces.add('ƒ($formatted)');
    }

    // -------------------------------------------------------------------------
    // RESULTADO
    // -------------------------------------------------------------------------

    if (pieces.isEmpty) {
      return 'Sin valor';
    }

    return _joinMathPieces(pieces);
  }

  // ===========================================================================
  // MATH JOIN
  // ===========================================================================

  static String _joinMathPieces(List<String> pieces) {
    if (pieces.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();

    for (var i = 0; i < pieces.length; i++) {
      final piece = pieces[i].trim();

      if (piece.isEmpty) {
        continue;
      }

      if (buffer.isEmpty) {
        buffer.write(piece);
        continue;
      }

      if (piece.startsWith('-')) {
        buffer.write(' - ${piece.substring(1)}');
      } else if (piece.startsWith('+')) {
        buffer.write(' + ${piece.substring(1)}');
      } else {
        buffer.write(' + $piece');
      }
    }

    return buffer.toString();
  }
}
