class AbilityResolutionSummary {
  final int damage;
  final int healing;
  final bool critical;

  const AbilityResolutionSummary({
    this.damage = 0,
    this.healing = 0,
    this.critical = false,
  });

  bool get dealtDamage => damage > 0;

  bool get healed => healing > 0;
}
