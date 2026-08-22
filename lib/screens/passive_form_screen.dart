import 'package:flutter/material.dart';

import '../models/passive.dart';
import '../models/skill.dart';
import '../models/damage_bonus.dart';
import '../models/critical_damage_bonus.dart';
import '../models/healing_bonus.dart';
import '../models/dice_pool.dart';

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
  late List<DamageBonus> damageBonuses;
  late List<CriticalDamageBonus> criticalDamageBonuses;
  late List<HealingBonus> healingBonuses;
  late List<DicePool> rollDicePools;

  late Map<AbilityType, int> rollAbilityModifierMultipliers;

  late final TextEditingController rollFlatBonusController;
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

    damageBonuses =
        passive?.damageBonuses
            .map((bonus) => DamageBonus.fromMap(bonus.toMap()))
            .toList() ??
        [];

    criticalDamageBonuses =
        passive?.criticalDamageBonuses
            .map((bonus) => CriticalDamageBonus.fromMap(bonus.toMap()))
            .toList() ??
        [];

    healingBonuses =
        passive?.healingBonuses
            .map((bonus) => HealingBonus.fromMap(bonus.toMap()))
            .toList() ??
        [];

    rollDicePools =
        passive?.rollDicePools
            .map((pool) => DicePool(count: pool.count, sides: pool.sides))
            .toList() ??
        [];

    rollAbilityModifierMultipliers = Map<AbilityType, int>.from(
      passive?.rollAbilityModifierMultipliers ?? {},
    );

    rollFlatBonusController = TextEditingController(
      text: '${passive?.rollFlatBonus ?? 0}',
    );
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

  void addPassiveRollDice() {
    setState(() {
      rollDicePools.add(DicePool(count: 1, sides: 6));
    });
  }

  void removePassiveRollDice(int index) {
    if (index < 0 || index >= rollDicePools.length) {
      return;
    }

    setState(() {
      rollDicePools.removeAt(index);
    });
  }

  String get passiveRollPreview {
    final pieces = <String>[];

    if (rollDicePools.isNotEmpty) {
      pieces.add(rollDicePools.map((pool) => pool.notation).join(' + '));
    }

    for (final entry in rollAbilityModifierMultipliers.entries) {
      if (entry.value == 0) {
        continue;
      }

      if (entry.value == 1) {
        pieces.add(_abilityShortName(entry.key));
      } else {
        pieces.add('${entry.value}×${_abilityShortName(entry.key)}');
      }
    }

    final flatBonus = int.tryParse(rollFlatBonusController.text.trim()) ?? 0;

    if (flatBonus != 0) {
      pieces.add(flatBonus > 0 ? '+$flatBonus' : '$flatBonus');
    }

    if (pieces.isEmpty) {
      return 'Sin tirada';
    }

    return pieces.join(' + ').replaceAll('+ -', '- ');
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

  // =============================================================================
  // DAMAGE BONUS
  // =============================================================================

  Future<void> addDamageBonus() async {
    final bonus = DamageBonus(
      id: '${DateTime.now().microsecondsSinceEpoch}_damage_bonus',
      name: 'Daño adicional',
      dicePools: [DicePool(count: 1, sides: 6)],
    );

    final result = await _editDamageBonusDialog(bonus);

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      damageBonuses.add(result);
    });
  }

  Future<void> editDamageBonus(int index) async {
    if (index < 0 || index >= damageBonuses.length) {
      return;
    }

    final result = await _editDamageBonusDialog(
      DamageBonus.fromMap(damageBonuses[index].toMap()),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      damageBonuses[index] = result;
    });
  }

  Future<DamageBonus?> _editDamageBonusDialog(DamageBonus bonus) async {
    return showDialog<DamageBonus>(
      context: context,
      builder: (_) {
        return _DamageBonusEditorDialog(bonus: bonus);
      },
    );
  }

  // =============================================================================
  // CRITICAL DAMAGE BONUS
  // =============================================================================

  Future<void> addCriticalDamageBonus() async {
    final bonus = CriticalDamageBonus(
      id: '${DateTime.now().microsecondsSinceEpoch}_critical_bonus',
      name: 'Daño crítico adicional',
      dicePools: [DicePool(count: 1, sides: 6)],
      chancePercent: 100,
    );

    final result = await _editCriticalDamageBonusDialog(bonus);

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      criticalDamageBonuses.add(result);
    });
  }

  Future<void> editCriticalDamageBonus(int index) async {
    if (index < 0 || index >= criticalDamageBonuses.length) {
      return;
    }

    final result = await _editCriticalDamageBonusDialog(
      CriticalDamageBonus.fromMap(criticalDamageBonuses[index].toMap()),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      criticalDamageBonuses[index] = result;
    });
  }

  Future<CriticalDamageBonus?> _editCriticalDamageBonusDialog(
    CriticalDamageBonus bonus,
  ) async {
    return showDialog<CriticalDamageBonus>(
      context: context,
      builder: (_) {
        return _CriticalDamageBonusEditorDialog(bonus: bonus);
      },
    );
  }

  // =============================================================================
  // HEALING BONUS
  // =============================================================================

  Future<void> addHealingBonus() async {
    final bonus = HealingBonus(
      id: '${DateTime.now().microsecondsSinceEpoch}_healing_bonus',
      name: 'Curación adicional',
      dicePools: [DicePool(count: 1, sides: 6)],
    );

    final result = await _editHealingBonusDialog(bonus);

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      healingBonuses.add(result);
    });
  }

  Future<void> editHealingBonus(int index) async {
    if (index < 0 || index >= healingBonuses.length) {
      return;
    }

    final result = await _editHealingBonusDialog(
      HealingBonus.fromMap(healingBonuses[index].toMap()),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      healingBonuses[index] = result;
    });
  }

  Future<HealingBonus?> _editHealingBonusDialog(HealingBonus bonus) async {
    return showDialog<HealingBonus>(
      context: context,
      builder: (_) {
        return _HealingBonusEditorDialog(bonus: bonus);
      },
    );
  }

  String _damageBonusText(DamageBonus bonus) {
    final pieces = <String>[];

    if (bonus.diceNotation.isNotEmpty) {
      pieces.add(bonus.diceNotation);
    }

    for (final entry in bonus.abilityModifierMultipliers.entries) {
      if (entry.value == 1) {
        pieces.add(_abilityShortName(entry.key));
      } else {
        pieces.add('${entry.value}×${_abilityShortName(entry.key)}');
      }
    }

    if (bonus.flatBonus != 0) {
      pieces.add(
        bonus.flatBonus > 0 ? '+${bonus.flatBonus}' : '${bonus.flatBonus}',
      );
    }

    var result = pieces.isEmpty ? 'Sin daño' : pieces.join(' + ');

    if (bonus.damageType.trim().isNotEmpty) {
      result += ' · ${bonus.damageType.trim()}';
    }

    if (bonus.name.trim().isNotEmpty) {
      return '${bonus.name} · $result';
    }

    return result;
  }

  String _criticalBonusText(CriticalDamageBonus bonus) {
    final pieces = <String>[];

    if (bonus.diceNotation.isNotEmpty) {
      pieces.add(bonus.diceNotation);
    }

    for (final entry in bonus.abilityModifierMultipliers.entries) {
      if (entry.value == 1) {
        pieces.add(_abilityShortName(entry.key));
      } else {
        pieces.add('${entry.value}×${_abilityShortName(entry.key)}');
      }
    }

    if (bonus.flatBonus != 0) {
      pieces.add(
        bonus.flatBonus > 0 ? '+${bonus.flatBonus}' : '${bonus.flatBonus}',
      );
    }

    var result = pieces.isEmpty
        ? 'Sin daño'
        : pieces.join(' + ').replaceAll('+ -', '- ');

    if (bonus.damageType.trim().isNotEmpty) {
      result += ' · ${bonus.damageType.trim()}';
    }

    if (!bonus.alwaysTriggers) {
      result += ' · ${bonus.chancePercent}%';
    }

    if (bonus.name.trim().isNotEmpty) {
      return '${bonus.name} · $result';
    }

    return result;
  }

  String _healingBonusText(HealingBonus bonus) {
    final pieces = <String>[];

    if (bonus.diceNotation.isNotEmpty) {
      pieces.add(bonus.diceNotation);
    }

    for (final entry in bonus.abilityModifierMultipliers.entries) {
      if (entry.value == 1) {
        pieces.add(_abilityShortName(entry.key));
      } else {
        pieces.add('${entry.value}×${_abilityShortName(entry.key)}');
      }
    }

    if (bonus.flatBonus != 0) {
      pieces.add(
        bonus.flatBonus > 0 ? '+${bonus.flatBonus}' : '${bonus.flatBonus}',
      );
    }

    final result = pieces.isEmpty
        ? 'Sin curación'
        : pieces.join(' + ').replaceAll('+ -', '- ');

    if (bonus.name.trim().isNotEmpty) {
      return '${bonus.name} · $result';
    }

    return result;
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
      damageBonuses: damageBonuses
          .map((bonus) => DamageBonus.fromMap(bonus.toMap()))
          .toList(),

      criticalDamageBonuses: criticalDamageBonuses
          .map((bonus) => CriticalDamageBonus.fromMap(bonus.toMap()))
          .toList(),

      healingBonuses: healingBonuses
          .map((bonus) => HealingBonus.fromMap(bonus.toMap()))
          .toList(),

      rollDicePools: rollDicePools
          .map((pool) => DicePool(count: pool.count, sides: pool.sides))
          .toList(),

      rollAbilityModifierMultipliers: Map<AbilityType, int>.from(
        rollAbilityModifierMultipliers,
      ),

      rollFlatBonus: int.tryParse(rollFlatBonusController.text.trim()) ?? 0,
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
    rollFlatBonusController.dispose();

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
              const SizedBox(height: 28),

              Text(
                'Efectos extra',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              Text(
                'Bonificaciones que se aplican automáticamente al daño, críticos y curaciones.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 14),

              _EffectBonusSection(
                icon: Icons.local_fire_department_rounded,
                title: 'Daño',
                subtitle: 'Daño adicional al causar daño',
                count: damageBonuses.length,
                onAdd: addDamageBonus,
                children: [
                  for (var i = 0; i < damageBonuses.length; i++)
                    _PassiveEffectTile(
                      title: _damageBonusText(damageBonuses[i]),
                      icon: Icons.local_fire_department_rounded,
                      onTap: () {
                        editDamageBonus(i);
                      },
                      onDelete: () {
                        setState(() {
                          damageBonuses.removeAt(i);
                        });
                      },
                    ),
                ],
              ),

              const SizedBox(height: 12),

              _EffectBonusSection(
                icon: Icons.bolt_rounded,
                title: 'Daño crítico',
                subtitle: 'Dados o daño adicional al realizar un crítico',
                count: criticalDamageBonuses.length,
                onAdd: addCriticalDamageBonus,
                children: [
                  for (var i = 0; i < criticalDamageBonuses.length; i++)
                    _PassiveEffectTile(
                      title: _criticalBonusText(criticalDamageBonuses[i]),
                      icon: Icons.bolt_rounded,
                      onTap: () {
                        editCriticalDamageBonus(i);
                      },
                      onDelete: () {
                        setState(() {
                          criticalDamageBonuses.removeAt(i);
                        });
                      },
                    ),
                ],
              ),

              const SizedBox(height: 12),

              _EffectBonusSection(
                icon: Icons.favorite_rounded,
                title: 'Curación',
                subtitle: 'Bonificación adicional al realizar curaciones',
                count: healingBonuses.length,
                onAdd: addHealingBonus,
                children: [
                  for (var i = 0; i < healingBonuses.length; i++)
                    _PassiveEffectTile(
                      title: _healingBonusText(healingBonuses[i]),
                      icon: Icons.favorite_rounded,
                      onTap: () {
                        editHealingBonus(i);
                      },
                      onDelete: () {
                        setState(() {
                          healingBonuses.removeAt(i);
                        });
                      },
                    ),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                'Tirada propia',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              Text(
                'Permite tirar dados directamente desde esta pasiva.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 14),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            child: Icon(Icons.casino_rounded, size: 19),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dados de la tirada',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),

                                Text(
                                  passiveRollPreview,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),

                          IconButton(
                            tooltip: 'Añadir dados',
                            onPressed: addPassiveRollDice,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),

                      if (rollDicePools.isNotEmpty) ...[
                        const Divider(),

                        ...List.generate(rollDicePools.length, (index) {
                          final pool = rollDicePools[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    initialValue: pool.count,

                                    decoration: const InputDecoration(
                                      labelText: 'Cantidad',
                                    ),

                                    items: List.generate(20, (i) => i + 1).map((
                                      value,
                                    ) {
                                      return DropdownMenuItem(
                                        value: value,
                                        child: Text('$value'),
                                      );
                                    }).toList(),

                                    onChanged: (value) {
                                      if (value == null) {
                                        return;
                                      }

                                      setState(() {
                                        pool.count = value;
                                      });
                                    },
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    initialValue: pool.sides,

                                    decoration: const InputDecoration(
                                      labelText: 'Dado',
                                    ),

                                    items: const [4, 6, 8, 10, 12, 20].map((
                                      value,
                                    ) {
                                      return DropdownMenuItem(
                                        value: value,
                                        child: Text('d$value'),
                                      );
                                    }).toList(),

                                    onChanged: (value) {
                                      if (value == null) {
                                        return;
                                      }

                                      setState(() {
                                        pool.sides = value;
                                      });
                                    },
                                  ),
                                ),

                                IconButton(
                                  tooltip: 'Eliminar dado',
                                  onPressed: () {
                                    removePassiveRollDice(index);
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: 14),

                      _BonusAttributeMultipliers(
                        multipliers: rollAbilityModifierMultipliers,
                        onChanged: (value) {
                          setState(() {
                            rollAbilityModifierMultipliers = value;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: rollFlatBonusController,

                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                        ),

                        decoration: const InputDecoration(
                          labelText: 'Bonus fijo de la tirada',
                          hintText: '0',
                          prefixIcon: Icon(Icons.exposure_plus_1_rounded),
                        ),

                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
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

class _EffectBonusSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final VoidCallback onAdd;
  final List<Widget> children;

  const _EffectBonusSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onAdd,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(child: Icon(icon, size: 19)),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),

                if (count > 0) Badge(label: Text('$count')),

                IconButton(
                  tooltip: 'Añadir',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),

            if (children.isNotEmpty) ...[const Divider(), ...children],
          ],
        ),
      ),
    );
  }
}

class _PassiveEffectTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PassiveEffectTile({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,

      leading: Icon(icon),

      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),

      onTap: onTap,

      trailing: IconButton(
        tooltip: 'Eliminar',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline_rounded),
      ),
    );
  }
}

class _DamageBonusEditorDialog extends StatefulWidget {
  final DamageBonus bonus;

  const _DamageBonusEditorDialog({required this.bonus});

  @override
  State<_DamageBonusEditorDialog> createState() =>
      _DamageBonusEditorDialogState();
}

class _DamageBonusEditorDialogState extends State<_DamageBonusEditorDialog> {
  late DamageBonus bonus;

  late final TextEditingController nameController;

  late final TextEditingController typeController;

  late final TextEditingController flatController;

  static const availableDice = [4, 6, 8, 10, 12, 20];

  @override
  void initState() {
    super.initState();

    bonus = DamageBonus.fromMap(widget.bonus.toMap());

    nameController = TextEditingController(text: bonus.name);

    typeController = TextEditingController(text: bonus.damageType);

    flatController = TextEditingController(text: '${bonus.flatBonus}');
  }

  @override
  void dispose() {
    nameController.dispose();
    typeController.dispose();
    flatController.dispose();

    super.dispose();
  }

  void addDice() {
    setState(() {
      bonus.dicePools.add(DicePool(count: 1, sides: 6));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Daño adicional'),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: 'Tipo de daño',
                hintText: 'Fuego, radiante...',
              ),
            ),

            const SizedBox(height: 16),

            ...List.generate(bonus.dicePools.length, (index) {
              final pool = bonus.dicePools[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: pool.count,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad',
                        ),
                        items: List.generate(20, (i) => i + 1)
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text('$value'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            pool.count = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: pool.sides,
                        decoration: const InputDecoration(labelText: 'Dado'),
                        items: availableDice
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text('d$value'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            pool.sides = value;
                          });
                        },
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        setState(() {
                          bonus.dicePools.removeAt(index);
                        });
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              );
            }),

            OutlinedButton.icon(
              onPressed: addDice,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Añadir dados'),
            ),

            const SizedBox(height: 16),

            _BonusAttributeMultipliers(
              multipliers: bonus.abilityModifierMultipliers,
              onChanged: (value) {
                setState(() {
                  bonus.abilityModifierMultipliers = value;
                });
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: flatController,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(labelText: 'Bonus fijo'),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),

        FilledButton(
          onPressed: () {
            bonus.name = nameController.text.trim();

            bonus.damageType = typeController.text.trim();

            bonus.flatBonus = int.tryParse(flatController.text) ?? 0;

            Navigator.pop(context, bonus);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _HealingBonusEditorDialog extends StatefulWidget {
  final HealingBonus bonus;

  const _HealingBonusEditorDialog({required this.bonus});

  @override
  State<_HealingBonusEditorDialog> createState() =>
      _HealingBonusEditorDialogState();
}

class _HealingBonusEditorDialogState extends State<_HealingBonusEditorDialog> {
  late HealingBonus bonus;

  late final TextEditingController nameController;

  late final TextEditingController flatController;

  static const availableDice = [4, 6, 8, 10, 12, 20];

  @override
  void initState() {
    super.initState();

    bonus = HealingBonus.fromMap(widget.bonus.toMap());

    nameController = TextEditingController(text: bonus.name);

    flatController = TextEditingController(text: '${bonus.flatBonus}');
  }

  @override
  void dispose() {
    nameController.dispose();
    flatController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Curación adicional'),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),

            const SizedBox(height: 16),

            ...List.generate(bonus.dicePools.length, (index) {
              final pool = bonus.dicePools[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: pool.count,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad',
                        ),
                        items: List.generate(20, (i) => i + 1)
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text('$value'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            pool.count = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: pool.sides,
                        decoration: const InputDecoration(labelText: 'Dado'),
                        items: availableDice
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text('d$value'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            pool.sides = value;
                          });
                        },
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        setState(() {
                          bonus.dicePools.removeAt(index);
                        });
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              );
            }),

            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  bonus.dicePools.add(DicePool(count: 1, sides: 6));
                });
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Añadir dados'),
            ),

            const SizedBox(height: 16),

            _BonusAttributeMultipliers(
              multipliers: bonus.abilityModifierMultipliers,
              onChanged: (value) {
                setState(() {
                  bonus.abilityModifierMultipliers = value;
                });
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: flatController,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(labelText: 'Bonus fijo'),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),

        FilledButton(
          onPressed: () {
            bonus.name = nameController.text.trim();

            bonus.flatBonus = int.tryParse(flatController.text) ?? 0;

            Navigator.pop(context, bonus);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _CriticalDamageBonusEditorDialog extends StatefulWidget {
  final CriticalDamageBonus bonus;

  const _CriticalDamageBonusEditorDialog({required this.bonus});

  @override
  State<_CriticalDamageBonusEditorDialog> createState() =>
      _CriticalDamageBonusEditorDialogState();
}

class _CriticalDamageBonusEditorDialogState
    extends State<_CriticalDamageBonusEditorDialog> {
  late CriticalDamageBonus bonus;

  late final TextEditingController nameController;

  late final TextEditingController typeController;

  late final TextEditingController chanceController;

  late final TextEditingController descriptionController;

  late final TextEditingController flatBonusController;

  static const availableDice = [4, 6, 8, 10, 12, 20];

  @override
  void initState() {
    super.initState();

    bonus = CriticalDamageBonus.fromMap(widget.bonus.toMap());

    nameController = TextEditingController(text: bonus.name);

    typeController = TextEditingController(text: bonus.damageType);

    chanceController = TextEditingController(text: '${bonus.chancePercent}');

    descriptionController = TextEditingController(text: bonus.description);

    flatBonusController = TextEditingController(text: '${bonus.flatBonus}');
  }

  @override
  void dispose() {
    nameController.dispose();
    typeController.dispose();
    chanceController.dispose();
    descriptionController.dispose();
    flatBonusController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Daño crítico adicional'),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: typeController,
              decoration: const InputDecoration(labelText: 'Tipo de daño'),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: chanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Probabilidad',
                suffixText: '%',
              ),
            ),

            const SizedBox(height: 16),

            ...List.generate(bonus.dicePools.length, (index) {
              final pool = bonus.dicePools[index];

              return Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: pool.count,
                      decoration: const InputDecoration(labelText: 'Cantidad'),
                      items: List.generate(20, (i) => i + 1)
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          pool.count = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: pool.sides,
                      decoration: const InputDecoration(labelText: 'Dado'),
                      items: availableDice
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('d$value'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          pool.sides = value;
                        });
                      },
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      setState(() {
                        bonus.dicePools.removeAt(index);
                      });
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              );
            }),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  bonus.dicePools.add(DicePool(count: 1, sides: 6));
                });
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Añadir dados'),
            ),
            const SizedBox(height: 16),

            _BonusAttributeMultipliers(
              multipliers: bonus.abilityModifierMultipliers,
              onChanged: (value) {
                setState(() {
                  bonus.abilityModifierMultipliers = value;
                });
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: flatBonusController,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(
                labelText: 'Modificador fijo',
                hintText: 'Ej. 3 o -2',
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),

        FilledButton(
          onPressed: () {
            bonus.name = nameController.text.trim();

            bonus.damageType = typeController.text.trim();

            bonus.description = descriptionController.text.trim();

            bonus.flatBonus =
                int.tryParse(flatBonusController.text.trim()) ?? 0;

            bonus.chancePercent = int.tryParse(chanceController.text) ?? 100;

            bonus.normalize();

            Navigator.pop(context, bonus);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _BonusAttributeMultipliers extends StatelessWidget {
  final Map<AbilityType, int> multipliers;

  final ValueChanged<Map<AbilityType, int>> onChanged;

  const _BonusAttributeMultipliers({
    required this.multipliers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Modificadores',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),

            IconButton.filledTonal(
              onPressed: () {
                for (final ability in AbilityType.values) {
                  if (!multipliers.containsKey(ability)) {
                    final updated = Map<AbilityType, int>.from(multipliers);

                    updated[ability] = 1;

                    onChanged(updated);

                    return;
                  }
                }
              },
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),

        ...multipliers.entries.map((entry) {
          return Row(
            children: [
              Expanded(child: Text(entry.key.label)),

              IconButton(
                onPressed: entry.value > 1
                    ? () {
                        final updated = Map<AbilityType, int>.from(multipliers);

                        updated[entry.key] = entry.value - 1;

                        onChanged(updated);
                      }
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),

              Text(
                '×${entry.value}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),

              IconButton(
                onPressed: () {
                  final updated = Map<AbilityType, int>.from(multipliers);

                  updated[entry.key] = entry.value + 1;

                  onChanged(updated);
                },
                icon: const Icon(Icons.add_rounded),
              ),

              IconButton(
                onPressed: () {
                  final updated = Map<AbilityType, int>.from(multipliers);

                  updated.remove(entry.key);

                  onChanged(updated);
                },
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          );
        }),
      ],
    );
  }
}
