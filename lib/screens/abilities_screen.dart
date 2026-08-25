import 'package:flutter/material.dart';
import 'package:rol/models/character_effect.dart';

import '../models/ability.dart';
import '../models/character.dart';
import '../models/dice_pool.dart';
import '../models/passive.dart';
import '../models/ability_resolution_summary.dart';
import '../models/action_execution_result.dart';
import '../models/action_resolution_context.dart';
import '../models/action_external_requirement.dart';
import '../models/action_resolution_plan.dart';
import '../models/action_cost.dart';
import '../models/action_optional_group.dart';
import '../models/action_attack_result.dart';
import '../models/action_resolution_result.dart';
import '../models/action_critical_profile.dart';
import '../models/action_saving_throw.dart';
import '../models/prepared_action_resolution.dart';
import '../models/action_dice_mode.dart';
import '../models/action_dice_request.dart';
import '../models/action_dice_result.dart';
import '../models/action_chance_check.dart';

import '../widgets/common/empty_state.dart';
import '../widgets/common/section_header.dart';
import '../widgets/combat/combat_action_sheet.dart';
import '../widgets/abilities/ability_card.dart';
import '../widgets/abilities/attack_roll_sheet.dart';
import '../widgets/abilities/ability_effects_result_dialog.dart';
import '../widgets/passives/passive_card.dart';

import '../services/character_storage_service.dart';
import '../services/action_resolver.dart';
import '../services/action_dice_resolver.dart';
import '../services/action_chance_resolver.dart';

import 'ability_form_screen.dart';
import 'passive_form_screen.dart';

class AbilitiesScreen extends StatefulWidget {
  final Character character;

  const AbilitiesScreen({super.key, required this.character});

  @override
  State<AbilitiesScreen> createState() => _AbilitiesScreenState();
}

class _AbilitiesScreenState extends State<AbilitiesScreen> {
  Character get character => widget.character;

  String _newLinkedEffectId(String originalId) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    return '${originalId}_applied_$timestamp';
  }

  List<CharacterEffect> _applyLinkedEffects(List<CharacterEffect> templates) {
    final applied = <CharacterEffect>[];

    for (final template in templates) {
      final effect = template.copyWith(
        id: _newLinkedEffectId(template.id),
        enabled: true,
        currentDuration: template.hasDuration ? template.maxDuration : 0,
      );

      effect.normalizeDuration();

      character.addEffect(effect);

      applied.add(effect);
    }

    return applied;
  }

  Future<ActionDiceMode?> _selectDiceMode() {
    return showModalBottomSheet<ActionDiceMode>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.casino_rounded),
                  title: const Text('Dados digitales'),
                  subtitle: const Text('Asteria realiza las tiradas.'),
                  onTap: () {
                    Navigator.pop(sheetContext, ActionDiceMode.digital);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.back_hand_rounded),
                  title: const Text('Dados físicos'),
                  subtitle: const Text(
                    'Tiras los dados y escribes los resultados.',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext, ActionDiceMode.physical);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<ActionPhysicalDiceInput?> _askPhysicalDiceForPart(
    ActionDiceRequestPart part,
  ) async {
    if (!part.requiresRoll) {
      return ActionPhysicalDiceInput(requestPartId: part.id, rolls: const []);
    }

    final controllers = <List<TextEditingController>>[];

    for (final pool in part.dicePools) {
      controllers.add(
        List<TextEditingController>.generate(
          pool.count,
          (_) => TextEditingController(),
        ),
      );
    }

    String? errorText;

    final result = await showDialog<ActionPhysicalDiceInput>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(part.effectName),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      part.diceNotation,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    if (part.modifier != 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Modificador: '
                        '${part.modifier > 0 ? '+' : ''}'
                        '${part.modifier}',
                      ),
                    ],

                    const SizedBox(height: 16),

                    for (
                      var poolIndex = 0;
                      poolIndex < part.dicePools.length;
                      poolIndex++
                    ) ...[
                      Text(
                        part.dicePools[poolIndex].notation,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),

                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          part.dicePools[poolIndex].count,
                          (dieIndex) {
                            final pool = part.dicePools[poolIndex];

                            return SizedBox(
                              width: 82,
                              child: TextField(
                                controller: controllers[poolIndex][dieIndex],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'd${pool.sides}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],

                    if (errorText != null)
                      Text(
                        errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),

                FilledButton(
                  onPressed: () {
                    final rolls = <List<int>>[];

                    for (
                      var poolIndex = 0;
                      poolIndex < part.dicePools.length;
                      poolIndex++
                    ) {
                      final pool = part.dicePools[poolIndex];

                      final poolRolls = <int>[];

                      for (final controller in controllers[poolIndex]) {
                        final value = int.tryParse(controller.text.trim());

                        if (value == null || value < 1 || value > pool.sides) {
                          setDialogState(() {
                            errorText =
                                'Cada d${pool.sides} debe estar entre '
                                '1 y ${pool.sides}.';
                          });

                          return;
                        }

                        poolRolls.add(value);
                      }

                      rolls.add(poolRolls);
                    }

                    Navigator.pop(
                      dialogContext,
                      ActionPhysicalDiceInput(
                        requestPartId: part.id,
                        rolls: rolls,
                      ),
                    );
                  },
                  child: const Text('Continuar'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  Future<ActionDiceResult?> _resolvePhysicalDiceRequest(
    ActionDiceRequest request,
  ) async {
    final inputs = <ActionPhysicalDiceInput>[];

    final rollableParts = request.parts
        .where((part) => part.requiresRoll)
        .toList(growable: false);

    for (var i = 0; i < rollableParts.length; i++) {
      final part = rollableParts[i];

      if (!mounted) {
        return null;
      }

      final input = await _askPhysicalDiceForPart(part);

      if (input == null) {
        return null;
      }

      inputs.add(input);

      // Si todavía queda otra parte, esperamos a que
      // Flutter termine de desmontar el diálogo actual.
      if (i < rollableParts.length - 1) {
        await WidgetsBinding.instance.endOfFrame;

        if (!mounted) {
          return null;
        }
      }
    }

    final resolver = const ActionDiceResolver();

    return resolver.resolvePhysical(request: request, inputs: inputs);
  }

  Future<ActionResolutionResult?> _resolvePreparedAction({
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    ActionAttackResult? attackResult,
    required List<ActionSavingThrowResult> savingThrowResults,
    ActionDiceMode? diceMode,
  }) async {
    final effectiveDiceMode = diceMode ?? await _selectDiceMode();

    if (effectiveDiceMode == null) {
      return null;
    }

    final critical = resolver.preparedActionIsCritical(
      prepared: prepared,
      attackResult: attackResult,
    );

    final chanceResults = await _resolveCriticalChanceChecks(
      resolver: resolver,
      prepared: prepared,
      critical: critical,
      diceMode: effectiveDiceMode,
    );

    if (chanceResults == null) {
      return null;
    }

    final successfulChanceIds = resolver.successfulChanceCheckIds(
      chanceResults,
    );

    switch (effectiveDiceMode) {
      case ActionDiceMode.digital:
        return resolver.resolvePreparedAbilityDigital(
          prepared: prepared,
          attackResult: attackResult,
          savingThrowResults: savingThrowResults,
          preResolvedChanceResults: chanceResults,
        );

      case ActionDiceMode.physical:
        switch (prepared.ability.targetResolutionMode) {
          case AbilityTargetResolutionMode.shared:
            final request = resolver.buildPreparedDiceRequest(
              prepared: prepared,
              attackResult: attackResult,
              successfulChanceCheckIds: successfulChanceIds,
            );

            final diceResult = await _resolvePhysicalDiceRequest(request);

            if (diceResult == null) {
              return null;
            }

            return resolver.buildPreparedSharedResolution(
              prepared: prepared,
              diceResult: diceResult,
              attackResult: attackResult,
              chanceResults: chanceResults,
              savingThrowResults: savingThrowResults,
            );

          case AbilityTargetResolutionMode.independent:
            final results = await _resolveIndependentPhysicalDice(
              resolver: resolver,
              prepared: prepared,
              attackResult: attackResult,
              successfulChanceCheckIds: successfulChanceIds,
            );

            if (results == null) {
              return null;
            }

            return resolver.buildPreparedIndependentResolution(
              prepared: prepared,
              diceResultsByTargetId: results,
              attackResult: attackResult,
              chanceResults: chanceResults,
              savingThrowResults: savingThrowResults,
            );
        }
    }
  }

  Future<List<ActionSavingThrowResult>?> _collectSavingThrowResults({
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
  }) async {
    final requests = resolver.collectSavingThrowRequests(prepared: prepared);

    if (requests.isEmpty) {
      return const [];
    }

    final results = <ActionSavingThrowResult>[];

    for (final request in requests) {
      final saved = await _askSavingThrowResult(request);

      if (saved == null) {
        return null;
      }

      results.add(ActionSavingThrowResult(request: request, saved: saved));
    }

    return results;
  }

  Future<bool?> _askSavingThrowResult(ActionSavingThrowRequest request) {
    String targetLabel = request.targetId;

    if (request.targetId == 'self') {
      targetLabel = character.name.isNotEmpty ? character.name : 'Tu personaje';
    } else {
      final number = RegExp(r'\d+$').firstMatch(request.targetId)?.group(0);

      targetLabel = number == null ? 'Objetivo' : 'Objetivo $number';
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tirada de salvación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                targetLabel,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 12),

              Text(request.effectName),

              const SizedBox(height: 12),

              Text(
                'Salvación de '
                '${request.ability.name}',
              ),

              const SizedBox(height: 4),

              Text(
                'CD ${request.dc}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 16),

              Text(_saveSuccessDescription(request.successEffect)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('No supera'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Supera'),
            ),
          ],
        );
      },
    );
  }

  String _saveSuccessDescription(SaveSuccessEffect effect) {
    switch (effect) {
      case SaveSuccessEffect.full:
        return 'Si supera la salvación, '
            'el efecto mantiene su valor completo.';

      case SaveSuccessEffect.half:
        return 'Si supera la salvación, '
            'el resultado se reduce a la mitad.';

      case SaveSuccessEffect.none:
        return 'Si supera la salvación, '
            'el resultado de este efecto pasa a 0.';
    }
  }

  Future<void> applyAbilityLinkedEffects(CharacterAbility ability) async {
    if (ability.linkedEffects.isEmpty) {
      return;
    }

    late List<CharacterEffect> applied;

    setState(() {
      applied = _applyLinkedEffects(ability.linkedEffects);

      character.normalizeHealth();
    });

    await save();

    if (!mounted || applied.isEmpty) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          applied.length == 1
              ? 'Se ha aplicado ${applied.first.name}.'
              : 'Se han aplicado ${applied.length} efectos.',
        ),
      ),
    );
  }

  Future<void> applyPassiveLinkedEffects(CharacterPassive passive) async {
    if (!passive.enabled || passive.linkedEffects.isEmpty) {
      return;
    }

    late List<CharacterEffect> applied;

    setState(() {
      applied = _applyLinkedEffects(passive.linkedEffects);

      character.normalizeHealth();
    });

    await save();

    if (!mounted || applied.isEmpty) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          applied.length == 1
              ? 'Se ha aplicado ${applied.first.name}.'
              : 'Se han aplicado ${applied.length} efectos.',
        ),
      ),
    );
  }

  Future<bool> _collectSharedOptionalChoices({
    required ActionResolver resolver,
    required ActionResolutionPlan plan,
    required ActionResolutionContext actionContext,
  }) async {
    final groups = resolver.availableOptionalGroups(
      plan: plan,
      context: actionContext,
    );

    for (final group in groups) {
      final validation = resolver.validateOptionalGroupSelection(
        plan: plan,
        context: actionContext,
        group: group,
      );

      final selected = await _askOptionalGroup(
        group: group,
        validation: validation,
        targetLabel: null,
      );

      if (selected == null) {
        return false;
      }

      actionContext.setOptionalGroupSelected(group.id, selected);
    }

    return true;
  }

  Future<bool> _collectIndependentOptionalChoices({
    required ActionResolver resolver,
    required ActionResolutionPlan plan,
    required ActionResolutionContext actionContext,
  }) async {
    for (final target in actionContext.targets) {
      final groups = resolver.availableOptionalGroups(
        plan: plan,
        context: actionContext,
        target: target,
      );

      for (final group in groups) {
        final validation = resolver.validateOptionalGroupSelection(
          plan: plan,
          context: actionContext,
          group: group,
          target: target,
        );

        final selected = await _askOptionalGroup(
          group: group,
          validation: validation,
          targetLabel: target.isSelf ? character.name : target.label,
        );

        if (selected == null) {
          return false;
        }

        actionContext.setOptionalGroupSelectedForTarget(
          target.id,
          group.id,
          selected,
        );
      }
    }

    return true;
  }

  Future<bool> _collectOptionalChoices({
    required ActionResolver resolver,
    required ActionResolutionPlan plan,
    required ActionResolutionContext actionContext,
  }) async {
    switch (plan.ability.targetResolutionMode) {
      case AbilityTargetResolutionMode.shared:
        return _collectSharedOptionalChoices(
          resolver: resolver,
          plan: plan,
          actionContext: actionContext,
        );

      case AbilityTargetResolutionMode.independent:
        return _collectIndependentOptionalChoices(
          resolver: resolver,
          plan: plan,
          actionContext: actionContext,
        );
    }
  }

  Future<bool?> _askOptionalGroup({
    required ActionOptionalGroup group,
    required ActionCostValidationResult validation,
    String? targetLabel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Componente opcional'),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (targetLabel != null && targetLabel.trim().isNotEmpty) ...[
                Text(
                  targetLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 12),
              ],

              Text(group.label, style: Theme.of(context).textTheme.titleMedium),

              if (group.costs.isNotEmpty) ...[
                const SizedBox(height: 12),

                const Text(
                  'Coste:',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 4),

                ...group.costs.map((cost) => Text(_actionCostLabel(cost))),
              ],

              if (!validation.valid) ...[
                const SizedBox(height: 16),

                Text(
                  validation.error ?? 'No puedes pagar este coste.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('No'),
            ),

            FilledButton(
              onPressed: validation.valid
                  ? () {
                      Navigator.pop(dialogContext, true);
                    }
                  : null,
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );
  }

  String _actionCostLabel(ActionCost cost) {
    final label = cost.label?.trim();

    final name = label != null && label.isNotEmpty
        ? label
        : switch (cost.type) {
            ActionCostType.resource => 'Recurso',

            ActionCostType.passiveCharge => 'Carga',

            ActionCostType.abilityUse => 'Uso',
          };

    return '• ${cost.amount} × $name';
  }

  bool _canUseNewSimpleResolver(CharacterAbility ability) {
    // ---------------------------------------------------------------------------
    // ATAQUES
    //
    // Todavía mantenemos el flujo antiguo para habilidades con tirada de ataque
    // hasta migrar completamente:
    // - ventaja/desventaja
    // - ActionAttackResult
    // - rango crítico efectivo
    // - crítico normal/potenciado
    // ---------------------------------------------------------------------------

    if (ability.requiresAttackRoll) {
      return false;
    }

    // ---------------------------------------------------------------------------
    // TARGETING
    //
    // Todos los tipos de objetivo ya pueden pasar por el flujo nuevo:
    // - self
    // - external
    // - selfOrExternal
    // - multipleExternal
    // - areaIncludingSelf
    // - areaExcludingSelf
    //
    // Tanto resolución compartida como independiente ya están soportadas.
    // ---------------------------------------------------------------------------

    // No bloqueamos ningún AbilityTargetType aquí.

    // ---------------------------------------------------------------------------
    // PREGUNTAS EXTERNAS
    //
    // Ya están soportadas:
    // - booleanos
    // - porcentajes
    // - deduplicación
    // - inferencia
    // - respuestas por objetivo
    //
    // Por tanto NO bloqueamos externalRequirements.
    // ---------------------------------------------------------------------------

    // ---------------------------------------------------------------------------
    // OPCIONALES
    //
    // Ya están soportados:
    // - opcionales normales
    // - condicional + opcional
    // - grupos independientes
    // - selección por target en resolución independiente
    //
    // Por tanto NO bloqueamos AbilityEffectPart.optional.
    // ---------------------------------------------------------------------------

    return true;
  }

  Future<void> showAbilityCombatActions(CharacterAbility ability) async {
    final hasEffects = ability.effects.any((effect) => effect.hasEffect);

    final hasLinkedEffects = ability.linkedEffects.isNotEmpty;

    final canResolve = hasEffects || hasLinkedEffects;

    await CombatActionSheet.show(
      context,

      title: ability.name,

      subtitle: 'Habilidad',

      canAttack: ability.requiresAttackRoll,

      canDamage: ability.dealsDamage,

      canCritical: ability.requiresAttackRoll && ability.dealsDamage,

      canHeal: ability.heals,

      canUse: canResolve,

      // =========================================================
      // ATAQUE
      // =========================================================
      onAttack: () async {
        final handled = await _tryRollAttackWithNewResolver(ability);

        if (handled) {
          return;
        }

        await rollAttack(ability);
      },

      // =========================================================
      // DAÑO NORMAL
      // =========================================================
      onDamage: () async {
        final handled = await _tryResolveWithNewSimpleResolver(ability);

        if (handled) {
          return;
        }

        // -------------------------------------------------------------------------
        // FALLBACK LEGACY
        // -------------------------------------------------------------------------

        final paid = await payAbilityCosts(ability);

        if (!paid) {
          return;
        }

        await resolveAllEffects(ability, critical: false);

        await applyAbilityLinkedEffects(ability);
      },

      // =========================================================
      // CRÍTICO MANUAL
      // =========================================================
      onCritical: () async {
        await _tryResolveManualCriticalWithNewResolver(
          ability,
          empowered: true,
        );
      },

      // =========================================================
      // CURACIÓN
      // =========================================================
      onHeal: () async {
        final handled = await _tryResolveWithNewSimpleResolver(ability);

        if (handled) {
          return;
        }

        // -------------------------------------------------------------------------
        // FALLBACK LEGACY
        // -------------------------------------------------------------------------

        final paid = await payAbilityCosts(ability);

        if (!paid) {
          return;
        }

        await resolveAllEffects(ability, critical: false);

        await applyAbilityLinkedEffects(ability);

        if (!mounted) {
          return;
        }

        setState(() {});
      },

      // =========================================================
      // USAR / RESOLVER
      // =========================================================
      onUse: () async {
        final handled = await _tryResolveWithNewSimpleResolver(ability);

        if (handled) {
          return;
        }

        await useAndResolveAbility(ability);
      },
    );
  }

  Future<bool> _collectExternalActionAnswers({
    required CharacterAbility ability,
    required ActionResolver resolver,
    required ActionResolutionContext actionContext,
  }) async {
    final requirements = resolver.collectExternalRequirements(ability: ability);

    if (requirements.isEmpty) {
      return true;
    }

    for (final target in actionContext.targets) {
      final completed = await _collectAnswersForTarget(
        target: target,
        requirements: requirements,
        actionContext: actionContext,
      );

      if (!completed) {
        return false;
      }
    }

    return true;
  }

  Future<bool> _collectAnswersForTarget({
    required ActionTarget target,
    required List<ActionExternalRequirement> requirements,
    required ActionResolutionContext actionContext,
  }) async {
    // =========================================================================
    // BOOLEANOS
    // =========================================================================

    final booleanRequirements = requirements
        .where(
          (requirement) =>
              requirement.type == ActionExternalRequirementType.boolean,
        )
        .toList(growable: false);

    for (final requirement in booleanRequirements) {
      final answer = await _askBooleanRequirement(
        target: target,
        requirement: requirement,
      );

      if (answer == null) {
        return false;
      }

      actionContext.applyTargetExternalRequirementAnswer(
        target.id,
        requirement,
        answer,
      );
    }

    // =========================================================================
    // PORCENTAJES
    //
    // Ya no separamos:
    // <
    // <=
    // >
    // >=
    //
    // El planner/resolver conoce el operador de cada requirement.
    // =========================================================================

    final percentageRequirements = requirements
        .where((requirement) => requirement.isPercentageRequirement)
        .toList(growable: false);

    return _collectPercentageAnswers(
      target: target,
      requirements: percentageRequirements,
      actionContext: actionContext,
    );
  }

  Future<bool?> _askBooleanRequirement({
    required ActionTarget target,
    required ActionExternalRequirement requirement,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(target.label ?? 'Objetivo'),
          content: Text(requirement.label),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _collectPercentageAnswers({
    required ActionTarget target,
    required List<ActionExternalRequirement> requirements,
    required ActionResolutionContext actionContext,
  }) async {
    if (requirements.isEmpty) {
      return true;
    }

    final planner = const ExternalPercentageQuestionPlanner();

    final resolver = const ExternalPercentageAnswerResolver();

    final ordered = planner.order(requirements);

    // La key incluye variable + operador + threshold.
    //
    // Ejemplos:
    // target_health_percent_lt_50
    // target_health_percent_lte_50
    // target_health_percent_gt_50
    // target_health_percent_gte_50
    final answers = <String, bool>{};

    for (final requirement in ordered) {
      final threshold = requirement.threshold;
      final operator = requirement.percentageOperator;

      if (threshold == null || operator == null) {
        continue;
      }

      // =======================================================================
      // 1. ¿YA CONOCEMOS EL PORCENTAJE EXACTO?
      //
      // Esto ocurre, por ejemplo, con self.
      // Si sabemos currentHealth/maxHealth, no preguntamos nada.
      // =======================================================================

      final knownAnswer = actionContext.evaluateKnownTargetHealthThreshold(
        target,
        operator: operator,
        threshold: threshold,
      );

      if (knownAnswer != null) {
        answers[requirement.normalizedVariableName] = knownAnswer;

        actionContext.applyTargetExternalRequirementAnswer(
          target.id,
          requirement,
          knownAnswer,
        );

        actionContext.setTargetHealthThresholdAnswer(
          target,
          operator: operator,
          threshold: threshold,
          answer: knownAnswer,
        );

        continue;
      }

      // =======================================================================
      // 2. ¿PODEMOS INFERIRLO DE RESPUESTAS ANTERIORES?
      // =======================================================================

      final inferredValues = resolver.resolve(
        requirements: ordered,
        answers: answers,
      );

      final inferred = inferredValues[requirement.normalizedVariableName];

      if (inferred != null) {
        final inferredAnswer = inferred != 0;

        answers[requirement.normalizedVariableName] = inferredAnswer;

        actionContext.applyTargetExternalRequirementAnswer(
          target.id,
          requirement,
          inferredAnswer,
        );

        actionContext.setTargetHealthThresholdAnswer(
          target,
          operator: operator,
          threshold: threshold,
          answer: inferredAnswer,
        );

        continue;
      }

      // =======================================================================
      // 3. NO LO SABEMOS -> PREGUNTAMOS
      // =======================================================================

      final answer = await _askBooleanRequirement(
        target: target,
        requirement: requirement,
      );

      if (answer == null) {
        return false;
      }

      answers[requirement.normalizedVariableName] = answer;

      actionContext.applyTargetExternalRequirementAnswer(
        target.id,
        requirement,
        answer,
      );

      actionContext.setTargetHealthThresholdAnswer(
        target,
        operator: operator,
        threshold: threshold,
        answer: answer,
      );

      // =======================================================================
      // 4. PROPAGAR TODO LO QUE PODAMOS INFERIR
      // =======================================================================

      final inferredAfterAnswer = resolver.resolve(
        requirements: ordered,
        answers: answers,
      );

      for (final entry in inferredAfterAnswer.entries) {
        final inferredRequirement = ordered
            .cast<ActionExternalRequirement?>()
            .firstWhere(
              (candidate) => candidate?.normalizedVariableName == entry.key,
              orElse: () => null,
            );

        if (inferredRequirement == null) {
          continue;
        }

        final inferredAnswer = entry.value != 0;

        answers[entry.key] = inferredAnswer;

        actionContext.applyTargetExternalRequirementAnswer(
          target.id,
          inferredRequirement,
          inferredAnswer,
        );

        final inferredOperator = inferredRequirement.percentageOperator;

        final inferredThreshold = inferredRequirement.threshold;

        if (inferredOperator != null && inferredThreshold != null) {
          actionContext.setTargetHealthThresholdAnswer(
            target,
            operator: inferredOperator,
            threshold: inferredThreshold,
            answer: inferredAnswer,
          );
        }
      }
    }

    return true;
  }

  Future<bool> _tryResolveWithNewSimpleResolver(
    CharacterAbility ability,
  ) async {
    if (!_canUseNewSimpleResolver(ability)) {
      return false;
    }

    final resolver = ActionResolver(character: character);

    final selectedTargets = await _selectAbilityTargets(ability);

    if (selectedTargets == null) {
      return true;
    }

    final actionContext = ActionResolutionContext(
      character: character,
      targets: selectedTargets,
    );

    actionContext.populateKnownTargetVariables();

    final answersCompleted = await _collectExternalActionAnswers(
      ability: ability,
      resolver: resolver,
      actionContext: actionContext,
    );

    if (!answersCompleted) {
      return true;
    }

    try {
      // =========================================================================
      // PLAN INICIAL
      //
      // Se utiliza para descubrir qué componentes opcionales están realmente
      // disponibles después de haber respondido las condiciones externas.
      // =========================================================================

      final initialPlan = resolver.prepareAbilityPlan(
        ability: ability,
        context: actionContext,
      );

      // =========================================================================
      // OPCIONALES
      // =========================================================================

      final optionalChoicesCompleted = await _collectOptionalChoices(
        resolver: resolver,
        plan: initialPlan,
        actionContext: actionContext,
      );

      if (!optionalChoicesCompleted) {
        return true;
      }

      // =========================================================================
      // PREPARACIÓN DEFINITIVA
      //
      // Ahora el ActionResolutionContext ya contiene:
      // - objetivos;
      // - respuestas externas;
      // - opcionales seleccionados.
      // =========================================================================

      final prepared = resolver.prepareAbilityAction(
        ability: ability,
        context: actionContext,
      );

      final savingThrowResults = await _collectSavingThrowResults(
        resolver: resolver,
        prepared: prepared,
      );

      if (savingThrowResults == null) {
        return true;
      }

      // =========================================================================
      // VALIDAR COSTES
      // =========================================================================

      final validation = resolver.validatePreparedActionCosts(prepared);

      if (!validation.valid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                validation.error ??
                    'No puedes pagar los costes de esta habilidad.',
              ),
            ),
          );
        }

        return true;
      }

      // -------------------------------------------------------------------------
      // RESOLUCIÓN DIGITAL
      //
      // Este primer flujo no tiene ataque ni salvaciones.
      // -------------------------------------------------------------------------

      final resolution = await _resolvePreparedAction(
        resolver: resolver,
        prepared: prepared,
        savingThrowResults: savingThrowResults,
      );

      if (resolution == null) {
        return true;
      }

      // -------------------------------------------------------------------------
      // COMMIT
      //
      // Aquí:
      // - revalidamos costes;
      // - pagamos;
      // - aplicamos self;
      // - producimos triggers;
      // - conservamos resultados externos.
      // -------------------------------------------------------------------------

      final execution = resolver.commitResolution(resolution);

      // -------------------------------------------------------------------------
      // PERSISTENCIA
      // -------------------------------------------------------------------------

      await save();

      if (!mounted) {
        return true;
      }

      setState(() {});

      await _showNewResolutionResult(execution);

      return true;
    } catch (error) {
      if (!mounted) {
        return true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se ha podido resolver la habilidad: $error'),
        ),
      );

      return true;
    }
  }

  Future<bool> _tryRollAttackWithNewResolver(CharacterAbility ability) async {
    if (!ability.requiresAttackRoll) {
      return false;
    }

    final resolver = ActionResolver(character: character);

    // =========================================================================
    // TARGETS
    // =========================================================================

    final selectedTargets = await _selectAbilityTargets(ability);

    if (selectedTargets == null) {
      return true;
    }

    final actionContext = ActionResolutionContext(
      character: character,
      targets: selectedTargets,
    );

    actionContext.populateKnownTargetVariables();

    // =========================================================================
    // INFORMACIÓN EXTERNA
    // =========================================================================

    final answersCompleted = await _collectExternalActionAnswers(
      ability: ability,
      resolver: resolver,
      actionContext: actionContext,
    );

    if (!answersCompleted) {
      return true;
    }

    try {
      // =======================================================================
      // PLAN PARA DESCUBRIR OPCIONALES
      // =======================================================================

      final initialPlan = resolver.prepareAbilityPlan(
        ability: ability,
        context: actionContext,
      );

      final optionalChoicesCompleted = await _collectOptionalChoices(
        resolver: resolver,
        plan: initialPlan,
        actionContext: actionContext,
      );

      if (!optionalChoicesCompleted) {
        return true;
      }

      // =======================================================================
      // PREPARACIÓN DEFINITIVA
      // =======================================================================

      final prepared = resolver.prepareAbilityAction(
        ability: ability,
        context: actionContext,
      );

      // =======================================================================
      // VALIDAR COSTES
      // =======================================================================

      final validation = resolver.validatePreparedActionCosts(prepared);

      if (!validation.valid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                validation.error ??
                    'No puedes pagar los costes de esta habilidad.',
              ),
            ),
          );
        }

        return true;
      }

      // =======================================================================
      // VENTAJA / DESVENTAJA
      // =======================================================================

      final mode = await showAttackRollModeSheet(context);

      if (mode == null || !mounted) {
        return true;
      }

      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) {
        return true;
      }

      final diceMode = await _selectDiceMode();

      if (diceMode == null || !mounted) {
        return true;
      }

      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) {
        return true;
      }

      // =======================================================================
      // PAGAR UNA SOLA VEZ
      //
      // Aquí entran:
      // - recurso base;
      // - uso;
      // - opcionales seleccionados;
      // - cargas opcionales.
      // =======================================================================

      final payment = resolver.payPreparedActionCosts(prepared);

      if (!payment.valid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                payment.error ?? 'No se han podido pagar los costes.',
              ),
            ),
          );
        }

        return true;
      }

      await save();

      if (!mounted) {
        return true;
      }

      // =======================================================================
      // TIRADA DE ATAQUE
      // =======================================================================

      await _performPreparedAttackRoll(
        resolver: resolver,
        prepared: prepared,
        mode: mode,
        diceMode: diceMode,
      );

      return true;
    } catch (error) {
      if (!mounted) {
        return true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se ha podido resolver el ataque: $error')),
      );

      return true;
    }
  }

  Future<int?> _askPhysicalD20({
    required String title,
    required String label,
  }) async {
    final controller = TextEditingController();

    String? errorText;

    final result = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(title),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(label),

                  const SizedBox(height: 16),

                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Resultado del d20',
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),

                FilledButton(
                  onPressed: () {
                    final value = int.tryParse(controller.text.trim());

                    if (value == null || value < 1 || value > 20) {
                      setDialogState(() {
                        errorText = 'Introduce un resultado entre 1 y 20.';
                      });

                      return;
                    }

                    Navigator.pop(dialogContext, value);
                  },
                  child: const Text('Continuar'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  Future<({int firstRoll, int? secondRoll})?> _resolveAttackD20s({
    required AttackRollMode attackMode,
    required ActionDiceMode diceMode,
  }) async {
    switch (diceMode) {
      // =========================================================================
      // DIGITAL
      // =========================================================================

      case ActionDiceMode.digital:
        final firstResult = DicePoolRoller.roll(
          pools: [DicePool(count: 1, sides: 20)],
        );

        final firstRoll = firstResult.groups.first.rolls.first;

        if (attackMode == AttackRollMode.normal) {
          return (firstRoll: firstRoll, secondRoll: null);
        }

        final secondResult = DicePoolRoller.roll(
          pools: [DicePool(count: 1, sides: 20)],
        );

        final secondRoll = secondResult.groups.first.rolls.first;

        return (firstRoll: firstRoll, secondRoll: secondRoll);

      // =========================================================================
      // FÍSICO
      // =========================================================================

      case ActionDiceMode.physical:
        final firstRoll = await _askPhysicalD20(
          title: 'Tirada de ataque',
          label: attackMode == AttackRollMode.normal
              ? 'Tira 1d20.'
              : 'Tira el primer d20.',
        );

        if (firstRoll == null) {
          return null;
        }

        if (attackMode == AttackRollMode.normal) {
          return (firstRoll: firstRoll, secondRoll: null);
        }

        // El primer diálogo acaba de cerrarse.
        // Dejamos que Flutter termine de desmontarlo antes
        // de construir el segundo.
        await WidgetsBinding.instance.endOfFrame;

        if (!mounted) {
          return null;
        }

        final secondRoll = await _askPhysicalD20(
          title: 'Tirada de ataque',
          label: 'Tira el segundo d20.',
        );

        if (secondRoll == null) {
          return null;
        }

        return (firstRoll: firstRoll, secondRoll: secondRoll);
    }
  }

  Future<bool> _tryResolveManualCriticalWithNewResolver(
    CharacterAbility ability, {
    bool empowered = false,
  }) async {
    final resolver = ActionResolver(character: character);

    final selectedTargets = await _selectAbilityTargets(ability);

    if (selectedTargets == null) {
      return true;
    }

    final actionContext = ActionResolutionContext(
      character: character,
      targets: selectedTargets,
    );

    actionContext.populateKnownTargetVariables();

    final answersCompleted = await _collectExternalActionAnswers(
      ability: ability,
      resolver: resolver,
      actionContext: actionContext,
    );

    if (!answersCompleted) {
      return true;
    }

    try {
      // =======================================================================
      // DESCUBRIR OPCIONALES
      // =======================================================================

      final initialPlan = resolver.prepareAbilityPlan(
        ability: ability,
        context: actionContext,
      );

      final optionalChoicesCompleted = await _collectOptionalChoices(
        resolver: resolver,
        plan: initialPlan,
        actionContext: actionContext,
      );

      if (!optionalChoicesCompleted) {
        return true;
      }

      // =======================================================================
      // PREPARACIÓN DEFINITIVA
      // =======================================================================

      final prepared = resolver.prepareAbilityAction(
        ability: ability,
        context: actionContext,

        forcedCritical: true,
        empoweredCritical: empowered,
      );

      // =======================================================================
      // SALVACIONES
      // =======================================================================

      final savingThrowResults = await _collectSavingThrowResults(
        resolver: resolver,
        prepared: prepared,
      );

      if (savingThrowResults == null) {
        return true;
      }

      // =======================================================================
      // COSTES
      // =======================================================================

      final validation = resolver.validatePreparedActionCosts(prepared);

      if (!validation.valid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                validation.error ??
                    'No puedes pagar los costes de esta habilidad.',
              ),
            ),
          );
        }

        return true;
      }

      // =======================================================================
      // FÍSICO / DIGITAL
      // =======================================================================

      final diceMode = await _selectDiceMode();

      if (diceMode == null || !mounted) {
        return true;
      }

      // Dejamos terminar el bottom sheet antes de abrir
      // cualquier diálogo físico posterior.
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) {
        return true;
      }

      // =======================================================================
      // RESOLUCIÓN
      //
      // Utilizamos exactamente el mismo pipeline que:
      // - daño normal;
      // - ataque;
      // - multiobjetivo;
      // - crítico extra;
      // - físico/digital.
      // =======================================================================

      final resolution = await _resolvePreparedAction(
        resolver: resolver,
        prepared: prepared,
        savingThrowResults: savingThrowResults,
        diceMode: diceMode,
      );

      if (resolution == null) {
        return true;
      }

      final execution = resolver.commitResolution(resolution);

      await save();

      if (!mounted) {
        return true;
      }

      setState(() {});

      await _showNewResolutionResult(execution);

      return true;
    } catch (error) {
      if (!mounted) {
        return true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se ha podido resolver el crítico: $error')),
      );

      return true;
    }
  }

  Future<void> _performPreparedAttackRoll({
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    required AttackRollMode mode,
    required ActionDiceMode diceMode,
  }) async {
    final ability = prepared.ability;

    final bonus = character.characterAbilityAttackBonus(ability);

    // ===========================================================================
    // D20
    // ===========================================================================

    final rolls = await _resolveAttackD20s(
      attackMode: mode,
      diceMode: diceMode,
    );

    if (rolls == null || !mounted) {
      return;
    }

    final firstRoll = rolls.firstRoll;
    final secondRoll = rolls.secondRoll;

    var naturalRoll = firstRoll;

    if (secondRoll != null) {
      switch (mode) {
        case AttackRollMode.normal:
          naturalRoll = firstRoll;
          break;

        case AttackRollMode.advantage:
          naturalRoll = firstRoll > secondRoll ? firstRoll : secondRoll;
          break;

        case AttackRollMode.disadvantage:
          naturalRoll = firstRoll < secondRoll ? firstRoll : secondRoll;
          break;
      }
    }

    // ===========================================================================
    // RESULTADO ATAQUE
    // ===========================================================================

    final attackResult = resolver.resolveAttackRoll(
      naturalRoll: naturalRoll,
      modifier: bonus,
      criticalProfile: prepared.criticalProfile,
    );

    final criticalFailure = attackResult.naturalRoll == 1;

    final canRollDamage =
        ability.effects.any((effect) => effect.hasEffect) ||
        ability.linkedEffects.isNotEmpty;

    // ===========================================================================
    // MOSTRAR RESULTADO
    //
    // IMPORTANTE:
    // El dialog solamente devuelve una decisión.
    // NO inicia aquí mismo la siguiente resolución.
    // ===========================================================================

    final rollDamage = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AttackResultDialog(
          abilityName: ability.name,
          mode: mode,

          firstRoll: firstRoll,
          secondRoll: secondRoll,

          naturalRoll: attackResult.naturalRoll,

          bonus: attackResult.modifier,

          total: attackResult.total,

          critical: attackResult.critical,

          criticalFailure: criticalFailure,

          onRollDamage: canRollDamage
              ? () {
                  Navigator.pop(dialogContext, true);
                }
              : null,
        );
      },
    );

    if (rollDamage != true || !mounted) {
      return;
    }

    // Dejamos terminar completamente este frame.
    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) {
      return;
    }

    // ===========================================================================
    // CONTINUAR LA MISMA ACCIÓN
    // ===========================================================================

    await _resolvePreparedAttackDamage(
      resolver: resolver,
      prepared: prepared,
      attackResult: attackResult,
      diceMode: diceMode,
    );
  }

  Future<void> _resolvePreparedAttackDamage({
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    required ActionAttackResult attackResult,
    required ActionDiceMode diceMode,
  }) async {
    try {
      final savingThrowResults = await _collectSavingThrowResults(
        resolver: resolver,
        prepared: prepared,
      );

      if (savingThrowResults == null) {
        return;
      }

      final resolution = await _resolvePreparedAction(
        resolver: resolver,
        prepared: prepared,
        attackResult: attackResult,
        savingThrowResults: savingThrowResults,
        diceMode: diceMode,
      );

      if (resolution == null) {
        return;
      }

      final execution = resolver.commitResolution(
        resolution,

        // El ataque ya pagó los costes antes del d20.
        payCosts: false,
      );

      await save();

      if (!mounted) {
        return;
      }

      setState(() {});

      await _showNewResolutionResult(execution);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se ha podido resolver el daño: $error')),
      );
    }
  }

  Future<ActionChanceResult?> _askPhysicalChanceCheck(
    ActionChanceCheck check,
  ) async {
    final controller = TextEditingController();

    String? errorText;

    final result = await showDialog<ActionChanceResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(check.label),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Probabilidad: ${check.normalizedChance}%'),

                  const SizedBox(height: 12),

                  const Text('Tira 1d100 e introduce el resultado.'),

                  const SizedBox(height: 12),

                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Resultado d100',
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),

                FilledButton(
                  onPressed: () {
                    final value = int.tryParse(controller.text.trim());

                    if (value == null || value < 1 || value > 100) {
                      setDialogState(() {
                        errorText = 'Introduce un valor entre 1 y 100.';
                      });

                      return;
                    }

                    final resolver = ActionChanceResolver();

                    Navigator.pop(
                      dialogContext,
                      resolver.resolvePhysical(check: check, roll: value),
                    );
                  },
                  child: const Text('Continuar'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    return result;
  }

  Future<List<ActionChanceResult>?> _resolveCriticalChanceChecks({
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    required bool critical,
    required ActionDiceMode diceMode,
  }) async {
    if (!critical) {
      return const [];
    }

    final checks = resolver.collectCriticalChanceChecks(critical: true);

    if (checks.isEmpty) {
      return const [];
    }

    final results = <ActionChanceResult>[];

    final chanceResolver = ActionChanceResolver();

    for (final check in checks) {
      ActionChanceResult? result;

      switch (diceMode) {
        case ActionDiceMode.digital:
          result = chanceResolver.rollDigital(check);
          break;

        case ActionDiceMode.physical:
          result = await _askPhysicalChanceCheck(check);
          break;
      }

      if (result == null) {
        return null;
      }

      results.add(result);
    }

    return List.unmodifiable(results);
  }

  bool _preparedActionIsCritical({
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    ActionAttackResult? attackResult,
  }) {
    return resolver.preparedActionIsCritical(
      prepared: prepared,
      attackResult: attackResult,
    );
  }

  Future<Map<String, ActionDiceResult>?> _resolveIndependentPhysicalDice({
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    ActionAttackResult? attackResult,
    Set<String> successfulChanceCheckIds = const {},
  }) async {
    final results = <String, ActionDiceResult>{};

    for (final target in prepared.context.targets) {
      final request = resolver.buildPreparedDiceRequest(
        prepared: prepared,
        attackResult: attackResult,
        target: target,
        successfulChanceCheckIds: successfulChanceCheckIds,
      );

      if (request.parts.isEmpty) {
        results[target.id] = const ActionDiceResult(parts: []);

        continue;
      }

      if (!mounted) {
        return null;
      }

      final targetLabel = target.isSelf
          ? (character.name.isNotEmpty ? character.name : 'Tu personaje')
          : target.label ?? 'Objetivo';

      // =========================================================================
      // AVISO DEL OBJETIVO
      // =========================================================================

      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(targetLabel),
            content: const Text(
              'Introduce ahora los resultados '
              'de los dados para este objetivo.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Continuar'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return null;
      }

      // Esperamos a que el diálogo anterior desaparezca
      // completamente antes de abrir el de dados.
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) {
        return null;
      }

      // =========================================================================
      // DADOS DEL OBJETIVO
      // =========================================================================

      final diceResult = await _resolvePhysicalDiceRequest(request);

      if (diceResult == null) {
        return null;
      }

      results[target.id] = diceResult;

      // _resolvePhysicalDiceRequest puede haber cerrado uno
      // o varios diálogos. Dejamos terminar el frame antes
      // de comenzar con el siguiente objetivo.
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) {
        return null;
      }
    }

    return Map<String, ActionDiceResult>.unmodifiable(results);
  }

  Future<void> _showNewResolutionResult(ActionExecutionResult execution) async {
    if (!mounted) {
      return;
    }

    final resolution = execution.resolution;
    final application = execution.application;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(resolution.ability.name),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final targetResult in resolution.targetResults) ...[
                  Text(
                    targetResult.target.isSelf
                        ? character.name
                        : targetResult.target.label ?? 'Objetivo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (targetResult.damage > 0)
                    Text('Daño: ${targetResult.damage}'),

                  if (targetResult.healing > 0)
                    Text('Curación: ${targetResult.healing}'),

                  if (targetResult.effects.isNotEmpty) ...[
                    const SizedBox(height: 8),

                    ...targetResult.effects.map(
                      (effect) => Text('Efecto: ${effect.name}'),
                    ),
                  ],

                  if (targetResult.damage <= 0 &&
                      targetResult.healing <= 0 &&
                      targetResult.effects.isEmpty)
                    const Text('Sin resultado numérico.'),

                  const SizedBox(height: 18),
                ],

                const Divider(),

                const SizedBox(height: 8),

                if (application.selfDamageApplied > 0)
                  Text(
                    'Daño aplicado a tu personaje: '
                    '${application.selfDamageApplied}',
                  ),

                if (application.selfHealingApplied > 0)
                  Text(
                    'Curación aplicada a tu personaje: '
                    '${application.selfHealingApplied}',
                  ),

                if (application.externalDamageDealt > 0)
                  Text(
                    'Daño externo calculado: '
                    '${application.externalDamageDealt}',
                  ),

                if (application.externalHealingDealt > 0)
                  Text(
                    'Curación externa calculada: '
                    '${application.externalHealingDealt}',
                  ),

                if (application.externalEffects.isNotEmpty) ...[
                  const SizedBox(height: 8),

                  ...application.externalEffects.map(
                    (entry) => Text(
                      '${entry.targetLabel ?? 'Objetivo'}: '
                      '${entry.effect.name}',
                    ),
                  ),
                ],
              ],
            ),
          ),

          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<List<ActionTarget>?> _selectAbilityTargets(
    CharacterAbility ability,
  ) async {
    switch (ability.targetType) {
      case AbilityTargetType.self:
        return const [ActionTarget.self()];

      case AbilityTargetType.external:
        return const [
          ActionTarget(
            id: 'target_1',
            kind: ActionTargetKind.external,
            label: 'Objetivo',
          ),
        ];

      case AbilityTargetType.selfOrExternal:
        final selected = await showDialog<ActionTarget>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Seleccionar objetivo'),
              content: const Text('¿A quién quieres dirigir esta habilidad?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      const ActionTarget(
                        id: 'target_1',
                        kind: ActionTargetKind.external,
                        label: 'Objetivo',
                      ),
                    );
                  },
                  child: const Text('Otro objetivo'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, const ActionTarget.self());
                  },
                  child: Text(
                    character.name.isNotEmpty ? character.name : 'A mí',
                  ),
                ),
              ],
            );
          },
        );

        if (selected == null) {
          return null;
        }

        return [selected];

      case AbilityTargetType.multipleExternal:
        final count = await _askExternalTargetCount(
          title: 'Número de objetivos',
          message: '¿A cuántos objetivos externos afecta esta habilidad?',
        );

        if (count == null) {
          return null;
        }

        return _buildExternalTargets(count);

      case AbilityTargetType.areaIncludingSelf:
        final count = await _askExternalTargetCount(
          title: 'Objetivos del área',
          message:
              'Además de ${character.name.isNotEmpty ? character.name : 'tu personaje'}, '
              '¿a cuántos objetivos externos afecta el área?',
          allowZero: true,
        );

        if (count == null) {
          return null;
        }

        return [const ActionTarget.self(), ..._buildExternalTargets(count)];

      case AbilityTargetType.areaExcludingSelf:
        final count = await _askExternalTargetCount(
          title: 'Objetivos del área',
          message: '¿A cuántos objetivos externos afecta el área?',
        );

        if (count == null) {
          return null;
        }

        return _buildExternalTargets(count);
    }
  }

  List<ActionTarget> _buildExternalTargets(int count) {
    return List<ActionTarget>.generate(count, (index) {
      final number = index + 1;

      return ActionTarget(
        id: 'target_$number',
        kind: ActionTargetKind.external,
        label: count == 1 ? 'Objetivo' : 'Objetivo $number',
      );
    }, growable: false);
  }

  Future<int?> _askExternalTargetCount({
    required String title,
    required String message,
    bool allowZero = false,
  }) async {
    final controller = TextEditingController(text: allowZero ? '0' : '1');

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        String? errorText;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(title),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(message),

                  const SizedBox(height: 16),

                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Cantidad de objetivos',
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),

                FilledButton(
                  onPressed: () {
                    final value = int.tryParse(controller.text.trim());

                    final minimum = allowZero ? 0 : 1;

                    if (value == null || value < minimum) {
                      setDialogState(() {
                        errorText = allowZero
                            ? 'Introduce 0 o más.'
                            : 'Introduce al menos 1.';
                      });

                      return;
                    }

                    Navigator.pop(dialogContext, value);
                  },
                  child: const Text('Continuar'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    return result;
  }

  // ===========================================================================
  // GUARDAR
  // ===========================================================================

  Future<void> save() async {
    await CharacterStorageService.saveCharacter(character);
  }

  // ===========================================================================
  // CREAR HABILIDAD
  // ===========================================================================

  Future<void> createAbility() async {
    final ability = await Navigator.push<CharacterAbility>(
      context,
      MaterialPageRoute(
        builder: (_) => AbilityFormScreen(character: character),
      ),
    );

    if (ability == null) {
      return;
    }

    setState(() {
      character.addCharacterAbility(ability);
    });

    await save();
  }

  // ===========================================================================
  // EDITAR HABILIDAD
  // ===========================================================================

  Future<void> editAbility(CharacterAbility ability) async {
    final result = await Navigator.push<CharacterAbility>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AbilityFormScreen(ability: ability, character: character),
      ),
    );

    if (result == null) {
      return;
    }

    final index = character.characterAbilities.indexWhere(
      (item) => item.id == result.id,
    );

    if (index < 0) {
      return;
    }

    setState(() {
      character.characterAbilities[index] = result;
    });

    await save();
  }

  // ===========================================================================
  // ELIMINAR HABILIDAD
  // ===========================================================================

  Future<void> deleteAbility(CharacterAbility ability) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar habilidad'),
          content: Text('¿Quieres eliminar "${ability.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      character.removeCharacterAbility(ability.id);
    });

    await save();
  }

  // ===========================================================================
  // CREAR PASIVA
  // ===========================================================================

  Future<void> createPassive() async {
    final passive = await Navigator.push<CharacterPassive>(
      context,
      MaterialPageRoute(
        builder: (_) => PassiveFormScreen(character: character),
      ),
    );

    if (passive == null) {
      return;
    }

    setState(() {
      character.addPassive(passive);

      character.normalizeHealth();
    });

    await save();
  }

  // ===========================================================================
  // EDITAR PASIVA
  // ===========================================================================

  Future<void> editPassive(CharacterPassive passive) async {
    final result = await Navigator.push<CharacterPassive>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PassiveFormScreen(character: character, passive: passive),
      ),
    );

    if (result == null) {
      return;
    }

    final index = character.passives.indexWhere((item) => item.id == result.id);

    if (index < 0) {
      return;
    }

    setState(() {
      character.passives[index] = result;

      character.normalizeHealth();
    });

    await save();
  }

  Future<void> usePassiveCharge(CharacterPassive passive) async {
    setState(() {
      passive.useCharge();
    });

    await save();
  }

  Future<void> restorePassiveCharge(CharacterPassive passive) async {
    setState(() {
      passive.restoreCharge();
    });

    await save();
  }

  Future<void> restoreAllPassiveCharges(CharacterPassive passive) async {
    setState(() {
      passive.restoreCharges();
    });

    await save();
  }

  // ===========================================================================
  // ELIMINAR PASIVA
  // ===========================================================================

  Future<void> deletePassive(CharacterPassive passive) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar pasiva'),
          content: Text('¿Quieres eliminar "${passive.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      character.removePassive(passive.id);

      character.normalizeHealth();
    });

    await save();
  }

  // ===========================================================================
  // ACTIVAR / DESACTIVAR PASIVA
  // ===========================================================================

  Future<void> togglePassive(CharacterPassive passive, bool value) async {
    setState(() {
      passive.enabled = value;

      character.normalizeHealth();
    });

    await save();
  }

  // ===========================================================================
  // USOS DE HABILIDADES
  // ===========================================================================

  Future<void> useAbility(CharacterAbility ability) async {
    if (!ability.hasLimitedUses) {
      return;
    }

    if (ability.currentUses <= 0) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No quedan usos disponibles.')),
      );

      return;
    }

    setState(() {
      character.useCharacterAbility(ability);
    });

    await save();
  }

  Future<void> restoreAbility(CharacterAbility ability) async {
    setState(() {
      character.restoreCharacterAbility(ability);
    });

    await save();
  }

  Future<void> restoreAllAbilities() async {
    setState(() {
      character.restoreAllAbilities();
    });

    await save();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Usos restaurados.')));
  }

  bool canUseAbility(CharacterAbility ability) {
    if (ability.hasLimitedUses && ability.currentUses <= 0) {
      return false;
    }

    if (!character.canPayAbilityResource(ability)) {
      return false;
    }

    return true;
  }

  String? abilityUnavailableReason(CharacterAbility ability) {
    if (ability.hasLimitedUses && ability.currentUses <= 0) {
      return 'No quedan usos';
    }

    if (ability.usesResource) {
      final resource = character.resourceForAbility(ability);

      if (resource == null) {
        return 'Recurso no disponible';
      }

      if (resource.currentValue < ability.resourceCost) {
        return 'Falta ${resource.name}';
      }
    }

    return null;
  }

  Future<void> useAndResolveAbility(CharacterAbility ability) async {
    final paid = await payAbilityCosts(ability);

    if (!paid) {
      return;
    }

    await resolveAllEffects(ability);

    await applyAbilityLinkedEffects(ability);
  }

  Future<bool> payAbilityCosts(
    CharacterAbility ability, {
    bool payResource = true,
    bool payUse = true,
  }) async {
    // =========================================================================
    // COMPROBAR USOS
    // =========================================================================

    if (payUse && ability.hasLimitedUses && ability.currentUses <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No quedan usos disponibles.')),
        );
      }

      return false;
    }

    // =========================================================================
    // COMPROBAR RECURSO
    // =========================================================================

    if (payResource && ability.usesResource) {
      final resource = character.resourceForAbility(ability);

      if (resource == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El recurso asociado ya no existe.')),
          );
        }

        return false;
      }

      if (resource.currentValue < ability.resourceCost) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No tienes suficiente ${resource.name}. '
                'Necesitas ${ability.resourceCost}.',
              ),
            ),
          );
        }

        return false;
      }
    }

    // =========================================================================
    // PAGAR TODO A LA VEZ
    // =========================================================================

    setState(() {
      if (payResource && ability.usesResource) {
        character.payAbilityResource(ability);
      }

      if (payUse && ability.hasLimitedUses) {
        character.useCharacterAbility(ability);
      }
    });

    await save();

    return true;
  }

  // ===========================================================================
  // TIRAR PASIVA
  // ===========================================================================

  Future<void> rollPassive(CharacterPassive passive) async {
    if (!passive.enabled || !passive.hasRoll) {
      return;
    }

    final result = character.rollPassive(passive);

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.casino_rounded),

              const SizedBox(width: 10),

              Expanded(child: Text(passive.name)),
            ],
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                character.passiveRollText(passive),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text(
                      'RESULTADO',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${result.total}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              if (result.groups.isNotEmpty) ...[
                const SizedBox(height: 16),

                ...result.groups.map((group) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(group.pool.notation)),

                        Text(
                          group.rolls.join(', '),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              if (result.modifier != 0) ...[
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Expanded(child: Text('Modificador')),

                    Text(
                      result.modifier > 0
                          ? '+${result.modifier}'
                          : '${result.modifier}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ],
          ),

          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);

                rollPassive(passive);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Volver a tirar'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // RESOLVER EFECTOS
  // ===========================================================================

  Future<AbilityResolutionSummary?> resolveAllEffects(
    CharacterAbility ability, {
    bool critical = false,
  }) async {
    final effects = ability.effects
        .where((effect) => effect.hasEffect)
        .toList();

    if (effects.isEmpty) {
      return null;
    }

    if (!mounted) {
      return null;
    }

    final result = await showDialog<AbilityResolutionSummary>(
      context: context,
      builder: (_) {
        return AbilityEffectsResultDialog(
          ability: ability,
          character: character,
          critical: critical,

          onRerollAttack: ability.requiresAttackRoll
              ? () {
                  rollAttack(ability);
                }
              : null,

          onPayRerollCosts: !ability.requiresAttackRoll
              ? () {
                  return payAbilityCosts(ability);
                }
              : null,
        );
      },
    );

    if (result == null) {
      return null;
    }

    // =========================================================================
    // DAÑO REALIZADO
    // =========================================================================

    if (result.damage > 0) {
      character.dispatchPassiveTrigger(
        PassiveTriggerEvent.damageDealt,
        eventVariables: {
          'damage_dealt': result.damage.toDouble(),
          'critical': result.critical ? 1 : 0,
        },
      );
    }

    // =========================================================================
    // CURACIÓN REALIZADA
    // =========================================================================

    if (result.healing > 0) {
      character.dispatchPassiveTrigger(
        PassiveTriggerEvent.healingDealt,
        eventVariables: {'healing': result.healing.toDouble()},
      );
    }

    await save();

    if (mounted) {
      setState(() {});
    }

    return result;
  }

  // ===========================================================================
  // ATAQUE
  // ===========================================================================

  Future<void> rollAttack(
    CharacterAbility ability, {
    bool payCosts = true,
  }) async {
    final mode = await showAttackRollModeSheet(context);

    if (mode == null || !mounted) {
      return;
    }

    if (payCosts) {
      final paid = await payAbilityCosts(ability);

      if (!paid) {
        return;
      }
    }

    _performAttackRoll(ability, mode);
  }

  void _performAttackRoll(CharacterAbility ability, AttackRollMode mode) {
    final resolver = ActionResolver(character: character);

    final bonus = character.characterAbilityAttackBonus(ability);

    // =========================================================================
    // PRIMER D20
    // =========================================================================

    final firstResult = DicePoolRoller.roll(
      pools: [DicePool(count: 1, sides: 20)],
    );

    final firstRoll = firstResult.groups.first.rolls.first;

    // =========================================================================
    // SEGUNDO D20
    // =========================================================================

    int? secondRoll;

    var naturalRoll = firstRoll;

    if (mode != AttackRollMode.normal) {
      final secondResult = DicePoolRoller.roll(
        pools: [DicePool(count: 1, sides: 20)],
      );

      secondRoll = secondResult.groups.first.rolls.first;

      switch (mode) {
        case AttackRollMode.normal:
          naturalRoll = firstRoll;
          break;

        case AttackRollMode.advantage:
          naturalRoll = firstRoll > secondRoll ? firstRoll : secondRoll;
          break;

        case AttackRollMode.disadvantage:
          naturalRoll = firstRoll < secondRoll ? firstRoll : secondRoll;
          break;
      }
    }

    // =========================================================================
    // PERFIL CRÍTICO
    // =========================================================================

    final criticalProfile = resolver.buildCriticalProfileForAbility(ability);

    final attackResult = resolver.resolveAttackRoll(
      naturalRoll: naturalRoll,
      modifier: bonus,
      criticalProfile: criticalProfile,
    );

    final criticalFailure = naturalRoll == 1;

    // =========================================================================
    // EVENTO CRÍTICO
    // =========================================================================

    if (attackResult.critical) {
      character.dispatchPassiveTrigger(
        PassiveTriggerEvent.criticalHit,
        eventVariables: {
          'critical': 1,
          'attack_roll': attackResult.naturalRoll.toDouble(),
          'attack_total': attackResult.total.toDouble(),
          'critical_range_min': attackResult.effectiveCriticalMinimumRoll
              .toDouble(),
        },
      );

      save();
    }

    // =========================================================================
    // POPUP
    // =========================================================================

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AttackResultDialog(
          abilityName: ability.name,
          mode: mode,
          firstRoll: firstRoll,
          secondRoll: secondRoll,
          naturalRoll: attackResult.naturalRoll,
          bonus: attackResult.modifier,
          total: attackResult.total,
          critical: attackResult.critical,
          criticalFailure: criticalFailure,

          onRollDamage:
              ability.effects.any((effect) => effect.hasEffect) ||
                  ability.linkedEffects.isNotEmpty
              ? () async {
                  Navigator.pop(dialogContext);

                  await resolveAllEffects(
                    ability,
                    critical: attackResult.critical,
                  );

                  await applyAbilityLinkedEffects(ability);
                }
              : null,
        );
      },
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------------------------
    // HABILIDADES
    // -------------------------------------------------------------------------

    final abilities = character.availableAbilities;

    // -------------------------------------------------------------------------
    // PASIVAS DE OBJETOS EQUIPADOS
    // -------------------------------------------------------------------------

    final itemPassives = character.items
        .where((item) => item.equipped)
        .expand((item) => item.passives)
        .toList();

    // -------------------------------------------------------------------------
    // TODAS LAS PASIVAS
    // -------------------------------------------------------------------------

    final passives = [...character.passives, ...itemPassives];

    final empty = abilities.isEmpty && passives.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habilidades'),
        actions: [
          if (abilities.any((ability) => ability.hasLimitedUses))
            IconButton(
              tooltip: 'Restaurar usos',
              onPressed: restoreAllAbilities,
              icon: const Icon(Icons.restart_alt_rounded),
            ),

          PopupMenuButton<String>(
            tooltip: 'Crear',
            icon: const Icon(Icons.add_rounded),
            onSelected: (value) {
              switch (value) {
                case 'ability':
                  createAbility();
                  break;

                case 'passive':
                  createPassive();
                  break;
              }
            },
            itemBuilder: (_) {
              return const [
                PopupMenuItem(
                  value: 'ability',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.flash_on_rounded),
                    title: Text('Nueva habilidad'),
                  ),
                ),

                PopupMenuItem(
                  value: 'passive',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.auto_awesome_rounded),
                    title: Text('Nueva pasiva'),
                  ),
                ),
              ];
            },
          ),
        ],
      ),

      // =======================================================================
      // CONTENIDO
      // =======================================================================
      body: empty
          ? EmptyState(
              icon: Icons.auto_awesome_rounded,
              title: 'Sin habilidades',
              message:
                  'Añade habilidades activas, ataques, poderes, rasgos y efectos pasivos.',
              actionLabel: 'Crear habilidad',
              onAction: createAbility,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
              children: [
                // =============================================================
                // HABILIDADES ACTIVAS
                // =============================================================
                if (abilities.isNotEmpty) ...[
                  SectionHeader(
                    icon: Icons.flash_on_rounded,
                    title: 'Habilidades',
                    subtitle:
                        '${abilities.length} ${abilities.length == 1 ? 'habilidad' : 'habilidades'}',
                  ),

                  const SizedBox(height: 12),

                  ...abilities.map((ability) {
                    final sourceItem = character.itemForAbility(ability);

                    return AbilityCard(
                      ability: ability,

                      character: character,

                      sourceItem: sourceItem,

                      onEdit: sourceItem == null
                          ? () {
                              editAbility(ability);
                            }
                          : null,

                      onDelete: sourceItem == null
                          ? () {
                              deleteAbility(ability);
                            }
                          : null,

                      onRestore: ability.hasLimitedUses
                          ? () {
                              restoreAbility(ability);
                            }
                          : null,

                      onUse: () {
                        useAbility(ability);
                      },

                      onCombatActions: () {
                        showAbilityCombatActions(ability);
                      },
                    );
                  }),

                  if (passives.isNotEmpty) const SizedBox(height: 24),
                ],

                // =============================================================
                // PASIVAS
                // =============================================================
                if (passives.isNotEmpty) ...[
                  SectionHeader(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Pasivas',
                    subtitle:
                        '${passives.length} ${passives.length == 1 ? 'pasiva' : 'pasivas'}',
                  ),

                  const SizedBox(height: 12),

                  ...passives.map((passive) {
                    final sourceItem = character.itemForPassive(passive);

                    final isItemPassive = sourceItem != null;

                    return PassiveCard(
                      passive: passive,

                      sourceItem: sourceItem,

                      showPassiveBadge: true,

                      onRoll: passive.hasRoll
                          ? () {
                              rollPassive(passive);
                            }
                          : null,

                      onApplyLinkedEffects: passive.linkedEffects.isNotEmpty
                          ? () {
                              applyPassiveLinkedEffects(passive);
                            }
                          : null,

                      onUseCharge: passive.usesCharges
                          ? () {
                              usePassiveCharge(passive);
                            }
                          : null,

                      onRestoreCharges: passive.usesCharges
                          ? () {
                              restorePassiveCharge(passive);
                            }
                          : null,

                      onToggle: isItemPassive
                          ? null
                          : (value) {
                              togglePassive(passive, value);
                            },

                      onEdit: isItemPassive
                          ? null
                          : () {
                              editPassive(passive);
                            },

                      onDelete: isItemPassive
                          ? null
                          : () {
                              deletePassive(passive);
                            },
                    );
                  }),
                ],
              ],
            ),

      // =======================================================================
      // CREAR
      // =======================================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateMenu();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Añadir'),
      ),
    );
  }

  // ===========================================================================
  // MENÚ CREAR
  // ===========================================================================

  Future<void> _showCreateMenu() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.flash_on_rounded),
                  title: const Text('Nueva habilidad'),
                  subtitle: const Text(
                    'Ataques, poderes, curaciones y técnicas',
                  ),
                  onTap: () {
                    Navigator.pop(context, 'ability');
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.auto_awesome_rounded),
                  title: const Text('Nueva pasiva'),
                  subtitle: const Text(
                    'Rasgos, bonificaciones y efectos permanentes',
                  ),
                  onTap: () {
                    Navigator.pop(context, 'passive');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    switch (result) {
      case 'ability':
        await createAbility();
        break;

      case 'passive':
        await createPassive();
        break;
    }
  }
}
