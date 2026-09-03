import '../models/ability.dart';
import '../models/action_resolution_plan.dart';
import '../models/character.dart';

class ActionStatResolver {
  final Character character;

  const ActionStatResolver({required this.character});

  int effectModifier({
    required ActionResolutionPlan plan,
    required AbilityEffect effect,
  }) {
    final ability = plan.source.ability;

    if (ability != null) {
      return character.abilityEffectModifier(ability, effect);
    }

    return 0;
  }

  int effectSaveDc({
    required ActionResolutionPlan plan,
    required AbilityEffect effect,
  }) {
    final fixedSaveDc = plan.definition.fixedSaveDc;

    if (fixedSaveDc != null) {
      return fixedSaveDc;
    }

    final ability = plan.source.ability;

    if (ability != null) {
      return character.abilityEffectSaveDc(ability, effect);
    }

    throw StateError(
      'La acción "${plan.definition.name}" '
      'no define una CD de salvación.',
    );
  }

  int attackModifier(ActionResolutionPlan plan) {
    final weapon = plan.source.weapon;

    if (weapon != null) {
      return character.attackBonus(weapon);
    }

    final ability = plan.source.ability;

    if (ability != null) {
      return character.characterAbilityAttackBonus(ability);
    }

    return plan.definition.attackBonus;
  }
}
