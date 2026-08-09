import 'package:flutter/material.dart';

import '../models/dice_roll.dart';
import '../models/character.dart';
import '../models/proficiency.dart';
import '../models/skill.dart';
import '../services/character_storage_service.dart';

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

  void rollD20({required String label, required int bonus}) {
    final roll = DiceRoller.d20(modifier: bonus);

    showDialog(
      context: context,
      builder: (context) {
        final isCritical = roll.die == 20;
        final isFail = roll.die == 1;

        return AlertDialog(
          title: Text(label),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.casino_rounded,
                size: 52,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '${roll.die}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('d20', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Text(
                bonus >= 0
                    ? '${roll.die} + $bonus'
                    : '${roll.die} - ${bonus.abs()}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'TOTAL ${roll.total}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isCritical) ...[
                const SizedBox(height: 10),
                const Text(
                  '✨ 20 natural',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
              if (isFail) ...[
                const SizedBox(height: 10),
                const Text(
                  '💀 1 natural',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cerrar'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);

                rollD20(label: label, bonus: bonus);
              },
              icon: const Icon(Icons.casino_rounded),
              label: const Text('Repetir'),
            ),
          ],
        );
      },
    );
  }

  Future<void> save() async {
    await CharacterStorageService.saveCharacter(character);
  }

  Future<void> editAbility(AbilityType ability) async {
    int currentValue;

    switch (ability) {
      case AbilityType.strength:
        currentValue = character.abilities.strength;
        break;

      case AbilityType.dexterity:
        currentValue = character.abilities.dexterity;
        break;

      case AbilityType.constitution:
        currentValue = character.abilities.constitution;
        break;

      case AbilityType.intelligence:
        currentValue = character.abilities.intelligence;
        break;

      case AbilityType.wisdom:
        currentValue = character.abilities.wisdom;
        break;

      case AbilityType.charisma:
        currentValue = character.abilities.charisma;
        break;
    }

    int newValue = currentValue;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_abilityName(ability)),
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
                  ScaffoldMessenger.of(context).showSnackBar(
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
      switch (ability) {
        case AbilityType.strength:
          character.abilities.strength = result;
          break;

        case AbilityType.dexterity:
          character.abilities.dexterity = result;
          break;

        case AbilityType.constitution:
          character.abilities.constitution = result;
          break;

        case AbilityType.intelligence:
          character.abilities.intelligence = result;
          break;

        case AbilityType.wisdom:
          character.abilities.wisdom = result;
          break;

        case AbilityType.charisma:
          character.abilities.charisma = result;
          break;
      }

      character.normalizeHealth();
    });

    await save();
  }

  String _abilityName(AbilityType ability) {
    switch (ability) {
      case AbilityType.strength:
        return 'Fuerza';

      case AbilityType.dexterity:
        return 'Destreza';

      case AbilityType.constitution:
        return 'Constitución';

      case AbilityType.intelligence:
        return 'Inteligencia';

      case AbilityType.wisdom:
        return 'Sabiduría';

      case AbilityType.charisma:
        return 'Carisma';
    }
  }

  Future<void> changeSkillProficiency(DndSkill skill) async {
    final current = character.skillProficiency(skill);

    final selected = await showModalBottomSheet<ProficiencyLevel>(
      context: context,
      showDragHandle: true,
      builder: (context) {
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
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...ProficiencyLevel.values.map((level) {
                  return RadioListTile<ProficiencyLevel>(
                    value: level,
                    groupValue: current,
                    title: Text(level.label),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      Navigator.pop(context, value);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) {
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
            _SectionTitle(title: 'Atributos'),

            const SizedBox(height: 12),

            _AttributesGrid(
              character: character,
              bonusText: bonusText,
              onEdit: editAbility,
            ),

            const SizedBox(height: 28),

            _SectionTitle(title: 'Tiradas de salvación'),

            const SizedBox(height: 12),

            Card(
              child: Column(
                children: AbilityType.values.map((ability) {
                  return _SavingThrowTile(
                    ability: ability,
                    character: character,
                    bonusText: bonusText,
                    onTap: () {
                      toggleSavingThrow(ability);
                    },
                    onRoll: () {
                      rollD20(
                        label: 'Salvación de ${_abilityName(ability)}',
                        bonus: character.savingThrowBonus(ability),
                      );
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 28),

            Row(
              children: [
                const Expanded(child: _SectionTitle(title: 'Habilidades')),
                _LegendItem(icon: Icons.circle_outlined, text: 'Normal'),
                const SizedBox(width: 8),
                _LegendItem(
                  icon: Icons.check_circle_outline,
                  text: 'Competencia',
                ),
                const SizedBox(width: 8),
                _LegendItem(icon: Icons.star_outline, text: 'Pericia'),
              ],
            ),

            const SizedBox(height: 12),

            Card(
              child: Column(
                children: DndSkill.values.map((skill) {
                  return _SkillTile(
                    skill: skill,
                    character: character,
                    bonusText: bonusText,
                    onTap: () {
                      changeSkillProficiency(
                        skill,
                      );
                    },
                    onRoll: () {
                      rollD20(
                        label: skill.label,
                        bonus:
                        character.skillBonus(
                          skill,
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _AttributesGrid extends StatelessWidget {
  final Character character;
  final String Function(int) bonusText;
  final void Function(AbilityType ability) onEdit;

  const _AttributesGrid({
    required this.character,
    required this.bonusText,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final attributes = [
      (
        type: AbilityType.strength,
        label: 'FUE',
        score: character.abilities.strength,
        modifier: character.strengthModifier,
        icon: Icons.fitness_center_rounded,
      ),
      (
        type: AbilityType.dexterity,
        label: 'DES',
        score: character.abilities.dexterity,
        modifier: character.dexterityModifier,
        icon: Icons.directions_run_rounded,
      ),
      (
        type: AbilityType.constitution,
        label: 'CON',
        score: character.abilities.constitution,
        modifier: character.constitutionModifier,
        icon: Icons.favorite_rounded,
      ),
      (
        type: AbilityType.intelligence,
        label: 'INT',
        score: character.abilities.intelligence,
        modifier: character.intelligenceModifier,
        icon: Icons.psychology_rounded,
      ),
      (
        type: AbilityType.wisdom,
        label: 'SAB',
        score: character.abilities.wisdom,
        modifier: character.wisdomModifier,
        icon: Icons.visibility_rounded,
      ),
      (
        type: AbilityType.charisma,
        label: 'CAR',
        score: character.abilities.charisma,
        modifier: character.charismaModifier,
        icon: Icons.auto_awesome_rounded,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: attributes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final attribute = attributes[index];

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              onEdit(attribute.type);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    attribute.icon,
                    size: 22,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    attribute.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${attribute.score}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    bonusText(attribute.modifier),
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SavingThrowTile extends StatelessWidget {
  final AbilityType ability;
  final Character character;
  final String Function(int) bonusText;
  final VoidCallback onTap;
  final VoidCallback onRoll;

  const _SavingThrowTile({
    required this.ability,
    required this.character,
    required this.bonusText,
    required this.onTap,
    required this.onRoll,
  });

  String get abilityName {
    switch (ability) {
      case AbilityType.strength:
        return 'Fuerza';
      case AbilityType.dexterity:
        return 'Destreza';
      case AbilityType.constitution:
        return 'Constitución';
      case AbilityType.intelligence:
        return 'Inteligencia';
      case AbilityType.wisdom:
        return 'Sabiduría';
      case AbilityType.charisma:
        return 'Carisma';
    }
  }

  @override
  Widget build(BuildContext context) {
    final proficient = character.isSavingThrowProficient(ability);

    final bonus = character.savingThrowBonus(ability);

    return ListTile(
      onTap: onTap,
      leading: Icon(
        proficient ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: proficient ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        abilityName,
        style: TextStyle(
          fontWeight: proficient ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: proficient
          ? Text('Competente · +${character.proficiencyBonus}')
          : const Text('Sin competencia'),
      trailing: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onRoll,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.casino_rounded, size: 18),
              const SizedBox(width: 5),
              Text(
                bonusText(bonus),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillTile extends StatelessWidget {
  final DndSkill skill;
  final Character character;
  final String Function(int) bonusText;
  final VoidCallback onTap;
  final VoidCallback onRoll;

  const _SkillTile({
    required this.skill,
    required this.character,
    required this.bonusText,
    required this.onTap,
    required this.onRoll,
  });

  @override
  Widget build(BuildContext context) {
    final proficiency = character.skillProficiency(skill);

    final bonus = character.skillBonus(skill);

    IconData icon;

    switch (proficiency) {
      case ProficiencyLevel.none:
        icon = Icons.circle_outlined;
        break;
      case ProficiencyLevel.proficient:
        icon = Icons.check_circle_rounded;
        break;
      case ProficiencyLevel.expertise:
        icon = Icons.star_rounded;
        break;
    }

    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: proficiency == ProficiencyLevel.none
            ? null
            : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        skill.label,
        style: TextStyle(
          fontWeight: proficiency == ProficiencyLevel.none
              ? FontWeight.normal
              : FontWeight.bold,
        ),
      ),
      subtitle: Text(
        '${_abilityShortName(skill.ability)} · ${proficiency.label}',
      ),
      trailing: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onRoll,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.casino_rounded, size: 18),
              const SizedBox(width: 5),
              Text(
                bonusText(bonus),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _abilityShortName(AbilityType ability) {
    switch (ability) {
      case AbilityType.strength:
        return 'FUE';
      case AbilityType.dexterity:
        return 'DES';
      case AbilityType.constitution:
        return 'CON';
      case AbilityType.intelligence:
        return 'INT';
      case AbilityType.wisdom:
        return 'SAB';
      case AbilityType.charisma:
        return 'CAR';
    }
  }
}

class _LegendItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _LegendItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Tooltip(message: text, child: Icon(icon, size: 20));
  }
}
