import 'dart:math';

import '../models/ability.dart';
import '../models/passive.dart';
import '../models/skill.dart';
import '../models/character.dart';
import '../models/character_knowledge.dart';
import '../models/knowledge_definition.dart';
import '../services/ability_library_service.dart';
import '../services/passive_library_service.dart';

enum RestStudyType { shortRest, longRest }

class StudyAttempt {
  final int naturalRoll;
  final int totalRoll;
  final bool success;
  final int dcUsed;

  const StudyAttempt({
    required this.naturalRoll,
    required this.totalRoll,
    required this.success,
    required this.dcUsed,
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

  Future<StudyRollResult> performStudyRoll({
    required Character character,
    required KnowledgeDefinition definition,
    required RestStudyType restType,
    int? customDc,
    List<int>? physicalRolls,
    bool applyIntelligenceModifier = true,
  }) async {
    final random = Random();
    final effectiveDc = customDc ?? definition.studyDc;
    final attemptsCount = restType == RestStudyType.shortRest ? 1 : 2;
    final int intModifier = applyIntelligenceModifier
        ? character.abilityModifier(AbilityType.intelligence)
        : 0;

    final attempts = <StudyAttempt>[];
    int successesGained = 0;

    for (var i = 0; i < attemptsCount; i++) {
      final int natural = (physicalRolls != null && i < physicalRolls.length)
          ? physicalRolls[i].clamp(1, 20)
          : random.nextInt(20) + 1;

      final total = natural + intModifier;
      final isSuccess = total >= effectiveDc;

      if (isSuccess) {
        successesGained++;
      }

      attempts.add(
        StudyAttempt(
          naturalRoll: natural,
          totalRoll: total,
          success: isSuccess,
          dcUsed: effectiveDc,
        ),
      );
    }

    var entry = character.getKnowledge(definition.id);
    if (entry == null) {
      entry = CharacterKnowledge(
        knowledgeId: definition.id,
        status: KnowledgeStatus.studying,
        currentProgress: 0,
      );
      character.knowledges.add(entry);
    }

    entry.currentProgress += successesGained;
    final bool completed = entry.currentProgress >= definition.requiredProgress;

    if (completed) {
      entry.status = KnowledgeStatus.mastered;

      // 1. Inyectar Habilidades solo si se ha completado el saber
      for (final abilityId in definition.unlockedAbilityIds) {
        final alreadyHas = character.characterAbilities.any(
          (a) => a.id == abilityId,
        );
        if (!alreadyHas) {
          final ability = await AbilityLibraryService.getAbilityById(abilityId);
          if (ability != null) {
            character.characterAbilities.add(
              CharacterAbility.fromMap(ability.toMap()),
            );
          }
        }
      }

      // 2. Inyectar Pasivas solo si se ha completado el saber
      for (final passiveId in definition.unlockedPassiveIds) {
        final alreadyHas = character.passives.any((p) => p.id == passiveId);
        if (!alreadyHas) {
          final passive = await PassiveLibraryService.getPassiveById(passiveId);
          if (passive != null) {
            character.addPassive(CharacterPassive.fromMap(passive.toMap()));
          }
        }
      }
    }

    return StudyRollResult(
      attempts: attempts,
      successesGained: successesGained,
      currentProgress: entry.currentProgress,
      requiredProgress: definition.requiredProgress,
      completed: completed,
    );
  }

  Future<void> checkAndUnlockRewardsForMasteredKnowledge({
    required Character character,
    required KnowledgeDefinition definition,
    required CharacterKnowledge entry,
  }) async {
    if (entry.status != KnowledgeStatus.mastered) {
      return;
    }

    for (final abilityId in definition.unlockedAbilityIds) {
      final alreadyHas = character.characterAbilities.any(
        (a) => a.id == abilityId,
      );
      if (!alreadyHas) {
        final ability = await AbilityLibraryService.getAbilityById(abilityId);
        if (ability != null) {
          character.characterAbilities.add(
            CharacterAbility.fromMap(ability.toMap()),
          );
        }
      }
    }

    for (final passiveId in definition.unlockedPassiveIds) {
      final alreadyHas = character.passives.any((p) => p.id == passiveId);
      if (!alreadyHas) {
        final passive = await PassiveLibraryService.getPassiveById(passiveId);
        if (passive != null) {
          character.addPassive(CharacterPassive.fromMap(passive.toMap()));
        }
      }
    }
  }
}
