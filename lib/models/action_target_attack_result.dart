class ActionTargetAttackResult {
  final bool hit;

  final int? defense;

  const ActionTargetAttackResult({required this.hit, this.defense});

  const ActionTargetAttackResult.hit({int? defense})
    : this(hit: true, defense: defense);

  const ActionTargetAttackResult.miss({int? defense})
    : this(hit: false, defense: defense);
}
