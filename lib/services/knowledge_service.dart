import 'dart:math';

import '../models/ability.dart';
import '../models/character.dart';
import '../models/character_knowledge.dart';
import '../models/knowledge_definition.dart';
import '../models/passive.dart';
import '../models/skill.dart';
import '../services/ability_library_service.dart';
import '../services/passive_library_service.dart';

enum RestStudyType { shortRest, longRest }

class StudyAttempt {
  final int naturalRoll;
  final int totalRoll;
  final bool success;
  final int dcUsed;
  final String checkLabel;
  final String? circleTitle;

  const StudyAttempt({
    required this.naturalRoll,
    required this.totalRoll,
    required this.success,
    required this.dcUsed,
    this.checkLabel = '',
    this.circleTitle,
  });
}

class StudyRollResult {
  final List<StudyAttempt> attempts;
  final int successesGained;
  final int currentProgress;
  final int requiredProgress;
  final bool completed;

  const StudyRollResult({
    required this.attempts,
    required this.successesGained,
    required this.currentProgress,
    required this.requiredProgress,
    required this.completed,
  });
}

class KnowledgeService {
  const KnowledgeService();

  int modifierForCheck(Character character, KnowledgeCheckOption option) {
    final skill = option.skill;
    if (skill != null) {
      return character.skillBonus(skill);
    }

    final ability = option.ability ?? AbilityType.intelligence;
    return character.abilityModifier(ability);
  }

  Future<StudyRollResult> performStudyRoll({
    required Character character,
    required KnowledgeDefinition definition,
    required RestStudyType restType,
    int? customDc,
    List<int>? physicalRolls,
    KnowledgeCheckOption? checkOption,
    bool applyIntelligenceModifier = true,
  }) async {
    final random = Random();
    final attemptsCount = restType == RestStudyType.shortRest ? 1 : 2;
    final selectedCheck = checkOption ?? definition.effectiveCheckOptions.first;
    final modifier = applyIntelligenceModifier
        ? modifierForCheck(character, selectedCheck)
        : 0;

    var entry = character.getKnowledge(definition.id);
    if (entry == null) {
      entry = CharacterKnowledge(
        knowledgeId: definition.id,
        status: KnowledgeStatus.studying,
        currentProgress: 0,
      );
      character.knowledges.add(entry);
    } else if (entry.status == KnowledgeStatus.discovered) {
      entry.status = KnowledgeStatus.studying;
    }

    final attempts = <StudyAttempt>[];
    var successesGained = 0;

    for (var i = 0; i < attemptsCount; i++) {
      if (entry.currentProgress >= definition.effectiveRequiredProgress) {
        break;
      }

      final progressBefore = entry.currentProgress;
      final circle = definition.circleAtProgress(progressBefore);
      final effectiveDc = customDc ?? definition.dcForProgress(progressBefore);

      final natural = (physicalRolls != null && i < physicalRolls.length)
          ? physicalRolls[i].clamp(1, 20)
          : random.nextInt(20) + 1;

      final total = natural + modifier;
      final success = total >= effectiveDc;

      attempts.add(
        StudyAttempt(
          naturalRoll: natural,
          totalRoll: total,
          success: success,
          dcUsed: effectiveDc,
          checkLabel: selectedCheck.label,
          circleTitle: circle?.title,
        ),
      );

      if (!success) continue;

      successesGained++;
      entry.currentProgress++;

      if (circle != null) {
        await _applyCircleRewards(
          character: character,
          entry: entry,
          circle: circle,
        );
      }
    }

    final completed =
        entry.currentProgress >= definition.effectiveRequiredProgress;

    if (completed) {
      entry.currentProgress = definition.effectiveRequiredProgress;
      entry.status = KnowledgeStatus.mastered;
      await _removeTemporaryStudyPassives(character, entry);
      await _applyPermanentRewards(
        character: character,
        abilityIds: definition.unlockedAbilityIds,
        passiveIds: definition.unlockedPassiveIds,
      );
    }

    return StudyRollResult(
      attempts: attempts,
      successesGained: successesGained,
      currentProgress: entry.currentProgress,
      requiredProgress: definition.effectiveRequiredProgress,
      completed: completed,
    );
  }

  Future<void> _applyCircleRewards({
    required Character character,
    required CharacterKnowledge entry,
    required KnowledgeCircle circle,
  }) async {
    await _applyPermanentRewards(
      character: character,
      abilityIds: circle.unlockedAbilityIds,
      passiveIds: circle.unlockedPassiveIds,
    );

    for (final passiveId in circle.temporaryPassiveIds) {
      final alreadyHas = character.passives.any((p) => p.id == passiveId);
      if (alreadyHas) continue;

      final passive = await PassiveLibraryService.getPassiveById(passiveId);
      if (passive == null) continue;

      character.addPassive(CharacterPassive.fromMap(passive.toMap()));
      if (!entry.temporaryPassiveIdsGranted.contains(passiveId)) {
        entry.temporaryPassiveIdsGranted.add(passiveId);
      }
    }
  }

  Future<void> _applyPermanentRewards({
    required Character character,
    required List<String> abilityIds,
    required List<String> passiveIds,
  }) async {
    for (final abilityId in abilityIds) {
      final alreadyHas = character.characterAbilities.any(
        (a) => a.id == abilityId,
      );
      if (alreadyHas) continue;
      final ability = await AbilityLibraryService.getAbilityById(abilityId);
      if (ability != null) {
        character.characterAbilities.add(
          CharacterAbility.fromMap(ability.toMap()),
        );
      }
    }

    for (final passiveId in passiveIds) {
      final alreadyHas = character.passives.any((p) => p.id == passiveId);
      if (alreadyHas) continue;
      final passive = await PassiveLibraryService.getPassiveById(passiveId);
      if (passive != null) {
        character.addPassive(CharacterPassive.fromMap(passive.toMap()));
      }
    }
  }

  Future<void> _removeTemporaryStudyPassives(
    Character character,
    CharacterKnowledge entry,
  ) async {
    for (final passiveId in List<String>.from(
      entry.temporaryPassiveIdsGranted,
    )) {
      character.removePassive(passiveId);
    }
    entry.temporaryPassiveIdsGranted.clear();
  }

  Future<void> syncKnowledgeRewards({
    required Character character,
    required KnowledgeDefinition definition,
    required CharacterKnowledge entry,
  }) async {
    final completedCircles = definition.circles
        .take(entry.currentProgress.clamp(0, definition.circles.length).toInt())
        .toList();

    for (final circle in completedCircles) {
      await _applyPermanentRewards(
        character: character,
        abilityIds: circle.unlockedAbilityIds,
        passiveIds: circle.unlockedPassiveIds,
      );
    }

    if (entry.status == KnowledgeStatus.mastered) {
      await _removeTemporaryStudyPassives(character, entry);
      await _applyPermanentRewards(
        character: character,
        abilityIds: definition.unlockedAbilityIds,
        passiveIds: definition.unlockedPassiveIds,
      );
      return;
    }

    for (final circle in completedCircles) {
      for (final passiveId in circle.temporaryPassiveIds) {
        final alreadyHas = character.passives.any((p) => p.id == passiveId);
        if (alreadyHas) continue;
        final passive = await PassiveLibraryService.getPassiveById(passiveId);
        if (passive != null) {
          character.addPassive(CharacterPassive.fromMap(passive.toMap()));
          if (!entry.temporaryPassiveIdsGranted.contains(passiveId)) {
            entry.temporaryPassiveIdsGranted.add(passiveId);
          }
        }
      }
    }
  }

  Future<void> checkAndUnlockRewardsForMasteredKnowledge({
    required Character character,
    required KnowledgeDefinition definition,
    required CharacterKnowledge entry,
  }) {
    return syncKnowledgeRewards(
      character: character,
      definition: definition,
      entry: entry,
    );
  }
}
