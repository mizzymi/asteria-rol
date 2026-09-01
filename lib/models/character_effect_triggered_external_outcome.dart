import 'character_effect.dart';
import 'damage_bonus.dart';
import 'healing_bonus.dart';
import 'passive.dart';

class CharacterEffectTriggeredExternalOutcome {
  final String sourceEffectId;

  final String sourceEffectName;

  final String triggerId;

  final String targetId;

  final String? targetLabel;

  final List<DamageBonus> damageBonuses;

  final List<HealingBonus> healingBonuses;

  final List<CharacterEffect> linkedEffects;

  final TriggerUsageLimit usageLimit;

  const CharacterEffectTriggeredExternalOutcome({
    required this.sourceEffectId,
    required this.sourceEffectName,
    required this.triggerId,
    required this.targetId,
    this.targetLabel,
    this.damageBonuses = const [],
    this.healingBonuses = const [],
    this.linkedEffects = const [],
    this.usageLimit = TriggerUsageLimit.unlimited,
  });

  bool get hasDamage {
    return damageBonuses.any((bonus) => bonus.hasDamage);
  }

  bool get hasHealing {
    return healingBonuses.any((bonus) => bonus.hasHealing);
  }

  bool get hasEffects {
    return linkedEffects.isNotEmpty;
  }

  bool get changedAnything {
    return hasDamage || hasHealing || hasEffects;
  }

  String get usageKey {
    return '$sourceEffectId:$triggerId';
  }
}
