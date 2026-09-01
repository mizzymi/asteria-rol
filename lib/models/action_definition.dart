import 'ability.dart';
import 'skill.dart';
import 'weapon.dart';

class ActionDefinition {
  final String id;
  final String name;

  final AbilityType abilityType;

  final bool requiresAttackRoll;

  final AbilityTargetType targetType;

  final AbilityTargetResolutionMode targetResolutionMode;

  const ActionDefinition({
    required this.id,
    required this.name,
    required this.abilityType,
    required this.requiresAttackRoll,
    required this.targetType,
    required this.targetResolutionMode,
  });

  factory ActionDefinition.fromAbility(CharacterAbility ability) {
    return ActionDefinition(
      id: ability.id,
      name: ability.name,
      abilityType: ability.abilityType,
      requiresAttackRoll: ability.requiresAttackRoll,
      targetType: ability.targetType,
      targetResolutionMode: ability.targetResolutionMode,
    );
  }
  factory ActionDefinition.fromWeapon(
      Weapon weapon,
      ) {
    return ActionDefinition(
      id: weapon.id,
      name: weapon.name,
      abilityType: weapon.attackAbility,
      requiresAttackRoll: true,
      targetType: AbilityTargetType.external,
      targetResolutionMode:
      AbilityTargetResolutionMode.shared,
    );
  }

}
