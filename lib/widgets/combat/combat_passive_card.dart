import 'package:flutter/material.dart';

import '../../models/character.dart';
import '../../models/item.dart';
import '../../models/passive.dart';

import '../character_home/character_home_colors.dart';

class CombatPassiveCard extends StatelessWidget {
  final Character character;
  final CharacterPassive passive;
  final ItemDefinition? sourceItem;

  final VoidCallback? onRoll;
  final VoidCallback? onApplyLinkedEffects;

  const CombatPassiveCard({
    super.key,
    required this.character,
    required this.passive,
    this.sourceItem,
    this.onRoll,
    this.onApplyLinkedEffects,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final color = CharacterHomeColors.effects;

    final background = CharacterHomeColors.tintedSurface(
      context,
      color,
      lightStrength: 0.09,
      darkStrength: 0.16,
    );

    final iconBackground = CharacterHomeColors.tintedSurface(
      context,
      color,
      lightStrength: 0.20,
      darkStrength: 0.28,
    );

    final borderColor = CharacterHomeColors.tintedBorder(
      context,
      color,
      lightAlpha: 0.18,
      darkAlpha: 0.30,
    );

    final hasActions = onRoll != null || onApplyLinkedEffects != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===================================================================
          // CABECERA
          // ===================================================================
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.auto_awesome_rounded, size: 21, color: color),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passive.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _subtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.check_circle_rounded,
                size: 19,
                color: CharacterHomeColors.notes,
              ),
            ],
          ),

          // ===================================================================
          // DESCRIPCIÓN
          // ===================================================================
          if (passive.description.trim().isNotEmpty) ...[
            const SizedBox(height: 11),

            Text(
              passive.description.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],

          // ===================================================================
          // INFO
          // ===================================================================
          if (_hasInfo) ...[
            const SizedBox(height: 11),

            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                if (passive.hasRoll)
                  _PassiveInfoChip(
                    icon: Icons.casino_rounded,
                    text: _rollText(character, passive),
                  ),

                if (passive.usesCharges)
                  _PassiveInfoChip(
                    icon: Icons.battery_charging_full_rounded,
                    text: passive.hasUnlimitedCharges
                        ? 'Cargas ilimitadas'
                        : '${passive.currentCharges}/${passive.maxCharges} cargas',
                  ),

                if (passive.linkedEffects.isNotEmpty)
                  _PassiveInfoChip(
                    icon: Icons.auto_awesome_motion_rounded,
                    text:
                        '${passive.linkedEffects.length} '
                        '${passive.linkedEffects.length == 1 ? 'efecto' : 'efectos'}',
                  ),

                if (passive.triggers.isNotEmpty)
                  _PassiveInfoChip(
                    icon: Icons.bolt_rounded,
                    text:
                        '${passive.triggers.length} '
                        '${passive.triggers.length == 1 ? 'trigger' : 'triggers'}',
                  ),
              ],
            ),
          ],

          // ===================================================================
          // ACCIONES
          // ===================================================================
          if (hasActions) ...[
            const SizedBox(height: 12),

            if (onRoll != null && onApplyLinkedEffects != null)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onRoll,
                      icon: const Icon(Icons.casino_rounded),
                      label: const Text('Tirar'),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onApplyLinkedEffects,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Aplicar'),
                    ),
                  ),
                ],
              )
            else if (onRoll != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRoll,
                  icon: const Icon(Icons.casino_rounded),
                  label: const Text('Tirar'),
                ),
              )
            else if (onApplyLinkedEffects != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: onApplyLinkedEffects,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Aplicar efecto'),
                ),
              ),
          ],
        ],
      ),
    );
  }

  bool get _hasInfo {
    return passive.hasRoll ||
        passive.usesCharges ||
        passive.linkedEffects.isNotEmpty ||
        passive.triggers.isNotEmpty;
  }

  String _subtitle() {
    if (sourceItem != null) {
      return 'Objeto · ${sourceItem!.name}';
    }

    return passive.sourceType.label;
  }

  static String _rollText(Character character, CharacterPassive passive) {
    final parts = <String>[];

    final dice = passive.rollDiceNotation.trim();

    if (dice.isNotEmpty) {
      parts.add(dice);
    }

    final modifier = character.passiveRollModifier(passive);

    if (modifier != 0) {
      parts.add(modifier > 0 ? '+$modifier' : '$modifier');
    }

    if (parts.isEmpty) {
      return 'Tirada';
    }

    return parts.join(' ');
  }
}

// =============================================================================
// INFO CHIP
// =============================================================================

class _PassiveInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PassiveInfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.onSurfaceVariant),

          const SizedBox(width: 5),

          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
