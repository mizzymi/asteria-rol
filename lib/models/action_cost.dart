enum ActionCostType { resource, passiveCharge, abilityUse }

class ActionCost {
  final ActionCostType type;

  /// ID del recurso, pasiva o habilidad correspondiente.
  final String sourceId;

  final int amount;

  /// Texto opcional para mostrar errores más claros en UI.
  final String? label;

  const ActionCost({
    required this.type,
    required this.sourceId,
    required this.amount,
    this.label,
  });

  const ActionCost.resource({
    required String resourceId,
    required int amount,
    String? label,
  }) : this(
         type: ActionCostType.resource,
         sourceId: resourceId,
         amount: amount,
         label: label,
       );

  const ActionCost.passiveCharge({
    required String passiveId,
    required int amount,
    String? label,
  }) : this(
         type: ActionCostType.passiveCharge,
         sourceId: passiveId,
         amount: amount,
         label: label,
       );

  const ActionCost.abilityUse({
    required String abilityId,
    int amount = 1,
    String? label,
  }) : this(
         type: ActionCostType.abilityUse,
         sourceId: abilityId,
         amount: amount,
         label: label,
       );

  bool get isValid {
    return sourceId.trim().isNotEmpty && amount > 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'sourceId': sourceId,
      'amount': amount,
      'label': label,
    };
  }

  factory ActionCost.fromMap(Map<dynamic, dynamic> map) {
    return ActionCost(
      type: ActionCostType.values.firstWhere(
        (value) => value.name == map['type']?.toString(),
        orElse: () => ActionCostType.resource,
      ),
      sourceId: map['sourceId']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      label: map['label']?.toString(),
    );
  }
}

class ActionCostValidationResult {
  final bool valid;

  final String? error;

  const ActionCostValidationResult._({required this.valid, this.error});

  const ActionCostValidationResult.success() : this._(valid: true);

  const ActionCostValidationResult.failure(String message)
    : this._(valid: false, error: message);
}
