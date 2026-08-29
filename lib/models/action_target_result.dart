import 'ability.dart';
import 'action_dice_result.dart';
import 'action_resolution_context.dart';
import 'action_saving_throw.dart';
import 'action_effect_result.dart';
import 'action_target_attack_result.dart';
import 'action_dice_request.dart';

class ActionTargetResult {
  final ActionTarget target;

  final ActionDiceResult diceResult;

  final ActionTargetAttackResult? attackResult;

  final List<ActionSavingThrowResult> savingThrows;

  final List<ActionEffectResult> effects;

  final int resolvedDamage;

  final int resolvedHealing;

  const ActionTargetResult({
    required this.target,
    required this.diceResult,
    this.attackResult,
    this.savingThrows = const [],
    this.effects = const [],
    this.resolvedDamage = 0,
    this.resolvedHealing = 0,
  }) : assert(resolvedDamage >= 0),
       assert(resolvedHealing >= 0);

  // ===========================================================================
  // ESTADO
  // ===========================================================================

  bool get hasEffects => effects.isNotEmpty;

  bool get hasAttackResult => attackResult != null;

  bool get hit => attackResult?.hit ?? true;

  bool get missed => !hit;

  int get rawDamage {
    return damageParts.fold<int>(0, (sum, part) => sum + part.total);
  }

  int get rawHealing {
    return healingParts.fold<int>(0, (sum, part) => sum + part.total);
  }

  // ===========================================================================
  // PARTES DEL RESULTADO
  // ===========================================================================

  List<ActionDicePartResult> get damageParts {
    return diceResult.parts
        .where((part) => part.request.effectType == AbilityEffectType.damage)
        .toList(growable: false);
  }

  List<ActionDicePartResult> get healingParts {
    return diceResult.parts
        .where((part) => part.request.effectType == AbilityEffectType.healing)
        .toList(growable: false);
  }

  // ===========================================================================
  // RESULTADOS
  // ===========================================================================

  int get damage => resolvedDamage;

  int get healing => resolvedHealing;

  bool get dealtDamage => damage > 0;

  bool get healed => healing > 0;
}
