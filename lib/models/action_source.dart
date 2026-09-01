import 'ability.dart';
import 'weapon.dart';

enum ActionSourceType {
  ability,
  weapon,
}

class ActionSource {
  final ActionSourceType type;

  final String id;
  final String name;

  final CharacterAbility? ability;
  final Weapon? weapon;

  const ActionSource._({
    required this.type,
    required this.id,
    required this.name,
    this.ability,
    this.weapon,
  });

  factory ActionSource.ability(
      CharacterAbility ability,
      ) {
    return ActionSource._(
      type: ActionSourceType.ability,
      id: ability.id,
      name: ability.name,
      ability: ability,
    );
  }

  factory ActionSource.weapon(
      Weapon weapon,
      ) {
    return ActionSource._(
      type: ActionSourceType.weapon,
      id: weapon.id,
      name: weapon.name,
      weapon: weapon,
    );
  }

  bool get isAbility {
    return type == ActionSourceType.ability;
  }

  bool get isWeapon {
    return type == ActionSourceType.weapon;
  }
}