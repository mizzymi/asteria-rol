import '../models/ability.dart';
import '../models/action_dice_request.dart';
import '../models/action_dice_result.dart';
import '../models/action_hit_behavior.dart';
import '../models/character.dart';
import '../models/dice_pool.dart';
import '../models/passive.dart';

import 'action_dice_resolver.dart';

class PassiveActionResolver {
  final Character character;

  final ActionDiceResolver diceResolver = const ActionDiceResolver();

  PassiveActionResolver({required this.character});

  ActionDiceResult resolveDigitalRequest(ActionDiceRequest request) {
    return diceResolver.rollDigital(request);
  }

  ActionDiceResult resolvePhysicalRequest(
    ActionDiceRequest request, {
    required List<ActionPhysicalDiceInput> inputs,
  }) {
    return diceResolver.resolvePhysical(request: request, inputs: inputs);
  }

  // ===========================================================================
  // REQUEST
  // ===========================================================================

  ActionDiceRequest buildRollRequest(CharacterPassive passive) {
    final modifier = character.passiveRollModifier(passive);

    return ActionDiceRequest(
      parts: [
        ActionDiceRequestPart(
          id: 'passive_roll:${passive.id}',

          effectId: passive.id,

          effectName: passive.name,

          effectType: AbilityEffectType.none,

          dicePools: List<DicePool>.unmodifiable(passive.rollDicePools),

          modifier: modifier,

          automaticValue: 0,

          sourceType: ActionDiceSourceType.passive,

          sourceId: passive.id,

          sourceName: passive.name,

          damageType: '',

          hitBehavior: ActionHitBehavior.ignoreHit,
        ),
      ],
    );
  }

  ActionDiceResult rollDigital(CharacterPassive passive) {
    return resolveDigitalRequest(buildRollRequest(passive));
  }

  ActionDiceResult resolvePhysical(
    CharacterPassive passive, {
    required List<ActionPhysicalDiceInput> inputs,
  }) {
    return resolvePhysicalRequest(buildRollRequest(passive), inputs: inputs);
  }

  String rollText(CharacterPassive passive) {
    final request = buildRollRequest(passive);

    if (request.parts.isEmpty) {
      return '0';
    }

    return request.parts.first.calculationText;
  }
}
