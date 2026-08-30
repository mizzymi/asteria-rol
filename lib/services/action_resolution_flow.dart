import 'package:flutter/material.dart';

import '../models/action_attack_roll_mode.dart';
import '../models/ability.dart';
import '../models/action_attack_result.dart';
import '../models/action_chance_check.dart';
import '../models/action_dice_mode.dart';
import '../models/action_dice_result.dart';
import '../models/action_execution_result.dart';
import '../models/action_resolution_context.dart';
import '../models/action_resolution_plan.dart';
import '../models/action_resolution_result.dart';
import '../models/action_saving_throw.dart';
import '../models/action_target_attack_result.dart';
import '../models/character.dart';
import '../models/prepared_action_resolution.dart';
import '../models/action_dice_request.dart';
import '../models/weapon.dart';
import '../models/action_critical_profile.dart';
import '../models/weapon_attack_resolution.dart';
import '../models/passive.dart';
import '../models/passive_roll_resolution.dart';

import '../widgets/abilities/attack_roll_sheet.dart';
import '../widgets/action_resolution/dice/dice_mode_sheet.dart';
import '../widgets/action_resolution/dice/physical_attack_roll_dialog.dart';
import '../widgets/action_resolution/dice/physical_dice_dialog.dart';
import '../widgets/action_resolution/targeting/target_selector_dialog.dart';
import '../widgets/action_resolution/targeting/attack_targets_dialog.dart';
import '../widgets/action_resolution/saves/saving_throws_dialog.dart';
import '../widgets/action_resolution/saves/saving_throw_results_dialog.dart';
import '../widgets/action_resolution/options/optional_choices_dialog.dart';
import '../widgets/action_resolution/requirements/external_requirements_dialog.dart';
import '../widgets/action_resolution/chance/chance_checks_dialog.dart';

import 'passive_action_resolver.dart';
import 'weapon_action_resolver.dart';
import 'action_resolver.dart';
import 'action_dice_resolver.dart';

class ActionResolutionFlow {
  final Character character;

  const ActionResolutionFlow({required this.character});

  String get selfLabel {
    return character.name.isNotEmpty ? character.name : 'Tu personaje';
  }

  Future<PassiveRollResolution?> resolvePassiveRoll(
    BuildContext context, {
    required CharacterPassive passive,
  }) async {
    final resolver = PassiveActionResolver(character: character);

    // ===========================================================================
    // MODO DE DADOS
    // ===========================================================================

    final diceMode = await showActionDiceModeSheet(context);

    if (diceMode == null || !context.mounted) {
      return null;
    }

    final request = resolver.buildRollRequest(passive);

    final calculationText = request.parts.isEmpty
        ? '0'
        : request.parts.first.calculationText;

    // ===========================================================================
    // RESOLVER
    // ===========================================================================

    switch (diceMode) {
      // -------------------------------------------------------------------------
      // DIGITAL
      // -------------------------------------------------------------------------

      case ActionDiceMode.digital:
        final diceResult = resolver.rollDigital(passive);

        return PassiveRollResolution(
          diceResult: diceResult,
          calculationText: calculationText,
        );

      // -------------------------------------------------------------------------
      // FÍSICO
      // -------------------------------------------------------------------------

      case ActionDiceMode.physical:
        final results = await showPhysicalDiceDialog(
          context,
          sections: [
            PhysicalDiceSection(
              id: 'passive:${passive.id}',
              title: passive.name,
              request: request,
            ),
          ],
        );

        if (results == null || !context.mounted) {
          return null;
        }

        final diceResult = results['passive:${passive.id}'];

        if (diceResult == null) {
          return null;
        }

        return PassiveRollResolution(
          diceResult: diceResult,
          calculationText: calculationText,
        );
    }
  }

  Future<WeaponAttackResolution?> resolveWeaponAttack(
    BuildContext context, {
    required Weapon weapon,
  }) async {
    final weaponResolver = WeaponActionResolver(character: character);

    // ===========================================================================
    // MODO DE DADOS
    // ===========================================================================

    final diceMode = await showActionDiceModeSheet(context);

    if (diceMode == null || !context.mounted) {
      return null;
    }

    // ===========================================================================
    // NORMAL / VENTAJA / DESVENTAJA
    // ===========================================================================

    final attackMode = await showAttackRollModeSheet(context);

    if (attackMode == null || !context.mounted) {
      return null;
    }

    // ===========================================================================
    // D20
    // ===========================================================================

    switch (diceMode) {
      case ActionDiceMode.digital:
        return weaponResolver.rollAttackDigital(
          weapon: weapon,
          mode: attackMode,
        );

      case ActionDiceMode.physical:
        final rolls = await showPhysicalAttackRollDialog(
          context,
          mode: attackMode,
        );

        if (rolls == null || !context.mounted) {
          return null;
        }

        return weaponResolver.resolveAttackPhysical(
          weapon: weapon,
          mode: attackMode,
          firstRoll: rolls.firstRoll,
          secondRoll: rolls.secondRoll,
        );
    }
  }

  Future<ActionDiceResult?> resolveWeaponDamage(
    BuildContext context, {
    required Weapon weapon,
    required ActionDiceMode diceMode,
    ActionCriticalType criticalType = ActionCriticalType.none,
  }) async {
    final weaponResolver = WeaponActionResolver(character: character);

    final actionResolver = ActionResolver(character: character);

    // ===========================================================================
    // CONTEXTO
    //
    // El arma de momento resuelve daño contra un objetivo externo genérico.
    // Más adelante podremos pasar targets reales igual que las habilidades.
    // ===========================================================================

    final actionContext = ActionResolutionContext(
      character: character,
      targets: const [
        ActionTarget(
          id: 'weapon_target',
          kind: ActionTargetKind.external,
          label: 'Objetivo',
        ),
      ],
    );

    actionContext.populateKnownTargetVariables();

    // ===========================================================================
    // CHANCE DE CRÍTICOS ADICIONALES
    // ===========================================================================

    final chanceChecks = weaponResolver.collectCriticalChanceChecks(
      weapon: weapon,
      criticalType: criticalType,
      context: actionContext,
    );

    List<ActionChanceResult> chanceResults = const [];

    switch (diceMode) {
      case ActionDiceMode.digital:
        if (chanceChecks.isNotEmpty) {
          chanceResults = actionResolver.resolveChanceChecksDigital(
            checks: chanceChecks,
          );
        }

        break;

      case ActionDiceMode.physical:
        if (chanceChecks.isNotEmpty) {
          final inputs = await showPhysicalChanceChecksDialog(
            context,
            checks: chanceChecks,
          );

          if (inputs == null || !context.mounted) {
            return null;
          }

          final rollsByCheckId = {
            for (final input in inputs) input.checkId: input.roll,
          };

          chanceResults = actionResolver.resolveChanceChecksPhysical(
            checks: chanceChecks,
            rollsByCheckId: rollsByCheckId,
          );
        }

        break;
    }

    final successfulChanceIds = actionResolver.successfulChanceCheckIds(
      chanceResults,
    );

    // ===========================================================================
    // REQUEST DE DAÑO
    // ===========================================================================

    final request = weaponResolver.buildDamageRequest(
      weapon: weapon,
      criticalType: criticalType,
      context: actionContext,
      successfulChanceCheckIds: successfulChanceIds,
    );

    // ===========================================================================
    // RESOLVER DADOS
    // ===========================================================================

    switch (diceMode) {
      case ActionDiceMode.digital:
        return const ActionDiceResolver().rollDigital(request);

      case ActionDiceMode.physical:
        final results = await showPhysicalDiceDialog(
          context,
          sections: [
            PhysicalDiceSection(
              id: weapon.id,
              title: weapon.name,
              request: request,
            ),
          ],
        );

        if (results == null || !context.mounted) {
          return null;
        }

        return results[weapon.id];
    }
  }

  // ===========================================================================
  // ENTRY POINT
  // ===========================================================================

  Future<ActionExecutionResult?> resolveAbility(
    BuildContext context, {
    required CharacterAbility ability,
  }) async {
    final resolver = ActionResolver(character: character);

    // -------------------------------------------------------------------------
    // TARGETS
    // -------------------------------------------------------------------------

    final targets = await showActionTargetSelector(
      context,
      targetType: ability.targetType,
      selfLabel: selfLabel,
    );

    if (targets == null || !context.mounted) {
      return null;
    }

    final actionContext = ActionResolutionContext(
      character: character,
      targets: targets,
    );

    actionContext.populateKnownTargetVariables();

    // -------------------------------------------------------------------------
    // CONDICIONES EXTERNAS
    // -------------------------------------------------------------------------

    final requirementsCompleted = await _collectExternalRequirements(
      context,
      resolver: resolver,
      ability: ability,
      actionContext: actionContext,
    );

    if (!requirementsCompleted || !context.mounted) {
      return null;
    }

    // -------------------------------------------------------------------------
    // PLAN
    // -------------------------------------------------------------------------

    final initialPlan = resolver.prepareAbilityPlan(
      ability: ability,
      context: actionContext,
    );

    // -------------------------------------------------------------------------
    // OPCIONALES
    // -------------------------------------------------------------------------

    final optionalCompleted = await _collectOptionalChoices(
      context,
      resolver: resolver,
      plan: initialPlan,
      actionContext: actionContext,
    );

    if (!optionalCompleted || !context.mounted) {
      return null;
    }

    // -------------------------------------------------------------------------
    // PREPARED
    // -------------------------------------------------------------------------

    final prepared = resolver.prepareAbilityAction(
      ability: ability,
      context: actionContext,
    );

    try {
      resolver.validatePreparedTargetResolution(prepared);
    } on StateError catch (error) {
      _showError(context, error.message.toString());

      return null;
    }

    // -------------------------------------------------------------------------
    // COSTES
    //
    // Solo validamos.
    // El pago ocurre exclusivamente en commitResolution().
    // -------------------------------------------------------------------------

    final validation = resolver.validatePreparedActionCosts(prepared);

    if (!validation.valid) {
      _showError(
        context,
        validation.error ?? 'No puedes pagar los costes de esta acción.',
      );

      return null;
    }

    // -------------------------------------------------------------------------
    // MODO DE DADOS
    //
    // Solo preguntamos físico/digital si realmente hay algo que tirar.
    // -------------------------------------------------------------------------

    ActionDiceMode diceMode = ActionDiceMode.digital;

    final requiresDiceMode = resolver.preparedActionRequiresDiceMode(prepared);

    if (requiresDiceMode) {
      final selectedDiceMode = await showActionDiceModeSheet(context);

      if (selectedDiceMode == null || !context.mounted) {
        return null;
      }

      diceMode = selectedDiceMode;
    }

    // -------------------------------------------------------------------------
    // ATAQUE
    // -------------------------------------------------------------------------

    if (ability.requiresAttackRoll) {
      return _resolveAttack(
        context,
        resolver: resolver,
        prepared: prepared,
        diceMode: diceMode,
      );
    }

    // -------------------------------------------------------------------------
    // SIN ATAQUE
    // -------------------------------------------------------------------------

    return _resolveWithoutAttack(
      context,
      resolver: resolver,
      prepared: prepared,
      diceMode: diceMode,
    );
  }

  // ===========================================================================
  // SIN ATAQUE
  // ===========================================================================

  Future<ActionExecutionResult?> _resolveWithoutAttack(
    BuildContext context, {
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    required ActionDiceMode diceMode,
  }) async {
    final saves = await _collectSavingThrows(
      context,
      resolver: resolver,
      prepared: prepared,
      diceMode: diceMode,
    );

    if (saves == null || !context.mounted) {
      return null;
    }

    final resolution = await _resolvePrepared(
      context,
      resolver: resolver,
      prepared: prepared,
      savingThrowResults: saves,
      diceMode: diceMode,
    );

    if (resolution == null) {
      return null;
    }

    return _commitResolution(
      context: context,
      resolver: resolver,
      resolution: resolution,
    );
  }

  // ===========================================================================
  // ATAQUE
  // ===========================================================================

  Future<ActionExecutionResult?> _resolveAttack(
    BuildContext context, {
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    required ActionDiceMode diceMode,
  }) async {
    // -------------------------------------------------------------------------
    // VENTAJA / DESVENTAJA
    // -------------------------------------------------------------------------

    final attackMode = await showAttackRollModeSheet(context);

    if (attackMode == null || !context.mounted) {
      return null;
    }

    // -------------------------------------------------------------------------
    // D20
    // -------------------------------------------------------------------------

    final rolls = await _resolveAttackRolls(
      context,
      mode: attackMode,
      diceMode: diceMode,
    );

    if (rolls == null || !context.mounted) {
      return null;
    }

    final attackResult = resolver.resolvePreparedAttackRoll(
      prepared: prepared,
      mode: attackMode,
      firstRoll: rolls.firstRoll,
      secondRoll: rolls.secondRoll,
    );

    // -------------------------------------------------------------------------
    // HIT / MISS
    // -------------------------------------------------------------------------

    final attackResults = await showAttackTargetsDialog(
      context,
      targets: prepared.context.targets,
      attackResult: attackResult,
      selfLabel: selfLabel,
      ability: prepared.ability.abilityType,
    );

    if (attackResults == null || !context.mounted) {
      return null;
    }

    // -------------------------------------------------------------------------
    // SALVACIONES
    // -------------------------------------------------------------------------

    final saves = await _collectSavingThrows(
      context,
      resolver: resolver,
      prepared: prepared,
      diceMode: diceMode,
      attackResults: attackResults,
    );

    if (saves == null || !context.mounted) {
      return null;
    }

    // -------------------------------------------------------------------------
    // RESOLUCIÓN
    // -------------------------------------------------------------------------

    final resolution = await _resolvePrepared(
      context,
      resolver: resolver,
      prepared: prepared,
      attackResult: attackResult,
      attackResultsByTargetId: attackResults,
      savingThrowResults: saves,
      diceMode: diceMode,
    );

    if (resolution == null) {
      return null;
    }

    return _commitResolution(
      context: context,
      resolver: resolver,
      resolution: resolution,
    );
  }

  // ===========================================================================
  // D20 ATAQUE
  // ===========================================================================

  Future<PhysicalAttackRolls?> _resolveAttackRolls(
    BuildContext context, {
    required AttackRollMode mode,
    required ActionDiceMode diceMode,
  }) async {
    switch (diceMode) {
      case ActionDiceMode.physical:
        return showPhysicalAttackRollDialog(context, mode: mode);

      case ActionDiceMode.digital:
        const diceResolver = ActionDiceResolver();

        final first = diceResolver.rollDigitalD20();

        int? second;

        if (mode != AttackRollMode.normal) {
          second = diceResolver.rollDigitalD20();
        }

        return (firstRoll: first, secondRoll: second);
    }
  }

  // ===========================================================================
  // RESOLUCIÓN PREPARADA
  // ===========================================================================

  Future<ActionResolutionResult?> _resolvePrepared(
    BuildContext context, {
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    required List<ActionSavingThrowResult> savingThrowResults,
    required ActionDiceMode diceMode,
    ActionAttackResult? attackResult,
    Map<String, ActionTargetAttackResult> attackResultsByTargetId = const {},
  }) async {
    final critical = resolver.preparedActionIsCritical(
      prepared: prepared,
      attackResult: attackResult,
    );

    switch (prepared.ability.targetResolutionMode) {
      // =========================================================================
      // SHARED
      // =========================================================================

      case AbilityTargetResolutionMode.shared:
        final chanceResults = await _resolveChanceChecks(
          context,
          resolver: resolver,
          prepared: prepared,
          critical: critical,
          diceMode: diceMode,
        );

        if (chanceResults == null || !context.mounted) {
          return null;
        }

        final successfulChanceIds = resolver.successfulChanceCheckIds(
          chanceResults,
        );

        // =========================================================================
        // REQUEST ÚNICO
        //
        // A partir de aquí físico y digital usan exactamente
        // la misma descripción mecánica de los dados.
        // =========================================================================

        final request = resolver.buildPreparedDiceRequest(
          prepared: prepared,
          attackResult: attackResult,
          successfulChanceCheckIds: successfulChanceIds,
        );

        ActionDiceResult diceResult;

        switch (diceMode) {
          // -----------------------------------------------------------------------
          // DIGITAL
          // -----------------------------------------------------------------------

          case ActionDiceMode.digital:
            diceResult = const ActionDiceResolver().rollDigital(request);

            break;

          // -----------------------------------------------------------------------
          // FÍSICO
          // -----------------------------------------------------------------------

          case ActionDiceMode.physical:
            final rolled = await showPhysicalDiceDialog(
              context,
              sections: [
                PhysicalDiceSection(
                  id: 'shared',
                  title: prepared.ability.name,
                  request: request,
                ),
              ],
            );

            if (rolled == null) {
              return null;
            }

            final resolved = rolled['shared'];

            if (resolved == null) {
              return null;
            }

            diceResult = resolved;

            break;
        }

        // =========================================================================
        // MISMO RESULTADO FINAL
        //
        // Ya no existe un camino de resolución distinto para digital.
        // =========================================================================

        return resolver.buildPreparedSharedResolution(
          prepared: prepared,
          diceResult: diceResult,
          attackResult: attackResult,
          attackResultsByTargetId: attackResultsByTargetId,
          chanceResults: chanceResults,
          savingThrowResults: savingThrowResults,
        );

      // =========================================================================
      // INDEPENDENT
      // =========================================================================

      case AbilityTargetResolutionMode.independent:
        final chanceResultsByTarget = await _resolveIndependentChanceChecks(
          context,
          resolver: resolver,
          prepared: prepared,
          critical: critical,
          diceMode: diceMode,
        );

        if (chanceResultsByTarget == null || !context.mounted) {
          return null;
        }

        final successfulChanceIdsByTargetId = <String, Set<String>>{
          for (final entry in chanceResultsByTarget.entries)
            entry.key: resolver.successfulChanceCheckIds(entry.value),
        };

        // =========================================================================
        // REQUESTS POR TARGET
        //
        // Cada target obtiene su request una única vez.
        // Físico y digital consumen exactamente ese mismo request.
        // =========================================================================

        final requestsByTargetId = <String, ActionDiceRequest>{};

        for (final target in prepared.context.targets) {
          final targetAttackResult = attackResultsByTargetId[target.id];

          final successfulChanceIds =
              successfulChanceIdsByTargetId[target.id] ?? const <String>{};

          final request = resolver.buildPreparedDiceRequest(
            prepared: prepared,
            attackResult: attackResult,
            targetAttackResult: targetAttackResult,
            target: target,
            successfulChanceCheckIds: successfulChanceIds,
          );

          requestsByTargetId[target.id] = request;
        }

        // =========================================================================
        // RESOLVER DADOS
        // =========================================================================

        final diceResultsByTargetId = <String, ActionDiceResult>{};

        switch (diceMode) {
          // -----------------------------------------------------------------------
          // DIGITAL
          // -----------------------------------------------------------------------

          case ActionDiceMode.digital:
            const diceResolver = ActionDiceResolver();

            for (final entry in requestsByTargetId.entries) {
              diceResultsByTargetId[entry.key] = diceResolver.rollDigital(
                entry.value,
              );
            }

            break;

          // -----------------------------------------------------------------------
          // FÍSICO
          // -----------------------------------------------------------------------

          case ActionDiceMode.physical:
            final immediate = <String, ActionDiceResult>{};

            final sections = <PhysicalDiceSection>[];

            for (final target in prepared.context.targets) {
              final request = requestsByTargetId[target.id];

              if (request == null) {
                continue;
              }

              // No hay dados reales que introducir.
              //
              // Ejemplo:
              // crítico potenciado completamente automático.
              if (!request.parts.any((part) => part.requiresRoll)) {
                immediate[target.id] = const ActionDiceResolver()
                    .resolvePhysical(request: request, inputs: const []);

                continue;
              }

              sections.add(
                PhysicalDiceSection(
                  id: target.id,
                  title: target.isSelf ? selfLabel : target.label ?? 'Objetivo',
                  request: request,
                ),
              );
            }

            if (sections.isNotEmpty) {
              final rolled = await showPhysicalDiceDialog(
                context,
                sections: sections,
              );

              if (rolled == null) {
                return null;
              }

              diceResultsByTargetId.addAll(rolled);
            }

            diceResultsByTargetId.addAll(immediate);

            break;
        }

        // =========================================================================
        // RESULTADO FINAL
        // =========================================================================

        return resolver.buildPreparedIndependentResolution(
          prepared: prepared,
          diceResultsByTargetId: Map<String, ActionDiceResult>.unmodifiable(
            diceResultsByTargetId,
          ),
          attackResult: attackResult,
          attackResultsByTargetId: attackResultsByTargetId,
          chanceResultsByTargetId: chanceResultsByTarget,
          savingThrowResults: savingThrowResults,
        );
    }
  }

  // ===========================================================================
  // FÍSICO INDEPENDIENTE
  // ===========================================================================

  Future<Map<String, List<ActionChanceResult>>?>
  _resolveIndependentChanceChecks(
    BuildContext context, {
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    required bool critical,
    required ActionDiceMode diceMode,
  }) async {
    final results = <String, List<ActionChanceResult>>{};

    for (final target in prepared.context.targets) {
      final checks = resolver.collectCriticalChanceChecks(
        critical: critical,
        context: prepared.context,
        target: target,
      );

      if (checks.isEmpty) {
        results[target.id] = const [];

        continue;
      }

      switch (diceMode) {
        case ActionDiceMode.digital:
          results[target.id] = resolver.resolveChanceChecksDigital(
            checks: checks,
          );

          break;

        case ActionDiceMode.physical:
          final inputs = await showPhysicalChanceChecksDialog(
            context,
            checks: checks,
          );

          if (inputs == null || !context.mounted) {
            return null;
          }

          final rollsByCheckId = {
            for (final input in inputs) input.checkId: input.roll,
          };

          results[target.id] = resolver.resolveChanceChecksPhysical(
            checks: checks,
            rollsByCheckId: rollsByCheckId,
          );
      }
    }

    return Map<String, List<ActionChanceResult>>.unmodifiable(results);
  }

  // ===========================================================================
  // SALVACIONES
  // ===========================================================================

  Future<List<ActionSavingThrowResult>?> _collectSavingThrows(
    BuildContext context, {
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    required ActionDiceMode diceMode,
    Map<String, ActionTargetAttackResult> attackResults = const {},
  }) async {
    final requests = resolver.collectSavingThrowRequests(
      prepared: prepared,
      attackResultsByTargetId: attackResults,
    );

    if (requests.isEmpty) {
      return const [];
    }

    final selfRequests = requests
        .where((request) => request.targetId == 'self')
        .toList(growable: false);

    final externalRequests = requests
        .where((request) => request.targetId != 'self')
        .toList(growable: false);

    final results = <ActionSavingThrowResult>[];

    // ===========================================================================
    // SELF
    // ===========================================================================

    if (selfRequests.isNotEmpty) {
      switch (diceMode) {
        // -----------------------------------------------------------------------
        // SELF FÍSICO
        // -----------------------------------------------------------------------

        case ActionDiceMode.physical:
          final inputs = await showPhysicalSavingThrowsDialog(
            context,
            requests: selfRequests,
          );

          if (inputs == null || !context.mounted) {
            // Cancelar aquí cancela TODA
            // la acción.
            return null;
          }

          results.addAll(
            resolver.resolvePhysicalSavingThrows(
              requests: selfRequests,
              inputs: inputs,
            ),
          );

          break;

        // -----------------------------------------------------------------------
        // SELF DIGITAL
        // -----------------------------------------------------------------------

        case ActionDiceMode.digital:
          results.addAll(
            resolver.resolveDigitalSavingThrows(requests: selfRequests),
          );

          break;
      }
    }

    // ===========================================================================
    // EXTERNOS
    //
    // No conocemos sus stats ni su tirada.
    // Solo preguntamos si superaron la salvación.
    // ===========================================================================

    if (externalRequests.isNotEmpty) {
      final externalAnswers = await showExternalSavingThrowResultsDialog(
        context,
        requests: externalRequests,
      );

      if (externalAnswers == null || !context.mounted) {
        // Cancelar aquí cancela TODA
        // la acción.
        return null;
      }

      results.addAll(
        resolver.resolveExternalSavingThrowResults(
          requests: externalRequests,
          resultsByRequestId: externalAnswers,
        ),
      );
    }

    final immutableResults = List<ActionSavingThrowResult>.unmodifiable(
      results,
    );

    await showSavingThrowResultsDialog(context, results: immutableResults);

    if (!context.mounted) {
      return null;
    }

    return immutableResults;
  }

  // ===========================================================================
  // CRITICAL CHANCE
  // ===========================================================================

  Future<List<ActionChanceResult>?> _resolveChanceChecks(
    BuildContext context, {
    required ActionResolver resolver,
    required PreparedActionResolution prepared,
    required bool critical,
    required ActionDiceMode diceMode,
  }) async {
    final checks = resolver.collectCriticalChanceChecks(
      critical: critical,
      context: prepared.context,
    );

    if (checks.isEmpty) {
      return const [];
    }

    switch (diceMode) {
      case ActionDiceMode.digital:
        return resolver.resolveChanceChecksDigital(checks: checks);

      case ActionDiceMode.physical:
        final inputs = await showPhysicalChanceChecksDialog(
          context,
          checks: checks,
        );

        if (inputs == null || !context.mounted) {
          return null;
        }

        final rollsByCheckId = {
          for (final input in inputs) input.checkId: input.roll,
        };

        return resolver.resolveChanceChecksPhysical(
          checks: checks,
          rollsByCheckId: rollsByCheckId,
        );
    }
  }

  // ===========================================================================
  // EXTERNAL REQUIREMENTS
  // ===========================================================================

  Future<bool> _collectExternalRequirements(
    BuildContext context, {
    required ActionResolver resolver,
    required CharacterAbility ability,
    required ActionResolutionContext actionContext,
  }) async {
    final requirements = resolver.orderedExternalRequirements(ability: ability);

    if (requirements.isEmpty) {
      return true;
    }

    for (final target in actionContext.targets) {
      for (final requirement in requirements) {
        // =====================================================================
        // EL RESOLVER DECIDE SI YA PUEDE RESPONDER
        // =====================================================================

        final resolved = resolver.tryResolveKnownExternalRequirement(
          context: actionContext,
          target: target,
          requirement: requirement,
        );

        if (resolved) {
          continue;
        }

        // =====================================================================
        // EL FLOW SOLO PREGUNTA
        // =====================================================================

        final answers = await showExternalRequirementsDialog(
          context,
          targetLabel: target.isSelf ? selfLabel : target.label ?? 'Objetivo',
          requirements: [requirement],
          knownAnswers: const {},
        );

        if (answers == null || !context.mounted) {
          return false;
        }

        final answer = answers[requirement.normalizedVariableName];

        if (answer == null) {
          continue;
        }

        // =====================================================================
        // EL RESOLVER INTERPRETA / REGISTRA
        // =====================================================================

        resolver.applyExternalRequirementAnswer(
          context: actionContext,
          target: target,
          requirement: requirement,
          answer: answer,
        );
      }
    }

    return true;
  }

  void _appendOptionalEntries({
    required List<OptionalChoiceEntry> entries,
    required ActionResolver resolver,
    required ActionResolutionPlan plan,
    required ActionResolutionContext actionContext,
    ActionTarget? target,
  }) {
    final groups = resolver.availableOptionalGroups(
      plan: plan,
      context: actionContext,
      target: target,
    );

    for (final group in groups) {
      entries.add(
        OptionalChoiceEntry(
          group: group,
          target: target,
          validation: resolver.validateOptionalGroupSelection(
            plan: plan,
            context: actionContext,
            group: group,
            target: target,
          ),
        ),
      );
    }
  }

  // ===========================================================================
  // OPCIONALES
  // ===========================================================================

  Future<bool> _collectOptionalChoices(
    BuildContext context, {
    required ActionResolver resolver,
    required ActionResolutionPlan plan,
    required ActionResolutionContext actionContext,
  }) async {
    final entries = <OptionalChoiceEntry>[];

    switch (plan.ability.targetResolutionMode) {
      case AbilityTargetResolutionMode.shared:
        _appendOptionalEntries(
          entries: entries,
          resolver: resolver,
          plan: plan,
          actionContext: actionContext,
        );

        break;

      case AbilityTargetResolutionMode.independent:
        for (final target in actionContext.targets) {
          _appendOptionalEntries(
            entries: entries,
            resolver: resolver,
            plan: plan,
            actionContext: actionContext,
            target: target,
          );
        }

        break;
    }

    if (entries.isEmpty) {
      return true;
    }

    final selections = await showOptionalChoicesDialog(
      context,
      entries: entries,
      selfLabel: selfLabel,
    );

    if (selections == null) {
      return false;
    }

    for (final entry in entries) {
      final selected = selections[entry.key] ?? false;

      final target = entry.target;

      if (target == null) {
        actionContext.setOptionalGroupSelected(entry.group.id, selected);
      } else {
        actionContext.setOptionalGroupSelectedForTarget(
          target.id,
          entry.group.id,
          selected,
        );
      }
    }

    return true;
  }

  // ===========================================================================
  // COMMIT
  // ===========================================================================

  ActionExecutionResult? _commitResolution({
    required BuildContext context,
    required ActionResolver resolver,
    required ActionResolutionResult resolution,
  }) {
    try {
      return resolver.commitResolution(resolution);
    } on StateError catch (error) {
      _showError(context, error.message.toString());

      return null;
    }
  }

  // ===========================================================================
  // ERROR
  // ===========================================================================

  void _showError(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
