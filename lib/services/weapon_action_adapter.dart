import '../models/weapon_damage.dart';
import '../models/ability.dart';
import '../models/ability_effect_part.dart';
import '../models/action_hit_behavior.dart';
import '../models/character.dart';
import '../models/weapon.dart';

class WeaponActionAdapter {
  final Character character;

  const WeaponActionAdapter({required this.character});

  CharacterAbility toAbility(Weapon weapon) {
    return CharacterAbility(
      id: 'weapon:${weapon.id}',

      name: weapon.name,

      abilityType: weapon.attackAbility,

      requiresAttackRoll: true,

      targetType: AbilityTargetType.external,

      targetResolutionMode: AbilityTargetResolutionMode.shared,

      effects: [
        AbilityEffect(
          id: 'weapon-damage:${weapon.id}',

          name: weapon.name,

          effectType: AbilityEffectType.damage,

          parts: [
            for (final damage in weapon.damages) _damagePart(weapon, damage),
          ],
        ),
      ],
    );
  }

  AbilityEffectPart _damagePart(Weapon weapon, WeaponDamage damage) {
    final modifier = character.weaponDamageModifier(weapon, damage);

    return AbilityEffectPart(
      id:
          'weapon-damage-part:'
          '${weapon.id}:'
          '${damage.id}',

      dicePools: List.unmodifiable(damage.dicePools),

      flatBonus: modifier,

      typeName: damage.damageType,

      hitBehavior: ActionHitBehavior.requireHit,

      participatesInCritical: damage.participatesInCritical,
    );
  }
}
