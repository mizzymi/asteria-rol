import 'package:flutter/material.dart';

import '../models/character.dart';
import '../models/formulas/character_formula.dart';
import '../models/character_effect.dart';
import '../models/critical_damage_bonus.dart';
import '../models/damage_bonus.dart';
import '../models/dice_pool.dart';
import '../models/healing_bonus.dart';
import '../models/skill.dart';

import '../widgets/formulas/formula_insert_bar.dart';

class EffectFormScreen extends StatefulWidget {
  final CharacterEffect? effect;
  final Character? character;

  const EffectFormScreen({super.key, this.effect, this.character});

  @override
  State<EffectFormScreen> createState() => _EffectFormScreenState();
}

class _EffectFormScreenState extends State<EffectFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late CharacterEffectType effectType;

  late final TextEditingController nameController;

  late final TextEditingController descriptionController;

  late final TextEditingController durationController;

  late final TextEditingController durationNoteController;

  late final TextEditingController armorClassController;

  late final TextEditingController initiativeController;

  late final TextEditingController speedController;

  late final TextEditingController maxHealthController;

  late final TextEditingController attackController;

  late final TextEditingController notesController;

  late CharacterEffectDurationType durationType;

  bool enabled = true;

  late Map<AbilityType, int> abilityModifierBonuses;

  late Map<DndSkill, int> skillBonuses;

  late Map<AbilityType, int> savingThrowBonuses;

  late List<DamageBonus> damageBonuses;

  late List<HealingBonus> healingBonuses;

  late List<CriticalDamageBonus> criticalDamageBonuses;

  bool get editing => widget.effect != null;

  @override
  void initState() {
    super.initState();

    final effect = widget.effect;

    effectType = effect?.type ?? CharacterEffectType.neutral;

    nameController = TextEditingController(text: effect?.name ?? '');

    descriptionController = TextEditingController(
      text: effect?.description ?? '',
    );

    durationController = TextEditingController(
      text: effect?.hasDuration == true ? '${effect!.maxDuration}' : '1',
    );

    durationNoteController = TextEditingController(
      text: effect?.durationNote ?? '',
    );

    armorClassController = TextEditingController(
      text: '${effect?.armorClassBonus ?? 0}',
    );

    initiativeController = TextEditingController(
      text: '${effect?.initiativeBonus ?? 0}',
    );

    speedController = TextEditingController(text: '${effect?.speedBonus ?? 0}');

    maxHealthController = TextEditingController(
      text: '${effect?.maxHealthBonus ?? 0}',
    );

    attackController = TextEditingController(
      text: '${effect?.attackBonus ?? 0}',
    );

    notesController = TextEditingController(text: effect?.notes ?? '');

    durationType =
        effect?.durationType ?? CharacterEffectDurationType.permanent;

    enabled = effect?.enabled ?? true;

    abilityModifierBonuses = {...?effect?.abilityModifierBonuses};

    skillBonuses = {...?effect?.skillBonuses};

    savingThrowBonuses = {...?effect?.savingThrowBonuses};

    damageBonuses =
        effect?.damageBonuses
            .map((bonus) => DamageBonus.fromMap(bonus.toMap()))
            .toList() ??
        [];

    healingBonuses =
        effect?.healingBonuses
            .map((bonus) => HealingBonus.fromMap(bonus.toMap()))
            .toList() ??
        [];

    criticalDamageBonuses =
        effect?.criticalDamageBonuses
            .map((bonus) => CriticalDamageBonus.fromMap(bonus.toMap()))
            .toList() ??
        [];
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    durationController.dispose();
    durationNoteController.dispose();
    armorClassController.dispose();
    initiativeController.dispose();
    speedController.dispose();
    maxHealthController.dispose();
    attackController.dispose();
    notesController.dispose();

    super.dispose();
  }

  int _parse(TextEditingController controller) {
    return int.tryParse(controller.text) ?? 0;
  }

  Future<void> _addDamageBonus() async {
    final bonus = DamageBonus(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
    );

    final result = await showDialog<DamageBonus>(
      context: context,
      builder: (context) {
        return _DamageBonusDialog(bonus: bonus, character: widget.character);
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      damageBonuses.add(result);
    });
  }

  Future<void> _editDamageBonus(DamageBonus bonus) async {
    final copy = DamageBonus.fromMap(bonus.toMap());

    final result = await showDialog<DamageBonus>(
      context: context,
      builder: (context) {
        return _DamageBonusDialog(bonus: copy);
      },
    );

    if (result == null) {
      return;
    }

    final index = damageBonuses.indexOf(bonus);

    if (index == -1) {
      return;
    }

    setState(() {
      damageBonuses[index] = result;
    });
  }

  Future<void> _addHealingBonus() async {
    final bonus = HealingBonus(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
    );

    final result = await showDialog<HealingBonus>(
      context: context,
      builder: (context) {
        return _HealingBonusDialog(bonus: bonus, character: widget.character);
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      healingBonuses.add(result);
    });
  }

  Future<void> _editHealingBonus(HealingBonus bonus) async {
    final copy = HealingBonus.fromMap(bonus.toMap());

    final result = await showDialog<HealingBonus>(
      context: context,
      builder: (context) {
        return _HealingBonusDialog(bonus: copy);
      },
    );

    if (result == null) {
      return;
    }

    final index = healingBonuses.indexOf(bonus);

    if (index == -1) {
      return;
    }

    setState(() {
      healingBonuses[index] = result;
    });
  }

  Future<void> _addCriticalDamageBonus() async {
    final bonus = CriticalDamageBonus(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
    );

    final result = await showDialog<CriticalDamageBonus>(
      context: context,
      builder: (context) {
        return _CriticalDamageBonusDialog(
          bonus: bonus,
          character: widget.character,
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      criticalDamageBonuses.add(result);
    });
  }

  Future<void> _editCriticalDamageBonus(CriticalDamageBonus bonus) async {
    final copy = CriticalDamageBonus.fromMap(bonus.toMap());

    final result = await showDialog<CriticalDamageBonus>(
      context: context,
      builder: (context) {
        return _CriticalDamageBonusDialog(
          bonus: copy,
          character: widget.character,
        );
      },
    );

    if (result == null) {
      return;
    }

    final index = criticalDamageBonuses.indexOf(bonus);

    if (index == -1) {
      return;
    }

    setState(() {
      criticalDamageBonuses[index] = result;
    });
  }

  String _damageBonusText(DamageBonus bonus) {
    final pieces = <String>[];

    if (bonus.diceNotation.isNotEmpty) {
      pieces.add(bonus.diceNotation);
    }

    for (final entry in bonus.abilityModifierMultipliers.entries) {
      if (entry.value == 1) {
        pieces.add(entry.key.shortLabel);
      } else {
        pieces.add('${entry.value}×${entry.key.shortLabel}');
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

    if (bonus.hasFormula) {
      pieces.add('ƒ(${bonus.formula!.expression})');
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
        pieces.add(entry.key.shortLabel);
      } else {
        pieces.add('${entry.value}×${entry.key.shortLabel}');
      }
    }

    if (bonus.flatBonus != 0) {
      pieces.add(
        bonus.flatBonus > 0 ? '+${bonus.flatBonus}' : '${bonus.flatBonus}',
      );
    }

    if (bonus.hasFormula) {
      pieces.add('ƒ(${bonus.formula!.expression})');
    }

    return pieces.isEmpty
        ? 'Sin curación'
        : pieces.join(' + ').replaceAll('+ -', '- ');
  }

  String _criticalBonusText(CriticalDamageBonus bonus) {
    final pieces = <String>[];

    if (bonus.diceNotation.isNotEmpty) {
      pieces.add(bonus.diceNotation);
    }

    for (final entry in bonus.abilityModifierMultipliers.entries) {
      if (entry.value == 1) {
        pieces.add(entry.key.shortLabel);
      } else {
        pieces.add('${entry.value}×${entry.key.shortLabel}');
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

    if (bonus.hasFormula) {
      pieces.add('ƒ(${bonus.formula!.expression})');
    }

    return result;
  }

  void saveEffect() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final hasDuration = durationType != CharacterEffectDurationType.permanent;

    final parsedDuration = hasDuration
        ? (int.tryParse(durationController.text) ?? 1)
        : 0;

    final safeDuration = parsedDuration < 1 && hasDuration ? 1 : parsedDuration;

    int currentDuration;

    if (!hasDuration) {
      currentDuration = 0;
    } else if (widget.effect == null ||
        widget.effect!.durationType != durationType) {
      /*
       * Nuevo efecto o hemos cambiado
       * el tipo de duración:
       * empieza completo.
       */
      currentDuration = safeDuration;
    } else {
      /*
       * Al editar conservamos
       * el tiempo restante.
       */
      currentDuration = widget.effect!.currentDuration;

      if (currentDuration > safeDuration) {
        currentDuration = safeDuration;
      }
    }

    final cleanedAbilities = <AbilityType, int>{};

    for (final entry in abilityModifierBonuses.entries) {
      if (entry.value != 0) {
        cleanedAbilities[entry.key] = entry.value;
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

    final effect = CharacterEffect(
      id: widget.effect?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),

      name: nameController.text.trim(),

      description: descriptionController.text.trim(),

      enabled: enabled,

      durationType: durationType,

      type: effectType,

      maxDuration: safeDuration,

      currentDuration: currentDuration,

      durationNote: durationNoteController.text.trim(),

      armorClassBonus: _parse(armorClassController),

      initiativeBonus: _parse(initiativeController),

      speedBonus: _parse(speedController),

      maxHealthBonus: _parse(maxHealthController),

      attackBonus: _parse(attackController),

      abilityModifierBonuses: cleanedAbilities,

      skillBonuses: cleanedSkills,

      savingThrowBonuses: cleanedSaves,

      damageBonuses: damageBonuses
          .where((bonus) => bonus.hasDamage)
          .map((bonus) => DamageBonus.fromMap(bonus.toMap()))
          .toList(),

      healingBonuses: healingBonuses
          .where((bonus) => bonus.hasHealing)
          .map((bonus) => HealingBonus.fromMap(bonus.toMap()))
          .toList(),

      criticalDamageBonuses: criticalDamageBonuses
          .where((bonus) => bonus.canTrigger)
          .map((bonus) => CriticalDamageBonus.fromMap(bonus.toMap()))
          .toList(),

      notes: notesController.text.trim(),
    );

    effect.normalizeDuration();

    Navigator.pop(context, effect);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar efecto' : 'Nuevo efecto'),
        actions: [
          IconButton(
            tooltip: 'Guardar',
            onPressed: saveEffect,
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
              // ===============================================================
              // GENERAL
              // ===============================================================
              Text(
                'General',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Bendición, Veneno, Prisa...',
                  prefixIcon: Icon(Icons.auto_awesome_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduce un nombre';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<CharacterEffectType>(
                initialValue: effectType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de efecto',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: CharacterEffectType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          _effectTypeIcon(type),
                          color: _effectTypeColor(type),
                          size: 20,
                        ),

                        const SizedBox(width: 8),

                        Text(type.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    effectType = value;
                  });
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: descriptionController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 12),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: enabled,
                title: const Text('Efecto activo'),
                subtitle: const Text(
                  'Sus bonificaciones se aplicarán al personaje.',
                ),
                onChanged: (value) {
                  setState(() {
                    enabled = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              // ===============================================================
              // DURACIÓN
              // ===============================================================
              Text(
                'Duración',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<CharacterEffectDurationType>(
                initialValue: durationType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de duración',
                  prefixIcon: Icon(Icons.timer_rounded),
                ),
                items: CharacterEffectDurationType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.label));
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    durationType = value;
                  });
                },
              ),

              if (durationType != CharacterEffectDurationType.permanent) ...[
                const SizedBox(height: 12),

                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () {
                        final value =
                            int.tryParse(durationController.text) ?? 1;

                        if (value <= 1) {
                          return;
                        }

                        setState(() {
                          durationController.text = '${value - 1}';
                        });
                      },
                      icon: const Icon(Icons.remove_rounded),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: TextFormField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: _durationLabel(durationType),
                        ),
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');

                          if (parsed == null || parsed < 1) {
                            return 'Mínimo 1';
                          }

                          return null;
                        },
                      ),
                    ),

                    const SizedBox(width: 10),

                    IconButton.filledTonal(
                      onPressed: () {
                        final value =
                            int.tryParse(durationController.text) ?? 1;

                        setState(() {
                          durationController.text = '${value + 1}';
                        });
                      },
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: durationNoteController,
                  decoration: const InputDecoration(
                    labelText: 'Nota de duración',
                    hintText:
                        'Hasta recibir daño, hasta terminar el combate...',
                    prefixIcon: Icon(Icons.schedule_rounded),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // ===============================================================
              // BONIFICACIONES GENERALES
              // ===============================================================
              Text(
                'Bonificaciones',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'También puedes usar valores negativos para penalizaciones.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 14),

              _BonusField(
                controller: armorClassController,
                icon: Icons.shield_rounded,
                label: 'CA',
              ),

              _BonusField(
                controller: initiativeController,
                icon: Icons.bolt_rounded,
                label: 'Iniciativa',
              ),

              _BonusField(
                controller: speedController,
                icon: Icons.directions_run_rounded,
                label: 'Velocidad',
              ),

              _BonusField(
                controller: maxHealthController,
                icon: Icons.favorite_rounded,
                label: 'PG máximos',
              ),

              _BonusField(
                controller: attackController,
                icon: Icons.gps_fixed_rounded,
                label: 'Ataque',
              ),

              const SizedBox(height: 28),

              // ===============================================================
              // DAÑO EXTRA
              // ===============================================================
              _BonusListSection(
                title: 'Daño extra',
                description:
                    'Se añade al daño mientras este efecto esté activo.',
                icon: Icons.flash_on_rounded,

                items: damageBonuses
                    .map(
                      (bonus) => _BonusListItem(
                        title: bonus.name.trim().isNotEmpty
                            ? bonus.name.trim()
                            : 'Daño extra',

                        subtitle: _damageBonusText(bonus),

                        onEdit: () {
                          _editDamageBonus(bonus);
                        },

                        onDelete: () {
                          setState(() {
                            damageBonuses.remove(bonus);
                          });
                        },
                      ),
                    )
                    .toList(),

                onAdd: _addDamageBonus,
              ),

              const SizedBox(height: 24),

              // ===============================================================
              // CURACIÓN EXTRA
              // ===============================================================
              _BonusListSection(
                title: 'Curación extra',
                description:
                    'Se añade a las curaciones mientras este efecto esté activo.',
                icon: Icons.favorite_rounded,

                items: healingBonuses
                    .map(
                      (bonus) => _BonusListItem(
                        title: bonus.name.trim().isNotEmpty
                            ? bonus.name.trim()
                            : 'Curación extra',

                        subtitle: _healingBonusText(bonus),

                        onEdit: () {
                          _editHealingBonus(bonus);
                        },

                        onDelete: () {
                          setState(() {
                            healingBonuses.remove(bonus);
                          });
                        },
                      ),
                    )
                    .toList(),

                onAdd: _addHealingBonus,
              ),

              const SizedBox(height: 24),

              // ===============================================================
              // BONUS DE CRÍTICO
              // ===============================================================
              _BonusListSection(
                title: 'Daño al hacer crítico',
                description:
                    'Daño adicional que aparece únicamente cuando se produce un crítico.',
                icon: Icons.local_fire_department_rounded,

                items: criticalDamageBonuses
                    .map(
                      (bonus) => _BonusListItem(
                        title: bonus.name.trim().isNotEmpty
                            ? bonus.name.trim()
                            : 'Daño crítico extra',

                        subtitle: _criticalBonusText(bonus),

                        onEdit: () {
                          _editCriticalDamageBonus(bonus);
                        },

                        onDelete: () {
                          setState(() {
                            criticalDamageBonuses.remove(bonus);
                          });
                        },
                      ),
                    )
                    .toList(),

                onAdd: _addCriticalDamageBonus,
              ),

              const SizedBox(height: 28),

              // ===============================================================
              // ATRIBUTOS
              // ===============================================================
              _MapBonusSection<AbilityType>(
                title: 'Atributos',
                icon: Icons.psychology_rounded,
                values: AbilityType.values,
                valueLabel: (ability) => ability.shortLabel,
                currentValue: (ability) => abilityModifierBonuses[ability] ?? 0,
                onChanged: (ability, value) {
                  setState(() {
                    if (value == 0) {
                      abilityModifierBonuses.remove(ability);
                    } else {
                      abilityModifierBonuses[ability] = value;
                    }
                  });
                },
              ),

              const SizedBox(height: 28),

              // ===============================================================
              // SKILLS
              // ===============================================================
              _MapBonusSection<DndSkill>(
                title: 'Habilidades',
                icon: Icons.bar_chart_rounded,
                values: DndSkill.values,
                valueLabel: (skill) => skill.label,
                currentValue: (skill) => skillBonuses[skill] ?? 0,
                onChanged: (skill, value) {
                  setState(() {
                    if (value == 0) {
                      skillBonuses.remove(skill);
                    } else {
                      skillBonuses[skill] = value;
                    }
                  });
                },
              ),

              const SizedBox(height: 28),

              // ===============================================================
              // SALVACIONES
              // ===============================================================
              _MapBonusSection<AbilityType>(
                title: 'Salvaciones',
                icon: Icons.security_rounded,
                values: AbilityType.values,
                valueLabel: (ability) => ability.shortLabel,
                currentValue: (ability) => savingThrowBonuses[ability] ?? 0,
                onChanged: (ability, value) {
                  setState(() {
                    if (value == 0) {
                      savingThrowBonuses.remove(ability);
                    } else {
                      savingThrowBonuses[ability] = value;
                    }
                  });
                },
              ),

              const SizedBox(height: 28),

              // ===============================================================
              // NOTAS
              // ===============================================================
              TextFormField(
                controller: notesController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),

              const SizedBox(height: 30),

              FilledButton.icon(
                onPressed: saveEffect,
                icon: const Icon(Icons.save_rounded),
                label: Text(editing ? 'Guardar cambios' : 'Crear efecto'),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  String _durationLabel(CharacterEffectDurationType type) {
    switch (type) {
      case CharacterEffectDurationType.permanent:
        return 'Duración';

      case CharacterEffectDurationType.turns:
        return 'Turnos';

      case CharacterEffectDurationType.rounds:
        return 'Rondas';

      case CharacterEffectDurationType.minutes:
        return 'Minutos';

      case CharacterEffectDurationType.custom:
        return 'Duración';
    }
  }
}

// =============================================================================
// BONUS GENERAL
// =============================================================================

class _BonusField extends StatelessWidget {
  final TextEditingController controller;

  final IconData icon;

  final String label;

  const _BonusField({
    required this.controller,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(signed: true),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          hintText: '0',
        ),
      ),
    );
  }
}

// =============================================================================
// BONUS POR MAPA
// =============================================================================

class _MapBonusSection<T> extends StatelessWidget {
  final String title;

  final IconData icon;

  final List<T> values;

  final String Function(T value) valueLabel;

  final int Function(T value) currentValue;

  final void Function(T value, int bonus) onChanged;

  const _MapBonusSection({
    required this.title,
    required this.icon,
    required this.values,
    required this.valueLabel,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 6),
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: const Text('Opcional'),
      children: values.map((value) {
        final bonus = currentValue(value);

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(valueLabel(value)),
          trailing: SizedBox(
            width: 130,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    onChanged(value, bonus - 1);
                  },
                  icon: const Icon(Icons.remove_rounded),
                ),

                Expanded(
                  child: Text(
                    bonus >= 0 ? '+$bonus' : '$bonus',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),

                IconButton(
                  onPressed: () {
                    onChanged(value, bonus + 1);
                  },
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

Color _effectTypeColor(CharacterEffectType type) {
  switch (type) {
    case CharacterEffectType.buff:
      return const Color(0xFF4CAF7D);

    case CharacterEffectType.debuff:
      return const Color(0xFFE45D68);

    case CharacterEffectType.condition:
      return const Color(0xFF9B6CE8);

    case CharacterEffectType.neutral:
      return const Color(0xFF5F8FD8);
  }
}

IconData _effectTypeIcon(CharacterEffectType type) {
  switch (type) {
    case CharacterEffectType.buff:
      return Icons.arrow_upward_rounded;

    case CharacterEffectType.debuff:
      return Icons.arrow_downward_rounded;

    case CharacterEffectType.condition:
      return Icons.warning_amber_rounded;

    case CharacterEffectType.neutral:
      return Icons.auto_awesome_rounded;
  }
}

class _BonusListSection extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  final List<_BonusListItem> items;

  final VoidCallback onAdd;

  const _BonusListSection({
    required this.title,
    required this.description,
    required this.icon,
    required this.items,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            IconButton.filledTonal(
              tooltip: 'Añadir',
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        if (items.isNotEmpty) ...[const SizedBox(height: 12), ...items],
      ],
    );
  }
}

class _BonusListItem extends StatelessWidget {
  final String title;
  final String subtitle;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BonusListItem({
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),

        subtitle: Text(subtitle),

        onTap: onEdit,

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Editar',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
            ),

            IconButton(
              tooltip: 'Eliminar',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DIÁLOGO - DAÑO EXTRA
// =============================================================================

class _DamageBonusDialog extends StatefulWidget {
  final DamageBonus bonus;
  final Character? character;

  const _DamageBonusDialog({required this.bonus, this.character});

  @override
  State<_DamageBonusDialog> createState() => _DamageBonusDialogState();
}

class _DamageBonusDialogState extends State<_DamageBonusDialog> {
  late DamageBonus bonus;

  late final TextEditingController nameController;
  late final TextEditingController diceController;
  late final TextEditingController flatBonusController;
  late final TextEditingController damageTypeController;
  late final TextEditingController formulaController;

  bool showFormulaTools = false;

  @override
  void initState() {
    super.initState();

    bonus = DamageBonus.fromMap(widget.bonus.toMap());

    nameController = TextEditingController(text: bonus.name);

    diceController = TextEditingController(text: bonus.diceNotation);

    flatBonusController = TextEditingController(text: '${bonus.flatBonus}');

    damageTypeController = TextEditingController(text: bonus.damageType);

    formulaController = TextEditingController(
      text: bonus.formula?.expression ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    diceController.dispose();
    flatBonusController.dispose();
    damageTypeController.dispose();
    formulaController.dispose();

    super.dispose();
  }

  void _insertFormula(String text) {
    final selection = formulaController.selection;
    final current = formulaController.text;

    final start = selection.isValid ? selection.start : current.length;

    final end = selection.isValid ? selection.end : current.length;

    final updated = current.replaceRange(start, end, text);

    formulaController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + text.length),
    );

    setState(() {});
  }

  void _save() {
    final parsedDice = _parseEffectDicePools(diceController.text);

    if (parsedDice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Formato de dados no válido. Usa por ejemplo: 2d6 + 1d4',
          ),
        ),
      );

      return;
    }

    bonus.name = nameController.text.trim();

    bonus.dicePools = parsedDice;

    bonus.flatBonus = int.tryParse(flatBonusController.text.trim()) ?? 0;

    bonus.damageType = damageTypeController.text.trim();

    final expression = formulaController.text.trim();

    bonus.formula = expression.isEmpty
        ? null
        : CharacterFormula(expression: expression);

    Navigator.pop(context, bonus);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BonusDialogHeader(
              icon: Icons.flash_on_rounded,
              title: 'Daño extra',
              onClose: () {
                Navigator.pop(context);
              },
            ),

            const Divider(height: 1),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ej: Fuego lunar',
                        prefixIcon: Icon(Icons.edit_rounded),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: diceController,
                      decoration: const InputDecoration(
                        labelText: 'Dados',
                        hintText: '2d6 + 1d4',
                        helperText:
                            'Puedes dejarlo vacío si solo usa modificadores.',
                        prefixIcon: Icon(Icons.casino_rounded),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: flatBonusController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Bonus fijo',
                        hintText: '0',
                        prefixIcon: Icon(Icons.exposure_plus_1_rounded),
                      ),
                    ),

                    const SizedBox(height: 18),

                    _EffectAbilityModifiersEditor(
                      multipliers: bonus.abilityModifierMultipliers,
                      onChanged: (value) {
                        setState(() {
                          bonus.abilityModifierMultipliers = value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Fórmula adicional',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Se suma al daño mientras el efecto esté activo.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      controller: formulaController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Fórmula',
                        hintText: 'rounddown(level / 5)',
                        prefixIcon: Icon(Icons.functions_rounded),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            showFormulaTools = !showFormulaTools;
                          });
                        },
                        icon: Icon(
                          showFormulaTools
                              ? Icons.expand_less_rounded
                              : Icons.functions_rounded,
                        ),
                        label: Text(
                          showFormulaTools
                              ? 'Ocultar herramientas'
                              : 'Insertar en fórmula',
                        ),
                      ),
                    ),

                    if (showFormulaTools)
                      FormulaInsertBar(
                        character: widget.character,
                        onInsert: _insertFormula,
                      ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: damageTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de daño',
                        hintText: 'Fuego, hielo, cortante, radiante...',
                        prefixIcon: Icon(Icons.local_fire_department_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            _BonusDialogActions(
              onCancel: () {
                Navigator.pop(context);
              },
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DIÁLOGO - CURACIÓN EXTRA
// =============================================================================

class _HealingBonusDialog extends StatefulWidget {
  final HealingBonus bonus;
  final Character? character;

  const _HealingBonusDialog({required this.bonus, this.character});

  @override
  State<_HealingBonusDialog> createState() => _HealingBonusDialogState();
}

class _HealingBonusDialogState extends State<_HealingBonusDialog> {
  late HealingBonus bonus;

  late final TextEditingController nameController;
  late final TextEditingController diceController;
  late final TextEditingController flatBonusController;
  late final TextEditingController formulaController;

  bool showFormulaTools = false;

  @override
  void initState() {
    super.initState();

    bonus = HealingBonus.fromMap(widget.bonus.toMap());

    nameController = TextEditingController(text: bonus.name);

    diceController = TextEditingController(text: bonus.diceNotation);

    flatBonusController = TextEditingController(text: '${bonus.flatBonus}');

    formulaController = TextEditingController(
      text: bonus.formula?.expression ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    diceController.dispose();
    flatBonusController.dispose();
    formulaController.dispose();

    super.dispose();
  }

  void _insertFormula(String text) {
    final selection = formulaController.selection;
    final current = formulaController.text;

    final start = selection.isValid ? selection.start : current.length;

    final end = selection.isValid ? selection.end : current.length;

    final updated = current.replaceRange(start, end, text);

    formulaController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + text.length),
    );

    setState(() {});
  }

  void _save() {
    final parsedDice = _parseEffectDicePools(diceController.text);

    if (parsedDice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Formato de dados no válido. Usa por ejemplo: 2d6 + 1d4',
          ),
        ),
      );

      return;
    }

    bonus.name = nameController.text.trim();

    bonus.dicePools = parsedDice;

    bonus.flatBonus = int.tryParse(flatBonusController.text.trim()) ?? 0;

    final expression = formulaController.text.trim();

    bonus.formula = expression.isEmpty
        ? null
        : CharacterFormula(expression: expression);

    Navigator.pop(context, bonus);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BonusDialogHeader(
              icon: Icons.favorite_rounded,
              title: 'Curación extra',
              onClose: () {
                Navigator.pop(context);
              },
            ),

            const Divider(height: 1),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ej: Regeneración',
                        prefixIcon: Icon(Icons.edit_rounded),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: diceController,
                      decoration: const InputDecoration(
                        labelText: 'Dados',
                        hintText: '1d8 + 1d4',
                        helperText:
                            'Puedes dejarlo vacío si solo usa modificadores.',
                        prefixIcon: Icon(Icons.casino_rounded),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: flatBonusController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Bonus fijo',
                        hintText: '0',
                        prefixIcon: Icon(Icons.exposure_plus_1_rounded),
                      ),
                    ),

                    const SizedBox(height: 18),

                    _EffectAbilityModifiersEditor(
                      multipliers: bonus.abilityModifierMultipliers,
                      onChanged: (value) {
                        setState(() {
                          bonus.abilityModifierMultipliers = value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: formulaController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Fórmula adicional',
                        hintText: 'SAB_MOD + rounddown(level / 5)',
                        prefixIcon: Icon(Icons.functions_rounded),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            showFormulaTools = !showFormulaTools;
                          });
                        },
                        icon: Icon(
                          showFormulaTools
                              ? Icons.expand_less_rounded
                              : Icons.functions_rounded,
                        ),
                        label: Text(
                          showFormulaTools
                              ? 'Ocultar herramientas'
                              : 'Insertar en fórmula',
                        ),
                      ),
                    ),

                    if (showFormulaTools)
                      FormulaInsertBar(
                        character: widget.character,
                        onInsert: _insertFormula,
                      ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            _BonusDialogActions(
              onCancel: () {
                Navigator.pop(context);
              },
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DIÁLOGO - DAÑO EXTRA AL HACER CRÍTICO
// =============================================================================

class _CriticalDamageBonusDialog extends StatefulWidget {
  final CriticalDamageBonus bonus;
  final Character? character;

  const _CriticalDamageBonusDialog({required this.bonus, this.character});

  @override
  State<_CriticalDamageBonusDialog> createState() =>
      _CriticalDamageBonusDialogState();
}

class _CriticalDamageBonusDialogState
    extends State<_CriticalDamageBonusDialog> {
  late CriticalDamageBonus bonus;

  late final TextEditingController nameController;
  late final TextEditingController diceController;
  late final TextEditingController flatBonusController;
  late final TextEditingController damageTypeController;
  late final TextEditingController chanceController;
  late final TextEditingController formulaController;

  bool showFormulaTools = false;
  @override
  void initState() {
    super.initState();

    bonus = CriticalDamageBonus.fromMap(widget.bonus.toMap());

    nameController = TextEditingController(text: bonus.name);

    diceController = TextEditingController(text: bonus.diceNotation);

    flatBonusController = TextEditingController(text: '${bonus.flatBonus}');

    damageTypeController = TextEditingController(text: bonus.damageType);

    chanceController = TextEditingController(text: '${bonus.chancePercent}');

    formulaController = TextEditingController(
      text: bonus.formula?.expression ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    diceController.dispose();
    flatBonusController.dispose();
    damageTypeController.dispose();
    chanceController.dispose();
    formulaController.dispose();

    super.dispose();
  }

  void _save() {
    final parsedDice = _parseEffectDicePools(diceController.text);

    if (parsedDice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Formato de dados no válido. Usa por ejemplo: 1d6 + 1d4',
          ),
        ),
      );

      return;
    }

    bonus.name = nameController.text.trim();

    bonus.dicePools = parsedDice;

    bonus.flatBonus = int.tryParse(flatBonusController.text.trim()) ?? 0;

    bonus.damageType = damageTypeController.text.trim();

    final chance = int.tryParse(chanceController.text.trim()) ?? 100;

    bonus.chancePercent = chance.clamp(0, 100);

    bonus.normalize();

    final expression = formulaController.text.trim();

    bonus.formula = expression.isEmpty
        ? null
        : CharacterFormula(expression: expression);

    Navigator.pop(context, bonus);
  }

  void _insertFormula(String text) {
    final selection = formulaController.selection;
    final current = formulaController.text;

    final start = selection.isValid ? selection.start : current.length;

    final end = selection.isValid ? selection.end : current.length;

    final updated = current.replaceRange(start, end, text);

    formulaController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + text.length),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BonusDialogHeader(
              icon: Icons.local_fire_department_rounded,
              title: 'Daño al hacer crítico',
              onClose: () {
                Navigator.pop(context);
              },
            ),

            const Divider(height: 1),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(
                          alpha: 0.35,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Este daño aparece porque se ha producido un crítico. '
                        'No vuelve a recibir las reglas de crítico.',
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ej: Herida profunda',
                        prefixIcon: Icon(Icons.edit_rounded),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: diceController,
                      decoration: const InputDecoration(
                        labelText: 'Dados adicionales',
                        hintText: '1d6',
                        helperText:
                            'Estos dados se tiran normalmente, no se maximizan.',
                        prefixIcon: Icon(Icons.casino_rounded),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: flatBonusController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Bonus fijo',
                        hintText: '0',
                        prefixIcon: Icon(Icons.exposure_plus_1_rounded),
                      ),
                    ),

                    const SizedBox(height: 18),

                    _EffectAbilityModifiersEditor(
                      multipliers: bonus.abilityModifierMultipliers,
                      onChanged: (value) {
                        setState(() {
                          bonus.abilityModifierMultipliers = value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: formulaController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Fórmula adicional',
                        hintText: 'FUE_MOD + rounddown(level / 4)',
                        prefixIcon: Icon(Icons.functions_rounded),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            showFormulaTools = !showFormulaTools;
                          });
                        },
                        icon: Icon(
                          showFormulaTools
                              ? Icons.expand_less_rounded
                              : Icons.functions_rounded,
                        ),
                        label: Text(
                          showFormulaTools
                              ? 'Ocultar herramientas'
                              : 'Insertar en fórmula',
                        ),
                      ),
                    ),

                    if (showFormulaTools)
                      FormulaInsertBar(
                        character: widget.character,
                        onInsert: _insertFormula,
                      ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: damageTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de daño',
                        hintText: 'Fuego, veneno, necrótico...',
                        prefixIcon: Icon(Icons.bolt_rounded),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: chanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Probabilidad de activación',
                        hintText: '100',
                        suffixText: '%',
                        helperText:
                            '100% significa que se activa en todos los críticos.',
                        prefixIcon: Icon(Icons.percent_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            _BonusDialogActions(
              onCancel: () {
                Navigator.pop(context);
              },
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CABECERA COMÚN
// =============================================================================

class _BonusDialogHeader extends StatelessWidget {
  final IconData icon;

  final String title;

  final VoidCallback onClose;

  const _BonusDialogHeader({
    required this.icon,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          IconButton(
            tooltip: 'Cerrar',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ACCIONES COMUNES
// =============================================================================

class _BonusDialogActions extends StatelessWidget {
  final VoidCallback onCancel;

  final VoidCallback onSave;

  const _BonusDialogActions({required this.onCancel, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              child: const Text('Cancelar'),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EDITOR DE MODIFICADORES DE ATRIBUTO
//
// Está hecho en vertical para que funcione bien incluso en pantallas estrechas.
// =============================================================================

class _EffectAbilityModifiersEditor extends StatelessWidget {
  final Map<AbilityType, int> multipliers;

  final ValueChanged<Map<AbilityType, int>> onChanged;

  const _EffectAbilityModifiersEditor({
    required this.multipliers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final entries = multipliers.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Modificadores de atributo',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),

            IconButton.filledTonal(
              tooltip: 'Añadir atributo',
              onPressed: () {
                final available = AbilityType.values
                    .where((ability) => !multipliers.containsKey(ability))
                    .toList();

                if (available.isEmpty) {
                  return;
                }

                final updated = Map<AbilityType, int>.from(multipliers);

                updated[available.first] = 1;

                onChanged(updated);
              },
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Text(
          'El resultado usará el modificador actual del personaje.',
          style: Theme.of(context).textTheme.bodySmall,
        ),

        if (entries.isNotEmpty) const SizedBox(height: 10),

        ...entries.map((entry) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                // ===========================================================
                // ATRIBUTO + BORRAR
                // ===========================================================
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<AbilityType>(
                        initialValue: entry.key,
                        decoration: const InputDecoration(
                          labelText: 'Atributo',
                          isDense: true,
                        ),
                        items: AbilityType.values.map((ability) {
                          return DropdownMenuItem(
                            value: ability,
                            child: Text(ability.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null || value == entry.key) {
                            return;
                          }

                          final updated = Map<AbilityType, int>.from(
                            multipliers,
                          );

                          final multiplier = updated.remove(entry.key) ?? 1;

                          /*
                             * Si el destino ya existía,
                             * sumamos los multiplicadores.
                             */
                          updated[value] = (updated[value] ?? 0) + multiplier;

                          onChanged(updated);
                        },
                      ),
                    ),

                    const SizedBox(width: 6),

                    IconButton(
                      tooltip: 'Eliminar atributo',
                      onPressed: () {
                        final updated = Map<AbilityType, int>.from(multipliers);

                        updated.remove(entry.key);

                        onChanged(updated);
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // ===========================================================
                // MULTIPLICADOR
                // ===========================================================
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Veces que se suma',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),

                    IconButton.filledTonal(
                      tooltip: 'Restar',
                      onPressed: entry.value > 1
                          ? () {
                              final updated = Map<AbilityType, int>.from(
                                multipliers,
                              );

                              updated[entry.key] = entry.value - 1;

                              onChanged(updated);
                            }
                          : null,
                      icon: const Icon(Icons.remove_rounded),
                    ),

                    Container(
                      constraints: const BoxConstraints(minWidth: 48),
                      alignment: Alignment.center,
                      child: Text(
                        '×${entry.value}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),

                    IconButton.filledTonal(
                      tooltip: 'Sumar',
                      onPressed: () {
                        final updated = Map<AbilityType, int>.from(multipliers);

                        updated[entry.key] = entry.value + 1;

                        onChanged(updated);
                      },
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// =============================================================================
// PARSER DE DADOS
//
// Acepta:
// 2d6
// 2d6 + 1d4
// 1d8 + 2d4 + 1d6
//
// Vacío = sin dados.
// =============================================================================

List<DicePool>? _parseEffectDicePools(String value) {
  final clean = value.trim();

  if (clean.isEmpty) {
    return [];
  }

  final pieces = clean
      .split('+')
      .map((piece) => piece.trim())
      .where((piece) => piece.isNotEmpty)
      .toList();

  final result = <DicePool>[];

  for (final piece in pieces) {
    final match = RegExp(
      r'^(\d+)d(\d+)$',
      caseSensitive: false,
    ).firstMatch(piece);

    if (match == null) {
      return null;
    }

    final count = int.tryParse(match.group(1) ?? '');

    final sides = int.tryParse(match.group(2) ?? '');

    if (count == null || sides == null || count <= 0 || sides <= 0) {
      return null;
    }

    result.add(DicePool(count: count, sides: sides));
  }

  return result;
}
