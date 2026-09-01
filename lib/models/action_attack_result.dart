import 'action_critical_profile.dart';

typedef ActionAttackRolls = ({int firstRoll, int? secondRoll});

class ActionAttackResult {
  final int naturalRoll;

  final int modifier;

  final int total;

  final ActionCriticalProfile criticalProfile;

  const ActionAttackResult({
    required this.naturalRoll,
    required this.modifier,
    required this.total,
    required this.criticalProfile,
  });

  bool get critical {
    return criticalProfile.isCriticalRoll(naturalRoll);
  }

  ActionCriticalType get criticalType {
    return criticalProfile.criticalTypeFor(naturalRoll);
  }

  int get effectiveCriticalMinimumRoll {
    return criticalProfile.minimumNaturalRoll;
  }
}
