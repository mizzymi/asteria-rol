import 'action_hit_behavior.dart';
import 'dice_pool.dart';
import 'skill.dart';

class ActionDamageComponent {
  final String id;

  final String name;

  final List<DicePool> dicePools;

  /// Dados que se añaden únicamente cuando la acción es crítica.
  ///
  /// Estos dados NO vuelven a transformarse por crítico.
  final List<DicePool> criticalDicePools;

  /// Modificadores de atributo.
  ///
  /// Ejemplo:
  ///
  /// {
  ///   AbilityType.strength: 1,
  /// }
  ///
  /// significa +1 × modificador de FUE.
  final Map<AbilityType, int> abilityModifierMultipliers;

  /// Bonus plano inherente al componente.
  ///
  /// Para un arma aquí podemos incluir:
  ///
  /// damage.bonus + magicBonus
  ///
  /// cuando corresponda.
  final int flatBonus;

  final String damageType;

  final bool participatesInCritical;

  final ActionHitBehavior hitBehavior;

  const ActionDamageComponent({
    required this.id,
    this.name = '',
    this.dicePools = const [],
    this.criticalDicePools = const [],
    this.abilityModifierMultipliers = const {},
    this.flatBonus = 0,
    this.damageType = '',
    this.participatesInCritical = true,
    this.hitBehavior = ActionHitBehavior.requireHit,
  });

  bool get hasDamage {
    return dicePools.isNotEmpty ||
        criticalDicePools.isNotEmpty ||
        abilityModifierMultipliers.values.any((value) => value != 0) ||
        flatBonus != 0;
  }
}
