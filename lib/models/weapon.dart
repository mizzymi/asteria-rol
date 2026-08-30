import 'skill.dart';
import 'weapon_damage.dart';
import 'dice_pool.dart';
import 'critical_damage_bonus.dart';

class Weapon {
  String id;
  String name;

  AbilityType attackAbility;

  bool proficient;

  int magicBonus;

  int criticalMinimumNaturalRoll;

  bool empoweredCritical;

  // ===========================================================================
  // SISTEMA ANTIGUO
  // ===========================================================================

  String damageDice;

  String damageType;

  // ===========================================================================
  // NUEVO SISTEMA
  // ===========================================================================

  List<WeaponDamage> damages;

  List<CriticalDamageBonus> criticalDamageBonuses;

  Weapon({
    required this.id,
    required this.name,
    this.attackAbility = AbilityType.strength,
    this.proficient = true,
    this.magicBonus = 0,
    this.criticalMinimumNaturalRoll = 20,
    this.empoweredCritical = false,

    // Legacy
    this.damageDice = '1d6',
    this.damageType = 'Cortante',

    // Nuevo
    List<WeaponDamage>? damages,
    List<CriticalDamageBonus>? criticalDamageBonuses,
  }) : damages = damages ?? [],
       criticalDamageBonuses = criticalDamageBonuses ?? [];

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool get hasDamageComponents {
    return damages.isNotEmpty;
  }

  WeaponDamage? get primaryDamage {
    if (damages.isEmpty) {
      return null;
    }

    return damages.first;
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'attackAbility': attackAbility.name,
      'proficient': proficient,
      'magicBonus': magicBonus,
      'criticalMinimumNaturalRoll': criticalMinimumNaturalRoll,
      'empoweredCritical': empoweredCritical,
      // Legacy
      'damageDice': damageDice,
      'damageType': damageType,

      // Nuevo
      'damages': damages.map((damage) => damage.toMap()).toList(),
      'criticalDamageBonuses': criticalDamageBonuses
          .map((damage) => damage.toMap())
          .toList(),
    };
  }

  // ===========================================================================
  // FROM MAP
  // ===========================================================================

  factory Weapon.fromMap(Map<dynamic, dynamic> map) {
    final attackAbility = AbilityType.values.firstWhere(
      (value) => value.name == map['attackAbility']?.toString(),
      orElse: () => AbilityType.strength,
    );

    // =========================================================================
    // CARGAR NUEVO SISTEMA
    // =========================================================================

    final damages = <WeaponDamage>[];

    final rawDamages = map['damages'];

    if (rawDamages is List) {
      for (final rawDamage in rawDamages) {
        if (rawDamage == null) {
          continue;
        }

        try {
          damages.add(
            WeaponDamage.fromMap(Map<dynamic, dynamic>.from(rawDamage)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    final criticalDamageBonuses = <CriticalDamageBonus>[];

    final rawCriticalDamageBonuses = map['criticalDamageBonuses'];

    if (rawCriticalDamageBonuses is List) {
      for (final rawDamage in rawCriticalDamageBonuses) {
        if (rawDamage is! Map) {
          continue;
        }

        try {
          criticalDamageBonuses.add(
            CriticalDamageBonus.fromMap(Map<dynamic, dynamic>.from(rawDamage)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    // =========================================================================
    // COMPATIBILIDAD CON ARMAS ANTIGUAS
    // =========================================================================

    final oldDamageDice = map['damageDice']?.toString().trim() ?? '1d6';

    final oldDamageType = map['damageType']?.toString().trim() ?? 'Cortante';

    /*
     * Si todavía no existen componentes de daño,
     * convertimos automáticamente el sistema antiguo.
     */
    if (damages.isEmpty) {
      final legacyPool = _parseLegacyDice(oldDamageDice);

      if (legacyPool != null) {
        damages.add(
          WeaponDamage(
            id: '${map['id']?.toString() ?? 'weapon'}_damage_1',

            name: 'Daño',

            dicePools: [legacyPool],

            /*
             * Tu sistema antiguo calculaba:
             *
             * daño del arma + modificador del atributo.
             *
             * Así conservamos exactamente ese comportamiento.
             */
            addAbilityModifier: true,

            abilityType: attackAbility,

            /*
             * El magicBonus ya se aplica desde Character.
             * De momento no lo duplicamos aquí.
             */
            bonus: 0,

            damageType: oldDamageType,
          ),
        );
      }
    }

    // =========================================================================
    // CREAR ARMA
    // =========================================================================

    return Weapon(
      id: map['id']?.toString() ?? '',

      name: map['name']?.toString() ?? '',

      attackAbility: attackAbility,

      proficient: map['proficient'] as bool? ?? true,

      magicBonus: (map['magicBonus'] as num?)?.toInt() ?? 0,

      criticalMinimumNaturalRoll:
          (map['criticalMinimumNaturalRoll'] as num?)?.toInt() ?? 20,

      empoweredCritical: map['empoweredCritical'] as bool? ?? false,

      damageDice: oldDamageDice,

      damageType: oldDamageType,

      damages: damages,

      criticalDamageBonuses: criticalDamageBonuses,
    );
  }
}

// =============================================================================
// LEGACY DICE PARSER
// =============================================================================

DicePool? _parseLegacyDice(String value) {
  final match = RegExp(
    r'^(\d+)d(\d+)$',
    caseSensitive: false,
  ).firstMatch(value.trim());

  if (match == null) {
    return null;
  }

  final count = int.tryParse(match.group(1) ?? '');

  final sides = int.tryParse(match.group(2) ?? '');

  if (count == null || sides == null || count <= 0 || sides <= 0) {
    return null;
  }

  return DicePool(count: count, sides: sides);
}
