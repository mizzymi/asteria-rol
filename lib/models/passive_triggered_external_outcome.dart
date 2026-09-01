import 'passive.dart';

class PassiveTriggeredExternalOutcome {
  final String passiveId;

  final String passiveName;

  final String triggerId;

  final String targetId;

  final String? targetLabel;

  final TriggerSavingThrow? savingThrow;

  final List<PassiveTriggerAction> actions;

  final TriggerUsageLimit usageLimit;

  const PassiveTriggeredExternalOutcome({
    required this.passiveId,
    required this.passiveName,
    required this.triggerId,
    required this.targetId,
    this.targetLabel,
    this.savingThrow,
    this.usageLimit = TriggerUsageLimit.unlimited,
    this.actions = const [],
  });

  String get usageKey {
    return '$passiveId:$triggerId';
  }

  bool get hasActions {
    return actions.isNotEmpty;
  }

  bool get requiresSavingThrow {
    return savingThrow != null &&
        savingThrow!.dc > 0;
  }
}