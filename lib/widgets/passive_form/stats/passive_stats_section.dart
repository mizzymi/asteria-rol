import 'package:flutter/material.dart';

import '../../../models/character.dart';
import '../../../models/damage_resistance.dart';
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
  final List<DamageResistance> damageResistances;
  final Map<DndSkill, FormulaBonus> skillBonuses;

  final void Function(AbilityType ability, FormulaBonus bonus)
  onAbilityScoreChanged;
  final void Function(AbilityType ability, FormulaBonus bonus)
  onAbilityModifierChanged;
  final void Function(AbilityType ability, FormulaBonus bonus)
  onSavingThrowChanged;
  final void Function(AbilityType ability, SavingThrowRollMode mode)
  onSavingThrowRollModeChanged;
  final ValueChanged<List<DamageResistance>> onDamageResistancesChanged;
  final void Function(DndSkill skill, FormulaBonus bonus) onSkillChanged;

  const PassiveStatsSection({
    super.key,
    required this.character,
    required this.abilityScoreBonuses,
    required this.abilityModifierBonuses,
    required this.savingThrowBonuses,
    required this.savingThrowRollModes,
    required this.damageResistances,
    required this.skillBonuses,
    required this.onAbilityScoreChanged,
    required this.onAbilityModifierChanged,
    required this.onSavingThrowChanged,
    required this.onSavingThrowRollModeChanged,
    required this.onDamageResistancesChanged,
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
        _DamageResistancesCard(
          values: damageResistances,
          onChanged: onDamageResistancesChanged,
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

class _DamageResistancesCard extends StatelessWidget {
  final List<DamageResistance> values;
  final ValueChanged<List<DamageResistance>> onChanged;

  const _DamageResistancesCard({
    required this.values,
    required this.onChanged,
  });

  Future<DamageResistance?> _edit(
    BuildContext context, {
    DamageResistance? initial,
  }) async {
    final controller = TextEditingController(
      text: initial?.damageType ?? '',
    );
    var tier = initial?.tier ?? DamageResistanceTier.minor;

    final result = await showDialog<DamageResistance>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                initial == null ? 'Añadir resistencia' : 'Editar resistencia',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de daño',
                      hintText: 'Fuego, frío, radiante, cortante...',
                      prefixIcon: Icon(Icons.local_fire_department_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<DamageResistanceTier>(
                    initialValue: tier,
                    decoration: const InputDecoration(
                      labelText: 'Nivel',
                      prefixIcon: Icon(Icons.shield_rounded),
                    ),
                    items: DamageResistanceTier.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => tier = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '2 menores = normal · 2 normales = mayor · '
                    '2 mayores = inmunidad',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final damageType = controller.text.trim();
                    if (damageType.isEmpty) {
                      return;
                    }
                    Navigator.pop(
                      dialogContext,
                      DamageResistance(
                        damageType: damageType,
                        tier: tier,
                      ),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  child: Icon(Icons.shield_rounded, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resistencias al daño',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Menor reduce 25 %, normal 50 %, mayor 75 % e '
                        'inmunidad 100 %. Se apilan por tipo.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Añadir resistencia',
                  onPressed: () async {
                    final result = await _edit(context);
                    if (result == null) {
                      return;
                    }
                    onChanged([...values, result]);
                  },
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ),
          if (values.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Sin resistencias.'),
              ),
            )
          else ...[
            const Divider(height: 1),
            for (var index = 0; index < values.length; index++)
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: Text(
                  values[index].damageType,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(values[index].tier.label),
                onTap: () async {
                  final result = await _edit(
                    context,
                    initial: values[index],
                  );
                  if (result == null) {
                    return;
                  }
                  final updated = List<DamageResistance>.from(values);
                  updated[index] = result;
                  onChanged(updated);
                },
                trailing: IconButton(
                  tooltip: 'Eliminar',
                  onPressed: () {
                    final updated = List<DamageResistance>.from(values)
                      ..removeAt(index);
                    onChanged(updated);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ),
          ],
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
