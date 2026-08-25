import 'package:flutter/material.dart';
import 'package:rol/models/character_effect.dart';

import '../widgets/formulas/formula_insert_bar.dart';
import '../models/passive.dart';
import '../models/skill.dart';
import '../models/damage_bonus.dart';
import '../models/critical_damage_bonus.dart';
import '../models/healing_bonus.dart';
import '../models/dice_pool.dart';
import '../models/character.dart';
import '../models/passive_resource_modifier.dart';

import '../models/formulas/formula_bonus.dart';
import '../models/formulas/formula_result.dart';
import '../models/formulas/character_formula.dart';
import '../models/formulas/character_formula_context.dart';
import '../models/formulas/formula_context.dart';
import '../models/formulas/formula_modifier.dart';

import '../services/formula_display_formatter.dart';
import '../services/formula_evaluator.dart';
import '../services/resource_modifier_resolver.dart';

import 'effect_form_screen.dart';

enum _PassiveFormSection {
  stats,
  baseStats,
  abilityModifiers,
  savingThrows,
  skills,

  generalBonuses,
  resources,
  charges,
  triggers,
  extraEffects,
  linkedEffects,
  ownRoll,
  notes,
}

class PassiveFormScreen extends StatefulWidget {
  final CharacterPassive? passive;

  final Character? character;

  const PassiveFormScreen({super.key, this.passive, this.character});

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
  late final TextEditingController armorClassFormulaController;
  late final TextEditingController initiativeFormulaController;
  late final TextEditingController speedFormulaController;
  late final TextEditingController maxHealthFormulaController;
  late final TextEditingController attackFormulaController;
  late final TextEditingController notesController;

  late final TextEditingController maxChargesController;
  late final TextEditingController rechargeController;

  late List<PassiveResourceModifier> resourceModifiers;

  late List<PassiveTrigger> triggers;

  bool hasCharges = false;
  bool unlimitedCharges = false;

  late PassiveSourceType sourceType;

  bool enabled = true;

  late Map<DndSkill, FormulaBonus> skillBonuses;

  late Map<AbilityType, FormulaBonus> savingThrowBonuses;

  late Map<AbilityType, FormulaBonus> abilityModifierBonuses;

  late Map<AbilityType, FormulaBonus> abilityScoreBonuses;

  late List<DamageBonus> damageBonuses;
  late List<CriticalDamageBonus> criticalDamageBonuses;
  late List<HealingBonus> healingBonuses;
  late List<DicePool> rollDicePools;
  late List<CharacterEffect> linkedEffects;
  late Map<AbilityType, int> rollAbilityModifierMultipliers;

  late final TextEditingController rollFlatBonusController;
  bool get editing => widget.passive != null;

  final Set<TextEditingController> expandedFormulaTools = {};

  final Set<_PassiveFormSection> expandedSections = {};

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

  @override
  void initState() {
    super.initState();

    final passive = widget.passive;

    nameController = TextEditingController(text: passive?.name ?? '');

    descriptionController = TextEditingController(
      text: passive?.description ?? '',
    );

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

    notesController = TextEditingController(text: passive?.notes ?? '');

    sourceType = passive?.sourceType ?? PassiveSourceType.custom;

    triggers =
        passive?.triggers
            .map((trigger) => PassiveTrigger.fromMap(trigger.toMap()))
            .toList() ??
        [];

    enabled = passive?.enabled ?? true;

    hasCharges = passive?.hasCharges ?? false;

    unlimitedCharges = passive?.hasUnlimitedCharges ?? false;

    maxChargesController = TextEditingController(
      text: '${passive?.maxCharges ?? 1}',
    );

    rechargeController = TextEditingController(
      text: passive?.rechargeDescription ?? '',
    );

    resourceModifiers =
        passive?.resourceModifiers
            .map(
              (modifier) => PassiveResourceModifier.fromMap(modifier.toMap()),
            )
            .toList() ??
        [];

    abilityModifierBonuses = {
      for (final ability in AbilityType.values)
        ability: passive?.abilityModifierBonuses[ability] != null
            ? FormulaBonus.fromMap(
                passive!.abilityModifierBonuses[ability]!.toMap(),
              )
            : FormulaBonus(),
    };

    abilityScoreBonuses = {
      for (final ability in AbilityType.values)
        ability: passive?.abilityScoreBonuses[ability] != null
            ? FormulaBonus.fromMap(
                passive!.abilityScoreBonuses[ability]!.toMap(),
              )
            : FormulaBonus(),
    };

    skillBonuses = {
      for (final skill in DndSkill.values)
        skill: passive?.skillBonuses[skill] != null
            ? FormulaBonus.fromMap(passive!.skillBonuses[skill]!.toMap())
            : FormulaBonus(),
    };

    savingThrowBonuses = {
      for (final ability in AbilityType.values)
        ability: passive?.savingThrowBonuses[ability] != null
            ? FormulaBonus.fromMap(
                passive!.savingThrowBonuses[ability]!.toMap(),
              )
            : FormulaBonus(),
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

    linkedEffects =
        passive?.linkedEffects
            .map((effect) => CharacterEffect.fromMap(effect.toMap()))
            .toList() ??
        [];

    rollAbilityModifierMultipliers = Map<AbilityType, int>.from(
      passive?.rollAbilityModifierMultipliers ?? {},
    );

    rollFlatBonusController = TextEditingController(
      text: '${passive?.rollFlatBonus ?? 0}',
    );
  }

  Future<void> addTrigger() async {
    final trigger = PassiveTrigger(
      id: '${DateTime.now().microsecondsSinceEpoch}_trigger',
      event: PassiveTriggerEvent.enemyKilled,
      actionType: PassiveTriggerActionType.incrementCounter,
      valueFormula: CharacterFormula(expression: '1'),
    );

    final result = await _editTriggerDialog(trigger);

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

    final result = await _editTriggerDialog(
      PassiveTrigger.fromMap(triggers[index].toMap()),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      triggers[index] = result;
    });
  }

  Future<PassiveTrigger?> _editTriggerDialog(PassiveTrigger trigger) {
    return showDialog<PassiveTrigger>(
      context: context,
      builder: (_) {
        return _TriggerEditorDialog(
          trigger: trigger,
          character: widget.character,
          passive: widget.passive,
        );
      },
    );
  }

  String _triggerEventLabel(PassiveTriggerEvent event) {
    switch (event) {
      case PassiveTriggerEvent.enemyKilled:
        return 'Al matar un enemigo';

      case PassiveTriggerEvent.damageDealt:
        return 'Al causar daño';

      case PassiveTriggerEvent.damageReceived:
        return 'Al recibir daño';

      case PassiveTriggerEvent.healed:
        return 'Al curar';

      case PassiveTriggerEvent.criticalHit:
        return 'Al realizar un crítico';

      case PassiveTriggerEvent.turnStarted:
        return 'Al empezar turno';

      case PassiveTriggerEvent.turnEnded:
        return 'Al terminar turno';

      case PassiveTriggerEvent.resourceChanged:
        return 'Al cambiar un recurso';

      case PassiveTriggerEvent.counterChanged:
        return 'Al cambiar un contador';

      case PassiveTriggerEvent.healthChanged:
        return 'Al cambiar la vida';

      case PassiveTriggerEvent.manual:
        return 'Activación manual';

      case PassiveTriggerEvent.custom:
        return 'Evento personalizado';

      case PassiveTriggerEvent.chargeChanged:
        return 'Al cambiar una carga';

      case PassiveTriggerEvent.roundStarted:
        return 'Al empezar una ronda';

      case PassiveTriggerEvent.roundEnded:
        return 'Al terminar una ronda';
    }
  }

  String _triggerActionLabel(PassiveTriggerActionType action) {
    switch (action) {
      case PassiveTriggerActionType.addResource:
        return 'Añadir recurso';

      case PassiveTriggerActionType.subtractResource:
        return 'Gastar recurso';

      case PassiveTriggerActionType.setResource:
        return 'Establecer recurso';

      case PassiveTriggerActionType.addCharge:
        return 'Añadir carga';

      case PassiveTriggerActionType.subtractCharge:
        return 'Gastar carga';

      case PassiveTriggerActionType.applyEffect:
        return 'Aplicar efecto';

      case PassiveTriggerActionType.removeEffect:
        return 'Eliminar efecto';

      case PassiveTriggerActionType.dealDamage:
        return 'Causar daño';

      case PassiveTriggerActionType.heal:
        return 'Curar';

      case PassiveTriggerActionType.incrementCounter:
        return 'Incrementar contador';

      case PassiveTriggerActionType.setCounter:
        return 'Establecer contador';
    }
  }

  String _triggerTitle(PassiveTrigger trigger) {
    return _triggerEventLabel(trigger.event);
  }

  String _triggerSubtitle(PassiveTrigger trigger) {
    final pieces = <String>[_triggerActionLabel(trigger.actionType)];

    final targetId = trigger.targetId?.trim();

    if (targetId != null && targetId.isNotEmpty) {
      var targetName = targetId;

      final character = widget.character;

      if (character != null) {
        // ============================================================
        // RECURSO
        // ============================================================

        switch (trigger.actionType) {
          case PassiveTriggerActionType.addResource:
          case PassiveTriggerActionType.subtractResource:
          case PassiveTriggerActionType.setResource:
            final resource = character.resourceById(targetId);

            if (resource != null) {
              targetName = resource.name;
            }

            break;

          // ==========================================================
          // CONTADOR
          // ==========================================================

          case PassiveTriggerActionType.incrementCounter:
          case PassiveTriggerActionType.setCounter:
            final counter = character.counterById(targetId);

            if (counter != null) {
              targetName = counter.name.trim().isEmpty
                  ? counter.id
                  : counter.name;
            }

            break;

          // ==========================================================
          // EFECTO
          // ==========================================================

          case PassiveTriggerActionType.applyEffect:
          case PassiveTriggerActionType.removeEffect:
            CharacterEffect? effect;

            // Primero efectos vinculados de la pasiva.
            for (final linkedEffect in linkedEffects) {
              if (linkedEffect.id == targetId) {
                effect = linkedEffect;
                break;
              }
            }

            // Fallback a efectos del personaje.
            effect ??= character.effectById(targetId);

            if (effect != null) {
              targetName = effect.name.trim().isEmpty ? effect.id : effect.name;
            }

            break;

          default:
            break;
        }
      }

      pieces.add(targetName);
    }

    if (trigger.valueFormula != null &&
        trigger.valueFormula!.expression.trim().isNotEmpty) {
      final formatted = FormulaDisplayFormatter.format(
        trigger.valueFormula!.expression,
        widget.character,
      );

      pieces.add('Valor: $formatted');
    }

    if (trigger.hasCondition) {
      final formatted = FormulaDisplayFormatter.format(
        trigger.condition!.expression,
        widget.character,
      );

      pieces.add('Si: $formatted');
    }

    return pieces.join(' · ');
  }

  Future<void> addResourceModifier() async {
    final character = widget.character;

    if (character == null || character.resources.isEmpty) {
      return;
    }

    final modifier = PassiveResourceModifier(
      id: '${DateTime.now().microsecondsSinceEpoch}_resource_modifier',
      resourceId: character.resources.first.id,
      target: PassiveResourceTarget.current,
      operation: FormulaModifierOperation.add,
      formula: CharacterFormula(expression: '0'),
    );

    final result = await _editResourceModifierDialog(modifier);

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

    final result = await _editResourceModifierDialog(
      PassiveResourceModifier.fromMap(resourceModifiers[index].toMap()),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      resourceModifiers[index] = result;
    });
  }

  Future<PassiveResourceModifier?> _editResourceModifierDialog(
    PassiveResourceModifier modifier,
  ) {
    final character = widget.character;

    if (character == null) {
      return Future.value(null);
    }

    return showDialog<PassiveResourceModifier>(
      context: context,
      builder: (_) {
        return _ResourceModifierEditorDialog(
          modifier: modifier,
          character: character,
          passive: widget.passive,
        );
      },
    );
  }

  String _resourceModifierText(PassiveResourceModifier modifier) {
    final resource = widget.character?.resourceById(modifier.resourceId);

    final resourceName = resource?.name ?? 'Recurso desconocido';

    final targetText = modifier.target == PassiveResourceTarget.current
        ? 'Actual'
        : 'Máximo';

    String operationText;

    switch (modifier.operation) {
      case FormulaModifierOperation.add:
        operationText = '+';
        break;

      case FormulaModifierOperation.subtract:
        operationText = '-';
        break;

      case FormulaModifierOperation.set:
        operationText = '=';
        break;
    }

    final expression = FormulaDisplayFormatter.format(
      modifier.formula.expression.trim(),
      widget.character,
    );

    return '$resourceName · $targetText · '
        '$operationText ${expression.isEmpty ? '0' : expression}';
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

  Future<FormulaBonus?> editFormulaBonus({
    required String title,
    required FormulaBonus bonus,
  }) {
    return showDialog<FormulaBonus>(
      context: context,
      builder: (_) {
        return _FormulaBonusEditorDialog(
          title: title,
          bonus: FormulaBonus.fromMap(bonus.toMap()),
          character: widget.character,
          passive: widget.passive,
        );
      },
    );
  }

  Future<void> editAbilityScoreBonus(AbilityType ability) async {
    final result = await editFormulaBonus(
      title: 'Stat base · ${abilityLabel(ability)}',
      bonus: abilityScoreBonuses[ability] ?? FormulaBonus(),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      abilityScoreBonuses[ability] = result;
    });
  }

  Future<void> editAbilityModifierBonus(AbilityType ability) async {
    final result = await editFormulaBonus(
      title: 'Modificador · ${abilityLabel(ability)}',
      bonus: abilityModifierBonuses[ability] ?? FormulaBonus(),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      abilityModifierBonuses[ability] = result;
    });
  }

  Future<void> editSkillBonus(DndSkill skill) async {
    final result = await editFormulaBonus(
      title: 'Bonus · ${skill.label}',
      bonus: skillBonuses[skill] ?? FormulaBonus(),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      skillBonuses[skill] = result;
    });
  }

  Future<void> editSavingThrowBonus(AbilityType ability) async {
    final result = await editFormulaBonus(
      title: 'Salvación · ${abilityLabel(ability)}',
      bonus: savingThrowBonuses[ability] ?? FormulaBonus(),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      savingThrowBonuses[ability] = result;
    });
  }

  // =============================================================================
  // EFECTOS VINCULADOS
  // =============================================================================

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
        return _DamageBonusEditorDialog(
          bonus: bonus,
          character: widget.character,
          passive: widget.passive,
        );
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
        return _CriticalDamageBonusEditorDialog(
          bonus: bonus,
          character: widget.character,
          passive: widget.passive,
        );
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
        return _HealingBonusEditorDialog(
          bonus: bonus,
          character: widget.character,
          passive: widget.passive,
        );
      },
    );
  }

  String _damageBonusText(DamageBonus bonus) {
    final pieces = <String>[];

    if (bonus.diceNotation.isNotEmpty) {
      pieces.add(bonus.diceNotation);
    }

    for (final entry in bonus.abilityModifierMultipliers.entries) {
      if (entry.value == 0) {
        continue;
      }

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

    if (bonus.hasFormula) {
      final formattedFormula = FormulaDisplayFormatter.format(
        bonus.formula!.expression,
        widget.character,
      );

      pieces.add('ƒ($formattedFormula)');
    }

    var result = pieces.isEmpty
        ? 'Sin daño'
        : pieces.join(' + ').replaceAll('+ -', '- ');

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

    if (bonus.hasFormula) {
      final formattedFormula = FormulaDisplayFormatter.format(
        bonus.formula!.expression,
        widget.character,
      );

      pieces.add('ƒ($formattedFormula)');
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
      if (entry.value == 0) {
        continue;
      }

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

    if (bonus.hasFormula) {
      final formattedFormula = FormulaDisplayFormatter.format(
        bonus.formula!.expression,
        widget.character,
      );

      pieces.add('ƒ($formattedFormula)');
    }

    final result = pieces.isEmpty
        ? 'Sin curación'
        : pieces.join(' + ').replaceAll('+ -', '- ');

    if (bonus.name.trim().isNotEmpty) {
      return '${bonus.name} · $result';
    }

    return result;
  }

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

  void savePassive() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cleanedAbilityScores = <AbilityType, FormulaBonus>{};

    for (final entry in abilityScoreBonuses.entries) {
      if (entry.value.hasValue) {
        cleanedAbilityScores[entry.key] = FormulaBonus.fromMap(
          entry.value.toMap(),
        );
      }
    }

    final cleanedAbilityModifiers = <AbilityType, FormulaBonus>{};

    for (final entry in abilityModifierBonuses.entries) {
      if (entry.value.hasValue) {
        cleanedAbilityModifiers[entry.key] = FormulaBonus.fromMap(
          entry.value.toMap(),
        );
      }
    }

    final cleanedSkills = <DndSkill, FormulaBonus>{};

    for (final entry in skillBonuses.entries) {
      if (entry.value.hasValue) {
        cleanedSkills[entry.key] = FormulaBonus.fromMap(entry.value.toMap());
      }
    }

    final cleanedSaves = <AbilityType, FormulaBonus>{};

    for (final entry in savingThrowBonuses.entries) {
      if (entry.value.hasValue) {
        cleanedSaves[entry.key] = FormulaBonus.fromMap(entry.value.toMap());
      }
    }

    // =========================================================================
    // CARGAS
    // =========================================================================

    final parsedMaxCharges = !hasCharges
        ? 0
        : unlimitedCharges
        ? 0
        : (int.tryParse(maxChargesController.text.trim()) ?? 1);

    int currentCharges = 0;

    if (hasCharges) {
      if (widget.passive?.usesCharges == true) {
        // Conservamos las cargas actuales al editar.
        currentCharges = widget.passive!.currentCharges;

        // Solo limitamos las cargas cuando existe un máximo.
        if (!unlimitedCharges && currentCharges > parsedMaxCharges) {
          currentCharges = parsedMaxCharges;
        }
      } else {
        // Una pasiva nueva con máximo empieza llena.
        // Una pasiva sin máximo empieza en 0.
        currentCharges = unlimitedCharges ? 0 : parsedMaxCharges;
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

      abilityScoreBonuses: cleanedAbilityScores,

      abilityModifierBonuses: cleanedAbilityModifiers,

      skillBonuses: cleanedSkills,

      savingThrowBonuses: cleanedSaves,

      triggers: triggers
          .map((trigger) => PassiveTrigger.fromMap(trigger.toMap()))
          .toList(),

      // =======================================================================
      // CARGAS
      // =======================================================================
      hasCharges: hasCharges,

      unlimitedCharges: hasCharges && unlimitedCharges,

      maxCharges: parsedMaxCharges,

      currentCharges: currentCharges,

      rechargeDescription: hasCharges ? rechargeController.text.trim() : '',

      resourceModifiers: resourceModifiers
          .map((modifier) => PassiveResourceModifier.fromMap(modifier.toMap()))
          .toList(),

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

      linkedEffects: linkedEffects
          .map((effect) => CharacterEffect.fromMap(effect.toMap()))
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
    armorClassFormulaController.dispose();
    initiativeFormulaController.dispose();
    speedFormulaController.dispose();
    maxHealthFormulaController.dispose();
    attackFormulaController.dispose();
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

              const SizedBox(height: 28),

              // ===========================================================================
              // STATS
              // ===========================================================================
              _sectionHeader(
                section: _PassiveFormSection.stats,
                title: 'Stats',
                icon: Icons.bar_chart_rounded,
                subtitle:
                    'Stats base, modificadores, salvaciones y habilidades.',
              ),

              if (_sectionExpanded(_PassiveFormSection.stats)) ...[
                const SizedBox(height: 8),

                // =========================================================================
                // BASE STATS
                // =========================================================================
                Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: Column(
                    children: [
                      _sectionHeader(
                        section: _PassiveFormSection.baseStats,
                        title: 'Base stats',
                        icon: Icons.straighten_rounded,
                        subtitle:
                            'Modifica directamente FUE, DES, CON, INT, SAB y CAR.',
                      ),

                      if (_sectionExpanded(_PassiveFormSection.baseStats)) ...[
                        const SizedBox(height: 10),

                        Card(
                          margin: EdgeInsets.zero,
                          child: Column(
                            children: AbilityType.values.map((ability) {
                              final bonus =
                                  abilityScoreBonuses[ability] ??
                                  FormulaBonus();

                              return ListTile(
                                onTap: () {
                                  editAbilityScoreBonus(ability);
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

                                subtitle: const Text('Puntuación de atributo'),

                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formulaBonusText(bonus),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(width: 6),

                                    const Icon(Icons.edit_rounded, size: 17),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // =========================================================================
                // MODIFICADORES
                // =========================================================================
                Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: Column(
                    children: [
                      _sectionHeader(
                        section: _PassiveFormSection.abilityModifiers,
                        title: 'Modificadores',
                        icon: Icons.tune_rounded,
                        subtitle:
                            'Bonificaciones directas al modificador de atributo.',
                      ),

                      if (_sectionExpanded(
                        _PassiveFormSection.abilityModifiers,
                      )) ...[
                        const SizedBox(height: 10),

                        Card(
                          margin: EdgeInsets.zero,
                          child: Column(
                            children: AbilityType.values.map((ability) {
                              final bonus =
                                  abilityModifierBonuses[ability] ??
                                  FormulaBonus();

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

                                subtitle: const Text('Bonus al modificador'),

                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formulaBonusText(bonus),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(width: 6),

                                    const Icon(Icons.edit_rounded, size: 17),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // =========================================================================
                // SALVACIONES
                // =========================================================================
                Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: Column(
                    children: [
                      _sectionHeader(
                        section: _PassiveFormSection.savingThrows,
                        title: 'Salvaciones',
                        icon: Icons.security_rounded,
                        subtitle:
                            'Bonificaciones adicionales a las tiradas de salvación.',
                      ),

                      if (_sectionExpanded(
                        _PassiveFormSection.savingThrows,
                      )) ...[
                        const SizedBox(height: 10),

                        Card(
                          margin: EdgeInsets.zero,
                          child: Column(
                            children: AbilityType.values.map((ability) {
                              final bonus =
                                  savingThrowBonuses[ability] ?? FormulaBonus();

                              return ListTile(
                                onTap: () {
                                  editSavingThrowBonus(ability);
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

                                subtitle: const Text('Salvación'),

                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formulaBonusText(bonus),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(width: 6),

                                    const Icon(Icons.edit_rounded, size: 17),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // =========================================================================
                // HABILIDADES
                // =========================================================================
                Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: Column(
                    children: [
                      _sectionHeader(
                        section: _PassiveFormSection.skills,
                        title: 'Habilidades',
                        icon: Icons.psychology_alt_rounded,
                        subtitle:
                            'Bonificaciones específicas a las habilidades.',
                      ),

                      if (_sectionExpanded(_PassiveFormSection.skills)) ...[
                        const SizedBox(height: 10),

                        Card(
                          margin: EdgeInsets.zero,
                          child: Column(
                            children: DndSkill.values.map((skill) {
                              final bonus =
                                  skillBonuses[skill] ?? FormulaBonus();

                              return ListTile(
                                onTap: () {
                                  editSkillBonus(skill);
                                },

                                leading: CircleAvatar(
                                  child: Text(
                                    _abilityShortName(skill.ability),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                title: Text(skill.label),

                                subtitle: Text(abilityLabel(skill.ability)),

                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formulaBonusText(bonus),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(width: 6),

                                    const Icon(Icons.edit_rounded, size: 17),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              _sectionHeader(
                section: _PassiveFormSection.generalBonuses,
                title: 'Bonificaciones generales',
                icon: Icons.tune_rounded,
                subtitle: 'CA, iniciativa, velocidad, PG máximos y ataque.',
              ),

              if (_sectionExpanded(_PassiveFormSection.generalBonuses)) ...[
                const SizedBox(height: 14),

                // ============================================================
                // BONUS FIJOS
                // ============================================================
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: armorClassController,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'CA fija',
                          hintText: '0',
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
                          labelText: 'Iniciativa fija',
                          hintText: '0',
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
                          labelText: 'PG máximos fijos',
                          hintText: '0',
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
                          labelText: 'Al golpe fijo',
                          hintText: '0',
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
                    labelText: 'Velocidad fija',
                    hintText: '0',
                    suffixText: 'pies',
                    prefixIcon: Icon(Icons.directions_run_rounded),
                  ),
                ),

                const SizedBox(height: 24),

                // ============================================================
                // FÓRMULAS
                // ============================================================
                Text(
                  'Fórmulas de bonificación',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Estas fórmulas se suman al bonus fijo indicado arriba.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: 14),

                _buildFormulaBonusField(
                  label: 'CA',
                  controller: armorClassFormulaController,
                ),

                const SizedBox(height: 12),

                _buildFormulaBonusField(
                  label: 'Iniciativa',
                  controller: initiativeFormulaController,
                ),

                const SizedBox(height: 12),

                _buildFormulaBonusField(
                  label: 'Velocidad',
                  controller: speedFormulaController,
                ),

                const SizedBox(height: 12),

                _buildFormulaBonusField(
                  label: 'PG máximos',
                  controller: maxHealthFormulaController,
                ),

                const SizedBox(height: 12),

                _buildFormulaBonusField(
                  label: 'Al golpe',
                  controller: attackFormulaController,
                ),
              ],

              const SizedBox(height: 28),

              _sectionHeader(
                section: _PassiveFormSection.resources,
                title: 'Modificadores de recursos',
                icon: Icons.account_balance_wallet_rounded,
                subtitle:
                    'Modifica la cantidad actual o máxima de un recurso mediante fórmulas.',
                trailing: IconButton.filledTonal(
                  tooltip: 'Añadir modificador de recurso',
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

                if (widget.character == null)
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
                          Icons.info_outline_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),

                        const SizedBox(width: 12),

                        const Expanded(
                          child: Text(
                            'No hay un personaje disponible para configurar recursos.',
                          ),
                        ),
                      ],
                    ),
                  )
                else if (widget.character!.resources.isEmpty)
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
                          Icons.account_balance_wallet_outlined,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),

                        const SizedBox(width: 12),

                        const Expanded(
                          child: Text('Este personaje no tiene recursos.'),
                        ),
                      ],
                    ),
                  )
                else if (resourceModifiers.isEmpty)
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
                          Icons.account_balance_wallet_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),

                        const SizedBox(width: 12),

                        const Expanded(
                          child: Text('Esta pasiva no modifica recursos.'),
                        ),
                      ],
                    ),
                  )
                else
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < resourceModifiers.length; i++) ...[
                          ListTile(
                            onTap: () {
                              editResourceModifier(i);
                            },
                            leading: const CircleAvatar(
                              child: Icon(Icons.account_balance_wallet_rounded),
                            ),
                            title: Text(
                              _resourceModifierText(resourceModifiers[i]),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit_rounded, size: 18),

                                const SizedBox(width: 4),

                                IconButton(
                                  tooltip: 'Eliminar',
                                  onPressed: () {
                                    setState(() {
                                      resourceModifiers.removeAt(i);
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (i < resourceModifiers.length - 1)
                            const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
              ],

              _sectionHeader(
                section: _PassiveFormSection.charges,
                title: 'Cargas',
                icon: Icons.battery_charging_full_rounded,
                subtitle: hasCharges
                    ? unlimitedCharges
                          ? 'Usa cargas sin límite máximo.'
                          : 'Máximo: ${maxChargesController.text.trim().isEmpty ? '0' : maxChargesController.text.trim()}'
                    : 'Esta pasiva no utiliza cargas.',
              ),

              if (_sectionExpanded(_PassiveFormSection.charges)) ...[
                const SizedBox(height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: hasCharges,
                  title: const Text('Usa cargas'),
                  subtitle: const Text('Permite gastar y recuperar cargas'),
                  onChanged: (value) {
                    setState(() {
                      hasCharges = value;

                      if (!value) {
                        unlimitedCharges = false;
                      }
                    });
                  },
                ),

                if (hasCharges) ...[
                  const SizedBox(height: 4),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: unlimitedCharges,
                    title: const Text('Sin máximo'),
                    subtitle: const Text(
                      'Las cargas pueden aumentar sin un límite máximo',
                    ),
                    secondary: const Icon(Icons.all_inclusive_rounded),
                    onChanged: (value) {
                      setState(() {
                        unlimitedCharges = value;
                      });
                    },
                  ),

                  if (!unlimitedCharges) ...[
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: maxChargesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cargas máximas',
                        prefixIcon: Icon(Icons.battery_full_rounded),
                      ),
                      validator: (value) {
                        if (!hasCharges || unlimitedCharges) {
                          return null;
                        }

                        final parsed = int.tryParse(value?.trim() ?? '');

                        if (parsed == null || parsed <= 0) {
                          return 'Introduce un máximo válido';
                        }

                        return null;
                      },
                    ),
                  ],

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
              ],

              const SizedBox(height: 28),

              _sectionHeader(
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

                if (triggers.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('Esta pasiva no tiene triggers.'),
                  )
                else
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < triggers.length; i++) ...[
                          ListTile(
                            onTap: () {
                              editTrigger(i);
                            },
                            leading: const CircleAvatar(
                              child: Icon(Icons.bolt_rounded),
                            ),
                            title: Text(
                              _triggerTitle(triggers[i]),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(_triggerSubtitle(triggers[i])),
                            trailing: IconButton(
                              tooltip: 'Eliminar',
                              onPressed: () {
                                setState(() {
                                  triggers.removeAt(i);
                                });
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ),

                          if (i < triggers.length - 1) const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
              ],

              const SizedBox(height: 28),

              _sectionHeader(
                section: _PassiveFormSection.extraEffects,
                title: 'Efectos extra',
                icon: Icons.auto_awesome_rounded,
                subtitle:
                    'Bonificaciones automáticas al daño, críticos y curaciones.',
              ),

              if (_sectionExpanded(_PassiveFormSection.extraEffects)) ...[
                const SizedBox(height: 12),

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
              ],

              const SizedBox(height: 20),

              _sectionHeader(
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
                            'Esta pasiva no tiene efectos vinculados.',
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
              ],

              const SizedBox(height: 20),

              _sectionHeader(
                section: _PassiveFormSection.ownRoll,
                title: 'Tirada propia',
                icon: Icons.casino_rounded,
                subtitle: 'Permite tirar dados directamente desde esta pasiva.',
              ),

              if (_sectionExpanded(_PassiveFormSection.ownRoll)) ...[
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 2),

                                  Text(
                                    passiveRollPreview,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
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
                                      items: List.generate(20, (i) => i + 1)
                                          .map((value) {
                                            return DropdownMenuItem<int>(
                                              value: value,
                                              child: Text('$value'),
                                            );
                                          })
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
                                      decoration: const InputDecoration(
                                        labelText: 'Dado',
                                      ),
                                      items: const [4, 6, 8, 10, 12, 20].map((
                                        value,
                                      ) {
                                        return DropdownMenuItem<int>(
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
              ],

              const SizedBox(height: 28),

              _sectionHeader(
                section: _PassiveFormSection.notes,
                title: 'Notas',
                icon: Icons.notes_rounded,
                subtitle: 'Información adicional sobre esta pasiva.',
              ),

              if (_sectionExpanded(_PassiveFormSection.notes)) ...[
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
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  String _formulaBonusText(FormulaBonus bonus) {
    final pieces = <String>[];

    if (bonus.flatValue != 0) {
      pieces.add(bonusText(bonus.flatValue));
    }

    if (bonus.hasFormula) {
      final formatted = FormulaDisplayFormatter.format(
        bonus.formula!.expression,
        widget.character,
      );

      pieces.add('ƒ($formatted)');
    }

    return pieces.isEmpty ? '+0' : pieces.join(' + ');
  }

  Widget _sectionHeader({
    required _PassiveFormSection section,
    required String title,
    required IconData icon,
    String? subtitle,
    Widget? trailing,
  }) {
    final expanded = _sectionExpanded(section);

    return InkWell(
      onTap: () {
        _toggleSection(section);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(child: Icon(icon, size: 19)),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (subtitle != null) ...[
                    const SizedBox(height: 2),

                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),

            if (trailing != null) ...[trailing, const SizedBox(width: 4)],

            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              child: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulaBonusField({
    required String label,
    required TextEditingController controller,
  }) {
    final showTools = expandedFormulaTools.contains(controller);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Fórmula · $label',
            hintText: 'rounddown(level / 5)',
            prefixIcon: const Icon(Icons.functions_rounded),
          ),
          onChanged: (_) {
            setState(() {});
          },
        ),

        const SizedBox(height: 6),

        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                if (showTools) {
                  expandedFormulaTools.remove(controller);
                } else {
                  expandedFormulaTools.add(controller);
                }
              });
            },
            icon: Icon(
              showTools ? Icons.expand_less_rounded : Icons.functions_rounded,
            ),
            label: Text(
              showTools ? 'Ocultar herramientas' : 'Insertar en fórmula',
            ),
          ),
        ),

        if (showTools) ...[
          const SizedBox(height: 4),

          FormulaInsertBar(
            character: widget.character,
            onInsert: (value) {
              _insertFormulaText(controller, value);
            },
          ),
        ],

        if (controller.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),

          Text(
            'Lectura: ${FormulaDisplayFormatter.format(controller.text, widget.character)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }

  void _insertFormulaText(TextEditingController controller, String text) {
    final selection = controller.selection;
    final currentText = controller.text;

    final start = selection.isValid ? selection.start : currentText.length;

    final end = selection.isValid ? selection.end : currentText.length;

    final newText = currentText.replaceRange(start, end, text);

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + text.length),
    );

    setState(() {});
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

  final Character? character;

  final CharacterPassive? passive;

  const _DamageBonusEditorDialog({
    required this.bonus,
    this.character,
    this.passive,
  });

  @override
  State<_DamageBonusEditorDialog> createState() =>
      _DamageBonusEditorDialogState();
}

class _DamageBonusEditorDialogState extends State<_DamageBonusEditorDialog> {
  late DamageBonus bonus;

  late final TextEditingController nameController;

  late final TextEditingController typeController;

  late final TextEditingController flatController;

  late final TextEditingController formulaController;

  bool showFormulaTools = false;

  static const availableDice = [4, 6, 8, 10, 12, 20];

  @override
  void initState() {
    super.initState();

    bonus = DamageBonus.fromMap(widget.bonus.toMap());

    nameController = TextEditingController(text: bonus.name);

    typeController = TextEditingController(text: bonus.damageType);

    flatController = TextEditingController(text: '${bonus.flatBonus}');

    formulaController = TextEditingController(
      text: bonus.formula?.expression ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    typeController.dispose();
    flatController.dispose();
    formulaController.dispose();

    super.dispose();
  }

  void addDice() {
    setState(() {
      bonus.dicePools.add(DicePool(count: 1, sides: 6));
    });
  }

  void insertIntoFormula(String text) {
    final selection = formulaController.selection;
    final currentText = formulaController.text;

    final start = selection.isValid ? selection.start : currentText.length;

    final end = selection.isValid ? selection.end : currentText.length;

    final newText = currentText.replaceRange(start, end, text);

    var cursorOffset = start + text.length;

    // Si insertamos una función con paréntesis vacíos,
    // dejamos el cursor dentro.
    final emptyParenthesesIndex = text.indexOf('()');

    if (emptyParenthesesIndex >= 0) {
      cursorOffset = start + emptyParenthesesIndex + 1;
    } else {
      // Para funciones tipo:
      // min(, )
      // max(, )
      // if(, , )
      //
      // dejamos el cursor justo después del primer "(".
      final openParenthesisIndex = text.indexOf('(');

      if (openParenthesisIndex >= 0) {
        cursorOffset = start + openParenthesisIndex + 1;
      }
    }

    formulaController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );

    setState(() {});
  }

  FormulaResult? _formulaPreview() {
    final expression = formulaController.text.trim();

    if (expression.isEmpty) {
      return null;
    }

    final character = widget.character;

    /*
     * Sin personaje podemos guardar la
     * fórmula igualmente.
     *
     * Simplemente no podemos calcular
     * resource(...), counter(...), etc.
     */
    if (character == null) {
      return null;
    }

    final resolver = ResourceModifierResolver(character: character);

    return const FormulaEvaluator().evaluate(
      CharacterFormula(expression: expression),
      context: CharacterFormulaContext.fromCharacter(
        character,

        passive: widget.passive,

        resourceResolver: (resourceId) {
          final resource = character.resourceById(resourceId);

          if (resource == null) {
            return null;
          }

          final snapshot = resolver.resolveSnapshot(resource);

          return FormulaResourceValue(
            baseCurrentValue: snapshot.baseCurrentValue,
            baseMaxValue: snapshot.baseMaxValue,
            currentValue: snapshot.currentValue,
            maxValue: snapshot.maxValue,
          );
        },

        baseResourceResolver: (resourceId) {
          final resource = character.resourceById(resourceId);

          if (resource == null) {
            return null;
          }

          final baseMax = resource.hasMaximum
              ? resource.maxValue.toDouble()
              : null;

          return FormulaResourceValue(
            baseCurrentValue: resource.currentValue.toDouble(),
            baseMaxValue: baseMax,

            // En un resolver BASE,
            // efectivo == base.
            currentValue: resource.currentValue.toDouble(),
            maxValue: baseMax,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final preview = _formulaPreview();

    final friendlyFormula = FormulaDisplayFormatter.format(
      formulaController.text,
      widget.character,
    );

    return AlertDialog(
      title: const Text('Daño adicional'),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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

            // ===============================================================
            // DADOS
            // ===============================================================
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
                        items: List.generate(20, (i) => i + 1).map((value) {
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
                        decoration: const InputDecoration(labelText: 'Dado'),
                        items: availableDice.map((value) {
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

            const SizedBox(height: 18),

            // ===============================================================
            // ATRIBUTOS
            // ===============================================================
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
              decoration: const InputDecoration(
                labelText: 'Bonus fijo',
                hintText: 'Ej. 5 o -2',
              ),
            ),

            const SizedBox(height: 20),

            // ===============================================================
            // FÓRMULA
            // ===============================================================
            Text(
              'Fórmula',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Se suma al daño adicional. Puede usar nivel, atributos, recursos, cargas y contadores.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: formulaController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Fórmula adicional',
                hintText: 'resource(souls)',
                prefixIcon: Icon(Icons.functions_rounded),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),

            const SizedBox(height: 8),

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

            if (showFormulaTools) ...[
              const SizedBox(height: 4),

              FormulaInsertBar(
                character: widget.character,
                onInsert: insertIntoFormula,
              ),
            ],

            if (formulaController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Lectura: $friendlyFormula',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],

            if (formulaController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _FormulaPreview(
                  preview: preview,
                  hasCharacter: widget.character != null,
                ),
              ),
            ],
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

            bonus.flatBonus = int.tryParse(flatController.text.trim()) ?? 0;

            final expression = formulaController.text.trim();

            bonus.formula = expression.isEmpty
                ? null
                : CharacterFormula(expression: expression);

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
  final Character? character;
  final CharacterPassive? passive;

  const _HealingBonusEditorDialog({
    required this.bonus,
    this.character,
    this.passive,
  });

  @override
  State<_HealingBonusEditorDialog> createState() =>
      _HealingBonusEditorDialogState();
}

class _HealingBonusEditorDialogState extends State<_HealingBonusEditorDialog> {
  late HealingBonus bonus;

  late final TextEditingController nameController;

  late final TextEditingController flatController;

  late final TextEditingController formulaController;

  bool showFormulaTools = false;

  static const availableDice = [4, 6, 8, 10, 12, 20];

  @override
  void initState() {
    super.initState();

    bonus = HealingBonus.fromMap(widget.bonus.toMap());

    nameController = TextEditingController(text: bonus.name);

    flatController = TextEditingController(text: '${bonus.flatBonus}');

    formulaController = TextEditingController(
      text: bonus.formula?.expression ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    flatController.dispose();
    formulaController.dispose();

    super.dispose();
  }

  void insertIntoFormula(String text) {
    final selection = formulaController.selection;
    final current = formulaController.text;

    final start = selection.isValid ? selection.start : current.length;

    final end = selection.isValid ? selection.end : current.length;

    final newText = current.replaceRange(start, end, text);

    var cursor = start + text.length;

    final emptyParentheses = text.indexOf('()');

    if (emptyParentheses >= 0) {
      cursor = start + emptyParentheses + 1;
    } else {
      final opening = text.indexOf('(');

      if (opening >= 0) {
        cursor = start + opening + 1;
      }
    }

    formulaController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor),
    );

    setState(() {});
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

            const SizedBox(height: 16),

            TextFormField(
              controller: formulaController,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Fórmula adicional',
                hintText: 'if(health_percent < 50, SAB_MOD * 2, SAB_MOD)',
                prefixIcon: Icon(Icons.functions_rounded),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),

            const SizedBox(height: 8),

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

            if (showFormulaTools) ...[
              const SizedBox(height: 4),

              FormulaInsertBar(
                character: widget.character,
                onInsert: insertIntoFormula,
              ),
            ],
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

            bonus.flatBonus = int.tryParse(flatController.text.trim()) ?? 0;

            final expression = formulaController.text.trim();

            bonus.formula = expression.isEmpty
                ? null
                : CharacterFormula(expression: expression);

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
  final Character? character;
  final CharacterPassive? passive;

  const _CriticalDamageBonusEditorDialog({
    required this.bonus,
    this.character,
    this.passive,
  });

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

  late final TextEditingController formulaController;

  bool showFormulaTools = false;

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

    formulaController = TextEditingController(
      text: bonus.formula?.expression ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    typeController.dispose();
    chanceController.dispose();
    descriptionController.dispose();
    flatBonusController.dispose();
    formulaController.dispose();

    super.dispose();
  }

  void insertIntoFormula(String text) {
    final selection = formulaController.selection;
    final current = formulaController.text;

    final start = selection.isValid ? selection.start : current.length;

    final end = selection.isValid ? selection.end : current.length;

    final newText = current.replaceRange(start, end, text);

    var cursor = start + text.length;

    final emptyParentheses = text.indexOf('()');

    if (emptyParentheses >= 0) {
      cursor = start + emptyParentheses + 1;
    } else {
      final opening = text.indexOf('(');

      if (opening >= 0) {
        cursor = start + opening + 1;
      }
    }

    formulaController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor),
    );

    setState(() {});
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

            const SizedBox(height: 16),

            TextFormField(
              controller: formulaController,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Fórmula adicional',
                hintText: 'rounddown(level / 5)',
                prefixIcon: Icon(Icons.functions_rounded),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),

            const SizedBox(height: 8),

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

            if (showFormulaTools) ...[
              const SizedBox(height: 4),

              FormulaInsertBar(
                character: widget.character,
                onInsert: insertIntoFormula,
              ),
            ],

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

            bonus.chancePercent =
                int.tryParse(chanceController.text.trim()) ?? 100;

            final expression = formulaController.text.trim();

            bonus.formula = expression.isEmpty
                ? null
                : CharacterFormula(expression: expression);

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
        pieces.add(
          effect.durationNote.trim().isNotEmpty
              ? effect.durationNote.trim()
              : 'Duración personalizada',
        );
        break;
    }

    return pieces.join(' · ');
  }
}

class _FormulaPreview extends StatelessWidget {
  final FormulaResult? preview;

  final bool hasCharacter;

  const _FormulaPreview({required this.preview, required this.hasCharacter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!hasCharacter) {
      return Row(
        children: [
          const Icon(Icons.info_outline_rounded),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'La fórmula se guardará, pero no hay un personaje disponible para calcular la vista previa.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      );
    }

    final result = preview;

    if (result == null) {
      return const SizedBox.shrink();
    }

    if (!result.valid) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              result.error ?? 'La fórmula no es válida',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.check_circle_outline_rounded),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            'Resultado actual: ${result.displayValue}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResourceModifierEditorDialog extends StatefulWidget {
  final PassiveResourceModifier modifier;

  final Character character;

  final CharacterPassive? passive;

  const _ResourceModifierEditorDialog({
    required this.modifier,
    required this.character,
    this.passive,
  });

  @override
  State<_ResourceModifierEditorDialog> createState() =>
      _ResourceModifierEditorDialogState();
}

class _ResourceModifierEditorDialogState
    extends State<_ResourceModifierEditorDialog> {
  late PassiveResourceModifier modifier;

  late final TextEditingController formulaController;

  bool showFormulaTools = false;

  // ============================================================
  // INSERTAR EN FÓRMULA
  // ============================================================

  void insertIntoFormula(String text) {
    final selection = formulaController.selection;
    final currentText = formulaController.text;

    final start = selection.isValid ? selection.start : currentText.length;

    final end = selection.isValid ? selection.end : currentText.length;

    final newText = currentText.replaceRange(start, end, text);

    formulaController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + text.length),
    );

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    modifier = PassiveResourceModifier.fromMap(widget.modifier.toMap());

    formulaController = TextEditingController(
      text: modifier.formula.expression,
    );
  }

  @override
  void dispose() {
    formulaController.dispose();
    super.dispose();
  }

  FormulaResult? _formulaPreview() {
    final expression = formulaController.text.trim();

    if (expression.isEmpty) {
      return null;
    }

    final resolver = ResourceModifierResolver(character: widget.character);

    return const FormulaEvaluator().evaluate(
      CharacterFormula(expression: expression),
      context: CharacterFormulaContext.fromCharacter(
        widget.character,
        passive: widget.passive,

        resourceResolver: (resourceId) {
          final resource = widget.character.resourceById(resourceId);

          if (resource == null) {
            return null;
          }

          final snapshot = resolver.resolveSnapshot(resource);

          return FormulaResourceValue(
            baseCurrentValue: snapshot.baseCurrentValue,
            baseMaxValue: snapshot.baseMaxValue,
            currentValue: snapshot.currentValue,
            maxValue: snapshot.maxValue,
          );
        },

        baseResourceResolver: (resourceId) {
          final resource = widget.character.resourceById(resourceId);

          if (resource == null) {
            return null;
          }

          final baseMax = resource.hasMaximum
              ? resource.maxValue.toDouble()
              : null;

          return FormulaResourceValue(
            baseCurrentValue: resource.currentValue.toDouble(),
            baseMaxValue: baseMax,
            currentValue: resource.currentValue.toDouble(),
            maxValue: baseMax,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final preview = _formulaPreview();

    final friendlyFormula = FormulaDisplayFormatter.format(
      formulaController.text,
      widget.character,
    );

    return AlertDialog(
      title: const Text('Modificar recurso'),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: modifier.resourceId,
              decoration: const InputDecoration(
                labelText: 'Recurso',
                prefixIcon: Icon(Icons.account_balance_wallet_rounded),
              ),
              items: widget.character.resources
                  .map(
                    (resource) => DropdownMenuItem(
                      value: resource.id,
                      child: Text(resource.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  modifier.resourceId = value;
                });
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<PassiveResourceTarget>(
              initialValue: modifier.target,
              decoration: const InputDecoration(labelText: 'Valor a modificar'),
              items: PassiveResourceTarget.values.map((target) {
                return DropdownMenuItem(
                  value: target,
                  child: Text(
                    target == PassiveResourceTarget.current
                        ? 'Cantidad actual'
                        : 'Cantidad máxima',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  modifier.target = value;
                });
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<FormulaModifierOperation>(
              initialValue: modifier.operation,
              decoration: const InputDecoration(labelText: 'Operación'),
              items: FormulaModifierOperation.values.map((operation) {
                return DropdownMenuItem(
                  value: operation,
                  child: Text(operation.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  modifier.operation = value;
                });
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: formulaController,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Fórmula',
                hintText: 'rounddown(counter(kills) / 75)',
                prefixIcon: Icon(Icons.functions_rounded),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),

            const SizedBox(height: 10),

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

            if (showFormulaTools) ...[
              const SizedBox(height: 4),

              FormulaInsertBar(
                character: widget.character,
                onInsert: insertIntoFormula,
              ),
            ],

            if (formulaController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Lectura: $friendlyFormula',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _FormulaPreview(preview: preview, hasCharacter: true),
              ),
            ],
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
            final expression = formulaController.text.trim();

            modifier.formula = CharacterFormula(
              expression: expression.isEmpty ? '0' : expression,
            );

            Navigator.pop(context, modifier);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _FormulaBonusEditorDialog extends StatefulWidget {
  final String title;
  final FormulaBonus bonus;
  final Character? character;
  final CharacterPassive? passive;

  const _FormulaBonusEditorDialog({
    required this.title,
    required this.bonus,
    this.character,
    this.passive,
  });

  @override
  State<_FormulaBonusEditorDialog> createState() =>
      _FormulaBonusEditorDialogState();
}

class _FormulaBonusEditorDialogState extends State<_FormulaBonusEditorDialog> {
  late final TextEditingController flatController;

  late final TextEditingController formulaController;

  bool showFormulaTools = false;

  @override
  void initState() {
    super.initState();

    flatController = TextEditingController(text: '${widget.bonus.flatValue}');

    formulaController = TextEditingController(
      text: widget.bonus.formula?.expression ?? '',
    );
  }

  void insertIntoFormula(String text) {
    final selection = formulaController.selection;

    final current = formulaController.text;

    final start = selection.isValid ? selection.start : current.length;

    final end = selection.isValid ? selection.end : current.length;

    final newText = current.replaceRange(start, end, text);

    var cursor = start + text.length;

    final emptyParentheses = text.indexOf('()');

    if (emptyParentheses >= 0) {
      cursor = start + emptyParentheses + 1;
    } else {
      final opening = text.indexOf('(');

      if (opening >= 0) {
        cursor = start + opening + 1;
      }
    }

    formulaController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor),
    );

    setState(() {});
  }

  @override
  void dispose() {
    flatController.dispose();
    formulaController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final friendly = FormulaDisplayFormatter.format(
      formulaController.text,
      widget.character,
    );

    return AlertDialog(
      title: Text(widget.title),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: flatController,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(
                labelText: 'Bonus fijo',
                hintText: '0',
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: formulaController,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Fórmula opcional',
                hintText: 'rounddown(level / 5)',
                prefixIcon: Icon(Icons.functions_rounded),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),

            const SizedBox(height: 10),

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

            if (showFormulaTools) ...[
              const SizedBox(height: 4),

              FormulaInsertBar(
                character: widget.character,
                onInsert: insertIntoFormula,
              ),
            ],

            if (formulaController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 10),

              Text(
                'Lectura: $friendly',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
            final expression = formulaController.text.trim();

            Navigator.pop(
              context,
              FormulaBonus(
                flatValue: int.tryParse(flatController.text.trim()) ?? 0,
                formula: expression.isEmpty
                    ? null
                    : CharacterFormula(expression: expression),
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _TriggerEditorDialog extends StatefulWidget {
  final PassiveTrigger trigger;
  final Character? character;
  final CharacterPassive? passive;

  const _TriggerEditorDialog({
    required this.trigger,
    this.character,
    this.passive,
  });

  @override
  State<_TriggerEditorDialog> createState() => _TriggerEditorDialogState();
}

class _TriggerEditorDialogState extends State<_TriggerEditorDialog> {
  late PassiveTrigger trigger;

  late final TextEditingController conditionController;

  late final TextEditingController valueController;

  late final TextEditingController targetController;

  late final TextEditingController customEventController;

  bool showConditionTools = false;
  bool showValueTools = false;

  @override
  void initState() {
    super.initState();

    trigger = PassiveTrigger.fromMap(widget.trigger.toMap());

    conditionController = TextEditingController(
      text: trigger.condition?.expression ?? '',
    );

    valueController = TextEditingController(
      text: trigger.valueFormula?.expression ?? '1',
    );

    targetController = TextEditingController(text: trigger.targetId ?? '');

    customEventController = TextEditingController(
      text: trigger.customEvent ?? '',
    );
  }

  @override
  void dispose() {
    conditionController.dispose();
    valueController.dispose();
    targetController.dispose();
    customEventController.dispose();

    super.dispose();
  }

  void _insert(TextEditingController controller, String text) {
    final selection = controller.selection;

    final current = controller.text;

    final start = selection.isValid ? selection.start : current.length;

    final end = selection.isValid ? selection.end : current.length;

    final newText = current.replaceRange(start, end, text);

    var cursor = start + text.length;

    final emptyParentheses = text.indexOf('()');

    if (emptyParentheses >= 0) {
      cursor = start + emptyParentheses + 1;
    } else {
      final opening = text.indexOf('(');

      if (opening >= 0) {
        cursor = start + opening + 1;
      }
    }

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor),
    );

    setState(() {});
  }

  bool get _usesResource {
    switch (trigger.actionType) {
      case PassiveTriggerActionType.addResource:
      case PassiveTriggerActionType.subtractResource:
      case PassiveTriggerActionType.setResource:
        return true;

      default:
        return false;
    }
  }

  bool get _usesCounter {
    switch (trigger.actionType) {
      case PassiveTriggerActionType.incrementCounter:
      case PassiveTriggerActionType.setCounter:
        return true;

      default:
        return false;
    }
  }

  bool get _usesEffect {
    switch (trigger.actionType) {
      case PassiveTriggerActionType.applyEffect:
      case PassiveTriggerActionType.removeEffect:
        return true;

      default:
        return false;
    }
  }

  bool get _usesValue {
    switch (trigger.actionType) {
      case PassiveTriggerActionType.addResource:
      case PassiveTriggerActionType.subtractResource:
      case PassiveTriggerActionType.setResource:
      case PassiveTriggerActionType.addCharge:
      case PassiveTriggerActionType.subtractCharge:
      case PassiveTriggerActionType.dealDamage:
      case PassiveTriggerActionType.heal:
      case PassiveTriggerActionType.incrementCounter:
      case PassiveTriggerActionType.setCounter:
        return true;

      case PassiveTriggerActionType.applyEffect:
      case PassiveTriggerActionType.removeEffect:
        return false;
    }
  }

  String _eventLabel(PassiveTriggerEvent event) {
    switch (event) {
      case PassiveTriggerEvent.enemyKilled:
        return 'Al matar un enemigo';

      case PassiveTriggerEvent.damageDealt:
        return 'Al causar daño';

      case PassiveTriggerEvent.damageReceived:
        return 'Al recibir daño';

      case PassiveTriggerEvent.healed:
        return 'Al curar';

      case PassiveTriggerEvent.criticalHit:
        return 'Al realizar un crítico';

      case PassiveTriggerEvent.turnStarted:
        return 'Al empezar turno';

      case PassiveTriggerEvent.turnEnded:
        return 'Al terminar turno';

      case PassiveTriggerEvent.resourceChanged:
        return 'Al cambiar un recurso';

      case PassiveTriggerEvent.counterChanged:
        return 'Al cambiar un contador';

      case PassiveTriggerEvent.healthChanged:
        return 'Al cambiar la vida';

      case PassiveTriggerEvent.manual:
        return 'Activación manual';

      case PassiveTriggerEvent.custom:
        return 'Evento personalizado';

      case PassiveTriggerEvent.chargeChanged:
        return 'Al cambiar una carga';

      case PassiveTriggerEvent.roundStarted:
        return 'Al empezar una ronda';

      case PassiveTriggerEvent.roundEnded:
        return 'Al terminar una ronda';
    }
  }

  String _actionLabel(PassiveTriggerActionType action) {
    switch (action) {
      case PassiveTriggerActionType.addResource:
        return 'Añadir recurso';

      case PassiveTriggerActionType.subtractResource:
        return 'Gastar recurso';

      case PassiveTriggerActionType.setResource:
        return 'Establecer recurso';

      case PassiveTriggerActionType.addCharge:
        return 'Añadir carga';

      case PassiveTriggerActionType.subtractCharge:
        return 'Gastar carga';

      case PassiveTriggerActionType.applyEffect:
        return 'Aplicar efecto';

      case PassiveTriggerActionType.removeEffect:
        return 'Eliminar efecto';

      case PassiveTriggerActionType.dealDamage:
        return 'Causar daño';

      case PassiveTriggerActionType.heal:
        return 'Curar';

      case PassiveTriggerActionType.incrementCounter:
        return 'Incrementar contador';

      case PassiveTriggerActionType.setCounter:
        return 'Establecer contador';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Trigger'),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================================================================
            // EVENTO
            // ================================================================
            DropdownButtonFormField<PassiveTriggerEvent>(
              initialValue: trigger.event,
              decoration: const InputDecoration(
                labelText: 'Evento',
                prefixIcon: Icon(Icons.bolt_rounded),
              ),
              items: PassiveTriggerEvent.values.map((event) {
                return DropdownMenuItem(
                  value: event,
                  child: Text(_eventLabel(event)),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  trigger.event = value;
                });
              },
            ),

            if (trigger.event == PassiveTriggerEvent.custom) ...[
              const SizedBox(height: 12),

              TextFormField(
                controller: customEventController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del evento',
                  hintText: 'enemy_boss_killed',
                ),
              ),
            ],

            const SizedBox(height: 18),

            // ================================================================
            // CONDICIÓN
            // ================================================================
            Text(
              'Condición',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Opcional. El trigger solo se ejecuta cuando el resultado es distinto de 0.',
              style: theme.textTheme.bodySmall,
            ),

            const SizedBox(height: 10),

            TextFormField(
              controller: conditionController,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Condición',
                hintText: 'counter(kills) % 75 == 0',
                prefixIcon: Icon(Icons.rule_rounded),
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
                    showConditionTools = !showConditionTools;
                  });
                },
                icon: Icon(
                  showConditionTools
                      ? Icons.expand_less_rounded
                      : Icons.functions_rounded,
                ),
                label: Text(
                  showConditionTools
                      ? 'Ocultar herramientas'
                      : 'Insertar en condición',
                ),
              ),
            ),

            if (showConditionTools)
              FormulaInsertBar(
                character: widget.character,
                onInsert: (value) {
                  _insert(conditionController, value);
                },
              ),

            if (conditionController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 6),

              Text(
                'Lectura: ${FormulaDisplayFormatter.format(conditionController.text, widget.character)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ================================================================
            // ACCIÓN
            // ================================================================
            DropdownButtonFormField<PassiveTriggerActionType>(
              initialValue: trigger.actionType,
              decoration: const InputDecoration(
                labelText: 'Acción',
                prefixIcon: Icon(Icons.play_arrow_rounded),
              ),
              items: PassiveTriggerActionType.values.map((action) {
                return DropdownMenuItem(
                  value: action,
                  child: Text(_actionLabel(action)),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  trigger.actionType = value;

                  targetController.clear();
                });
              },
            ),

            // ================================================================
            // RECURSO
            // ================================================================
            if (_usesResource) ...[
              const SizedBox(height: 12),

              if (widget.character != null &&
                  widget.character!.resources.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue:
                      widget.character!.resourceById(targetController.text) !=
                          null
                      ? targetController.text
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Recurso',
                    prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                  ),
                  items: widget.character!.resources.map((resource) {
                    return DropdownMenuItem<String>(
                      value: resource.id,
                      child: Text(resource.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    targetController.text = value ?? '';
                  },
                )
              else
                const Text('El personaje no tiene recursos disponibles.'),
            ],

            // ================================================================
            // CONTADOR
            // ================================================================
            if (_usesCounter) ...[
              const SizedBox(height: 12),

              if (widget.character != null &&
                  widget.character!.counters.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue:
                      widget.character!.counters.any(
                        (counter) => counter.id == targetController.text,
                      )
                      ? targetController.text
                      : null,

                  decoration: const InputDecoration(
                    labelText: 'Contador',
                    prefixIcon: Icon(Icons.pin_rounded),
                  ),

                  items: widget.character!.counters.map((counter) {
                    return DropdownMenuItem<String>(
                      value: counter.id,
                      child: Text(
                        counter.name.trim().isEmpty ? counter.id : counter.name,
                      ),
                    );
                  }).toList(),

                  onChanged: (value) {
                    setState(() {
                      targetController.text = value ?? '';
                    });
                  },
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'Este personaje no tiene contadores disponibles.',
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            // ================================================================
            // EFECTO
            // ================================================================
            if (_usesEffect) ...[
              const SizedBox(height: 12),

              if (widget.character != null &&
                  widget.character!.effects.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue:
                      widget.character!.effects.any(
                        (effect) => effect.id == targetController.text,
                      )
                      ? targetController.text
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Efecto',
                    prefixIcon: Icon(Icons.auto_awesome_rounded),
                  ),
                  items: widget.character!.effects.map((effect) {
                    return DropdownMenuItem<String>(
                      value: effect.id,
                      child: Text(
                        effect.name.trim().isEmpty
                            ? 'Efecto sin nombre'
                            : effect.name,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      targetController.text = value ?? '';
                    });
                  },
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Este personaje no tiene efectos disponibles.',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            // ================================================================
            // VALOR
            // ================================================================
            if (_usesValue) ...[
              const SizedBox(height: 18),

              Text(
                'Valor',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: valueController,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Fórmula de valor',
                  hintText: '1',
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
                      showValueTools = !showValueTools;
                    });
                  },
                  icon: Icon(
                    showValueTools
                        ? Icons.expand_less_rounded
                        : Icons.functions_rounded,
                  ),
                  label: Text(
                    showValueTools
                        ? 'Ocultar herramientas'
                        : 'Insertar en valor',
                  ),
                ),
              ),

              if (showValueTools)
                FormulaInsertBar(
                  character: widget.character,
                  onInsert: (value) {
                    _insert(valueController, value);
                  },
                ),

              if (valueController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 6),

                Text(
                  'Lectura: ${FormulaDisplayFormatter.format(valueController.text, widget.character)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
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
            final condition = conditionController.text.trim();

            final value = valueController.text.trim();

            trigger.condition = condition.isEmpty
                ? null
                : CharacterFormula(expression: condition);

            trigger.valueFormula = _usesValue
                ? CharacterFormula(expression: value.isEmpty ? '0' : value)
                : null;

            trigger.targetId = targetController.text.trim().isEmpty
                ? null
                : targetController.text.trim();

            trigger.customEvent = trigger.event == PassiveTriggerEvent.custom
                ? customEventController.text.trim()
                : null;

            Navigator.pop(context, trigger);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
