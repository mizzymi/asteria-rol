import 'ability.dart';
import 'ability_effect_part.dart';
import 'dice_pool.dart';
import 'action_critical_profile.dart';

enum ActionDicePartKind { normal, criticalExtra }

enum ActionDiceSourceType { ability, passive, effect, criticalBonus }

class ActionDiceRequest {
  final List<ActionDiceRequestPart> parts;

  final ActionCriticalProfile criticalProfile;

  const ActionDiceRequest({
    this.parts = const [],
    this.criticalProfile = const ActionCriticalProfile(),
  });

  bool get isEmpty => parts.isEmpty;

  bool get isNotEmpty => parts.isNotEmpty;

  int get totalDiceCount {
    return parts.fold<int>(0, (total, part) => total + part.totalDiceCount);
  }
}

class ActionDiceRequestPart {
  final String id;

  final String effectId;

  final String effectName;

  final AbilityEffectType effectType;

  final AbilityEffectPart? abilityPart;

  final List<DicePool> dicePools;

  /// Modificador que se suma DESPUÉS de los dados.
  final int modifier;

  final ActionDicePartKind kind;

  /// Cantidad fija que esta parte aporta sin necesidad de tirada.
  ///
  /// Se utilizará especialmente en crítico potenciado.
  final int automaticValue;

  final ActionDiceSourceType sourceType;

  final String sourceId;

  final String sourceName;

  final String damageType;

  const ActionDiceRequestPart({
    required this.id,
    required this.effectId,
    required this.effectName,
    required this.effectType,
    required this.dicePools,
    required this.modifier,
    this.abilityPart,
    this.kind = ActionDicePartKind.normal,
    this.automaticValue = 0,
    this.sourceType = ActionDiceSourceType.ability,
    this.sourceId = '',
    this.sourceName = '',
    this.damageType = '',
  });

  bool get requiresRoll {
    return dicePools.isNotEmpty;
  }

  int get totalDiceCount {
    return dicePools.fold<int>(0, (total, pool) => total + pool.count);
  }

  bool get hasDice => dicePools.isNotEmpty;

  String get diceNotation {
    return dicePools.map((pool) => pool.notation).join(' + ');
  }
}
