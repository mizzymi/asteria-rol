import 'package:flutter/material.dart';

import '../models/character.dart';
import '../models/character_effect.dart';
import '../models/critical_damage_bonus.dart';
import '../models/damage_bonus.dart';
import '../models/dice_pool.dart';
import '../models/healing_bonus.dart';
import '../models/passive.dart';
import '../models/passive_resource_modifier.dart';
import '../models/skill.dart';

import '../models/formulas/character_formula.dart';
import '../models/formulas/formula_bonus.dart';
import '../models/formulas/formula_modifier.dart';

import '../services/passive_display_formatter.dart';

import '../widgets/forms/common/form_section_header.dart';

import '../widgets/passive_form/bonuses/critical_damage_bonus_editor_dialog.dart';
import '../widgets/passive_form/bonuses/damage_bonus_editor_dialog.dart';
import '../widgets/passive_form/bonuses/healing_bonus_editor_dialog.dart';
import '../widgets/passive_form/bonuses/passive_extra_bonuses_section.dart';

import '../widgets/passive_form/charges/passive_charges_section.dart';

import '../widgets/passive_form/effects/passive_linked_effects_section.dart';

import '../widgets/passive_form/general/passive_general_bonuses_section.dart';
import '../widgets/passive_form/general/passive_identity_section.dart';
import '../widgets/passive_form/general/passive_notes_section.dart';

import '../widgets/passive_form/resources/passive_resources_section.dart';
import '../widgets/passive_form/resources/resource_modifier_editor_dialog.dart';

import '../widgets/passive_form/roll/passive_own_roll_section.dart';

import '../widgets/passive_form/stats/passive_stats_section.dart';

import '../widgets/passive_form/triggers/passive_trigger_editor_dialog.dart';
import '../widgets/passive_form/triggers/passive_triggers_section.dart';

import 'effect_form_screen.dart';

// =============================================================================
// SECCIONES
// =============================================================================

enum _PassiveFormSection {
  stats,
  generalBonuses,
  resources,
  charges,
  triggers,
  extraEffects,
  linkedEffects,
  ownRoll,
  notes,
}

// =============================================================================
// SCREEN
// =============================================================================

class PassiveFormScreen extends StatefulWidget {
  final CharacterPassive? passive;

  final Character? character;

  const PassiveFormScreen({super.key, this.passive, this.character});

  @override
  State<PassiveFormScreen> createState() => _PassiveFormScreenState();
}

// =============================================================================
// STATE
// =============================================================================

class _PassiveFormScreenState extends State<PassiveFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ===========================================================================
  // IDENTIDAD
  // ===========================================================================

  late final TextEditingController nameController;

  late final TextEditingController descriptionController;

  late final TextEditingController notesController;

  late PassiveSourceType sourceType;

  bool enabled = true;

  // ===========================================================================
  // BONUS GENERALES
  // ===========================================================================

  late final TextEditingController armorClassController;

  late final TextEditingController initiativeController;

  late final TextEditingController speedController;

  late final TextEditingController maxHealthController;

  late final TextEditingController attackController;

  late final TextEditingController armorClassFormulaController;

  late final TextEditingController initiativeFormulaController;

  late final TextEditingController speedFormulaController;

  late final TextEditingController maxHealthFormulaController;

  late final TextEditingController attackFormulaController;

  // ===========================================================================
  // STATS
  // ===========================================================================

  late Map<AbilityType, FormulaBonus> abilityScoreBonuses;

  late Map<AbilityType, FormulaBonus> abilityModifierBonuses;

  late Map<AbilityType, FormulaBonus> savingThrowBonuses;

  late Map<DndSkill, FormulaBonus> skillBonuses;

  // ===========================================================================
  // RECURSOS
  // ===========================================================================

  late List<PassiveResourceModifier> resourceModifiers;

  // ===========================================================================
  // CARGAS
  // ===========================================================================

  bool hasCharges = false;

  bool unlimitedCharges = false;

  late final TextEditingController maxChargesController;

  late final TextEditingController rechargeController;

  // ===========================================================================
  // TRIGGERS
  // ===========================================================================

  late List<PassiveTrigger> triggers;

  // ===========================================================================
  // BONUS EXTRA
  // ===========================================================================

  late List<DamageBonus> damageBonuses;

  late List<CriticalDamageBonus> criticalDamageBonuses;

  late List<HealingBonus> healingBonuses;

  late int criticalMinimumNaturalRoll;

  late bool empoweredCritical;

  // ===========================================================================
  // EFECTOS VINCULADOS
  // ===========================================================================

  late List<CharacterEffect> linkedEffects;

  // ===========================================================================
  // TIRADA PROPIA
  // ===========================================================================

  late List<DicePool> rollDicePools;

  late Map<AbilityType, int> rollAbilityModifierMultipliers;

  late final TextEditingController rollFlatBonusController;

  // ===========================================================================
  // UI
  // ===========================================================================

  final Set<_PassiveFormSection> expandedSections = {};

  late final String passiveId;

  bool get editing {
    return widget.passive != null;
  }

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    final passive = widget.passive;

    passiveId = passive?.id ?? DateTime.now().microsecondsSinceEpoch.toString();

    // =========================================================================
    // IDENTIDAD
    // =========================================================================

    nameController = TextEditingController(text: passive?.name ?? '');

    descriptionController = TextEditingController(
      text: passive?.description ?? '',
    );

    notesController = TextEditingController(text: passive?.notes ?? '');

    sourceType = passive?.sourceType ?? PassiveSourceType.custom;

    enabled = passive?.enabled ?? true;

    // =========================================================================
    // BONUS GENERALES
    // =========================================================================

    armorClassController = TextEditingController(
      text: '${passive?.armorClassBonus.flatValue ?? 0}',
    );

    initiativeController = TextEditingController(
      text: '${passive?.initiativeBonus.flatValue ?? 0}',
    );

    speedController = TextEditingController(
      text: '${passive?.speedBonus.flatValue ?? 0}',
    );

    maxHealthController = TextEditingController(
      text: '${passive?.maxHealthBonus.flatValue ?? 0}',
    );

    attackController = TextEditingController(
      text: '${passive?.attackBonus.flatValue ?? 0}',
    );

    armorClassFormulaController = TextEditingController(
      text: passive?.armorClassBonus.formula?.expression ?? '',
    );

    initiativeFormulaController = TextEditingController(
      text: passive?.initiativeBonus.formula?.expression ?? '',
    );

    speedFormulaController = TextEditingController(
      text: passive?.speedBonus.formula?.expression ?? '',
    );

    maxHealthFormulaController = TextEditingController(
      text: passive?.maxHealthBonus.formula?.expression ?? '',
    );

    attackFormulaController = TextEditingController(
      text: passive?.attackBonus.formula?.expression ?? '',
    );

    // =========================================================================
    // STATS BASE
    // =========================================================================

    abilityScoreBonuses = {
      for (final ability in AbilityType.values)
        ability: passive?.abilityScoreBonuses[ability] != null
            ? FormulaBonus.fromMap(
                passive!.abilityScoreBonuses[ability]!.toMap(),
              )
            : FormulaBonus(),
    };

    // =========================================================================
    // MODIFICADORES
    // =========================================================================

    abilityModifierBonuses = {
      for (final ability in AbilityType.values)
        ability: passive?.abilityModifierBonuses[ability] != null
            ? FormulaBonus.fromMap(
                passive!.abilityModifierBonuses[ability]!.toMap(),
              )
            : FormulaBonus(),
    };

    // =========================================================================
    // SALVACIONES
    // =========================================================================

    savingThrowBonuses = {
      for (final ability in AbilityType.values)
        ability: passive?.savingThrowBonuses[ability] != null
            ? FormulaBonus.fromMap(
                passive!.savingThrowBonuses[ability]!.toMap(),
              )
            : FormulaBonus(),
    };

    // =========================================================================
    // HABILIDADES
    // =========================================================================

    skillBonuses = {
      for (final skill in DndSkill.values)
        skill: passive?.skillBonuses[skill] != null
            ? FormulaBonus.fromMap(passive!.skillBonuses[skill]!.toMap())
            : FormulaBonus(),
    };

    // =========================================================================
    // RECURSOS
    // =========================================================================

    resourceModifiers =
        passive?.resourceModifiers
            .map(
              (modifier) => PassiveResourceModifier.fromMap(modifier.toMap()),
            )
            .toList() ??
        [];

    // =========================================================================
    // CARGAS
    // =========================================================================

    hasCharges = passive?.hasCharges ?? false;

    unlimitedCharges = passive?.hasUnlimitedCharges ?? false;

    maxChargesController = TextEditingController(
      text: '${passive?.maxCharges ?? 1}',
    );

    rechargeController = TextEditingController(
      text: passive?.rechargeDescription ?? '',
    );

    // =========================================================================
    // TRIGGERS
    // =========================================================================

    triggers =
        passive?.triggers
            .map((trigger) => PassiveTrigger.fromMap(trigger.toMap()))
            .toList() ??
        [];

    // =========================================================================
    // DAMAGE BONUS
    // =========================================================================

    damageBonuses =
        passive?.damageBonuses
            .map((bonus) => DamageBonus.fromMap(bonus.toMap()))
            .toList() ??
        [];

    // =========================================================================
    // CRITICAL BONUS
    // =========================================================================

    criticalDamageBonuses =
        passive?.criticalDamageBonuses
            .map((bonus) => CriticalDamageBonus.fromMap(bonus.toMap()))
            .toList() ??
        [];

    criticalMinimumNaturalRoll = passive?.criticalMinimumNaturalRoll ?? 20;

    empoweredCritical = passive?.empoweredCritical ?? false;

    // =========================================================================
    // HEALING BONUS
    // =========================================================================

    healingBonuses =
        passive?.healingBonuses
            .map((bonus) => HealingBonus.fromMap(bonus.toMap()))
            .toList() ??
        [];

    // =========================================================================
    // LINKED EFFECTS
    // =========================================================================

    linkedEffects =
        passive?.linkedEffects
            .map((effect) => CharacterEffect.fromMap(effect.toMap()))
            .toList() ??
        [];

    // =========================================================================
    // TIRADA PROPIA
    // =========================================================================

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

  // ===========================================================================
  // SECCIONES
  // ===========================================================================

  bool _sectionExpanded(_PassiveFormSection section) {
    return expandedSections.contains(section);
  }

  void _toggleSection(_PassiveFormSection section) {
    setState(() {
      if (expandedSections.contains(section)) {
        expandedSections.remove(section);
      } else {
        expandedSections.add(section);
      }
    });
  }

  Widget _section({
    required _PassiveFormSection section,
    required String title,
    required IconData icon,
    String? subtitle,
    Widget? trailing,
  }) {
    return FormSectionHeader(
      title: title,
      icon: icon,
      subtitle: subtitle,
      trailing: trailing,
      expanded: _sectionExpanded(section),
      onTap: () {
        _toggleSection(section);
      },
    );
  }

  // ===========================================================================
  // RECURSOS
  // ===========================================================================

  Future<void> addResourceModifier() async {
    final character = widget.character;

    if (character == null || character.resources.isEmpty) {
      return;
    }

    final result = await showResourceModifierEditorDialog(
      context,
      modifier: PassiveResourceModifier(
        id: '${DateTime.now().microsecondsSinceEpoch}_resource_modifier',
        resourceId: character.resources.first.id,
        target: PassiveResourceTarget.current,
        operation: FormulaModifierOperation.add,
        formula: CharacterFormula(expression: '0'),
      ),
      character: character,
      passive: widget.passive,
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      resourceModifiers.add(result);
    });
  }

  Future<void> editResourceModifier(int index) async {
    if (index < 0 || index >= resourceModifiers.length) {
      return;
    }

    final character = widget.character;

    if (character == null) {
      return;
    }

    final result = await showResourceModifierEditorDialog(
      context,
      modifier: PassiveResourceModifier.fromMap(
        resourceModifiers[index].toMap(),
      ),
      character: character,
      passive: widget.passive,
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      resourceModifiers[index] = result;
    });
  }

  // ===========================================================================
  // TRIGGERS
  // ===========================================================================

  Future<void> addTrigger() async {
    final trigger = PassiveTrigger(
      id: '${DateTime.now().microsecondsSinceEpoch}_trigger',

      event: PassiveTriggerEvent.enemyKilled,

      target: PassiveTriggerTarget.self,

      usageLimit: TriggerUsageLimit.unlimited,

      mode: PassiveTriggerMode.once,

      actions: [],
    );

    final result = await showPassiveTriggerEditorDialog(
      context,

      trigger: trigger,

      character: widget.character,

      linkedEffects: linkedEffects,
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      triggers.add(result);
    });
  }

  Future<void> editTrigger(int index) async {
    if (index < 0 || index >= triggers.length) {
      return;
    }

    final result = await showPassiveTriggerEditorDialog(
      context,

      trigger: PassiveTrigger.fromMap(triggers[index].toMap()),

      character: widget.character,

      linkedEffects: linkedEffects,
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      triggers[index] = result;
    });
  }

  // ===========================================================================
  // LINKED EFFECTS
  // ===========================================================================

  Future<void> addLinkedEffect() async {
    final result = await Navigator.push<CharacterEffect>(
      context,
      MaterialPageRoute(
        builder: (_) => EffectFormScreen(character: widget.character),
      ),
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

    final result = await Navigator.push<CharacterEffect>(
      context,
      MaterialPageRoute(
        builder: (_) => EffectFormScreen(
          effect: CharacterEffect.fromMap(linkedEffects[index].toMap()),
          character: widget.character,
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      linkedEffects[index] = CharacterEffect.fromMap(result.toMap());
    });
  }

  // ===========================================================================
  // DAMAGE BONUS
  // ===========================================================================

  Future<void> addDamageBonus() async {
    final result = await showDamageBonusEditorDialog(
      context,
      bonus: DamageBonus(
        id: '${DateTime.now().microsecondsSinceEpoch}_damage_bonus',
        name: 'Daño adicional',
        dicePools: [],
      ),
      character: widget.character,
      passive: widget.passive,
      ownerPassiveId: passiveId,
      ownerUsesCharges: hasCharges,
    );

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

    final result = await showDamageBonusEditorDialog(
      context,
      bonus: DamageBonus.fromMap(damageBonuses[index].toMap()),
      character: widget.character,
      passive: widget.passive,
      ownerPassiveId: passiveId,
      ownerUsesCharges: hasCharges,
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      damageBonuses[index] = result;
    });
  }

  // ===========================================================================
  // CRITICAL DAMAGE BONUS
  // ===========================================================================

  Future<void> addCriticalBonus() async {
    final result = await showCriticalDamageBonusEditorDialog(
      context,
      bonus: CriticalDamageBonus(
        id: '${DateTime.now().microsecondsSinceEpoch}_critical_bonus',
        name: 'Daño crítico adicional',
        dicePools: [],
        chancePercent: 100,
      ),
      character: widget.character,
      passive: widget.passive,
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      criticalDamageBonuses.add(result);
    });
  }

  Future<void> editCriticalBonus(int index) async {
    if (index < 0 || index >= criticalDamageBonuses.length) {
      return;
    }

    final result = await showCriticalDamageBonusEditorDialog(
      context,
      bonus: CriticalDamageBonus.fromMap(criticalDamageBonuses[index].toMap()),
      character: widget.character,
      passive: widget.passive,
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      criticalDamageBonuses[index] = result;
    });
  }

  // ===========================================================================
  // HEALING BONUS
  // ===========================================================================

  Future<void> addHealingBonus() async {
    final result = await showHealingBonusEditorDialog(
      context,
      bonus: HealingBonus(
        id: '${DateTime.now().microsecondsSinceEpoch}_healing_bonus',
        name: 'Curación adicional',
        dicePools: [],
      ),
      character: widget.character,
      passive: widget.passive,
      ownerPassiveId: passiveId,
      ownerUsesCharges: hasCharges,
    );

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

    final result = await showHealingBonusEditorDialog(
      context,
      bonus: HealingBonus.fromMap(healingBonuses[index].toMap()),
      character: widget.character,
      passive: widget.passive,
      ownerPassiveId: passiveId,
      ownerUsesCharges: hasCharges,
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      healingBonuses[index] = result;
    });
  }

  // ===========================================================================
  // TIRADA PROPIA
  // ===========================================================================

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
        pieces.add(entry.key.shortLabel);
      } else {
        pieces.add('${entry.value}×${entry.key.shortLabel}');
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

  // ===========================================================================
  // FORMULA BONUS
  // ===========================================================================

  FormulaBonus _buildFormulaBonus({
    required TextEditingController flatController,
    required TextEditingController formulaController,
  }) {
    final flatValue = int.tryParse(flatController.text.trim()) ?? 0;

    final expression = formulaController.text.trim();

    return FormulaBonus(
      flatValue: flatValue,
      formula: expression.isEmpty
          ? null
          : CharacterFormula(expression: expression),
    );
  }

  // ===========================================================================
  // SAVE
  // ===========================================================================

  void savePassive() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // =========================================================================
    // LIMPIAR BONUS VACÍOS
    // =========================================================================

    final cleanedAbilityScores = <AbilityType, FormulaBonus>{};

    for (final entry in abilityScoreBonuses.entries) {
      if (!entry.value.hasValue) {
        continue;
      }

      cleanedAbilityScores[entry.key] = FormulaBonus.fromMap(
        entry.value.toMap(),
      );
    }

    final cleanedAbilityModifiers = <AbilityType, FormulaBonus>{};

    for (final entry in abilityModifierBonuses.entries) {
      if (!entry.value.hasValue) {
        continue;
      }

      cleanedAbilityModifiers[entry.key] = FormulaBonus.fromMap(
        entry.value.toMap(),
      );
    }

    final cleanedSavingThrows = <AbilityType, FormulaBonus>{};

    for (final entry in savingThrowBonuses.entries) {
      if (!entry.value.hasValue) {
        continue;
      }

      cleanedSavingThrows[entry.key] = FormulaBonus.fromMap(
        entry.value.toMap(),
      );
    }

    final cleanedSkills = <DndSkill, FormulaBonus>{};

    for (final entry in skillBonuses.entries) {
      if (!entry.value.hasValue) {
        continue;
      }

      cleanedSkills[entry.key] = FormulaBonus.fromMap(entry.value.toMap());
    }

    // =========================================================================
    // CARGAS
    // =========================================================================

    final rawMaxCharges = int.tryParse(maxChargesController.text.trim()) ?? 1;

    final parsedMaxCharges = !hasCharges || unlimitedCharges
        ? 0
        : rawMaxCharges < 1
        ? 1
        : rawMaxCharges;

    var currentCharges = 0;

    if (hasCharges) {
      final previousPassive = widget.passive;

      if (previousPassive?.usesCharges == true) {
        currentCharges = previousPassive!.currentCharges;

        if (!unlimitedCharges && currentCharges > parsedMaxCharges) {
          currentCharges = parsedMaxCharges;
        }

        if (currentCharges < 0) {
          currentCharges = 0;
        }
      } else {
        currentCharges = unlimitedCharges ? 0 : parsedMaxCharges;
      }
    }

    // =========================================================================
    // CREAR MODELO
    // =========================================================================

    final passive = CharacterPassive(
      id: passiveId,

      name: nameController.text.trim(),

      description: descriptionController.text.trim(),

      sourceType: sourceType,

      enabled: enabled,

      // =======================================================================
      // BONUS GENERALES
      // =======================================================================
      armorClassBonus: _buildFormulaBonus(
        flatController: armorClassController,
        formulaController: armorClassFormulaController,
      ),

      initiativeBonus: _buildFormulaBonus(
        flatController: initiativeController,
        formulaController: initiativeFormulaController,
      ),

      speedBonus: _buildFormulaBonus(
        flatController: speedController,
        formulaController: speedFormulaController,
      ),

      maxHealthBonus: _buildFormulaBonus(
        flatController: maxHealthController,
        formulaController: maxHealthFormulaController,
      ),

      attackBonus: _buildFormulaBonus(
        flatController: attackController,
        formulaController: attackFormulaController,
      ),

      // =======================================================================
      // STATS
      // =======================================================================
      abilityScoreBonuses: cleanedAbilityScores,

      abilityModifierBonuses: cleanedAbilityModifiers,

      savingThrowBonuses: cleanedSavingThrows,

      skillBonuses: cleanedSkills,

      // =======================================================================
      // RECURSOS
      // =======================================================================
      resourceModifiers: resourceModifiers
          .map((modifier) => PassiveResourceModifier.fromMap(modifier.toMap()))
          .toList(),

      // =======================================================================
      // CARGAS
      // =======================================================================
      hasCharges: hasCharges,

      unlimitedCharges: hasCharges && unlimitedCharges,

      maxCharges: parsedMaxCharges,

      currentCharges: currentCharges,

      rechargeDescription: hasCharges ? rechargeController.text.trim() : '',

      // =======================================================================
      // TRIGGERS
      // =======================================================================
      triggers: triggers
          .map((trigger) => PassiveTrigger.fromMap(trigger.toMap()))
          .toList(),

      // =======================================================================
      // DAMAGE
      // =======================================================================
      damageBonuses: damageBonuses
          .map((bonus) => DamageBonus.fromMap(bonus.toMap()))
          .toList(),

      criticalDamageBonuses: criticalDamageBonuses
          .map((bonus) => CriticalDamageBonus.fromMap(bonus.toMap()))
          .toList(),

      criticalMinimumNaturalRoll: criticalMinimumNaturalRoll,

      empoweredCritical: empoweredCritical,

      healingBonuses: healingBonuses
          .map((bonus) => HealingBonus.fromMap(bonus.toMap()))
          .toList(),

      // =======================================================================
      // LINKED EFFECTS
      // =======================================================================
      linkedEffects: linkedEffects
          .map((effect) => CharacterEffect.fromMap(effect.toMap()))
          .toList(),

      // =======================================================================
      // TIRADA PROPIA
      // =======================================================================
      rollDicePools: rollDicePools
          .map((pool) => DicePool(count: pool.count, sides: pool.sides))
          .toList(),

      rollAbilityModifierMultipliers: Map<AbilityType, int>.from(
        rollAbilityModifierMultipliers,
      ),

      rollFlatBonus: int.tryParse(rollFlatBonusController.text.trim()) ?? 0,

      // =======================================================================
      // NOTAS
      // =======================================================================
      notes: notesController.text.trim(),
    );

    passive.normalizeCharges();

    Navigator.pop(context, passive);
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar pasiva' : 'Nueva pasiva'),

        actions: [
          IconButton(
            tooltip: 'Guardar',
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
              // ===============================================================
              // IDENTIDAD
              // ===============================================================
              PassiveIdentitySection(
                nameController: nameController,

                descriptionController: descriptionController,

                sourceType: sourceType,

                enabled: enabled,

                onSourceTypeChanged: (value) {
                  setState(() {
                    sourceType = value;
                  });
                },

                onEnabledChanged: (value) {
                  setState(() {
                    enabled = value;
                  });
                },
              ),

              const SizedBox(height: 28),

              // ===============================================================
              // STATS
              // ===============================================================
              _section(
                section: _PassiveFormSection.stats,

                title: 'Stats',

                icon: Icons.bar_chart_rounded,

                subtitle:
                    'Stats base, modificadores, salvaciones y habilidades.',
              ),

              if (_sectionExpanded(_PassiveFormSection.stats)) ...[
                const SizedBox(height: 12),

                PassiveStatsSection(
                  character: widget.character,

                  abilityScoreBonuses: abilityScoreBonuses,

                  abilityModifierBonuses: abilityModifierBonuses,

                  savingThrowBonuses: savingThrowBonuses,

                  skillBonuses: skillBonuses,

                  onAbilityScoreChanged: (ability, bonus) {
                    setState(() {
                      abilityScoreBonuses[ability] = bonus;
                    });
                  },

                  onAbilityModifierChanged: (ability, bonus) {
                    setState(() {
                      abilityModifierBonuses[ability] = bonus;
                    });
                  },

                  onSavingThrowChanged: (ability, bonus) {
                    setState(() {
                      savingThrowBonuses[ability] = bonus;
                    });
                  },

                  onSkillChanged: (skill, bonus) {
                    setState(() {
                      skillBonuses[skill] = bonus;
                    });
                  },
                ),
              ],

              const SizedBox(height: 28),

              // ===============================================================
              // BONUS GENERALES
              // ===============================================================
              _section(
                section: _PassiveFormSection.generalBonuses,

                title: 'Bonificaciones generales',

                icon: Icons.tune_rounded,

                subtitle: 'CA, iniciativa, velocidad, PG máximos y ataque.',
              ),

              if (_sectionExpanded(_PassiveFormSection.generalBonuses)) ...[
                const SizedBox(height: 12),

                PassiveGeneralBonusesSection(
                  character: widget.character,

                  armorClassController: armorClassController,

                  initiativeController: initiativeController,

                  speedController: speedController,

                  maxHealthController: maxHealthController,

                  attackController: attackController,

                  armorClassFormulaController: armorClassFormulaController,

                  initiativeFormulaController: initiativeFormulaController,

                  speedFormulaController: speedFormulaController,

                  maxHealthFormulaController: maxHealthFormulaController,

                  attackFormulaController: attackFormulaController,
                ),
              ],

              const SizedBox(height: 28),

              // ===============================================================
              // RECURSOS
              // ===============================================================
              _section(
                section: _PassiveFormSection.resources,

                title: 'Modificadores de recursos',

                icon: Icons.account_balance_wallet_rounded,

                subtitle:
                    'Modifica la cantidad actual o máxima mediante fórmulas.',

                trailing: IconButton.filledTonal(
                  tooltip: 'Añadir modificador',

                  onPressed:
                      widget.character == null ||
                          widget.character!.resources.isEmpty
                      ? null
                      : addResourceModifier,

                  icon: const Icon(Icons.add_rounded),
                ),
              ),

              if (_sectionExpanded(_PassiveFormSection.resources)) ...[
                const SizedBox(height: 12),

                PassiveResourcesSection(
                  character: widget.character,

                  modifiers: resourceModifiers,

                  textBuilder: (modifier) {
                    return PassiveDisplayFormatter.resourceModifier(
                      modifier,
                      character: widget.character,
                    );
                  },

                  onAdd: addResourceModifier,

                  onEdit: editResourceModifier,

                  onDelete: (index) {
                    setState(() {
                      resourceModifiers.removeAt(index);
                    });
                  },
                ),
              ],

              const SizedBox(height: 28),

              // ===============================================================
              // CARGAS
              // ===============================================================
              _section(
                section: _PassiveFormSection.charges,

                title: 'Cargas',

                icon: Icons.battery_charging_full_rounded,

                subtitle: hasCharges
                    ? unlimitedCharges
                          ? 'Usa cargas sin límite máximo.'
                          : 'Máximo: '
                                '${maxChargesController.text.trim().isEmpty ? '0' : maxChargesController.text.trim()}'
                    : 'Esta pasiva no utiliza cargas.',
              ),

              if (_sectionExpanded(_PassiveFormSection.charges)) ...[
                const SizedBox(height: 8),

                PassiveChargesSection(
                  hasCharges: hasCharges,

                  unlimitedCharges: unlimitedCharges,

                  maxChargesController: maxChargesController,

                  rechargeController: rechargeController,

                  onHasChargesChanged: (value) {
                    setState(() {
                      hasCharges = value;

                      if (!value) {
                        unlimitedCharges = false;
                      }
                    });
                  },

                  onUnlimitedChanged: (value) {
                    setState(() {
                      unlimitedCharges = value;
                    });
                  },
                ),
              ],

              const SizedBox(height: 28),

              // ===============================================================
              // TRIGGERS
              // ===============================================================
              _section(
                section: _PassiveFormSection.triggers,

                title: 'Triggers',

                icon: Icons.bolt_rounded,

                subtitle:
                    'Acciones automáticas que se ejecutan cuando ocurre un evento.',

                trailing: IconButton.filledTonal(
                  tooltip: 'Añadir trigger',

                  onPressed: addTrigger,

                  icon: const Icon(Icons.add_rounded),
                ),
              ),

              if (_sectionExpanded(_PassiveFormSection.triggers)) ...[
                const SizedBox(height: 12),

                PassiveTriggersSection(
                  triggers: triggers,

                  onAdd: addTrigger,

                  onEdit: editTrigger,

                  onDelete: (index) {
                    setState(() {
                      triggers.removeAt(index);
                    });
                  },

                  subtitleBuilder: (trigger) {
                    return PassiveDisplayFormatter.trigger(
                      trigger,
                      character: widget.character,
                      linkedEffects: linkedEffects,
                    );
                  },
                ),
              ],

              const SizedBox(height: 28),

              // ===============================================================
              // BONUS EXTRA
              // ===============================================================
              _section(
                section: _PassiveFormSection.extraEffects,

                title: 'Efectos extra',

                icon: Icons.auto_awesome_rounded,

                subtitle: 'Bonificaciones al daño, críticos y curaciones.',
              ),

              if (_sectionExpanded(_PassiveFormSection.extraEffects)) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: criticalMinimumNaturalRoll,
                  decoration: const InputDecoration(
                    labelText: 'Rango crítico',
                    helperText:
                        'Valor natural mínimo del d20 que produce crítico.',
                    prefixIcon: Icon(Icons.gps_fixed_rounded),
                  ),
                  items: List.generate(20, (index) {
                    final value = 20 - index;

                    final label = value == 20 ? '20' : '$value–20';

                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(label),
                    );
                  }),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      criticalMinimumNaturalRoll = value;
                    });
                  },
                ),

                const SizedBox(height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: empoweredCritical,
                  title: const Text('Crítico potenciado'),
                  subtitle: const Text(
                    'Mientras esta pasiva esté activa, '
                    'los críticos usan la regla potenciada.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      empoweredCritical = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                PassiveExtraBonusesSection(
                  damageBonuses: damageBonuses,

                  criticalDamageBonuses: criticalDamageBonuses,

                  healingBonuses: healingBonuses,

                  damageText: (bonus) {
                    return PassiveDisplayFormatter.damageBonus(
                      bonus,
                      character: widget.character,
                    );
                  },

                  criticalText: (bonus) {
                    return PassiveDisplayFormatter.criticalDamageBonus(
                      bonus,
                      character: widget.character,
                    );
                  },

                  healingText: (bonus) {
                    return PassiveDisplayFormatter.healingBonus(
                      bonus,
                      character: widget.character,
                    );
                  },

                  onAddDamage: addDamageBonus,

                  onAddCritical: addCriticalBonus,

                  onAddHealing: addHealingBonus,

                  onEditDamage: editDamageBonus,

                  onEditCritical: editCriticalBonus,

                  onEditHealing: editHealingBonus,

                  onDeleteDamage: (index) {
                    setState(() {
                      damageBonuses.removeAt(index);
                    });
                  },

                  onDeleteCritical: (index) {
                    setState(() {
                      criticalDamageBonuses.removeAt(index);
                    });
                  },

                  onDeleteHealing: (index) {
                    setState(() {
                      healingBonuses.removeAt(index);
                    });
                  },
                ),
              ],

              const SizedBox(height: 28),

              // ===============================================================
              // LINKED EFFECTS
              // ===============================================================
              _section(
                section: _PassiveFormSection.linkedEffects,

                title: 'Efectos vinculados',

                icon: Icons.auto_awesome_motion_rounded,

                subtitle: 'Estados y efectos que esta pasiva puede aplicar.',

                trailing: IconButton.filledTonal(
                  tooltip: 'Añadir efecto vinculado',

                  onPressed: addLinkedEffect,

                  icon: const Icon(Icons.add_rounded),
                ),
              ),

              if (_sectionExpanded(_PassiveFormSection.linkedEffects)) ...[
                const SizedBox(height: 12),

                PassiveLinkedEffectsSection(
                  effects: linkedEffects,

                  onEdit: editLinkedEffect,

                  onDelete: (index) {
                    setState(() {
                      linkedEffects.removeAt(index);
                    });
                  },
                ),
              ],

              const SizedBox(height: 28),

              // ===============================================================
              // TIRADA PROPIA
              // ===============================================================
              _section(
                section: _PassiveFormSection.ownRoll,

                title: 'Tirada propia',

                icon: Icons.casino_rounded,

                subtitle: 'Permite tirar dados directamente desde esta pasiva.',
              ),

              if (_sectionExpanded(_PassiveFormSection.ownRoll)) ...[
                const SizedBox(height: 12),

                PassiveOwnRollSection(
                  dicePools: rollDicePools,

                  abilityMultipliers: rollAbilityModifierMultipliers,

                  flatBonusController: rollFlatBonusController,

                  preview: passiveRollPreview,

                  onChanged: () {
                    setState(() {});
                  },

                  onMultipliersChanged: (value) {
                    setState(() {
                      rollAbilityModifierMultipliers = value;
                    });
                  },
                ),
              ],

              const SizedBox(height: 28),

              // ===============================================================
              // NOTAS
              // ===============================================================
              _section(
                section: _PassiveFormSection.notes,

                title: 'Notas',

                icon: Icons.notes_rounded,

                subtitle: 'Información adicional sobre esta pasiva.',
              ),

              if (_sectionExpanded(_PassiveFormSection.notes)) ...[
                const SizedBox(height: 12),

                PassiveNotesSection(controller: notesController),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    nameController.dispose();

    descriptionController.dispose();

    notesController.dispose();

    armorClassController.dispose();

    initiativeController.dispose();

    speedController.dispose();

    maxHealthController.dispose();

    attackController.dispose();

    armorClassFormulaController.dispose();

    initiativeFormulaController.dispose();

    speedFormulaController.dispose();

    maxHealthFormulaController.dispose();

    attackFormulaController.dispose();

    maxChargesController.dispose();

    rechargeController.dispose();

    rollFlatBonusController.dispose();

    super.dispose();
  }
}
