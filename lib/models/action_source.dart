import 'ability.dart';
import 'weapon.dart';
import 'item_definition.dart';

enum ActionSourceType { ability, weapon, item, spell, passive, custom }

class ActionSource {
  final ActionSourceType type;

  final String id;

  final String name;

  // ===========================================================================
  // REFERENCIAS TIPADAS
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
  // CONSTRUCTORES FACTORY
  // ===========================================================================

  factory ActionSource.ability(CharacterAbility ability) {
    return ActionSource._(
      type: ActionSourceType.ability,
      id: ability.id,
      name: ability.name,
      ability: ability,
    );
  }

  factory ActionSource.weapon(Weapon weapon) {
    return ActionSource._(
      type: ActionSourceType.weapon,
      id: weapon.id,
      name: weapon.name,
      weapon: weapon,
    );
  }

  factory ActionSource.item(ItemDefinition item) {
    return ActionSource._(
      type: ActionSourceType.item,
      id: item.id,
      name: item.name,
      item: item,
    );
  }

  factory ActionSource.generic({
    required ActionSourceType type,
    required String id,
    required String name,
  }) {
    if (type == ActionSourceType.ability ||
        type == ActionSourceType.weapon ||
        type == ActionSourceType.item ||
        type == ActionSourceType.spell) {
      throw ArgumentError(
        'Las fuentes soportadas deben construirse mediante su método tipado: '
        'ActionSource.ability(), ActionSource.weapon(), ActionSource.item() o ActionSource.spell().',
      );
    }

    return ActionSource._(type: type, id: id, name: name);
  }

  // ===========================================================================
  // TYPE HELPERS
  // ===========================================================================

  bool get isAbility => type == ActionSourceType.ability;
  bool get isWeapon => type == ActionSourceType.weapon;
  bool get isItem => type == ActionSourceType.item;
  bool get isSpell => type == ActionSourceType.spell;
  bool get isPassive => type == ActionSourceType.passive;
  bool get isCustom => type == ActionSourceType.custom;

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

  ItemDefinition get requireItem {
    final value = item;
    if (value == null) {
      throw StateError('La acción "$name" no procede de un objeto.');
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
