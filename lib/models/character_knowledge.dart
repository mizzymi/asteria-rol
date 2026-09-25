enum KnowledgeStatus {
  discovered,
  studying,
  mastered,
}

class CharacterKnowledge {
  final String knowledgeId;
  KnowledgeStatus status;
  int currentProgress;
  String notes;
  List<String> unlockedSpellIds;
  List<String> temporaryPassiveIdsGranted;

  CharacterKnowledge({
    required this.knowledgeId,
    this.status = KnowledgeStatus.discovered,
    this.currentProgress = 0,
    this.notes = '',
    List<String>? unlockedSpellIds,
    List<String>? temporaryPassiveIdsGranted,
  }) : unlockedSpellIds = unlockedSpellIds ?? [],
       temporaryPassiveIdsGranted = temporaryPassiveIdsGranted ?? [];

  bool get isMastered => status == KnowledgeStatus.mastered;

  Map<String, dynamic> toMap() => {
    'knowledgeId': knowledgeId,
    'status': status.name,
    'currentProgress': currentProgress,
    'notes': notes,
    'unlockedSpellIds': unlockedSpellIds,
    'temporaryPassiveIdsGranted': temporaryPassiveIdsGranted,
  };

  factory CharacterKnowledge.fromMap(Map<dynamic, dynamic> map) {
    List<String> strings(dynamic raw) => raw is List
        ? raw.where((e) => e != null).map((e) => e.toString()).toList()
        : <String>[];

    return CharacterKnowledge(
      knowledgeId: map['knowledgeId']?.toString() ?? '',
      status: KnowledgeStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => KnowledgeStatus.discovered,
      ),
      currentProgress: (map['currentProgress'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString() ?? '',
      unlockedSpellIds: strings(map['unlockedSpellIds']),
      temporaryPassiveIdsGranted: strings(map['temporaryPassiveIdsGranted']),
    );
  }
}
