import 'action_dice_result.dart';
import 'action_effect_result.dart';
import 'action_saving_throw.dart';
import 'action_target_result.dart';
import 'action_result_dice_part_view_data.dart';
import 'action_result_saving_throw_view_data.dart';

class ActionResultTargetViewData {
  // ===========================================================================
  // TARGET
  // ===========================================================================

  final String targetId;

  final String targetLabel;

  final bool isSelf;

  final bool isExternal;

  // ===========================================================================
  // ATAQUE
  //
  // null = esta resolución no tuvo resultado de ataque para este target.
  // ===========================================================================

  final bool? hit;

  // ===========================================================================
  // RESULTADO FINAL
  //
  // Estos valores YA vienen resueltos por el Action Engine.
  //
  // La UI nunca debe volver a:
  // - aplicar hit/miss,
  // - dividir por saves,
  // - sumar dados,
  // - aplicar críticos.
  // ===========================================================================

  final int damage;

  final int healing;

  // ===========================================================================
  // DESGLOSE
  // ===========================================================================

  final ActionDiceResult diceResult;

  final List<ActionResultDicePartViewData> diceParts;

  final List<ActionSavingThrowResult> savingThrows;

  final List<ActionEffectResult> effects;

  final List<ActionResultSavingThrowViewData> savingThrowViews;

  const ActionResultTargetViewData({
    required this.targetId,
    required this.targetLabel,
    required this.isSelf,
    required this.isExternal,
    required this.hit,
    required this.damage,
    required this.healing,
    required this.diceResult,
    required this.diceParts,
    required this.savingThrows,
    required this.effects,
    required this.savingThrowViews,
  });

  // ===========================================================================
  // FACTORY
  // ===========================================================================

  factory ActionResultTargetViewData.fromTargetResult(
    ActionTargetResult result, {
    required String selfLabel,
  }) {
    final target = result.target;

    final String label;

    if (target.isSelf) {
      final normalizedSelfLabel = selfLabel.trim();

      label = normalizedSelfLabel.isEmpty
          ? 'Tu personaje'
          : normalizedSelfLabel;
    } else {
      final targetLabel = target.label?.trim();

      label = targetLabel == null || targetLabel.isEmpty
          ? 'Objetivo'
          : targetLabel;
    }

    return ActionResultTargetViewData(
      targetId: target.id,
      targetLabel: label,
      isSelf: target.isSelf,
      isExternal: target.isExternal,

      hit: result.hasAttackResult ? result.hit : null,

      damage: result.damage,

      healing: result.healing,

      diceResult: result.diceResult,

      diceParts: List<ActionResultDicePartViewData>.unmodifiable(
        result.diceResult.parts.map(
          ActionResultDicePartViewData.fromPartResult,
        ),
      ),

      savingThrows: List<ActionSavingThrowResult>.unmodifiable(
        result.savingThrows,
      ),

      effects: List<ActionEffectResult>.unmodifiable(result.effects),

      savingThrowViews: List<ActionResultSavingThrowViewData>.unmodifiable(
        result.savingThrows.map(ActionResultSavingThrowViewData.fromResult),
      ),
    );
  }

  // ===========================================================================
  // PRESENTACIÓN
  //
  // Estos getters NO resuelven mecánicas.
  // Solo ayudan a la UI a decidir qué secciones mostrar.
  // ===========================================================================

  bool get hasAttackResult {
    return hit != null;
  }

  bool get missed {
    return hit == false;
  }

  bool get landedHit {
    return hit == true;
  }

  bool get hasDamage {
    return damage > 0;
  }

  bool get hasHealing {
    return healing > 0;
  }

  bool get hasSavingThrows {
    return savingThrows.isNotEmpty;
  }

  bool get hasEffects {
    return effects.isNotEmpty;
  }

  bool get hasDiceBreakdown {
    return diceParts.isNotEmpty;
  }

  bool get hasResolvedContent {
    return hasDamage ||
        hasHealing ||
        hasSavingThrows ||
        hasEffects ||
        hasDiceBreakdown;
  }
}
