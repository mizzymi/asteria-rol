import 'package:flutter/material.dart';

import '../models/passive.dart';
import '../models/skill.dart';

class PassiveFormScreen extends StatefulWidget {
  final CharacterPassive? passive;

  const PassiveFormScreen({super.key, this.passive});

  @override
  State<PassiveFormScreen> createState() => _PassiveFormScreenState();
}

class _PassiveFormScreenState extends State<PassiveFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;

  late final TextEditingController descriptionController;

  late final TextEditingController armorClassController;

  late final TextEditingController initiativeController;

  late final TextEditingController speedController;

  late final TextEditingController maxHealthController;

  late final TextEditingController attackController;

  late final TextEditingController notesController;

  late final TextEditingController maxChargesController;
  late final TextEditingController rechargeController;

  bool hasCharges = false;

  late PassiveSourceType sourceType;

  bool enabled = true;

  late Map<DndSkill, int> skillBonuses;

  late Map<AbilityType, int> savingThrowBonuses;
  late Map<AbilityType, int> abilityModifierBonuses;
  bool get editing => widget.passive != null;

  @override
  void initState() {
    super.initState();

    final passive = widget.passive;

    nameController = TextEditingController(text: passive?.name ?? '');

    descriptionController = TextEditingController(
      text: passive?.description ?? '',
    );

    armorClassController = TextEditingController(
      text: '${passive?.armorClassBonus ?? 0}',
    );

    initiativeController = TextEditingController(
      text: '${passive?.initiativeBonus ?? 0}',
    );

    speedController = TextEditingController(
      text: '${passive?.speedBonus ?? 0}',
    );

    maxHealthController = TextEditingController(
      text: '${passive?.maxHealthBonus ?? 0}',
    );

    attackController = TextEditingController(
      text: '${passive?.attackBonus ?? 0}',
    );

    notesController = TextEditingController(text: passive?.notes ?? '');

    sourceType = passive?.sourceType ?? PassiveSourceType.custom;

    enabled = passive?.enabled ?? true;

    hasCharges = passive?.hasCharges ?? false;

    maxChargesController = TextEditingController(
      text: '${passive?.maxCharges ?? 1}',
    );

    rechargeController = TextEditingController(
      text: passive?.rechargeDescription ?? '',
    );

    abilityModifierBonuses = {
      for (final ability in AbilityType.values)
        ability: passive?.abilityModifierBonuses[ability] ?? 0,
    };
    skillBonuses = {
      for (final skill in DndSkill.values)
        skill: passive?.skillBonuses[skill] ?? 0,
    };

    savingThrowBonuses = {
      for (final ability in AbilityType.values)
        ability: passive?.savingThrowBonuses[ability] ?? 0,
    };
  }

  String bonusText(int value) {
    return value >= 0 ? '+$value' : '$value';
  }

  String abilityLabel(AbilityType ability) {
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

  Future<int?> editBonus({
    required String title,
    required int currentValue,
  }) async {
    int value = currentValue;

    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextFormField(
            initialValue: '$currentValue',
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: 'Bonificación',
              helperText: 'Puede ser positiva o negativa',
            ),
            onChanged: (text) {
              value = int.tryParse(text) ?? currentValue;
            },
            onFieldSubmitted: (_) {
              Navigator.of(dialogContext).pop(value);
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
                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> editAbilityModifierBonus(AbilityType ability) async {
    final value = await editBonus(
      title: 'Modificador · ${abilityLabel(ability)}',
      currentValue: abilityModifierBonuses[ability] ?? 0,
    );

    if (value == null || !mounted) {
      return;
    }

    setState(() {
      abilityModifierBonuses[ability] = value;
    });
  }

  Future<void> editSkillBonus(DndSkill skill) async {
    final value = await editBonus(
      title: 'Bonus · ${skill.label}',
      currentValue: skillBonuses[skill] ?? 0,
    );

    if (value == null || !mounted) {
      return;
    }

    setState(() {
      skillBonuses[skill] = value;
    });
  }

  Future<void> editSavingThrowBonus(AbilityType ability) async {
    final value = await editBonus(
      title: 'Salvación · ${abilityLabel(ability)}',
      currentValue: savingThrowBonuses[ability] ?? 0,
    );

    if (value == null || !mounted) {
      return;
    }

    setState(() {
      savingThrowBonuses[ability] = value;
    });
  }

  void savePassive() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cleanedAbilityModifiers = <AbilityType, int>{};

    for (final entry in abilityModifierBonuses.entries) {
      if (entry.value != 0) {
        cleanedAbilityModifiers[entry.key] = entry.value;
      }
    }

    final cleanedSkills = <DndSkill, int>{};

    for (final entry in skillBonuses.entries) {
      if (entry.value != 0) {
        cleanedSkills[entry.key] = entry.value;
      }
    }

    final cleanedSaves = <AbilityType, int>{};

    for (final entry in savingThrowBonuses.entries) {
      if (entry.value != 0) {
        cleanedSaves[entry.key] = entry.value;
      }
    }

    // =========================================================================
    // CARGAS
    // =========================================================================

    final parsedMaxCharges = hasCharges
        ? (int.tryParse(maxChargesController.text) ?? 1)
        : 0;

    int currentCharges = 0;

    if (hasCharges) {
      if (widget.passive?.usesCharges == true) {
        /*
     * Si estamos editando una pasiva existente,
     * conservamos sus cargas actuales.
     */
        currentCharges = widget.passive!.currentCharges;

        /*
     * Pero nunca puede superar el nuevo máximo.
     */
        if (currentCharges > parsedMaxCharges) {
          currentCharges = parsedMaxCharges;
        }
      } else {
        /*
     * Una pasiva nueva empieza llena.
     */
        currentCharges = parsedMaxCharges;
      }
    }

    // =========================================================================
    // CREAR PASIVA
    // =========================================================================

    final passive = CharacterPassive(
      id:
          widget.passive?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),

      name: nameController.text.trim(),

      description: descriptionController.text.trim(),

      sourceType: sourceType,

      enabled: enabled,

      armorClassBonus: int.tryParse(armorClassController.text) ?? 0,

      initiativeBonus: int.tryParse(initiativeController.text) ?? 0,

      speedBonus: int.tryParse(speedController.text) ?? 0,

      maxHealthBonus: int.tryParse(maxHealthController.text) ?? 0,

      attackBonus: int.tryParse(attackController.text) ?? 0,

      abilityModifierBonuses: cleanedAbilityModifiers,

      skillBonuses: cleanedSkills,

      savingThrowBonuses: cleanedSaves,

      // =======================================================================
      // CARGAS
      // =======================================================================
      hasCharges: hasCharges,

      maxCharges: parsedMaxCharges,

      rechargeDescription: hasCharges ? rechargeController.text.trim() : '',

      notes: notesController.text.trim(),
    );

    /*
   * Evita cosas como:
   *
   * 5/3 cargas
   * -1/3 cargas
   * 0 cargas máximas si hasCharges = true
   */
    passive.normalizeCharges();

    Navigator.pop(context, passive);
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();

    armorClassController.dispose();
    initiativeController.dispose();
    speedController.dispose();
    maxHealthController.dispose();
    attackController.dispose();
    maxChargesController.dispose();
    rechargeController.dispose();
    notesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar pasiva' : 'Nueva pasiva'),
        actions: [
          IconButton(
            onPressed: savePassive,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.auto_awesome_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduce un nombre';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: descriptionController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<PassiveSourceType>(
                initialValue: sourceType,
                decoration: const InputDecoration(
                  labelText: 'Origen',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: PassiveSourceType.values.map((source) {
                  return DropdownMenuItem(
                    value: source,
                    child: Text(source.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    sourceType = value;
                  });
                },
              ),

              const SizedBox(height: 10),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: enabled,
                title: const Text('Pasiva activa'),
                subtitle: const Text(
                  'Sus bonificaciones se aplicarán automáticamente',
                ),
                onChanged: (value) {
                  setState(() {
                    enabled = value;
                  });
                },
              ),

              const SizedBox(height: 26),

              Text(
                'Bonificaciones generales',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              Text(
                'Cargas',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: hasCharges,
                title: const Text('Usa cargas'),
                subtitle: const Text('Permite gastar y recuperar cargas'),
                onChanged: (value) {
                  setState(() {
                    hasCharges = value;
                  });
                },
              ),

              if (hasCharges) ...[
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: maxChargesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cargas máximas',
                          prefixIcon: Icon(Icons.battery_full_rounded),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: rechargeController,
                  decoration: const InputDecoration(
                    labelText: 'Recuperación',
                    hintText: 'Descanso largo, amanecer...',
                    prefixIcon: Icon(Icons.refresh_rounded),
                  ),
                ),
              ],
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: armorClassController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'CA',
                        prefixIcon: Icon(Icons.shield_rounded),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: TextFormField(
                      controller: initiativeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Iniciativa',
                        prefixIcon: Icon(Icons.bolt_rounded),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: maxHealthController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'PG máximos',
                        prefixIcon: Icon(Icons.favorite_rounded),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: TextFormField(
                      controller: attackController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Al golpe',
                        prefixIcon: Icon(Icons.gps_fixed_rounded),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: speedController,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Bonus de velocidad',
                  suffixText: 'pies',
                  prefixIcon: Icon(Icons.directions_run_rounded),
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'Modificadores de atributo',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              const Text(
                'Estos bonus se suman al modificador del atributo y afectan automáticamente a todo lo que dependa de él.',
              ),

              const SizedBox(height: 12),

              Card(
                child: Column(
                  children: AbilityType.values.map((ability) {
                    final bonus = abilityModifierBonuses[ability] ?? 0;

                    return ListTile(
                      onTap: () {
                        editAbilityModifierBonus(ability);
                      },
                      leading: CircleAvatar(
                        child: Text(
                          _abilityShortName(ability),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(abilityLabel(ability)),
                      subtitle: const Text('Modificador base'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            bonusText(bonus),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_rounded, size: 17),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'Habilidades',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              const Text(
                'Añade bonificaciones específicas a las habilidades que afecte esta pasiva.',
              ),

              const SizedBox(height: 12),

              Card(
                child: Column(
                  children: DndSkill.values.map((skill) {
                    final bonus = skillBonuses[skill] ?? 0;

                    return ListTile(
                      onTap: () {
                        editSkillBonus(skill);
                      },
                      title: Text(skill.label),
                      subtitle: Text(_abilityShortName(skill.ability)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            bonusText(bonus),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_rounded, size: 17),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Salvaciones',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              const Text(
                'Bonus adicionales que se sumarán a las tiradas de salvación.',
              ),

              const SizedBox(height: 12),

              Card(
                child: Column(
                  children: AbilityType.values.map((ability) {
                    final bonus = savingThrowBonuses[ability] ?? 0;

                    return ListTile(
                      onTap: () {
                        editSavingThrowBonus(ability);
                      },
                      title: Text(abilityLabel(ability)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            bonusText(bonus),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_rounded, size: 17),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Notas',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: notesController,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Notas adicionales',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 30),

              FilledButton.icon(
                onPressed: savePassive,
                icon: const Icon(Icons.save_rounded),
                label: Text(editing ? 'Guardar cambios' : 'Crear pasiva'),
              ),

              const SizedBox(height: 30),
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
