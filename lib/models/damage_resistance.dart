enum DamageResistanceTier { minor, normal, major, immunity }

extension DamageResistanceTierData on DamageResistanceTier {
  String get label {
    switch (this) {
      case DamageResistanceTier.minor:
        return 'Menor';
      case DamageResistanceTier.normal:
        return 'Normal';
      case DamageResistanceTier.major:
        return 'Mayor';
      case DamageResistanceTier.immunity:
        return 'Inmunidad';
    }
  }

  /// Unidad de apilado:
  /// menor=1, normal=2, mayor=4, inmunidad=8.
  ///
  /// Por tanto:
  /// 2 menores = 1 normal
  /// 2 normales = 1 mayor
  /// 2 mayores = inmunidad
  int get resistancePoints {
    switch (this) {
      case DamageResistanceTier.minor:
        return 1;
      case DamageResistanceTier.normal:
        return 2;
      case DamageResistanceTier.major:
        return 4;
      case DamageResistanceTier.immunity:
        return 8;
    }
  }

  static DamageResistanceTier? fromPoints(int points) {
    if (points >= DamageResistanceTier.immunity.resistancePoints) {
      return DamageResistanceTier.immunity;
    }
    if (points >= DamageResistanceTier.major.resistancePoints) {
      return DamageResistanceTier.major;
    }
    if (points >= DamageResistanceTier.normal.resistancePoints) {
      return DamageResistanceTier.normal;
    }
    if (points >= DamageResistanceTier.minor.resistancePoints) {
      return DamageResistanceTier.minor;
    }
    return null;
  }

  int applyToDamage(int damage) {
    if (damage <= 0) {
      return 0;
    }

    switch (this) {
      case DamageResistanceTier.minor:
        return (damage * 3) ~/ 4;
      case DamageResistanceTier.normal:
        return damage ~/ 2;
      case DamageResistanceTier.major:
        return damage ~/ 4;
      case DamageResistanceTier.immunity:
        return 0;
    }
  }
}

class DamageResistance {
  final String damageType;
  final DamageResistanceTier tier;

  const DamageResistance({
    required this.damageType,
    this.tier = DamageResistanceTier.minor,
  });

  String get normalizedDamageType => normalizeDamageType(damageType);

  bool get isValid => normalizedDamageType.isNotEmpty;

  DamageResistance copyWith({String? damageType, DamageResistanceTier? tier}) {
    return DamageResistance(
      damageType: damageType ?? this.damageType,
      tier: tier ?? this.tier,
    );
  }

  Map<String, dynamic> toMap() {
    return {'damageType': damageType, 'tier': tier.name};
  }

  factory DamageResistance.fromMap(Map<dynamic, dynamic> map) {
    return DamageResistance(
      damageType: map['damageType']?.toString() ?? '',
      tier: DamageResistanceTier.values.firstWhere(
        (value) => value.name == map['tier']?.toString(),
        orElse: () => DamageResistanceTier.minor,
      ),
    );
  }
}

String normalizeDamageType(String value) {
  return value.trim().toLowerCase();
}
