import '../models/character.dart';
import '../models/ability.dart';
import '../models/passive.dart';
import '../models/custom_class_definition.dart';

class PendingClassProgressionChoice {
  final CustomClassDefinition definition;
  final ClassProgressionReward reward;
  final int slot;

  const PendingClassProgressionChoice({
    required this.definition,
    required this.reward,
    required this.slot,
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
      if (character.campaignId == null ||
          definition.campaignId != character.campaignId) {
        continue;
      }
      for (final classEntry in character.classes) {
        if (classEntry.classId != definition.classId) continue;
        classEntry.customName = definition.name;
        classEntry.customHitDie = definition.hitDie;
        classEntry.customSavingThrowProficiencies = Set.of(
          definition.savingThrowProficiencies,
        );
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
          for (var slot = 0; slot < reward.choiceCount; slot++) {
            final slotKey = slot == 0 ? key : '$key::$slot';
            if (character.classProgressionChoices.containsKey(slotKey)) continue;
            pending.add(PendingClassProgressionChoice(
              definition: definition,
              reward: reward,
              slot: slot,
            ));
          }
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
    int slot = 0,
  }) {
    final key = rewardKey(definition.classId, reward.rewardId);
    final slotKey = slot == 0 ? key : '$key::$slot';
    if (slot < 0 || slot >= reward.choiceCount || character.classProgressionChoices.containsKey(slotKey)) return false;
    if (character.appliedClassRewardIds.contains(key)) return false;

    ClassProgressionContent? selected;
    for (final content in reward.contents) {
      if (content.contentId == contentId) {
        selected = content;
        break;
      }
    }
    if (selected == null) return false;
    if (!reward.stackable && character.classProgressionChoices.entries.any((entry) =>
      entry.key.startsWith('${definition.classId}::') && entry.value == contentId)) return false;

    _grantContent(character, definition, reward, selected, slot: slot);
    character.classProgressionChoices[slotKey] = contentId;
    if (List.generate(reward.choiceCount, (index) => index == 0 ? key : '$key::$index')
        .every(character.classProgressionChoices.containsKey)) {
      character.appliedClassRewardIds.add(key);
    }
    return true;
  }

  static void _grantContent(
    Character character,
    CustomClassDefinition definition,
    ClassProgressionReward reward,
    ClassProgressionContent content, {
    int slot = 0,
  }) {
    final ability = content.instantiateAbility(
      classId: definition.classId,
      rewardId: reward.rewardId,
    );
    if (ability != null) {
      if (reward.stackable) {
        final copy = ability.toMap();
        copy['id'] = '${ability.id}::${reward.rewardId}::$slot';
        character.characterAbilities.add(CharacterAbility.fromMap(copy));
        return;
      }
      if (!character.characterAbilities.any((item) => item.id == ability.id)) {
        character.characterAbilities.add(ability);
      }
      return;
    }

    final passive = content.instantiatePassive(
      classId: definition.classId,
      rewardId: reward.rewardId,
    );
    if (passive != null) {
      if (reward.stackable) {
        final copy = passive.toMap();
        copy['id'] = '${passive.id}::${reward.rewardId}::$slot';
        character.passives.add(CharacterPassive.fromMap(copy));
      } else if (!character.passives.any((item) => item.id == passive.id)) {
        character.passives.add(passive);
      }
    }
  }
}
