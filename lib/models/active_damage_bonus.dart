import 'damage_bonus.dart';
import 'passive.dart';

class ActiveDamageBonus {
  final DamageBonus bonus;

  final CharacterPassive? passive;

  const ActiveDamageBonus({required this.bonus, this.passive});
}
