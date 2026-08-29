import 'package:flutter/material.dart';

import '../../../models/action_target_result.dart';
import '../../../models/skill.dart';
import '../../../models/action_critical_profile.dart';

import 'action_saving_throw_breakdown.dart';
import 'action_value_breakdown.dart';

class ActionHealingBreakdown extends StatelessWidget {
  final ActionTargetResult targetResult;

  final AbilityType? ability;

  final ActionCriticalType criticalType;

  const ActionHealingBreakdown({
    super.key,
    required this.targetResult,
    this.ability,
    this.criticalType = ActionCriticalType.none,
  });

  @override
  Widget build(BuildContext context) {
    final relevantSaves = targetResult.savingThrows
        .where(
          (save) => targetResult.healingParts.any(
            (part) => part.request.effectId == save.request.effectId,
          ),
        )
        .toList(growable: false);

    return ActionValueBreakdown(
      title: 'Desglose de la curación',
      collapsedLabel: 'Curación total',
      totalLabel: 'CURACIÓN TOTAL',
      icon: Icons.favorite_rounded,
      parts: targetResult.healingParts,

      modificationDetails: relevantSaves.isEmpty
          ? null
          : ActionSavingThrowBreakdown(savingThrows: relevantSaves),

      finalTotal: targetResult.healing,
      ability: ability,
      criticalType: criticalType,
      fallbackColor: Theme.of(context).colorScheme.primary,
      initiallyExpanded: false,
    );
  }
}
