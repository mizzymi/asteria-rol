import 'ability.dart';
import 'action_linked_effect.dart';

class ActionContent {
  final List<AbilityEffect> effects;

  final List<ActionLinkedEffect> linkedEffects;

  const ActionContent({this.effects = const [], this.linkedEffects = const []});

  factory ActionContent.fromAbility(CharacterAbility ability) {
    return ActionContent(
      effects: List<AbilityEffect>.unmodifiable(ability.effects),

      linkedEffects: List<ActionLinkedEffect>.unmodifiable(
        ability.linkedEffects,
      ),
    );
  }

  const ActionContent.empty() : effects = const [], linkedEffects = const [];

  bool get hasEffects => effects.isNotEmpty;

  bool get hasLinkedEffects => linkedEffects.isNotEmpty;

  bool get dealsDamage {
    return effects.any(
      (effect) => effect.effectType == AbilityEffectType.damage,
    );
  }

  bool get heals {
    return effects.any(
      (effect) => effect.effectType == AbilityEffectType.healing,
    );
  }
}
