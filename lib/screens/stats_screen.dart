import 'package:flutter/material.dart';

import '../widgets/common/section_header.dart';
import '../widgets/stats/attributes_grid.dart';
import '../widgets/stats/roll_result_dialog.dart';
import '../widgets/stats/saving_throw_tile.dart';
import '../widgets/stats/skill_tile.dart';

import '../models/action_critical_profile.dart';
import '../models/character.dart';
import '../models/proficiency.dart';
import '../models/skill.dart';

import '../services/character_storage_service.dart';
import '../services/action_dice_resolver.dart';

class StatsScreen extends StatefulWidget {
  final Character character;

  const StatsScreen({super.key, required this.character});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Character get character => widget.character;

  String bonusText(int value) {
    return value >= 0 ? '+$value' : '$value';
  }

  void rollD20({
    required String label,
    required AbilityType ability,
    required int bonus,
  }) {
    const diceResolver = ActionDiceResolver();

    final naturalRoll = diceResolver.rollDigitalD20();

    final total = naturalRoll + bonus;

    final criticalProfile = ActionCriticalProfile(
      minimumNaturalRoll: ActionCriticalProfile.effectiveMinimumRoll(
        character.criticalMinimumRollSources,
      ),
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return RollResultDialog(
          label: label,
          ability: ability,
          naturalRoll: naturalRoll,
          total: total,
          bonus: bonus,
          criticalProfile: criticalProfile,
          onRepeat: () {
            Navigator.pop(dialogContext);

            rollD20(label: label, ability: ability, bonus: bonus);
          },
        );
      },
    );
  }

  Future<void> save() async {
    await CharacterStorageService.saveCharacter(character);
  }

  Future<void> editAbility(AbilityType ability) async {
    final currentValue = character.abilities.valueByType(ability);

    var newValue = currentValue;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(ability.label),
          content: TextFormField(
            initialValue: currentValue.toString(),
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: 'Valor del atributo',
              helperText: 'Introduce un valor entre 1 y 30',
            ),
            onChanged: (value) {
              newValue = int.tryParse(value) ?? currentValue;
            },
            onFieldSubmitted: (_) {
              if (newValue >= 1 && newValue <= 30) {
                Navigator.of(dialogContext).pop(newValue);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (newValue < 1 || newValue > 30) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('El atributo debe estar entre 1 y 30'),
                    ),
                  );

                  return;
                }

                Navigator.of(dialogContext).pop(newValue);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      character.setAbilityScore(ability, result);
    });

    await save();
  }

  Future<void> changeSkillProficiency(DndSkill skill) async {
    final current = character.skillProficiency(skill);

    final selected = await showModalBottomSheet<ProficiencyLevel>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.label,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...ProficiencyLevel.values.map((level) {
                  final isSelected = level == current;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected
                          ? Theme.of(sheetContext).colorScheme.primary
                          : Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                    ),
                    title: Text(level.label),
                    onTap: () {
                      Navigator.pop(sheetContext, level);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      character.setSkillProficiency(skill, selected);
    });

    await save();
  }

  Future<void> toggleSavingThrow(AbilityType ability) async {
    final current = character.isSavingThrowProficient(ability);

    setState(() {
      character.setSavingThrowProficiency(ability, !current);
    });

    await save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const SectionHeader(
              icon: Icons.analytics_rounded,
              title: 'Atributos',
              subtitle: 'Toca un atributo para modificar su valor',
            ),

            const SizedBox(height: 14),

            AttributesGrid(character: character, onEdit: editAbility),

            const SizedBox(height: 28),

            const SectionHeader(
              icon: Icons.shield_rounded,
              title: 'Tiradas de salvación',
              subtitle: 'Toca el círculo para cambiar la competencia',
            ),

            const SizedBox(height: 14),

            ...AbilityType.values.map(
              (ability) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SavingThrowTile(
                  ability: ability,
                  character: character,
                  onToggle: () {
                    toggleSavingThrow(ability);
                  },
                  onRoll: () {
                    rollD20(
                      label: 'Salvación de ${ability.label}',
                      ability: ability,
                      bonus: character.savingThrowBonus(ability),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 28),

            const SectionHeader(
              icon: Icons.list_alt_rounded,
              title: 'Habilidades',
              subtitle: 'El color indica el atributo asociado',
            ),

            const SizedBox(height: 14),

            ...DndSkill.values.map(
              (skill) => SkillTile(
                skill: skill,
                character: character,
                onChangeProficiency: () {
                  changeSkillProficiency(skill);
                },
                onRoll: () {
                  rollD20(
                    label: skill.label,
                    ability: skill.ability,
                    bonus: character.skillBonus(skill),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
