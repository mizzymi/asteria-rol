import 'package:flutter/material.dart';

import '../../../models/character.dart';
import '../../../models/saving_throw_roll_mode.dart';
import '../../../models/skill.dart';
import '../../../models/formulas/formula_bonus.dart';

import '../../forms/common/formula_bonus_editor_dialog.dart';

class PassiveStatsSection extends StatelessWidget {
  final Character? character;

  final Map<AbilityType, FormulaBonus> abilityScoreBonuses;
  final Map<AbilityType, FormulaBonus> abilityModifierBonuses;
  final Map<AbilityType, FormulaBonus> savingThrowBonuses;
  final Map<AbilityType, SavingThrowRollMode> savingThrowRollModes;
  final Map<DndSkill, FormulaBonus> skillBonuses;

  final void Function(AbilityType ability, FormulaBonus bonus)
  onAbilityScoreChanged;
  final void Function(AbilityType ability, FormulaBonus bonus)
  onAbilityModifierChanged;
  final void Function(AbilityType ability, FormulaBonus bonus)
  onSavingThrowChanged;
  final void Function(AbilityType ability, SavingThrowRollMode mode)
  onSavingThrowRollModeChanged;
  final void Function(DndSkill skill, FormulaBonus bonus) onSkillChanged;

  const PassiveStatsSection({
    super.key,
    required this.character,
    required this.abilityScoreBonuses,
    required this.abilityModifierBonuses,
    required this.savingThrowBonuses,
    required this.savingThrowRollModes,
    required this.skillBonuses,
    required this.onAbilityScoreChanged,
    required this.onAbilityModifierChanged,
    required this.onSavingThrowChanged,
    required this.onSavingThrowRollModeChanged,
    required this.onSkillChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FormulaBonusGroup<AbilityType>(
          title: 'Stats base',
          subtitle: 'Modifica directamente FUE, DES, CON, INT, SAB y CAR.',
          icon: Icons.straighten_rounded,
          values: abilityScoreBonuses,
          labelBuilder: (ability) => ability.label,
          subtitleBuilder: (_) => 'Puntuación de atributo',
          editorTitleBuilder: (ability) => 'Stat base · ${ability.label}',
          character: character,
          onChanged: onAbilityScoreChanged,
        ),
        const SizedBox(height: 12),
        _FormulaBonusGroup<AbilityType>(
          title: 'Modificadores',
          subtitle: 'Bonificaciones directas al modificador de atributo.',
          icon: Icons.tune_rounded,
          values: abilityModifierBonuses,
          labelBuilder: (ability) => ability.label,
          subtitleBuilder: (_) => 'Bonus al modificador',
          editorTitleBuilder: (ability) => 'Modificador · ${ability.label}',
          character: character,
          onChanged: onAbilityModifierChanged,
        ),
        const SizedBox(height: 12),
        _FormulaBonusGroup<AbilityType>(
          title: 'Salvaciones',
          subtitle: 'Bonificaciones adicionales a las tiradas de salvación.',
          icon: Icons.security_rounded,
          values: savingThrowBonuses,
          labelBuilder: (ability) => ability.label,
          subtitleBuilder: (_) => 'Salvación',
          editorTitleBuilder: (ability) => 'Salvación · ${ability.label}',
          character: character,
          onChanged: onSavingThrowChanged,
        ),
        const SizedBox(height: 12),
        _SavingThrowModesCard(
          values: savingThrowRollModes,
          onChanged: onSavingThrowRollModeChanged,
        ),
        const SizedBox(height: 12),
        _FormulaBonusGroup<DndSkill>(
          title: 'Habilidades',
          subtitle: 'Bonificaciones específicas a las habilidades.',
          icon: Icons.psychology_alt_rounded,
          values: skillBonuses,
          labelBuilder: (skill) => skill.label,
          subtitleBuilder: (skill) => skill.ability.label,
          editorTitleBuilder: (skill) => 'Bonus · ${skill.label}',
          character: character,
          onChanged: onSkillChanged,
        ),
      ],
    );
  }
}

class _SavingThrowModesCard extends StatelessWidget {
  final Map<AbilityType, SavingThrowRollMode> values;
  final void Function(AbilityType ability, SavingThrowRollMode mode) onChanged;

  const _SavingThrowModesCard({
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  child: Icon(Icons.casino_rounded, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ventaja en salvaciones',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'La pasiva puede dar ventaja o desventaja por atributo. '
                        'Si coinciden ambas, se cancelan.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final ability in AbilityType.values)
            ListTile(
              title: Text(
                ability.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Tirada de salvación'),
              trailing: DropdownButton<SavingThrowRollMode>(
                value: values[ability] ?? SavingThrowRollMode.normal,
                onChanged: (value) {
                  if (value != null) {
                    onChanged(ability, value);
                  }
                },
                items: SavingThrowRollMode.values
                    .map(
                      (mode) => DropdownMenuItem(
                        value: mode,
                        child: Text(mode.label),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
        ],
      ),
    );
  }
}

class _FormulaBonusGroup<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Map<T, FormulaBonus> values;
  final String Function(T value) labelBuilder;
  final String Function(T value) subtitleBuilder;
  final String Function(T value) editorTitleBuilder;
  final Character? character;
  final void Function(T key, FormulaBonus bonus) onChanged;

  const _FormulaBonusGroup({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.values,
    required this.labelBuilder,
    required this.subtitleBuilder,
    required this.editorTitleBuilder,
    required this.character,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(child: Icon(icon, size: 19)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final entry in values.entries)
            ListTile(
              title: Text(
                labelBuilder(entry.key),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(subtitleBuilder(entry.key)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _bonusText(entry.value),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_rounded, size: 17),
                ],
              ),
              onTap: () async {
                final result = await showFormulaBonusEditorDialog(
                  context,
                  title: editorTitleBuilder(entry.key),
                  bonus: FormulaBonus.fromMap(entry.value.toMap()),
                  character: character,
                );

                if (result == null) {
                  return;
                }

                onChanged(entry.key, result);
              },
            ),
        ],
      ),
    );
  }

  String _bonusText(FormulaBonus bonus) {
    final parts = <String>[];

    if (bonus.flatValue != 0) {
      parts.add(
        bonus.flatValue > 0 ? '+${bonus.flatValue}' : '${bonus.flatValue}',
      );
    }

    if (bonus.hasFormula) {
      parts.add('ƒ');
    }

    if (parts.isEmpty) {
      return '+0';
    }

    return parts.join(' ');
  }
}
