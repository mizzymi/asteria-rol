import 'package:flutter/material.dart';

import '../models/ability.dart';
import '../models/dice_pool.dart';
import '../models/skill.dart';

class AbilityFormScreen extends StatefulWidget {
  final CharacterAbility? ability;

  const AbilityFormScreen({super.key, this.ability});

  @override
  State<AbilityFormScreen> createState() => _AbilityFormScreenState();
}

class _AbilityFormScreenState extends State<AbilityFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController descriptionController;

  late final TextEditingController attackBonusController;

  late final TextEditingController effectBonusController;
  late final TextEditingController effectTypeNameController;

  late final TextEditingController saveDcBonusController;

  late final TextEditingController maxUsesController;

  late final TextEditingController notesController;

  late AbilityActionType actionType;

  late AbilityType abilityType;

  late AbilityType savingThrowAbility;

  late AbilityEffectType effectType;

  bool requiresAttackRoll = false;
  bool proficient = true;

  bool addAbilityModifierToEffect = true;

  bool usesSavingThrow = false;

  late List<DicePool> dicePools;

  final List<int> availableDice = [4, 6, 8, 10, 12, 20, 100];

  bool get editing => widget.ability != null;

  @override
  void initState() {
    super.initState();

    final ability = widget.ability;

    nameController = TextEditingController(text: ability?.name ?? '');

    descriptionController = TextEditingController(
      text: ability?.description ?? '',
    );

    attackBonusController = TextEditingController(
      text: '${ability?.attackBonus ?? 0}',
    );

    effectBonusController = TextEditingController(
      text: '${ability?.effectBonus ?? 0}',
    );

    effectTypeNameController = TextEditingController(
      text: ability?.effectTypeName ?? '',
    );

    saveDcBonusController = TextEditingController(
      text: '${ability?.saveDcBonus ?? 0}',
    );

    maxUsesController = TextEditingController(text: '${ability?.maxUses ?? 0}');

    notesController = TextEditingController(text: ability?.notes ?? '');

    actionType = ability?.actionType ?? AbilityActionType.action;

    abilityType = ability?.abilityType ?? AbilityType.strength;

    savingThrowAbility = ability?.savingThrowAbility ?? AbilityType.dexterity;

    effectType = ability?.effectType ?? AbilityEffectType.none;

    requiresAttackRoll = ability?.requiresAttackRoll ?? false;

    proficient = ability?.proficient ?? true;

    addAbilityModifierToEffect = ability?.addAbilityModifierToEffect ?? true;

    usesSavingThrow = ability?.usesSavingThrow ?? false;

    dicePools =
        ability?.dicePools
            .map((pool) => DicePool(count: pool.count, sides: pool.sides))
            .toList() ??
        [];
  }

  void addDicePool() {
    setState(() {
      dicePools.add(DicePool(count: 1, sides: 6));
    });
  }

  void removeDicePool(int index) {
    setState(() {
      dicePools.removeAt(index);
    });
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

  void saveAbility() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final maxUses = int.tryParse(maxUsesController.text) ?? 0;

    int currentUses;

    if (widget.ability == null) {
      currentUses = maxUses;
    } else {
      currentUses = widget.ability!.currentUses;

      if (currentUses > maxUses && maxUses > 0) {
        currentUses = maxUses;
      }

      if (maxUses == 0) {
        currentUses = 0;
      }
    }

    final ability = CharacterAbility(
      id:
          widget.ability?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),

      name: nameController.text.trim(),

      description: descriptionController.text.trim(),

      actionType: actionType,

      requiresAttackRoll: requiresAttackRoll,

      abilityType: abilityType,

      proficient: proficient,

      attackBonus: int.tryParse(attackBonusController.text) ?? 0,

      effectType: effectType,

      dicePools: dicePools
          .map((pool) => DicePool(count: pool.count, sides: pool.sides))
          .toList(),

      addAbilityModifierToEffect: addAbilityModifierToEffect,

      effectBonus: int.tryParse(effectBonusController.text) ?? 0,

      effectTypeName: effectTypeNameController.text.trim(),

      usesSavingThrow: usesSavingThrow,

      savingThrowAbility: savingThrowAbility,

      saveDcBonus: int.tryParse(saveDcBonusController.text) ?? 0,

      maxUses: maxUses,

      currentUses: currentUses,

      notes: notesController.text.trim(),
    );

    Navigator.pop(context, ability);
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();

    attackBonusController.dispose();

    effectBonusController.dispose();
    effectTypeNameController.dispose();

    saveDcBonusController.dispose();

    maxUsesController.dispose();

    notesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar habilidad' : 'Nueva habilidad'),
        actions: [
          IconButton(
            onPressed: saveAbility,
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

              const SizedBox(height: 18),

              DropdownButtonFormField<AbilityActionType>(
                initialValue: actionType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de acción',
                  prefixIcon: Icon(Icons.bolt_rounded),
                ),
                items: AbilityActionType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.label));
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    actionType = value;
                  });
                },
              ),

              const SizedBox(height: 28),

              Text(
                'Ataque',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<AbilityType>(
                initialValue: abilityType,
                decoration: const InputDecoration(
                  labelText: 'Atributo usado',
                  helperText: 'Se usa para ataque, daño, curación o CD',
                  prefixIcon: Icon(Icons.psychology_rounded),
                ),
                items: AbilityType.values.map((ability) {
                  return DropdownMenuItem(
                    value: ability,
                    child: Text(abilityLabel(ability)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    abilityType = value;
                  });
                },
              ),

              const SizedBox(height: 18),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: requiresAttackRoll,
                title: const Text('Requiere tirada de ataque'),
                subtitle: const Text('Tira d20 para comprobar si impacta'),
                onChanged: (value) {
                  setState(() {
                    requiresAttackRoll = value;
                  });
                },
              ),

              if (requiresAttackRoll) ...[

                const SizedBox(height: 8),

                TextFormField(
                  controller: attackBonusController,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Bonus adicional al golpe',
                    helperText: 'Ej: arma +1, rasgo +2...',
                  ),
                ),

                const SizedBox(height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: proficient,
                  title: const Text('Sumar competencia'),
                  subtitle: const Text(
                    'Añade el bonus de competencia al golpe',
                  ),
                  onChanged: (value) {
                    setState(() {
                      proficient = value;
                    });
                  },
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: attackBonusController,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Bonus adicional al golpe',
                    helperText: 'Ej: arma +1, rasgo +2...',
                  ),
                ),
              ],

              const SizedBox(height: 30),

              Text(
                'Daño / Curación',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<AbilityEffectType>(
                initialValue: effectType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de efecto',
                  prefixIcon: Icon(Icons.casino_rounded),
                ),
                items: AbilityEffectType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.label));
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    effectType = value;

                    if (effectType != AbilityEffectType.none &&
                        dicePools.isEmpty) {
                      dicePools.add(DicePool(count: 1, sides: 6));
                    }
                  });
                },
              ),

              if (effectType != AbilityEffectType.none) ...[
                const SizedBox(height: 18),

                Text(
                  effectType == AbilityEffectType.healing
                      ? 'Dados de curación'
                      : 'Dados de daño',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                ...List.generate(dicePools.length, (index) {
                  final pool = dicePools[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: pool.count,
                            decoration: const InputDecoration(
                              labelText: 'Cantidad',
                            ),
                            items: List.generate(20, (index) => index + 1).map((
                              count,
                            ) {
                              return DropdownMenuItem(
                                value: count,
                                child: Text('$count'),
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

                        const SizedBox(width: 10),

                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: pool.sides,
                            decoration: const InputDecoration(
                              labelText: 'Dado',
                            ),
                            items: availableDice.map((sides) {
                              return DropdownMenuItem(
                                value: sides,
                                child: Text('d$sides'),
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

                        const SizedBox(width: 4),

                        IconButton(
                          tooltip: 'Eliminar dados',
                          onPressed: () {
                            removeDicePool(index);
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  );
                }),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: addDicePool,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Añadir otro grupo de dados'),
                  ),
                ),

                const SizedBox(height: 12),

                if (dicePools.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.casino_rounded),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              dicePools
                                  .map((pool) => pool.notation)
                                  .join(' + '),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            'Máx. ${dicePools.fold<int>(0, (sum, pool) => sum + pool.maximum)}',
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: addAbilityModifierToEffect,
                  title: Text(
                    effectType == AbilityEffectType.healing
                        ? 'Sumar modificador a la curación'
                        : 'Sumar modificador al daño',
                  ),
                  subtitle: const Text(
                    'Usa el atributo seleccionado en la habilidad',
                  ),
                  onChanged: (value) {
                    setState(() {
                      addAbilityModifierToEffect = value;
                    });
                  },
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: effectBonusController,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: effectType == AbilityEffectType.healing
                        ? 'Bonus adicional de curación'
                        : 'Bonus adicional de daño',
                  ),
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: effectTypeNameController,
                  decoration: InputDecoration(
                    labelText: effectType == AbilityEffectType.healing
                        ? 'Tipo / descripción'
                        : 'Tipo de daño',
                    hintText: effectType == AbilityEffectType.healing
                        ? 'Ej: curación mágica'
                        : 'Ej: fuego, frío, necrótico...',
                  ),
                ),
              ],

              const SizedBox(height: 30),

              Text(
                'Salvación',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: usesSavingThrow,
                title: const Text('La habilidad fuerza una salvación'),
                subtitle: const Text('La CD se calcula automáticamente'),
                onChanged: (value) {
                  setState(() {
                    usesSavingThrow = value;
                  });
                },
              ),

              if (usesSavingThrow) ...[
                const SizedBox(height: 12),

                DropdownButtonFormField<AbilityType>(
                  initialValue: savingThrowAbility,
                  decoration: const InputDecoration(
                    labelText: 'Salvación del objetivo',
                  ),
                  items: AbilityType.values.map((ability) {
                    return DropdownMenuItem(
                      value: ability,
                      child: Text(abilityLabel(ability)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      savingThrowAbility = value;
                    });
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: saveDcBonusController,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Bonus adicional a la CD',
                    helperText: 'CD base = 8 + competencia + atributo',
                  ),
                ),
              ],

              const SizedBox(height: 30),

              Text(
                'Usos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: maxUsesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Usos máximos',
                  helperText: '0 = usos ilimitados',
                  prefixIcon: Icon(Icons.repeat_rounded),
                ),
                validator: (value) {
                  final number = int.tryParse(value ?? '');

                  if (number == null) {
                    return 'Introduce un número';
                  }

                  if (number < 0) {
                    return 'No puede ser negativo';
                  }

                  return null;
                },
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
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Notas adicionales',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 30),

              FilledButton.icon(
                onPressed: saveAbility,
                icon: const Icon(Icons.save_rounded),
                label: Text(editing ? 'Guardar cambios' : 'Crear habilidad'),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
