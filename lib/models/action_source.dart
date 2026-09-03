import 'ability.dart';
import 'weapon.dart';
import 'item_definition.dart';

enum ActionSourceType {
  ability,
  weapon,

  // ---------------------------------------------------------------------------
  // RESERVADOS PARA EL SISTEMA GENERAL
  // ---------------------------------------------------------------------------
  item,
  spell,
  passive,
  custom,
}

class ActionSource {
  final ActionSourceType type;

  final String id;

  final String name;

  // ===========================================================================
  // REFERENCIAS TIPADAS
  //
  // Solo existen para fuentes cuyo modelo ya forma parte estable
  // del Action Engine.
  // ===========================================================================

  final CharacterAbility? ability;

  final Weapon? weapon;

  final ItemDefinition? item;

  const ActionSource._({
    required this.type,
    required this.id,
    required this.name,
    this.ability,
    this.weapon,
    this.item,
  });

  // ===========================================================================
  // ABILITY
  // ===========================================================================

  factory ActionSource.ability(CharacterAbility ability) {
    return ActionSource._(
      type: ActionSourceType.ability,
      id: ability.id,
      name: ability.name,
      ability: ability,
    );
  }

  // ===========================================================================
  // WEAPON
  // ===========================================================================

  factory ActionSource.weapon(Weapon weapon) {
    return ActionSource._(
      type: ActionSourceType.weapon,
      id: weapon.id,
      name: weapon.name,
      weapon: weapon,
    );
  }

  // ===========================================================================
  // GENÉRICO
  //
  // Permite introducir nuevas fuentes sin obligar al Action Engine
  // a conocer inmediatamente el modelo concreto.
  //
  // Ejemplos futuros:
  //
  // ActionSource.generic(
  //   type: ActionSourceType.item,
  //   id: item.id,
  //   name: item.name,
  // )
  //
  // ActionSource.generic(
  //   type: ActionSourceType.spell,
  //   id: spell.id,
  //   name: spell.name,
  // )
  // ===========================================================================

  factory ActionSource.generic({
    required ActionSourceType type,
    required String id,
    required String name,
  }) {
    if (type == ActionSourceType.ability || type == ActionSourceType.weapon) {
      throw ArgumentError(
        'Ability y Weapon deben construirse mediante '
        'ActionSource.ability() o ActionSource.weapon().',
      );
    }

    return ActionSource._(type: type, id: id, name: name);
  }

  factory ActionSource.item(
      ItemDefinition item,
      ) {
    return ActionSource._(
      type: ActionSourceType.item,
      id: item.id,
      name: item.name,
      item: item,
    );
  }

  // ===========================================================================
  // TYPE HELPERS
  // ===========================================================================

  bool get isAbility {
    return type == ActionSourceType.ability;
  }

  bool get isWeapon {
    return type == ActionSourceType.weapon;
  }

  bool get isItem {
    return type == ActionSourceType.item;
  }

  bool get isSpell {
    return type == ActionSourceType.spell;
  }

  bool get isPassive {
    return type == ActionSourceType.passive;
  }

  bool get isCustom {
    return type == ActionSourceType.custom;
  }

  // ===========================================================================
  // REFERENCIAS SEGURAS
  // ===========================================================================

  CharacterAbility get requireAbility {
    final value = ability;

    if (value == null) {
      throw StateError('La acción "$name" no procede de una habilidad.');
    }

    return value;
  }

  Weapon get requireWeapon {
    final value = weapon;

    if (value == null) {
      throw StateError('La acción "$name" no procede de un arma.');
    }

    return value;
  }

  // ===========================================================================
  // DEBUG / LOG
  // ===========================================================================

  String get debugLabel {
    return '${type.name}:$id:$name';
  }
}
