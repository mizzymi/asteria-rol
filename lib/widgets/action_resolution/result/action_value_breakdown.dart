import 'package:flutter/material.dart';

import '../../../models/action_dice_request.dart';
import '../../../models/action_critical_profile.dart';
import '../../../models/action_dice_result.dart';
import '../../../models/skill.dart';

import '../../../theme/ability_colors.dart';

import '../common/action_section_card.dart';

class ActionValueBreakdown extends StatefulWidget {
  final String title;
  final String collapsedLabel;
  final String totalLabel;

  final IconData icon;

  final List<ActionDicePartResult> parts;

  final int finalTotal;

  final AbilityType? ability;

  final Color? fallbackColor;

  final Widget? modificationDetails;

  final ActionCriticalType criticalType;

  /// Si quieres que abra inicialmente.
  final bool initiallyExpanded;

  const ActionValueBreakdown({
    super.key,
    required this.title,
    required this.collapsedLabel,
    required this.totalLabel,
    required this.icon,
    required this.parts,
    required this.finalTotal,
    this.ability,
    this.fallbackColor,
    this.modificationDetails,
    this.criticalType = ActionCriticalType.none,
    this.initiallyExpanded = false,
  });

  @override
  State<ActionValueBreakdown> createState() => _ActionValueBreakdownState();
}

class _ActionValueBreakdownState extends State<ActionValueBreakdown> {
  late bool expanded;

  @override
  void initState() {
    super.initState();

    expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.parts.isEmpty && widget.finalTotal <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    final accentColor = widget.ability == null
        ? widget.fallbackColor ?? theme.colorScheme.primary
        : AbilityColors.of(widget.ability!);

    final rawTotal = widget.parts.fold<int>(0, (sum, part) => sum + part.total);

    final modified = rawTotal != widget.finalTotal;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: accentColor.withValues(alpha: 0.22)),

        color: accentColor.withValues(alpha: 0.045),
      ),
      child: Column(
        children: [
          // ===============================================================
          // CABECERA CERRABLE
          // ===============================================================
          InkWell(
            borderRadius: BorderRadius.circular(18),

            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },

            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(widget.icon, size: 20, color: accentColor),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expanded ? widget.title : widget.collapsedLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        if (!expanded)
                          Text(
                            'Pulsa para ver el desglose',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // -------------------------------------------------------
                  // TOTAL SI ESTÁ CERRADO
                  // -------------------------------------------------------
                  if (!expanded) ...[
                    Text(
                      '${widget.finalTotal}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(width: 8),
                  ],

                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,

                    duration: const Duration(milliseconds: 180),

                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===============================================================
          // CONTENIDO
          // ===============================================================
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),

            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1),

                  const SizedBox(height: 14),

                  for (final part in widget.parts) ...[
                    _ValuePartCard(
                      part: part,
                      ability: widget.ability,
                      accentColor: accentColor,
                      criticalType: widget.criticalType,
                    ),

                    const SizedBox(height: 10),
                  ],

                  if (modified) ...[
                    _SummaryRow(
                      label: 'Total antes de ajustes',
                      value: '$rawTotal',
                    ),

                    if (widget.modificationDetails != null) ...[
                      const SizedBox(height: 8),

                      widget.modificationDetails!,
                    ],

                    const SizedBox(height: 10),
                  ],

                  _TotalCard(
                    label: widget.totalLabel,
                    total: widget.finalTotal,
                    accentColor: accentColor,
                    ability: widget.ability,
                  ),
                ],
              ),
            ),

            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,

            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

class _ValuePartCard extends StatelessWidget {
  final ActionDicePartResult part;
  final AbilityType? ability;
  final Color accentColor;
  final ActionCriticalType criticalType;

  const _ValuePartCard({
    required this.part,
    required this.ability,
    required this.accentColor,
    required this.criticalType,
  });

  @override
  Widget build(BuildContext context) {
    final request = part.request;

    final baseTitle = request.effectName.trim().isEmpty
        ? 'Resultado'
        : request.effectName.trim();

    final title = part.isCriticalExtra
        ? 'Dados críticos adicionales · $baseTitle'
        : baseTitle;

    final typeName = request.damageType.trim();

    final automaticValueLabel = _automaticValueLabel(
      part: part,
      criticalType: criticalType,
    );

    final sourceLabel = _sourceLabel(part);

    return ActionSectionCard(
      title: title,
      subtitle: typeName.isEmpty ? null : typeName,
      icon: Icons.casino_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FormulaHeader(part: part),

          const SizedBox(height: 8),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _InfoChip(icon: _sourceIcon(part), label: sourceLabel),

              if (part.isCriticalExtra)
                const _InfoChip(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Crítico adicional',
                ),
            ],
          ),

          if (part.result.groups.isNotEmpty) ...[
            const SizedBox(height: 14),

            for (
              var groupIndex = 0;
              groupIndex < part.result.groups.length;
              groupIndex++
            ) ...[
              _DiceGroup(
                part: part,
                groupIndex: groupIndex,
                accentColor: accentColor,
              ),

              if (groupIndex < part.result.groups.length - 1)
                const SizedBox(height: 10),
            ],
          ],

          if (request.modifier != 0 || request.automaticValue != 0) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            if (request.modifier != 0)
              _SummaryRow(
                label:
                    criticalType == ActionCriticalType.normal &&
                        !part.isCriticalExtra
                    ? 'Modificador crítico'
                    : ability == null
                    ? 'Modificador'
                    : 'Mod. ${ability!.shortLabel}',
                value: _signed(request.modifier),
              ),

            if (request.modifier != 0 && request.automaticValue != 0)
              const SizedBox(height: 6),

            if (request.automaticValue != 0)
              _SummaryRow(
                label: automaticValueLabel,
                value: _signed(request.automaticValue),
              ),
          ],

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),

                Text(
                  '${part.total}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaHeader extends StatelessWidget {
  final ActionDicePartResult part;

  const _FormulaHeader({required this.part});

  @override
  Widget build(BuildContext context) {
    final text = part.request.calculationText;

    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _DiceGroup extends StatelessWidget {
  final ActionDicePartResult part;
  final int groupIndex;
  final Color accentColor;

  const _DiceGroup({
    required this.part,
    required this.groupIndex,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final group = part.result.groups[groupIndex];

    final request = part.request;

    final label = groupIndex < request.dicePools.length
        ? request.dicePools[groupIndex].notation
        : 'Dados';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 7),

        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final roll in group.rolls)
              _RollChip(value: roll, color: accentColor),
          ],
        ),
      ],
    );
  }
}

class _RollChip extends StatelessWidget {
  final int value;
  final Color color;

  const _RollChip({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 42, minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        '$value',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final String label;
  final int total;
  final Color accentColor;
  final AbilityType? ability;

  const _TotalCard({
    required this.label,
    required this.total,
    required this.accentColor,
    required this.ability,
  });

  @override
  Widget build(BuildContext context) {
    final background = ability == null
        ? accentColor.withValues(alpha: 0.10)
        : AbilityColors.soft(ability!, alpha: 0.10);

    final border = ability == null
        ? accentColor.withValues(alpha: 0.30)
        : AbilityColors.border(ability!, alpha: 0.32);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '$total',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),

        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),

          const SizedBox(width: 5),

          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String _sourceLabel(ActionDicePartResult part) {
  switch (part.request.sourceType) {
    case ActionDiceSourceType.ability:
      return 'Habilidad';

    case ActionDiceSourceType.passive:
      return 'Pasiva';

    case ActionDiceSourceType.effect:
      return 'Efecto activo';

    case ActionDiceSourceType.criticalBonus:
      return 'Crítico';
  }
}

IconData _sourceIcon(ActionDicePartResult part) {
  switch (part.request.sourceType) {
    case ActionDiceSourceType.ability:
      return Icons.auto_awesome_rounded;

    case ActionDiceSourceType.passive:
      return Icons.bolt_rounded;

    case ActionDiceSourceType.effect:
      return Icons.flare_rounded;

    case ActionDiceSourceType.criticalBonus:
      return Icons.local_fire_department_rounded;
  }
}

String _signed(int value) {
  return value > 0 ? '+$value' : '$value';
}

String _automaticValueLabel({
  required ActionDicePartResult part,
  required ActionCriticalType criticalType,
}) {
  if (part.isCriticalExtra) {
    return 'Valor automático';
  }

  switch (criticalType) {
    case ActionCriticalType.none:
      return 'Valor automático';

    case ActionCriticalType.normal:
      return 'Máximo crítico';

    case ActionCriticalType.empowered:
      return 'Valor crítico automático';
  }
}
