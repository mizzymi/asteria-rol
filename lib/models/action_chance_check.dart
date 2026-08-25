class ActionChanceCheck {
  final String id;

  final String label;

  final int chancePercent;

  const ActionChanceCheck({
    required this.id,
    required this.label,
    required this.chancePercent,
  });

  int get normalizedChance {
    return chancePercent.clamp(0, 100);
  }

  bool get alwaysSucceeds {
    return normalizedChance >= 100;
  }

  bool get impossible {
    return normalizedChance <= 0;
  }
}

class ActionChanceResult {
  final ActionChanceCheck check;

  final int roll;

  final bool success;

  const ActionChanceResult({
    required this.check,
    required this.roll,
    required this.success,
  });
}
