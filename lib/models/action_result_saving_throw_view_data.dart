import 'ability.dart';
import 'action_saving_throw.dart';

class ActionResultSavingThrowViewData {
  final String id;

  final String effectId;

  final String effectName;

  final String abilityLabel;

  final int dc;

  final bool saved;

  final SaveSuccessEffect successEffect;

  final int? naturalRoll;

  final int? modifier;

  final int? total;

  const ActionResultSavingThrowViewData({
    required this.id,
    required this.effectId,
    required this.effectName,
    required this.abilityLabel,
    required this.dc,
    required this.saved,
    required this.successEffect,
    required this.naturalRoll,
    required this.modifier,
    required this.total,
  });

  factory ActionResultSavingThrowViewData.fromResult(
    ActionSavingThrowResult result,
  ) {
    final request = result.request;

    return ActionResultSavingThrowViewData(
      id: request.id,
      effectId: request.effectId,
      effectName: request.effectName,

      abilityLabel: request.ability.name,

      dc: request.dc,

      saved: result.saved,

      successEffect: request.successEffect,

      naturalRoll: result.naturalRoll,

      modifier: result.modifier,

      total: result.total,
    );
  }

  bool get failed {
    return !saved;
  }

  bool get hasRollDetails {
    return naturalRoll != null;
  }

  String get resultLabel {
    return saved ? 'Salvación superada' : 'Salvación fallida';
  }

  String get successEffectLabel {
    switch (successEffect) {
      case SaveSuccessEffect.full:
        return 'Efecto completo';

      case SaveSuccessEffect.half:
        return 'Mitad al superar';

      case SaveSuccessEffect.none:
        return 'Sin efecto al superar';
    }
  }

  String get outcomeLabel {
    if (!saved) {
      return 'Efecto completo';
    }

    switch (successEffect) {
      case SaveSuccessEffect.full:
        return 'Efecto completo';

      case SaveSuccessEffect.half:
        return 'Mitad del efecto';

      case SaveSuccessEffect.none:
        return 'Sin efecto';
    }
  }

  bool get reducedOutcome {
    return saved && successEffect == SaveSuccessEffect.half;
  }

  bool get preventedOutcome {
    return saved && successEffect == SaveSuccessEffect.none;
  }
}
