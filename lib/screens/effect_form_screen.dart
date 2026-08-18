import 'package:flutter/material.dart';

import '../models/character_effect.dart';
import '../models/skill.dart';

class EffectFormScreen extends StatefulWidget {
  final CharacterEffect? effect;

  const EffectFormScreen({super.key, this.effect});

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

  String _bonusText(int value) {
    return value >= 0 ? '+$value' : '$value';
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
