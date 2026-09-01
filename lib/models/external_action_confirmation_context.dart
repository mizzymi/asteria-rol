class ExternalActionConfirmationContext {
  final String transferId;

  final String targetId;

  final String targetLabel;

  /// Variables que pertenecían al target en el momento
  /// en que se resolvió la acción.
  final Map<String, double> eventVariables;

  final int resolvedDamage;

  final int resolvedHealing;

  final int resolvedEffectCount;

  const ExternalActionConfirmationContext({
    required this.transferId,
    required this.targetId,
    this.targetLabel = '',
    this.eventVariables = const {},
    this.resolvedDamage = 0,
    this.resolvedHealing = 0,
    this.resolvedEffectCount = 0,
  });

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'transferId': transferId,
      'targetId': targetId,
      'targetLabel': targetLabel,

      'eventVariables': {
        for (final entry in eventVariables.entries) entry.key: entry.value,
      },

      'resolvedDamage': resolvedDamage,
      'resolvedHealing': resolvedHealing,
      'resolvedEffectCount': resolvedEffectCount,
    };
  }

  factory ExternalActionConfirmationContext.fromMap(Map<dynamic, dynamic> map) {
    final variables = <String, double>{};

    final rawVariables = map['eventVariables'];

    if (rawVariables is Map) {
      for (final entry in Map<dynamic, dynamic>.from(rawVariables).entries) {
        final key = entry.key?.toString().trim() ?? '';

        final value = entry.value;

        if (key.isEmpty || value is! num) {
          continue;
        }

        variables[key] = value.toDouble();
      }
    }

    return ExternalActionConfirmationContext(
      transferId: map['transferId']?.toString() ?? '',

      targetId: map['targetId']?.toString() ?? '',

      targetLabel: map['targetLabel']?.toString() ?? '',

      eventVariables: Map<String, double>.unmodifiable(variables),

      resolvedDamage: (map['resolvedDamage'] as num?)?.toInt() ?? 0,

      resolvedHealing: (map['resolvedHealing'] as num?)?.toInt() ?? 0,

      resolvedEffectCount: (map['resolvedEffectCount'] as num?)?.toInt() ?? 0,
    );
  }
}
