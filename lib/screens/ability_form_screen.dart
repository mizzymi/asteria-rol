import 'package:flutter/material.dart';
import 'package:rol/models/character_effect.dart';

import 'effect_form_screen.dart';

import '../models/ability_effect_part.dart';
import '../models/character.dart';
import '../models/ability.dart';
import '../models/dice_pool.dart';
import '../models/skill.dart';
import '../models/character_resource.dart';

import '../widgets/abilities/ability_form/ability_general_section.dart';
import '../widgets/abilities/ability_form/ability_attack_section.dart';
import '../widgets/abilities/ability_form/ability_effects_section.dart';
import '../widgets/abilities/ability_form/ability_uses_section.dart';

class AbilityFormScreen extends StatefulWidget {
  final CharacterAbility? ability;
  final Character? character;

  const AbilityFormScreen({super.key, this.ability, this.character});

  @override
  State<AbilityFormScreen> createState() => _AbilityFormScreenState();
}

class _AbilityFormScreenState extends State<AbilityFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController attackBonusController;
  late final TextEditingController maxUsesController;
  late final TextEditingController notesController;

  late AbilityActionType actionType;
  late AbilityType abilityType;

  bool requiresAttackRoll = false;
  bool proficient = true;

  late List<AbilityEffect> effects;

  late List<CharacterEffect> linkedEffects;

  bool get editing => widget.ability != null;

  String? selectedResourceId;

  late final TextEditingController resourceCostController;

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

    maxUsesController = TextEditingController(text: '${ability?.maxUses ?? 0}');

    notesController = TextEditingController(text: ability?.notes ?? '');

    actionType = ability?.actionType ?? AbilityActionType.action;

    abilityType = ability?.abilityType ?? AbilityType.strength;

    requiresAttackRoll = ability?.requiresAttackRoll ?? false;

    proficient = ability?.proficient ?? true;

    /*
     * Copia profunda.
     *
     * No queremos modificar la habilidad real
     * hasta pulsar Guardar.
     */
    effects = ability?.effects.map(_cloneEffect).toList() ?? [];

    linkedEffects =
        ability?.linkedEffects
            .map((effect) => CharacterEffect.fromMap(effect.toMap()))
            .toList() ??
        [];

    selectedResourceId = widget.ability?.resourceId;

    resourceCostController = TextEditingController(
      text: '${widget.ability?.resourceCost ?? 0}',
    );
  }

  AbilityEffect _cloneEffect(AbilityEffect effect) {
    return AbilityEffect(
      id: effect.id,
      name: effect.name,
      effectType: effect.effectType,

      // =========================================================
      // NUEVO SISTEMA: PARTES / GRUPOS DE DAÑO
      // =========================================================
      parts: effect.parts
          .map(
            (part) => AbilityEffectPart(
              id: part.id,

              dicePools: part.dicePools
                  .map((pool) => DicePool(count: pool.count, sides: pool.sides))
                  .toList(),

              abilityModifierMultipliers: Map<AbilityType, int>.from(
                part.abilityModifierMultipliers,
              ),

              resourceValueMultipliers: Map<String, int>.from(
                part.resourceValueMultipliers,
              ),

              flatBonus: part.flatBonus,

              typeName: part.typeName,
            ),
          )
          .toList(),

      // =========================================================
      // LEGACY
      // =========================================================
      dicePools: effect.dicePools
          .map((pool) => DicePool(count: pool.count, sides: pool.sides))
          .toList(),

      abilityModifierMultipliers: Map<AbilityType, int>.from(
        effect.abilityModifierMultipliers,
      ),

      legacyAddAbilityModifier: effect.legacyAddAbilityModifier,

      effectBonus: effect.effectBonus,

      effectTypeName: effect.effectTypeName,

      usesSavingThrow: effect.usesSavingThrow,

      savingThrowAbility: effect.savingThrowAbility,

      saveDcBonus: effect.saveDcBonus,

      saveSuccessEffect: effect.saveSuccessEffect,
    );
  }

  void addEffect() {
    setState(() {
      effects.add(
        AbilityEffect(
          id: '${DateTime.now().microsecondsSinceEpoch}_effect',

          name: '',

          effectType: AbilityEffectType.damage,

          // No forzamos dados.
          //
          // Ahora son válidos:
          // 2×SAB
          // +5
          // SAB + CAR
          // etc.
          dicePools: [],

          abilityModifierMultipliers: {},

          legacyAddAbilityModifier: false,

          effectBonus: 0,

          saveSuccessEffect: SaveSuccessEffect.half,
        ),
      );
    });
  }

  void updateEffect(int index, AbilityEffect effect) {
    if (index < 0 || index >= effects.length) {
      return;
    }

    setState(() {
      effects[index] = effect;
    });
  }

  void removeEffect(int index) {
    if (index < 0 || index >= effects.length) {
      return;
    }

    setState(() {
      effects.removeAt(index);
    });
  }

  void moveEffectUp(int index) {
    if (index <= 0 || index >= effects.length) {
      return;
    }

    setState(() {
      final effect = effects.removeAt(index);

      effects.insert(index - 1, effect);
    });
  }

  void moveEffectDown(int index) {
    if (index < 0 || index >= effects.length - 1) {
      return;
    }

    setState(() {
      final effect = effects.removeAt(index);

      effects.insert(index + 1, effect);
    });
  }

  // ===========================================================================
  // EFECTOS VINCULADOS
  // ===========================================================================

  Future<void> addLinkedEffect() async {
    final result = await Navigator.push<CharacterEffect>(
      context,
      MaterialPageRoute(builder: (_) => const EffectFormScreen()),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      linkedEffects.add(CharacterEffect.fromMap(result.toMap()));
    });
  }

  Future<void> editLinkedEffect(int index) async {
    if (index < 0 || index >= linkedEffects.length) {
      return;
    }

    final copy = CharacterEffect.fromMap(linkedEffects[index].toMap());

    final result = await Navigator.push<CharacterEffect>(
      context,
      MaterialPageRoute(builder: (_) => EffectFormScreen(effect: copy)),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      linkedEffects[index] = CharacterEffect.fromMap(result.toMap());
    });
  }

  void removeLinkedEffect(int index) {
    if (index < 0 || index >= linkedEffects.length) {
      return;
    }

    setState(() {
      linkedEffects.removeAt(index);
    });
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

      if (maxUses == 0) {
        currentUses = 0;
      } else if (currentUses > maxUses) {
        currentUses = maxUses;
      }
    }

    /*
     * Compatibilidad con el sistema antiguo.
     *
     * CharacterAbility todavía conserva
     * algunos campos legacy.
     *
     * El sistema real trabaja con effects.
     */

    final firstEffect = effects.isNotEmpty ? effects.first : null;

    final firstPart = firstEffect != null && firstEffect.parts.isNotEmpty
        ? firstEffect.parts.first
        : null;

    /*
     * Los campos legacy se generan únicamente
     * como compatibilidad.
     *
     * La fuente real de datos son:
     *
     * effects -> parts
     */
    final legacyAddAbilityModifier =
        firstPart != null &&
        firstPart.abilityModifierMultipliers[abilityType] == 1 &&
        firstPart.abilityModifierMultipliers.length == 1;

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

      // ============================================================
      // NUEVO SISTEMA
      // ============================================================
      effects: effects.map(_cloneEffect).toList(),

      linkedEffects: linkedEffects
          .map((effect) => CharacterEffect.fromMap(effect.toMap()))
          .toList(),

      // ============================================================
      // LEGACY
      // ============================================================
      effectType: firstEffect?.effectType ?? AbilityEffectType.none,

      dicePools:
          firstPart?.dicePools
              .map((pool) => DicePool(count: pool.count, sides: pool.sides))
              .toList() ??
          [],

      addAbilityModifierToEffect: legacyAddAbilityModifier,

      effectBonus: firstPart?.flatBonus ?? 0,

      effectTypeName: firstPart?.typeName ?? '',

      usesSavingThrow: firstEffect?.usesSavingThrow ?? false,

      savingThrowAbility:
          firstEffect?.savingThrowAbility ?? AbilityType.dexterity,

      saveDcBonus: firstEffect?.saveDcBonus ?? 0,

      // ============================================================
      // USOS
      // ============================================================
      maxUses: maxUses,

      currentUses: currentUses,

      notes: notesController.text.trim(),

      resourceId: selectedResourceId,

      resourceCost: selectedResourceId != null
          ? (int.tryParse(resourceCostController.text) ?? 1)
          : 0,
    );

    Navigator.pop(context, ability);
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    attackBonusController.dispose();
    maxUsesController.dispose();
    notesController.dispose();
    resourceCostController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar habilidad' : 'Nueva habilidad'),
        actions: [
          IconButton(
            tooltip: 'Guardar',
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
              AbilityGeneralSection(
                nameController: nameController,
                descriptionController: descriptionController,
                actionType: actionType,
                abilityType: abilityType,

                onActionTypeChanged: (value) {
                  setState(() {
                    actionType = value;
                  });
                },

                onAbilityTypeChanged: (value) {
                  setState(() {
                    abilityType = value;
                  });
                },
              ),

              const SizedBox(height: 28),

              AbilityAttackSection(
                requiresAttackRoll: requiresAttackRoll,
                proficient: proficient,
                attackBonusController: attackBonusController,

                onRequiresAttackChanged: (value) {
                  setState(() {
                    requiresAttackRoll = value;
                  });
                },

                onProficientChanged: (value) {
                  setState(() {
                    proficient = value;
                  });
                },
              ),

              const SizedBox(height: 28),

              AbilityEffectsSection(
                effects: effects,
                onAddEffect: addEffect,
                onEffectChanged: updateEffect,
                onRemoveEffect: removeEffect,
                onMoveUp: moveEffectUp,
                onMoveDown: moveEffectDown,
                resources:
                    widget.character?.resources ?? const <CharacterResource>[],
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Efectos vinculados',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  IconButton.filledTonal(
                    tooltip: 'Añadir efecto vinculado',
                    onPressed: addLinkedEffect,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                'Estados y efectos que esta habilidad puede aplicar al personaje.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 12),

              if (linkedEffects.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Text(
                          'Esta habilidad no aplica efectos vinculados.',
                        ),
                      ),
                    ],
                  ),
                )
              else
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < linkedEffects.length; i++) ...[
                        _LinkedEffectTile(
                          effect: linkedEffects[i],

                          onEdit: () {
                            editLinkedEffect(i);
                          },

                          onDelete: () {
                            removeLinkedEffect(i);
                          },
                        ),

                        if (i < linkedEffects.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),

              if (widget.character != null &&
                  widget.character!.resources.isNotEmpty) ...[
                const SizedBox(height: 24),

                Text(
                  'Coste de recurso',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Opcional. La habilidad consumirá este recurso cuando se utilice.',
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String?>(
                  initialValue: selectedResourceId,
                  decoration: const InputDecoration(
                    labelText: 'Recurso',
                    prefixIcon: Icon(Icons.battery_charging_full_rounded),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Sin recurso'),
                    ),

                    ...widget.character!.resources.map((resource) {
                      return DropdownMenuItem<String?>(
                        value: resource.id,
                        child: Row(
                          children: [
                            Icon(
                              resource.icon,
                              color: resource.color,
                              size: 20,
                            ),

                            const SizedBox(width: 8),

                            Text(resource.name),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedResourceId = value;

                      if (value == null) {
                        resourceCostController.text = '0';
                      } else if ((int.tryParse(resourceCostController.text) ??
                              0) <=
                          0) {
                        resourceCostController.text = '1';
                      }
                    });
                  },
                ),

                if (selectedResourceId != null) ...[
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: resourceCostController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Coste',
                      prefixIcon: Icon(Icons.remove_circle_outline_rounded),
                    ),
                    validator: (value) {
                      if (selectedResourceId == null) {
                        return null;
                      }

                      final parsed = int.tryParse(value ?? '');

                      if (parsed == null || parsed < 1) {
                        return 'Introduce un coste mínimo de 1';
                      }

                      return null;
                    },
                  ),
                ],
              ],

              const SizedBox(height: 28),

              AbilityUsesSection(
                maxUsesController: maxUsesController,
                notesController: notesController,
              ),

              const SizedBox(height: 30),

              FilledButton.icon(
                onPressed: saveAbility,
                icon: const Icon(Icons.save_rounded),
                label: Text(editing ? 'Guardar cambios' : 'Crear habilidad'),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkedEffectTile extends StatelessWidget {
  final CharacterEffect effect;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LinkedEffectTile({
    required this.effect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onEdit,

      leading: CircleAvatar(child: Icon(_iconForType(effect.type))),

      title: Text(
        effect.name.trim().isNotEmpty ? effect.name : 'Efecto sin nombre',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),

      subtitle: Text(_subtitle(effect)),

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
    );
  }

  static IconData _iconForType(CharacterEffectType type) {
    switch (type) {
      case CharacterEffectType.buff:
        return Icons.trending_up_rounded;

      case CharacterEffectType.debuff:
        return Icons.trending_down_rounded;

      case CharacterEffectType.condition:
        return Icons.warning_amber_rounded;

      case CharacterEffectType.neutral:
        return Icons.auto_awesome_rounded;
    }
  }

  static String _subtitle(CharacterEffect effect) {
    final pieces = <String>[];

    if (effect.description.trim().isNotEmpty) {
      pieces.add(effect.description.trim());
    }

    switch (effect.durationType) {
      case CharacterEffectDurationType.permanent:
        pieces.add('Permanente');
        break;

      case CharacterEffectDurationType.turns:
        pieces.add(
          '${effect.maxDuration} '
          '${effect.maxDuration == 1 ? 'turno' : 'turnos'}',
        );
        break;

      case CharacterEffectDurationType.rounds:
        pieces.add(
          '${effect.maxDuration} '
          '${effect.maxDuration == 1 ? 'ronda' : 'rondas'}',
        );
        break;

      case CharacterEffectDurationType.minutes:
        pieces.add('${effect.maxDuration} min');
        break;

      case CharacterEffectDurationType.custom:
        if (effect.durationNote.trim().isNotEmpty) {
          pieces.add(effect.durationNote.trim());
        } else {
          pieces.add('Duración personalizada');
        }
        break;
    }

    return pieces.join(' · ');
  }
}
