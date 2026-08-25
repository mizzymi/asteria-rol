enum ActionExternalRequirementType {
  boolean,

  percentageBelow,
  percentageAtOrBelow,
  percentageAbove,
  percentageAtOrAbove,
}

class ActionExternalRequirement {
  final String variableName;

  final ActionExternalRequirementType type;

  final String label;

  final double? threshold;

  const ActionExternalRequirement({
    required this.variableName,
    required this.type,
    required this.label,
    this.threshold,
  });

  const ActionExternalRequirement.boolean({
    required String variableName,
    required String label,
  }) : this(
         variableName: variableName,
         type: ActionExternalRequirementType.boolean,
         label: label,
       );

  const ActionExternalRequirement.percentageBelow({
    required String variableName,
    required String label,
    required double threshold,
  }) : this(
         variableName: variableName,
         type: ActionExternalRequirementType.percentageBelow,
         label: label,
         threshold: threshold,
       );

  const ActionExternalRequirement.percentageAtOrBelow({
    required String variableName,
    required String label,
    required double threshold,
  }) : this(
         variableName: variableName,
         type: ActionExternalRequirementType.percentageAtOrBelow,
         label: label,
         threshold: threshold,
       );

  const ActionExternalRequirement.percentageAbove({
    required String variableName,
    required String label,
    required double threshold,
  }) : this(
    variableName: variableName,
    type: ActionExternalRequirementType.percentageAbove,
    label: label,
    threshold: threshold,
  );

  const ActionExternalRequirement.percentageAtOrAbove({
    required String variableName,
    required String label,
    required double threshold,
  }) : this(
    variableName: variableName,
    type: ActionExternalRequirementType.percentageAtOrAbove,
    label: label,
    threshold: threshold,
  );

  String get normalizedVariableName {
    final normalized = variableName.trim().toLowerCase();

    final currentThreshold = threshold;

    if (currentThreshold == null || !isPercentageRequirement) {
      return normalized;
    }

    final cleanThreshold = currentThreshold == currentThreshold.roundToDouble()
        ? currentThreshold.toInt().toString()
        : currentThreshold.toString();

    final operatorName = switch (type) {
      ActionExternalRequirementType.percentageBelow => 'lt',

      ActionExternalRequirementType.percentageAtOrBelow => 'lte',

      ActionExternalRequirementType.percentageAbove => 'gt',

      ActionExternalRequirementType.percentageAtOrAbove => 'gte',

      _ => '',
    };

    return '${normalized}_${operatorName}_$cleanThreshold';
  }

  bool get isPercentageRequirement {
    switch (type) {
      case ActionExternalRequirementType.percentageBelow:
      case ActionExternalRequirementType.percentageAtOrBelow:
      case ActionExternalRequirementType.percentageAbove:
      case ActionExternalRequirementType.percentageAtOrAbove:
        return true;

      default:
        return false;
    }
  }

  bool get isBelowPercentageRequirement {
    return type == ActionExternalRequirementType.percentageBelow ||
        type == ActionExternalRequirementType.percentageAtOrBelow;
  }

  bool get isAbovePercentageRequirement {
    return type == ActionExternalRequirementType.percentageAbove ||
        type == ActionExternalRequirementType.percentageAtOrAbove;
  }

  String? get percentageOperator {
    switch (type) {
      case ActionExternalRequirementType.percentageBelow:
        return '<';

      case ActionExternalRequirementType.percentageAtOrBelow:
        return '<=';

      case ActionExternalRequirementType.percentageAbove:
        return '>';

      case ActionExternalRequirementType.percentageAtOrAbove:
        return '>=';

      default:
        return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'variableName': variableName,
      'type': type.name,
      'label': label,
      'threshold': threshold,
    };
  }

  factory ActionExternalRequirement.fromMap(Map<dynamic, dynamic> map) {
    return ActionExternalRequirement(
      variableName: map['variableName']?.toString() ?? '',
      type: ActionExternalRequirementType.values.firstWhere(
        (value) => value.name == map['type']?.toString(),
        orElse: () => ActionExternalRequirementType.boolean,
      ),
      label: map['label']?.toString() ?? '',
      threshold: (map['threshold'] as num?)?.toDouble(),
    );
  }
}

class ActionExternalRequirementSet {
  final List<ActionExternalRequirement> requirements;

  ActionExternalRequirementSet(Iterable<ActionExternalRequirement> requirements)
    : requirements = List.unmodifiable(_deduplicate(requirements));

  bool get isEmpty => requirements.isEmpty;

  bool get isNotEmpty => requirements.isNotEmpty;

  static List<ActionExternalRequirement> _deduplicate(
    Iterable<ActionExternalRequirement> source,
  ) {
    final result = <String, ActionExternalRequirement>{};

    for (final requirement in source) {
      final threshold = requirement.threshold;

      final key = [
        requirement.type.name,
        requirement.normalizedVariableName,
        threshold?.toString() ?? '',
      ].join(':');

      result.putIfAbsent(key, () => requirement);
    }

    return result.values.toList(growable: false);
  }
}
