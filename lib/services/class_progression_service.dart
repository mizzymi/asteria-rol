import '../models/character.dart';
import '../models/custom_class_definition.dart';

class PendingClassProgressionChoice {
  final CustomClassDefinition definition;
  final ClassProgressionReward reward;

  const PendingClassProgressionChoice({
    required this.definition,
    required this.reward,
  });
}

class ClassProgressionResult {
  final int appliedRewards;
  final List<PendingClassProgressionChoice> pendingChoices;

  const ClassProgressionResult({
    required this.appliedRewards,
    required this.pendingChoices,
  });
}

class ClassProgressionService {
  const ClassProgressionService._();

  static String rewardKey(String classId, String rewardId) =>
      '$classId::$rewardId';

  static int _levelForClass(Character character, String classId) {
    var level = 0;
    for (final classLevel in character.classes) {
      if (classLevel.classId == classId) {
        level += classLevel.level;
      }
    }
    return level;
  }

  static ClassProgressionResult reconcile(
    Character character,
    Iterable<CustomClassDefinition> definitions,
  ) {
    var applied = 0;
    final pending = <PendingClassProgressionChoice>[];

    for (final definition in definitions) {
      if (character.campaignId == null || definition.campaignId != character.campaignId) {
        continue;
      }
      for (final classEntry in character.classes) {
        if (classEntry.classId != definition.classId) continue;
        classEntry.customName = definition.name;
        classEntry.customHitDie = definition.hitDie;
        classEntry.customSavingThrowProficiencies =
            Set.of(definition.savingThrowProficiencies);
      }

      final classLevel = _levelForClass(character, definition.classId);
      if (classLevel <= 0) continue;

      final rewards = [...definition.rewards]
        ..sort((a, b) => a.level.compareTo(b.level));

      for (final reward in rewards) {
        if (!reward.isValid || reward.level > classLevel) continue;

        final key = rewardKey(definition.classId, reward.rewardId);
        if (character.appliedClassRewardIds.contains(key)) continue;

        if (reward.mode == ClassProgressionRewardMode.choice) {
          pending.add(
            PendingClassProgressionChoice(
              definition: definition,
              reward: reward,
            ),
          );
          continue;
        }

        for (final content in reward.contents) {
          _grantContent(character, definition, reward, content);
        }
        character.appliedClassRewardIds.add(key);
        applied++;
      }
    }

    return ClassProgressionResult(
      appliedRewards: applied,
      pendingChoices: pending,
    );
  }

  static bool applyChoice(
    Character character, {
    required CustomClassDefinition definition,
    required ClassProgressionReward reward,
    required String contentId,
  }) {
    final key = rewardKey(definition.classId, reward.rewardId);
    if (character.appliedClassRewardIds.contains(key)) return false;

    ClassProgressionContent? selected;
    for (final content in reward.contents) {
      if (content.contentId == contentId) {
        selected = content;
        break;
      }
    }
    if (selected == null) return false;

    _grantContent(character, definition, reward, selected);
    character.classProgressionChoices[key] = contentId;
    character.appliedClassRewardIds.add(key);
    return true;
  }

  static void _grantContent(
    Character character,
    CustomClassDefinition definition,
    ClassProgressionReward reward,
    ClassProgressionContent content,
  ) {
    final ability = content.instantiateAbility(
      classId: definition.classId,
      rewardId: reward.rewardId,
    );
    if (ability != null) {
      if (!character.characterAbilities.any((item) => item.id == ability.id)) {
        character.characterAbilities.add(ability);
      }
      return;
    }

    final passive = content.instantiatePassive(
      classId: definition.classId,
      rewardId: reward.rewardId,
    );
    if (passive != null &&
        !character.passives.any((item) => item.id == passive.id)) {
      character.passives.add(passive);
    }
  }
}
