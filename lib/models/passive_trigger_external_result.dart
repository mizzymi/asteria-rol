import 'character_effect.dart';

class PassiveTriggerExternalResult {
  final String passiveId;
  final String passiveName;

  final String triggerId;

  final String targetId;
  final String? targetLabel;

  final bool saved;

  final int damage;
  final int healing;
  final int mitigation;

  /// Human-readable action/dice breakdown for this trigger.
  final List<String> breakdown;

  final List<CharacterEffect> effects;

  final String resolutionId;

  const PassiveTriggerExternalResult({
    required this.passiveId,
    required this.passiveName,
    required this.triggerId,
    required this.targetId,
    this.targetLabel,
    this.saved = false,
    this.damage = 0,
    this.healing = 0,
    this.mitigation = 0,
    this.breakdown = const [],
    this.effects = const [],
    required this.resolutionId,
  });

  bool get changedAnything {
    return damage > 0 ||
        healing > 0 ||
        mitigation > 0 ||
        effects.isNotEmpty;
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'passiveId': passiveId,
      'passiveName': passiveName,
      'triggerId': triggerId,

      'targetId': targetId,
      'targetLabel': targetLabel,

      'saved': saved,

      'damage': damage,
      'healing': healing,
      'mitigation': mitigation,
      'breakdown': breakdown,

      'effects': effects.map((effect) => effect.toMap()).toList(),
      'resolutionId': resolutionId,
    };
  }

  factory PassiveTriggerExternalResult.fromMap(Map<dynamic, dynamic> map) {
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

    return PassiveTriggerExternalResult(
      passiveId: map['passiveId']?.toString() ?? '',

      passiveName: map['passiveName']?.toString() ?? '',

      triggerId: map['triggerId']?.toString() ?? '',

      targetId: map['targetId']?.toString() ?? '',

      targetLabel: map['targetLabel']?.toString(),

      saved: map['saved'] as bool? ?? false,

      damage: (map['damage'] as num?)?.toInt() ?? 0,

      healing: (map['healing'] as num?)?.toInt() ?? 0,
      mitigation: (map['mitigation'] as num?)?.toInt() ?? 0,
      breakdown: (map['breakdown'] as List?)
              ?.map((value) => value.toString())
              .toList(growable: false) ??
          const [],

      effects: List<CharacterEffect>.unmodifiable(effects),

      resolutionId: map['resolutionId']?.toString() ?? '',
    );
  }
}
