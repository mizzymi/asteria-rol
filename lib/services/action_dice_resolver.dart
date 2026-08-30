import '../models/action_dice_request.dart';
import '../models/action_dice_result.dart';
import '../models/dice_pool.dart';

class ActionDiceResolver {
  const ActionDiceResolver();

  // ===========================================================================
  // DADO DIGITAL SIMPLE
  // ===========================================================================

  int rollDigitalDie({required int sides}) {
    if (sides <= 0) {
      throw ArgumentError.value(
        sides,
        'sides',
        'El dado debe tener al menos 1 cara.',
      );
    }

    final result = DicePoolRoller.roll(
      pools: [DicePool(count: 1, sides: sides)],
    );

    return result.groups.first.rolls.first;
  }

  int rollDigitalD20() {
    return rollDigitalDie(sides: 20);
  }

  // ===========================================================================
  // FÍSICO
  // ===========================================================================

  ActionDiceResult resolvePhysical({
    required ActionDiceRequest request,
    required List<ActionPhysicalDiceInput> inputs,
  }) {
    final results = <ActionDicePartResult>[];

    for (final part in request.parts) {
      // -----------------------------------------------------------------------
      // SIN TIRADA
      // -----------------------------------------------------------------------

      if (!part.requiresRoll) {
        results.add(_resolveAutomaticPart(part));

        continue;
      }

      // -----------------------------------------------------------------------
      // BUSCAR INPUT
      // -----------------------------------------------------------------------

      ActionPhysicalDiceInput? input;

      for (final candidate in inputs) {
        if (candidate.requestPartId == part.id) {
          input = candidate;
          break;
        }
      }

      if (input == null) {
        throw StateError('Faltan dados físicos para ${part.id}.');
      }

      // -----------------------------------------------------------------------
      // VALIDAR GRUPOS
      // -----------------------------------------------------------------------

      if (input.rolls.length != part.dicePools.length) {
        throw StateError(
          'La cantidad de grupos de dados no coincide para ${part.id}.',
        );
      }

      final groups = <DiceGroupRoll>[];

      for (var i = 0; i < part.dicePools.length; i++) {
        final pool = part.dicePools[i];

        final rolls = input.rolls[i];

        // ---------------------------------------------------------------------
        // CANTIDAD
        // ---------------------------------------------------------------------

        if (rolls.length != pool.count) {
          throw StateError(
            'La cantidad de resultados no coincide con ${pool.notation}.',
          );
        }

        // ---------------------------------------------------------------------
        // RANGO
        // ---------------------------------------------------------------------

        for (final value in rolls) {
          if (value < 1 || value > pool.sides) {
            throw StateError('Resultado $value inválido para d${pool.sides}.');
          }
        }

        groups.add(
          DiceGroupRoll(pool: pool, rolls: List<int>.unmodifiable(rolls)),
        );
      }

      // -----------------------------------------------------------------------
      // RESULTADO
      // -----------------------------------------------------------------------

      results.add(
        ActionDicePartResult(
          request: part,
          result: DiceCalculationResult(
            groups: List<DiceGroupRoll>.unmodifiable(groups),
            modifier: part.modifier,
          ),
        ),
      );
    }

    return ActionDiceResult(
      parts: List<ActionDicePartResult>.unmodifiable(results),
    );
  }

  // ===========================================================================
  // DIGITAL
  // ===========================================================================

  ActionDiceResult rollDigital(ActionDiceRequest request) {
    final results = <ActionDicePartResult>[];

    for (final part in request.parts) {
      // -----------------------------------------------------------------------
      // SIN TIRADA
      //
      // Exactamente la misma semántica que físico.
      // -----------------------------------------------------------------------

      if (!part.requiresRoll) {
        results.add(_resolveAutomaticPart(part));

        continue;
      }

      // -----------------------------------------------------------------------
      // TIRADA DIGITAL
      // -----------------------------------------------------------------------

      final roll = DicePoolRoller.roll(
        pools: part.dicePools,
        modifier: part.modifier,
      );

      results.add(ActionDicePartResult(request: part, result: roll));
    }

    return ActionDiceResult(
      parts: List<ActionDicePartResult>.unmodifiable(results),
    );
  }

  ActionDicePartResult _resolveAutomaticPart(ActionDiceRequestPart part) {
    return ActionDicePartResult(
      request: part,
      result: DiceCalculationResult(groups: const [], modifier: part.modifier),
    );
  }
}
