import 'package:flutter/material.dart';

import '../../../models/character_effect.dart';
import '../../../models/action_effect_result.dart';
import '../../../models/action_linked_effect.dart';
import '../../../models/action_target_result.dart';
import '../../../models/action_saving_throw.dart';

import '../common/action_section_card.dart';

import 'action_saving_throw_breakdown.dart';

class ActionEffectsBreakdown extends StatelessWidget {
  final ActionTargetResult targetResult;

  final String targetLabel;

  const ActionEffectsBreakdown({
    super.key,
    required this.targetResult,
    required this.targetLabel,
  });

  @override
  Widget build(BuildContext context) {
    final effects = targetResult.effects;

    if (effects.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                'Efectos aplicados',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            Text(
              '${effects.length}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        for (final effectResult in effects) ...[
          _EffectResultCard(
            effectResult: effectResult,
            targetLabel: targetLabel,
            targetResult: targetResult,
          ),

          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _EffectResultCard extends StatelessWidget {
  final ActionEffectResult effectResult;

  final String targetLabel;

  final ActionTargetResult targetResult;

  const _EffectResultCard({
    required this.effectResult,
    required this.targetLabel,
    required this.targetResult,
  });

  @override
  Widget build(BuildContext context) {
    final effect = effectResult.template;

    final sourceEffectId = effectResult.sourceEffectId;

    final List<ActionSavingThrowResult> relevantSaves = sourceEffectId == null
        ? const <ActionSavingThrowResult>[]
        : targetResult.savingThrows
              .where((save) => save.request.effectId == sourceEffectId)
              .toList(growable: false);

    return ActionSectionCard(
      title: effect.name.trim().isNotEmpty ? effect.name.trim() : 'Efecto',

      subtitle: _effectSubtitle(effect),

      icon: _iconForEffectType(effect.type),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.arrow_forward_rounded, size: 18),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  'Se aplica a $targetLabel.',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          // ===============================================================
          // METADATA DEL VÍNCULO
          //
          // Solo informativa.
          // El resolver ya decidió si el efecto sobrevivía o no.
          // ===============================================================
          if (effectResult.sourceEffectId != null) ...[
            const SizedBox(height: 10),

            _InfoLine(
              icon: Icons.account_tree_rounded,
              text: 'Vinculado a un efecto de la habilidad.',
            ),
          ],

          if (effectResult.saveBehavior !=
              ActionLinkedEffectSaveBehavior.ignore) ...[
            const SizedBox(height: 6),

            _InfoLine(
              icon: Icons.shield_outlined,
              text: effectResult.saveBehavior.label,
            ),
          ],
          if (relevantSaves.isNotEmpty) ...[
            const SizedBox(height: 10),

            const Divider(height: 1),

            const SizedBox(height: 10),

            ActionSavingThrowBreakdown(savingThrows: relevantSaves),
          ],
        ],
      ),
    );
  }

  String _effectSubtitle(CharacterEffect effect) {
    final description = effect.description.trim();

    if (description.isEmpty) {
      return effect.durationText;
    }

    return '$description · ${effect.durationText}';
  }

  IconData _iconForEffectType(CharacterEffectType type) {
    switch (type) {
      case CharacterEffectType.buff:
        return Icons.trending_up_rounded;

      case CharacterEffectType.debuff:
        return Icons.trending_down_rounded;

      case CharacterEffectType.condition:
        return Icons.warning_amber_rounded;

      case CharacterEffectType.neutral:
        return Icons.auto_awesome_rounded;
    }
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;

  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),

        const SizedBox(width: 7),

        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
