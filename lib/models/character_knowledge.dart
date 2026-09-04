enum KnowledgeStatus {
  discovered, // El PJ sabe de su existencia
  studying, // En progreso de lectura/estudio
  mastered, // Asimilado por completo
}

class CharacterKnowledge {
  final String knowledgeId;
  KnowledgeStatus status;
  int currentProgress;
  String notes;
  List<String> unlockedSpellIds; // <-- Añadido

  CharacterKnowledge({
    required this.knowledgeId,
    this.status = KnowledgeStatus.discovered,
    this.currentProgress = 0,
    this.notes = '',
    List<String>? unlockedSpellIds,
  }) : unlockedSpellIds = unlockedSpellIds ?? [];

  bool get isMastered => status == KnowledgeStatus.mastered;

  Map<String, dynamic> toMap() => {
    'knowledgeId': knowledgeId,
    'status': status.name,
    'currentProgress': currentProgress,
    'notes': notes,
    'unlockedSpellIds': unlockedSpellIds, // <-- Añadido
  };

  factory CharacterKnowledge.fromMap(Map<dynamic, dynamic> map) {
    final rawSpells = map['unlockedSpellIds'];
    final spells = <String>[];
    if (rawSpells is List) {
      for (final s in rawSpells) {
        if (s != null) spells.add(s.toString());
      }
    }

    return CharacterKnowledge(
      knowledgeId: map['knowledgeId']?.toString() ?? '',
      status: KnowledgeStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => KnowledgeStatus.discovered,
      ),
      currentProgress: (map['currentProgress'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString() ?? '',
      unlockedSpellIds: spells, // <-- Añadido
    );
  }
}
