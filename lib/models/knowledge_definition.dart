import 'package:flutter/foundation.dart';

enum KnowledgeCategory {
  arcana,
  alchemy,
  history,
  religion,
  nature,
  martial,
  language,
  custom,
}

@immutable
class KnowledgeDefinition {
  final String id;
  final String name;
  final String description;
  final KnowledgeCategory category;
  final int requiredProgress;
  final int studyDc;
  final List<String> unlockedSpellIds;
  final List<String> unlockedAbilityIds;
  final List<String> unlockedPassiveIds; // <-- Añadido

  const KnowledgeDefinition({
    required this.id,
    required this.name,
    this.description = '',
    this.category = KnowledgeCategory.arcana,
    this.requiredProgress = 5,
    this.studyDc = 15,
    this.unlockedSpellIds = const [],
    this.unlockedAbilityIds = const [],
    this.unlockedPassiveIds = const [], // <-- Añadido
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category.name,
    'requiredProgress': requiredProgress,
    'studyDc': studyDc,
    'unlockedSpellIds': unlockedSpellIds,
    'unlockedAbilityIds': unlockedAbilityIds,
    'unlockedPassiveIds': unlockedPassiveIds, // <-- Añadido
  };

  factory KnowledgeDefinition.fromMap(Map<dynamic, dynamic> map) {
    // ... parsers para listas (spellIds, abilityIds, passiveIds)
    // Asegúrate de parsear unlockedPassiveIds de forma similar a los demás.
    return KnowledgeDefinition(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: KnowledgeCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => KnowledgeCategory.arcana,
      ),
      requiredProgress: (map['requiredProgress'] as num?)?.toInt() ?? 5,
      studyDc: (map['studyDc'] as num?)?.toInt() ?? 15,
      unlockedSpellIds: List<String>.from(map['unlockedSpellIds'] ?? const []),
      unlockedAbilityIds: List<String>.from(
        map['unlockedAbilityIds'] ?? const [],
      ),
      unlockedPassiveIds: List<String>.from(
        map['unlockedPassiveIds'] ?? const [],
      ),
    );
  }
}
