import 'ability_effect_part.dart';
import 'action_cost.dart';

enum ActionOptionalSourceType { abilityPart, damageBonus, criticalDamageBonus }

class ActionOptionalSource {
  final ActionOptionalSourceType type;

  final String id;

  final String label;

  const ActionOptionalSource({
    required this.type,
    required this.id,
    required this.label,
  });
}

class ActionOptionalGroup {
  final String id;

  final String label;

  /// Partes opcionales procedentes directamente de la habilidad.
  ///
  /// Se mantiene para compatibilidad y para costes de AbilityEffectPart.
  final List<AbilityEffectPart> parts;

  /// Todas las fuentes que forman parte visual/mecánicamente del grupo.
  ///
  /// Puede contener:
  /// - AbilityEffectPart
  /// - DamageBonus
  /// - CriticalDamageBonus
  final List<ActionOptionalSource> sources;

  final List<ActionCost> costs;

  const ActionOptionalGroup({
    required this.id,
    required this.label,
    this.parts = const [],
    this.sources = const [],
    this.costs = const [],
  });

  bool get hasCosts => costs.isNotEmpty;

  bool get hasSources => sources.isNotEmpty;

  bool get hasAbilityParts => parts.isNotEmpty;
}
