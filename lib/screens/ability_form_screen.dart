import 'package:flutter/material.dart';

import 'effect_form_screen.dart';

import '../models/action_hit_behavior.dart';
import '../models/action_linked_effect.dart';
import '../models/ability_effect_part.dart';
import '../models/character.dart';
import '../models/ability.dart';
import '../models/dice_pool.dart';
import '../models/skill.dart';
import '../models/character_resource.dart';
import '../models/action_external_requirement.dart';
import '../models/action_cost.dart';
import '../models/character_effect.dart';

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

  late AbilityTargetType targetType;

  late AbilityTargetResolutionMode targetResolutionMode;

  bool requiresAttackRoll = false;
  bool proficient = true;
  late int criticalMinimumNaturalRoll;
  late bool empoweredCritical;

  late List<AbilityEffect> effects;

  late List<ActionLinkedEffect> linkedEffects;

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

    targetType = ability?.targetType ?? AbilityTargetType.external;

    targetResolutionMode =
        ability?.targetResolutionMode ?? AbilityTargetResolutionMode.shared;

    abilityType = ability?.abilityType ?? AbilityType.strength;

    requiresAttackRoll = ability?.requiresAttackRoll ?? false;

    proficient = ability?.proficient ?? true;

    criticalMinimumNaturalRoll = ability?.criticalMinimumNaturalRoll ?? 20;

    empoweredCritical = ability?.empoweredCritical ?? false;

    /*
     * Copia profunda.
     *
     * No queremos modificar la habilidad real
     * hasta pulsar Guardar.
     */
    effects = ability?.effects.map(_cloneEffect).toList() ?? [];

    linkedEffects =
        widget.ability?.linkedEffects
            .map(
              (linkedEffect) => ActionLinkedEffect(
                effect: CharacterEffect.fromMap(linkedEffect.effect.toMap()),
                target: linkedEffect.target,
                hitBehavior: linkedEffect.hitBehavior,
                sourceEffectId: linkedEffect.sourceEffectId,
                saveBehavior: linkedEffect.saveBehavior,
              ),
            )
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

              costs: part.costs
                  .map((cost) => ActionCost.fromMap(cost.toMap()))
                  .toList(),

              condition: part.condition?.copy(),

              externalRequirements: part.externalRequirements
                  .map(
                    (requirement) =>
                        ActionExternalRequirement.fromMap(requirement.toMap()),
                  )
                  .toList(),

              optional: part.optional,

              optionalGroupId: part.optionalGroupId,

              optionalLabel: part.optionalLabel,

              hitBehavior: part.hitBehavior,

              participatesInCritical: part.participatesInCritical,
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

      extraParticipatesInCritical: effect.extraParticipatesInCritical,

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

    final previousEffect = effects[index];

    setState(() {
      effects[index] = effect;

      // =========================================================================
      // ID CAMBIADO
      //
      // Normalmente el ID debería conservarse durante una edición.
      // Si por algún motivo cambia, actualizamos las referencias vinculadas.
      // =========================================================================

      if (previousEffect.id != effect.id) {
        for (var i = 0; i < linkedEffects.length; i++) {
          final linkedEffect = linkedEffects[i];

          if (linkedEffect.normalizedSourceEffectId != previousEffect.id) {
            continue;
          }

          linkedEffects[i] = ActionLinkedEffect(
            effect: linkedEffect.effect,
            target: linkedEffect.target,
            sourceEffectId: effect.id,
            hitBehavior: linkedEffect.hitBehavior,
            saveBehavior: linkedEffect.saveBehavior,
          );
        }
      }
    });
  }

  void removeEffect(int index) {
    if (index < 0 || index >= effects.length) {
      return;
    }

    final removedEffectId = effects[index].id;

    setState(() {
      effects.removeAt(index);

      // =========================================================================
      // LIMPIAR VÍNCULOS HUÉRFANOS
      //
      // Un ActionLinkedEffect puede depender de un AbilityEffect concreto.
      //
      // Si ese AbilityEffect desaparece, el vínculo deja de tener un origen
      // válido. No eliminamos el linked effect: simplemente lo dejamos sin origen.
      // =========================================================================

      for (var i = 0; i < linkedEffects.length; i++) {
        final linkedEffect = linkedEffects[i];

        if (linkedEffect.normalizedSourceEffectId != removedEffectId) {
          continue;
        }

        linkedEffects[i] = ActionLinkedEffect(
          effect: linkedEffect.effect,
          target: linkedEffect.target,
          sourceEffectId: null,
          hitBehavior: linkedEffect.hitBehavior,
          saveBehavior: linkedEffect.saveBehavior,
        );
      }
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

  AbilityEffect? _linkedEffectSourceEffect(ActionLinkedEffect linkedEffect) {
    final sourceId = _validatedLinkedEffectSourceId(linkedEffect);

    if (sourceId == null) {
      return null;
    }

    for (final effect in effects) {
      if (effect.id == sourceId) {
        return effect;
      }
    }

    return null;
  }

  String? _validatedLinkedEffectSourceId(ActionLinkedEffect linkedEffect) {
    final sourceId = linkedEffect.normalizedSourceEffectId;

    if (sourceId == null) {
      return null;
    }

    final exists = effects.any((effect) => effect.id == sourceId);

    return exists ? sourceId : null;
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
      linkedEffects.add(
        ActionLinkedEffect(
          effect: CharacterEffect.fromMap(result.toMap()),
          target: ActionLinkedEffectTarget.actionTarget,
        ),
      );
    });
  }

  Future<void> editLinkedEffect(int index) async {
    if (index < 0 || index >= linkedEffects.length) {
      return;
    }

    final linkedEffect = linkedEffects[index];

    final copy = CharacterEffect.fromMap(linkedEffect.effect.toMap());

    final result = await Navigator.push<CharacterEffect>(
      context,
      MaterialPageRoute(builder: (_) => EffectFormScreen(effect: copy)),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      linkedEffects[index] = ActionLinkedEffect(
        effect: CharacterEffect.fromMap(result.toMap()),
        target: linkedEffect.target,
        sourceEffectId: linkedEffect.sourceEffectId,
        hitBehavior: linkedEffect.hitBehavior,
        saveBehavior: linkedEffect.saveBehavior,
      );
    });
  }

  void updateLinkedEffectHitBehavior(
    int index,
    ActionHitBehavior? hitBehavior,
  ) {
    if (index < 0 || index >= linkedEffects.length) {
      return;
    }

    final linkedEffect = linkedEffects[index];

    setState(() {
      linkedEffects[index] = ActionLinkedEffect(
        effect: linkedEffect.effect,
        target: linkedEffect.target,
        sourceEffectId: linkedEffect.sourceEffectId,
        hitBehavior: hitBehavior,
        saveBehavior: linkedEffect.saveBehavior,
      );
    });
  }

  void updateLinkedEffectTarget(int index, ActionLinkedEffectTarget target) {
    if (index < 0 || index >= linkedEffects.length) {
      return;
    }

    final linkedEffect = linkedEffects[index];

    setState(() {
      linkedEffects[index] = ActionLinkedEffect(
        effect: linkedEffect.effect,
        target: target,
        sourceEffectId: linkedEffect.sourceEffectId,
        hitBehavior: linkedEffect.hitBehavior,
        saveBehavior: linkedEffect.saveBehavior,
      );
    });
  }

  void updateLinkedEffectSource(int index, String? sourceEffectId) {
    if (index < 0 || index >= linkedEffects.length) {
      return;
    }

    final linkedEffect = linkedEffects[index];

    final normalizedSourceId = sourceEffectId?.trim().isNotEmpty == true
        ? sourceEffectId!.trim()
        : null;

    AbilityEffect? sourceEffect;

    if (normalizedSourceId != null) {
      for (final effect in effects) {
        if (effect.id == normalizedSourceId) {
          sourceEffect = effect;
          break;
        }
      }
    }

    final sourceHasSavingThrow = sourceEffect?.usesSavingThrow ?? false;

    setState(() {
      linkedEffects[index] = ActionLinkedEffect(
        effect: linkedEffect.effect,
        target: linkedEffect.target,
        sourceEffectId: normalizedSourceId,
        hitBehavior: linkedEffect.hitBehavior,

        saveBehavior: sourceHasSavingThrow
            ? linkedEffect.saveBehavior
            : ActionLinkedEffectSaveBehavior.ignore,
      );
    });
  }

  void updateLinkedEffectSaveBehavior(
    int index,
    ActionLinkedEffectSaveBehavior saveBehavior,
  ) {
    if (index < 0 || index >= linkedEffects.length) {
      return;
    }

    final linkedEffect = linkedEffects[index];

    setState(() {
      linkedEffects[index] = ActionLinkedEffect(
        effect: linkedEffect.effect,
        target: linkedEffect.target,
        sourceEffectId: linkedEffect.sourceEffectId,
        hitBehavior: linkedEffect.hitBehavior,
        saveBehavior: saveBehavior,
      );
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

  ActionLinkedEffectSaveBehavior _validatedLinkedEffectSaveBehavior(
    ActionLinkedEffect linkedEffect,
  ) {
    final sourceEffect = _linkedEffectSourceEffect(linkedEffect);

    if (sourceEffect == null || !sourceEffect.usesSavingThrow) {
      return ActionLinkedEffectSaveBehavior.ignore;
    }

    return linkedEffect.saveBehavior;
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

      targetType: targetType,

      targetResolutionMode: targetResolutionMode,

      requiresAttackRoll: requiresAttackRoll,

      abilityType: abilityType,

      proficient: proficient,

      attackBonus: int.tryParse(attackBonusController.text) ?? 0,

      criticalMinimumNaturalRoll: criticalMinimumNaturalRoll,

      empoweredCritical: empoweredCritical,

      // ============================================================
      // NUEVO SISTEMA
      // ============================================================
      effects: effects.map(_cloneEffect).toList(),

      linkedEffects: linkedEffects
          .map(
            (linkedEffect) => ActionLinkedEffect(
              effect: CharacterEffect.fromMap(linkedEffect.effect.toMap()),
              target: linkedEffect.target,
              hitBehavior: linkedEffect.hitBehavior,
              sourceEffectId: linkedEffect.sourceEffectId,
              saveBehavior: _validatedLinkedEffectSaveBehavior(linkedEffect),
            ),
          )
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

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Objetivos',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<AbilityTargetType>(
                        initialValue: targetType,

                        decoration: const InputDecoration(
                          labelText: 'Tipo de objetivo',
                          border: OutlineInputBorder(),
                        ),

                        items: AbilityTargetType.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value.label),
                              ),
                            )
                            .toList(),

                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            targetType = value;

                            if (!targetType.supportsMultipleTargets) {
                              targetResolutionMode =
                                  AbilityTargetResolutionMode.shared;
                            }
                          });
                        },
                      ),

                      if (targetType.supportsMultipleTargets) ...[
                        const SizedBox(height: 16),

                        DropdownButtonFormField<AbilityTargetResolutionMode>(
                          initialValue: targetResolutionMode,

                          decoration: const InputDecoration(
                            labelText: 'Resolución',
                            border: OutlineInputBorder(),
                          ),

                          items: AbilityTargetResolutionMode.values
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value.label),
                                ),
                              )
                              .toList(),

                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              targetResolutionMode = value;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              AbilityAttackSection(
                requiresAttackRoll: requiresAttackRoll,
                proficient: proficient,
                attackBonusController: attackBonusController,

                criticalMinimumNaturalRoll: criticalMinimumNaturalRoll,

                empoweredCritical: empoweredCritical,

                onRequiresAttackChanged: (value) {
                  setState(() {
                    requiresAttackRoll = value;
                  });
                },

                onCriticalMinimumNaturalRollChanged: (value) {
                  setState(() {
                    criticalMinimumNaturalRoll = value;
                  });
                },

                onEmpoweredCriticalChanged: (value) {
                  setState(() {
                    empoweredCritical = value;
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
                'Estados y efectos adicionales que puede aplicar esta habilidad.',
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
                          linkedEffect: linkedEffects[i],
                          abilityEffects: effects,

                          onTargetChanged: (target) {
                            updateLinkedEffectTarget(i, target);
                          },

                          onSourceEffectChanged: (effectId) {
                            updateLinkedEffectSource(i, effectId);
                          },

                          onHitBehaviorChanged: (behavior) {
                            updateLinkedEffectHitBehavior(i, behavior);
                          },

                          requiresAttackRoll: requiresAttackRoll,

                          onSaveBehaviorChanged: (behavior) {
                            updateLinkedEffectSaveBehavior(i, behavior);
                          },

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
  final ActionLinkedEffect linkedEffect;

  final List<AbilityEffect> abilityEffects;

  final ValueChanged<ActionLinkedEffectTarget> onTargetChanged;

  final ValueChanged<String?> onSourceEffectChanged;

  final ValueChanged<ActionLinkedEffectSaveBehavior> onSaveBehaviorChanged;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool requiresAttackRoll;

  final ValueChanged<ActionHitBehavior?> onHitBehaviorChanged;

  const _LinkedEffectTile({
    required this.linkedEffect,
    required this.abilityEffects,
    required this.onTargetChanged,
    required this.onSourceEffectChanged,
    required this.onSaveBehaviorChanged,
    required this.onEdit,
    required this.onDelete,
    required this.requiresAttackRoll,
    required this.onHitBehaviorChanged,
  });

  String _hitBehaviorDescription(
    ActionLinkedEffect linkedEffect, {
    required bool requiresAttackRoll,
  }) {
    if (!requiresAttackRoll) {
      return 'Esta habilidad no utiliza tirada de ataque, '
          'así que hit/miss no afecta a este efecto.';
    }

    final explicit = linkedEffect.hitBehavior;

    if (explicit != null) {
      return explicit.description;
    }

    switch (linkedEffect.target) {
      case ActionLinkedEffectTarget.self:
        return 'Automático: al aplicarse sobre ti mismo, '
            'no depende del impacto.';

      case ActionLinkedEffectTarget.actionTarget:
        return 'Automático: requiere impactar al objetivo '
            'de la acción.';

      case ActionLinkedEffectTarget.externalTargets:
        return 'Automático: requiere impactar a cada '
            'objetivo externo.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final effect = linkedEffect.effect;

    AbilityEffect? sourceEffect;

    final sourceEffectId = linkedEffect.normalizedSourceEffectId;

    if (sourceEffectId != null) {
      for (final candidate in abilityEffects) {
        if (candidate.id == sourceEffectId) {
          sourceEffect = candidate;
          break;
        }
      }
    }

    final sourceHasSavingThrow = sourceEffect?.usesSavingThrow ?? false;

    final effectiveSaveBehavior = sourceHasSavingThrow
        ? linkedEffect.saveBehavior
        : ActionLinkedEffectSaveBehavior.ignore;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(child: Icon(_iconForType(effect.type))),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      effect.name.trim().isNotEmpty
                          ? effect.name
                          : 'Efecto sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),

                    finalSubtitle(context, effect),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Editar efecto',
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

          const SizedBox(height: 14),

          DropdownButtonFormField<ActionLinkedEffectTarget>(
            initialValue: linkedEffect.target,
            decoration: InputDecoration(
              labelText: 'Aplicar efecto a',
              prefixIcon: Icon(_targetIcon(linkedEffect.target)),
              border: const OutlineInputBorder(),
            ),
            items: ActionLinkedEffectTarget.values.map((target) {
              return DropdownMenuItem(
                value: target,
                child: Row(
                  children: [
                    Icon(_targetIcon(target), size: 19),

                    const SizedBox(width: 9),

                    Text(target.label),
                  ],
                ),
              );
            }).toList(),
            onChanged: (target) {
              if (target == null) {
                return;
              }

              onTargetChanged(target);
            },
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<ActionHitBehavior?>(
            key: ValueKey(
              'linked_hit_'
              '${linkedEffect.target.name}_'
              '${linkedEffect.hitBehavior?.name ?? 'auto'}',
            ),

            initialValue: linkedEffect.hitBehavior,

            decoration: const InputDecoration(
              labelText: 'Si hay tirada de ataque',
              prefixIcon: Icon(Icons.gps_fixed_rounded),
              border: OutlineInputBorder(),
            ),

            items: [
              const DropdownMenuItem<ActionHitBehavior?>(
                value: null,
                child: Text('Automático'),
              ),

              ...ActionHitBehavior.values.map(
                (behavior) => DropdownMenuItem<ActionHitBehavior?>(
                  value: behavior,
                  child: Text(behavior.label),
                ),
              ),
            ],

            onChanged: requiresAttackRoll ? onHitBehaviorChanged : null,
          ),

          const SizedBox(height: 7),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _hitBehaviorDescription(
                linkedEffect,
                requiresAttackRoll: requiresAttackRoll,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: 7),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              linkedEffect.target.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<String?>(
            initialValue: linkedEffect.normalizedSourceEffectId,
            decoration: const InputDecoration(
              labelText: 'Efecto de origen',
              prefixIcon: Icon(Icons.account_tree_rounded),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Ninguno'),
              ),

              ...abilityEffects.map(
                (effect) => DropdownMenuItem<String?>(
                  value: effect.id,
                  child: Text(
                    effect.name.trim().isNotEmpty
                        ? effect.name
                        : 'Efecto sin nombre',
                  ),
                ),
              ),
            ],
            onChanged: onSourceEffectChanged,
          ),

          const SizedBox(height: 7),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              sourceEffect == null
                  ? 'Este efecto vinculado no depende de un efecto concreto de la habilidad.'
                  : sourceHasSavingThrow
                  ? 'La salvación de este efecto de origen puede afectar al efecto vinculado.'
                  : 'Este efecto de origen no utiliza salvación.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<ActionLinkedEffectSaveBehavior>(
            key: ValueKey(
              'linked_save_${sourceEffectId ?? 'none'}_$sourceHasSavingThrow',
            ),

            initialValue: effectiveSaveBehavior,

            decoration: const InputDecoration(
              labelText: 'Si hay salvación',
              prefixIcon: Icon(Icons.shield_outlined),
              border: OutlineInputBorder(),
            ),

            items: ActionLinkedEffectSaveBehavior.values.map((behavior) {
              return DropdownMenuItem(
                value: behavior,
                child: Text(behavior.label),
              );
            }).toList(),

            onChanged: !sourceHasSavingThrow
                ? null
                : (behavior) {
                    if (behavior == null) {
                      return;
                    }

                    onSaveBehaviorChanged(behavior);
                  },
          ),

          const SizedBox(height: 7),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              sourceHasSavingThrow
                  ? effectiveSaveBehavior.description
                  : 'No hay comportamiento de salvación para este vínculo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget finalSubtitle(BuildContext context, CharacterEffect effect) {
    final subtitle = _subtitle(effect);

    if (subtitle.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  static IconData _targetIcon(ActionLinkedEffectTarget target) {
    switch (target) {
      case ActionLinkedEffectTarget.actionTarget:
        return Icons.gps_fixed_rounded;

      case ActionLinkedEffectTarget.self:
        return Icons.person_rounded;

      case ActionLinkedEffectTarget.externalTargets:
        return Icons.groups_rounded;
    }
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

    final description = effect.description.trim();

    if (description.isNotEmpty) {
      pieces.add(description);
    }

    pieces.add(effect.durationText);

    return pieces.join(' · ');
  }
}
