class ActionCommitResult {
  final bool committed;

  final int resourceSpent;
  final int chargesSpent;
  final int usesSpent;

  const ActionCommitResult({
    required this.committed,
    this.resourceSpent = 0,
    this.chargesSpent = 0,
    this.usesSpent = 0,
  });

  const ActionCommitResult.notCommitted()
    : committed = false,
      resourceSpent = 0,
      chargesSpent = 0,
      usesSpent = 0;
}
