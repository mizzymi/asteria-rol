import '../models/ability.dart';
import '../models/action_resolution_plan.dart';
import '../models/character.dart';

class ActionStatResolver {
  final Character character;

  const ActionStatResolver({required this.character});

  // ===========================================================================
  // EFFECT MODIFIER
  // ===========================================================================

  int effectModifier({
    required ActionResolutionPlan plan,
    required AbilityEffect effect,
  }) {
    final ability = plan.ability;

    // -------------------------------------------------------------------------
    // HABILIDAD LEGACY
    // -------------------------------------------------------------------------

    if (ability != null) {
      return character.abilityEffectModifier(ability, effect);
    }

    // -------------------------------------------------------------------------
    // ACCIÓN GENÉRICA
    //
    // De momento una acción genérica sin CharacterAbility no posee
    // modificador específico de AbilityEffect.
    // -------------------------------------------------------------------------

    return 0;
  }

  // ===========================================================================
  // SAVE DC
  // ===========================================================================

  int effectSaveDc({
    required ActionResolutionPlan plan,
    required AbilityEffect effect,
  }) {
    final fixedSaveDc = plan.definition.fixedSaveDc;

    // -------------------------------------------------------------------------
    // CD DEFINIDA POR LA ACCIÓN
    // -------------------------------------------------------------------------

    if (fixedSaveDc != null) {
      return fixedSaveDc;
    }

    // -------------------------------------------------------------------------
    // HABILIDAD LEGACY
    // -------------------------------------------------------------------------

    final ability = plan.ability;

    if (ability != null) {
      return character.abilityEffectSaveDc(ability, effect);
    }

    throw StateError(
      'La acción "${plan.definition.name}" '
      'no define una CD de salvación.',
    );
  }

  // ===========================================================================
  // ATTACK MODIFIER
  // ===========================================================================

  int attackModifier(ActionResolutionPlan plan) {
    // -------------------------------------------------------------------------
    // HABILIDAD LEGACY
    // -------------------------------------------------------------------------

    final ability = plan.ability;

    if (ability != null) {
      return character.characterAbilityAttackBonus(ability);
    }

    // -------------------------------------------------------------------------
    // ACCIÓN GENÉRICA
    // -------------------------------------------------------------------------

    return plan.definition.attackBonus;
  }
}
