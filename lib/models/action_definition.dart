import 'ability.dart';
import 'skill.dart';
import 'weapon.dart';
import 'item_definition.dart';

class ActionDefinition {
  final String id;

  final String name;

  final AbilityType abilityType;

  final bool requiresAttackRoll;

  final AbilityTargetType targetType;

  final AbilityTargetResolutionMode targetResolutionMode;

  /// Bonus de ataque propio de una acción genérica.
  ///
  /// En habilidades legacy normalmente será 0 porque el cálculo
  /// todavía procede de Character.
  final int attackBonus;

  /// CD fija opcional para acciones que no procedan de CharacterAbility.
  final int? fixedSaveDc;

  const ActionDefinition({
    required this.id,
    required this.name,
    required this.abilityType,
    required this.requiresAttackRoll,
    required this.targetType,
    required this.targetResolutionMode,
    this.attackBonus = 0,
    this.fixedSaveDc,
  });

  factory ActionDefinition.fromAbility(CharacterAbility ability) {
    return ActionDefinition(
      id: ability.id,

      name: ability.name,

      abilityType: ability.abilityType,

      requiresAttackRoll: ability.requiresAttackRoll,

      targetType: ability.targetType,

      targetResolutionMode: ability.targetResolutionMode,

      // Legacy:
      // characterAbilityAttackBonus() sigue encargándose del cálculo.
      attackBonus: 0,

      fixedSaveDc: null,
    );
  }

  factory ActionDefinition.fromWeapon(Weapon weapon) {
    return ActionDefinition(
      id: weapon.id,

      name: weapon.name,

      abilityType: weapon.attackAbility,

      requiresAttackRoll: true,

      targetType: AbilityTargetType.external,

      targetResolutionMode: AbilityTargetResolutionMode.shared,

      attackBonus: 0,

      fixedSaveDc: null,
    );
  }

  factory ActionDefinition.fromConsumableItem(ItemDefinition item) {
    return ActionDefinition(
      id: item.id,
      name: item.name,

      targetType: AbilityTargetType.self,

      targetResolutionMode: AbilityTargetResolutionMode.shared,

      requiresAttackRoll: false,

      abilityType: AbilityType.strength,

      attackBonus: 0,
    );
  }
}
