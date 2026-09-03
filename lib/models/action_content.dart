import 'skill.dart';
import 'action_hit_behavior.dart';
import 'ability.dart';
import 'action_damage_component.dart';
import 'action_linked_effect.dart';
import 'critical_damage_bonus.dart';
import 'weapon.dart';
import 'item_definition.dart';

class ActionContent {
  final List<AbilityEffect> effects;

  final List<ActionLinkedEffect> linkedEffects;

  /// Componentes de daño genéricos de la acción.
  ///
  /// Pueden proceder de:
  ///
  /// - armas
  /// - Items
  /// - magia
  /// - otras fuentes futuras
  final List<ActionDamageComponent> damageComponents;

  final List<CriticalDamageBonus> criticalDamageBonuses;

  const ActionContent({
    this.effects = const [],
    this.linkedEffects = const [],
    this.damageComponents = const [],
    this.criticalDamageBonuses = const [],
  });

  factory ActionContent.fromAbility(CharacterAbility ability) {
    return ActionContent(
      effects: List<AbilityEffect>.unmodifiable(ability.effects),

      linkedEffects: List<ActionLinkedEffect>.unmodifiable(
        ability.linkedEffects,
      ),
    );
  }

  factory ActionContent.fromWeapon(Weapon weapon) {
    final damageComponents = <ActionDamageComponent>[];

    for (var index = 0; index < weapon.damages.length; index++) {
      final damage = weapon.damages[index];

      final abilityMultipliers = <AbilityType, int>{};

      if (damage.addAbilityModifier) {
        abilityMultipliers[damage.abilityType] = 1;
      }

      damageComponents.add(
        ActionDamageComponent(
          id: damage.id,

          name: damage.name,

          dicePools: List.unmodifiable(damage.dicePools),

          criticalDicePools: List.unmodifiable(damage.criticalDicePools),

          abilityModifierMultipliers: Map.unmodifiable(abilityMultipliers),

          // El bonus mágico del arma forma
          // parte únicamente del primer
          // componente de daño.
          flatBonus: damage.bonus + (index == 0 ? weapon.magicBonus : 0),

          damageType: damage.damageType,

          participatesInCritical: damage.participatesInCritical,

          hitBehavior: ActionHitBehavior.requireHit,
        ),
      );
    }

    return ActionContent(
      damageComponents: List<ActionDamageComponent>.unmodifiable(
        damageComponents,
      ),

      criticalDamageBonuses: List<CriticalDamageBonus>.unmodifiable(
        weapon.criticalDamageBonuses,
      ),
    );
  }

  const ActionContent.empty()
    : effects = const [],
      linkedEffects = const [],
      damageComponents = const [],
      criticalDamageBonuses = const [];

  bool get hasEffects => effects.isNotEmpty;

  bool get hasLinkedEffects => linkedEffects.isNotEmpty;

  bool get hasDamageComponents => damageComponents.isNotEmpty;

  bool get hasCriticalDamageBonuses => criticalDamageBonuses.isNotEmpty;

  bool get dealsDamage {
    return effects.any(
          (effect) => effect.effectType == AbilityEffectType.damage,
        ) ||
        damageComponents.any((component) => component.hasDamage);
  }

  bool get heals {
    return effects.any(
      (effect) => effect.effectType == AbilityEffectType.healing,
    );
  }

  factory ActionContent.fromConsumableItem(ItemDefinition item) {
    final consumable = item.consumable;

    if (consumable == null) {
      return const ActionContent.empty();
    }

    return ActionContent(
      effects: List<AbilityEffect>.unmodifiable(consumable.effects),
    );
  }
}
