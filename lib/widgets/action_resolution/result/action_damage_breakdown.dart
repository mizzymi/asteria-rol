import 'package:flutter/material.dart';

import '../../../models/action_critical_profile.dart';
import '../../../models/action_target_result.dart';
import '../../../models/skill.dart';

import 'action_saving_throw_breakdown.dart';
import 'action_value_breakdown.dart';

class ActionDamageBreakdown extends StatelessWidget {
  final ActionTargetResult targetResult;

  final AbilityType? ability;

  final ActionCriticalType criticalType;

  const ActionDamageBreakdown({
    super.key,
    required this.targetResult,
    this.ability,
    this.criticalType = ActionCriticalType.none,
  });

  @override
  Widget build(BuildContext context) {
    final relevantSaves = targetResult.savingThrows
        .where(
          (save) => targetResult.damageParts.any(
            (part) => part.request.effectId == save.request.effectId,
          ),
        )
        .toList(growable: false);

    return ActionValueBreakdown(
      title: 'Desglose del daño',
      collapsedLabel: 'Daño total',
      totalLabel: 'DAÑO TOTAL',
      icon: Icons.flash_on_rounded,
      parts: targetResult.damageParts,
      finalTotal: targetResult.damage,
      ability: ability,
      criticalType: criticalType,
      fallbackColor: Theme.of(context).colorScheme.error,

      modificationDetails: relevantSaves.isEmpty
          ? null
          : ActionSavingThrowBreakdown(savingThrows: relevantSaves),

      initiallyExpanded: false,
    );
  }
}
