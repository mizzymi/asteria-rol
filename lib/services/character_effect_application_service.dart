import '../models/character.dart';
import '../models/character_effect.dart';

class CharacterEffectApplicationService {
  final Character character;

  const CharacterEffectApplicationService({required this.character});

  CharacterEffect applyTemplate(
    CharacterEffect template, {
    String? instanceId,
  }) {
    final effect = CharacterEffect.fromMap(template.toMap());

    effect.id = instanceId ?? _buildInstanceId(template.id);

    effect.enabled = true;

    if (effect.hasDuration) {
      effect.resetDuration();
    }

    effect.normalizeDuration();

    character.addEffect(effect);

    return effect;
  }

  List<CharacterEffect> applyTemplates(Iterable<CharacterEffect> templates) {
    final result = <CharacterEffect>[];

    for (final template in templates) {
      result.add(applyTemplate(template));
    }

    return List<CharacterEffect>.unmodifiable(result);
  }

  String _buildInstanceId(String templateId) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    return '${templateId}_applied_$timestamp';
  }
}
