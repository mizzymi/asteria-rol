class ActionTriggerContext {
  final String? targetId;

  final String? targetLabel;

  const ActionTriggerContext({this.targetId, this.targetLabel});

  bool get hasTarget {
    final id = targetId?.trim();

    return id != null && id.isNotEmpty;
  }
}
