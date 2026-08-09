import 'package:flutter/material.dart';

import '../models/ability.dart';
import '../models/dice_pool.dart';
import '../models/skill.dart';

import '../widgets/abilities/ability_form/ability_general_section.dart';
import '../widgets/abilities/ability_form/ability_attack_section.dart';
import '../widgets/abilities/ability_form/ability_effects_section.dart';
import '../widgets/abilities/ability_form/ability_uses_section.dart';

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
  late final TextEditingController maxUsesController;
  late final TextEditingController notesController;

  late AbilityActionType actionType;
  late AbilityType abilityType;

  bool requiresAttackRoll = false;
  bool proficient = true;

  late List<AbilityEffect> effects;

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
  }

  AbilityEffect _cloneEffect(AbilityEffect effect) {
    return AbilityEffect(
      id: effect.id,
      name: effect.name,
      effectType: effect.effectType,

      dicePools: effect.dicePools
          .map((pool) => DicePool(count: pool.count, sides: pool.sides))
          .toList(),

      addAbilityModifierToEffect: effect.addAbilityModifierToEffect,

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
          dicePools: [DicePool(count: 1, sides: 6)],
          addAbilityModifierToEffect: false,
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
     * CharacterAbility todavía tiene los campos
     * effectType, dicePools, savingThrowAbility...
     *
     * Los rellenamos usando el primer efecto.
     *
     * El sistema nuevo trabajará con effects.
     */
    final firstEffect = effects.isNotEmpty ? effects.first : null;

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

      // ============================
      // NUEVO SISTEMA
      // ============================
      effects: effects.map(_cloneEffect).toList(),

      // ============================
      // LEGACY
      // ============================
      effectType: firstEffect?.effectType ?? AbilityEffectType.none,

      dicePools:
          firstEffect?.dicePools
              .map((pool) => DicePool(count: pool.count, sides: pool.sides))
              .toList() ??
          [],

      addAbilityModifierToEffect:
          firstEffect?.addAbilityModifierToEffect ?? false,

      effectBonus: firstEffect?.effectBonus ?? 0,

      effectTypeName: firstEffect?.effectTypeName ?? '',

      usesSavingThrow: firstEffect?.usesSavingThrow ?? false,

      savingThrowAbility:
          firstEffect?.savingThrowAbility ?? AbilityType.dexterity,

      saveDcBonus: firstEffect?.saveDcBonus ?? 0,

      // ============================
      // USOS
      // ============================
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
              ),

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
