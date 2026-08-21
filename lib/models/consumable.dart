import 'ability.dart';

class Consumable {
  List<AbilityEffect> effects;

  String useText;

  Consumable({List<AbilityEffect>? effects, this.useText = 'Usar'})
    : effects = effects ?? [];

  bool get hasEffects {
    return effects.any((effect) => effect.hasEffect);
  }

  Map<String, dynamic> toMap() {
    return {
      'effects': effects.map((effect) => effect.toMap()).toList(),
      'useText': useText,
    };
  }

  factory Consumable.fromMap(Map<dynamic, dynamic> map) {
    final effects = <AbilityEffect>[];

    final rawEffects = map['effects'];

    if (rawEffects is List) {
      for (final rawEffect in rawEffects) {
        if (rawEffect is! Map) {
          continue;
        }

        try {
          effects.add(
            AbilityEffect.fromMap(Map<dynamic, dynamic>.from(rawEffect)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    return Consumable(
      effects: effects,
      useText: map['useText']?.toString() ?? 'Usar',
    );
  }
}
