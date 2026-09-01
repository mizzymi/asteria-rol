import 'character_effect.dart';

class CharacterEffectTriggerExternalResult {
  final String sourceEffectId;

  final String sourceEffectName;

  final String triggerId;

  final String targetId;

  final String? targetLabel;

  final int damage;

  final int healing;

  final List<CharacterEffect> effects;

  final String resolutionId;

  const CharacterEffectTriggerExternalResult({
    required this.sourceEffectId,
    required this.sourceEffectName,
    required this.triggerId,
    required this.targetId,
    this.targetLabel,
    this.damage = 0,
    this.healing = 0,
    this.effects = const [],
    required this.resolutionId,
  });

  bool get changedAnything {
    return damage > 0 || healing > 0 || effects.isNotEmpty;
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'sourceEffectId': sourceEffectId,

      'sourceEffectName': sourceEffectName,

      'triggerId': triggerId,

      'targetId': targetId,

      'targetLabel': targetLabel,

      'damage': damage,

      'healing': healing,

      'effects': effects.map((effect) => effect.toMap()).toList(),

      'resolutionId': resolutionId,
    };
  }

  factory CharacterEffectTriggerExternalResult.fromMap(
    Map<dynamic, dynamic> map,
  ) {
    final effects = <CharacterEffect>[];

    final rawEffects = map['effects'];

    if (rawEffects is List) {
      for (final rawEffect in rawEffects) {
        if (rawEffect is! Map) {
          continue;
        }

        try {
          effects.add(
            CharacterEffect.fromMap(Map<dynamic, dynamic>.from(rawEffect)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    return CharacterEffectTriggerExternalResult(
      sourceEffectId: map['sourceEffectId']?.toString() ?? '',

      sourceEffectName: map['sourceEffectName']?.toString() ?? '',

      triggerId: map['triggerId']?.toString() ?? '',

      targetId: map['targetId']?.toString() ?? '',

      targetLabel: map['targetLabel']?.toString(),

      damage: (map['damage'] as num?)?.toInt() ?? 0,

      healing: (map['healing'] as num?)?.toInt() ?? 0,

      effects: List<CharacterEffect>.unmodifiable(effects),

      resolutionId: map['resolutionId']?.toString() ?? '',
    );
  }
}
