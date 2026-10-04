import 'package:flutter/foundation.dart';

import 'skill.dart';

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

enum KnowledgeCheckKind { ability, skill }

@immutable
class KnowledgeCheckOption {
  final KnowledgeCheckKind kind;
  final String value;

  const KnowledgeCheckOption({required this.kind, required this.value});

  KnowledgeCheckOption.ability(AbilityType ability)
    : kind = KnowledgeCheckKind.ability,
      value = ability.name;

  KnowledgeCheckOption.skill(DndSkill skill)
    : kind = KnowledgeCheckKind.skill,
      value = skill.name;

  AbilityType? get ability {
    if (kind != KnowledgeCheckKind.ability) return null;
    for (final item in AbilityType.values) {
      if (item.name == value) return item;
    }
    return null;
  }

  DndSkill? get skill {
    if (kind != KnowledgeCheckKind.skill) return null;
    for (final item in DndSkill.values) {
      if (item.name == value) return item;
    }
    return null;
  }

  String get label {
    final a = ability;
    if (a != null) return a.label;
    final s = skill;
    if (s != null) return '${s.label} (${s.ability.shortLabel})';
    return value;
  }

  Map<String, dynamic> toMap() => {'kind': kind.name, 'value': value};

  factory KnowledgeCheckOption.fromMap(Map<dynamic, dynamic> map) {
    return KnowledgeCheckOption(
      kind: KnowledgeCheckKind.values.firstWhere(
        (e) => e.name == map['kind']?.toString(),
        orElse: () => KnowledgeCheckKind.ability,
      ),
      value: map['value']?.toString() ?? AbilityType.intelligence.name,
    );
  }
}

@immutable
class KnowledgeCircle {
  final String id;
  final String title;
  final int dc;
  final String description;
  final String rewardDescription;
  final List<String> unlockedAbilityIds;
  final List<String> unlockedPassiveIds;
  final List<String> temporaryPassiveIds;

  const KnowledgeCircle({
    required this.id,
    required this.title,
    required this.dc,
    this.description = '',
    this.rewardDescription = '',
    this.unlockedAbilityIds = const [],
    this.unlockedPassiveIds = const [],
    this.temporaryPassiveIds = const [],
  });

  KnowledgeCircle copyWith({
    String? id,
    String? title,
    int? dc,
    String? description,
    String? rewardDescription,
    List<String>? unlockedAbilityIds,
    List<String>? unlockedPassiveIds,
    List<String>? temporaryPassiveIds,
  }) {
    return KnowledgeCircle(
      id: id ?? this.id,
      title: title ?? this.title,
      dc: dc ?? this.dc,
      description: description ?? this.description,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      unlockedAbilityIds: unlockedAbilityIds ?? this.unlockedAbilityIds,
      unlockedPassiveIds: unlockedPassiveIds ?? this.unlockedPassiveIds,
      temporaryPassiveIds: temporaryPassiveIds ?? this.temporaryPassiveIds,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'dc': dc,
    'description': description,
    'rewardDescription': rewardDescription,
    'unlockedAbilityIds': unlockedAbilityIds,
    'unlockedPassiveIds': unlockedPassiveIds,
    'temporaryPassiveIds': temporaryPassiveIds,
  };

  factory KnowledgeCircle.fromMap(Map<dynamic, dynamic> map) {
    List<String> strings(dynamic raw) => raw is List
        ? raw.where((e) => e != null).map((e) => e.toString()).toList()
        : <String>[];

    return KnowledgeCircle(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      dc: (map['dc'] as num?)?.toInt() ?? 15,
      description: map['description']?.toString() ?? '',
      rewardDescription: map['rewardDescription']?.toString() ?? '',
      unlockedAbilityIds: strings(map['unlockedAbilityIds']),
      unlockedPassiveIds: strings(map['unlockedPassiveIds']),
      temporaryPassiveIds: strings(map['temporaryPassiveIds']),
    );
  }
}

@immutable
class KnowledgeDefinition {
  final String id;
  final String name;
  final String description;
  final KnowledgeCategory category;

  /// Legacy/simple-mode fields. Kept for existing saved books.
  final int requiredProgress;
  final int studyDc;

  final String rarity;
  final String difficulty;
  final String levelLabel;
  final String studyRequirement;
  final List<KnowledgeCheckOption> checkOptions;
  final List<KnowledgeCircle> circles;

  final List<String> unlockedSpellIds;
  final List<String> unlockedAbilityIds;
  final List<String> unlockedPassiveIds;

  const KnowledgeDefinition({
    required this.id,
    required this.name,
    this.description = '',
    this.category = KnowledgeCategory.arcana,
    this.requiredProgress = 5,
    this.studyDc = 15,
    this.rarity = '',
    this.difficulty = '',
    this.levelLabel = '',
    this.studyRequirement = '',
    this.checkOptions = const [],
    this.circles = const [],
    this.unlockedSpellIds = const [],
    this.unlockedAbilityIds = const [],
    this.unlockedPassiveIds = const [],
  });

  int get effectiveRequiredProgress =>
      circles.isNotEmpty ? circles.length : requiredProgress;

  List<KnowledgeCheckOption> get effectiveCheckOptions =>
      checkOptions.isNotEmpty
      ? checkOptions
      : [KnowledgeCheckOption.ability(AbilityType.intelligence)];

  KnowledgeCircle? circleAtProgress(int progress) {
    if (circles.isEmpty || progress < 0 || progress >= circles.length) {
      return null;
    }
    return circles[progress];
  }

  int dcForProgress(int progress) => circleAtProgress(progress)?.dc ?? studyDc;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category.name,
    'requiredProgress': requiredProgress,
    'studyDc': studyDc,
    'rarity': rarity,
    'difficulty': difficulty,
    'levelLabel': levelLabel,
    'studyRequirement': studyRequirement,
    'checkOptions': checkOptions.map((e) => e.toMap()).toList(),
    'circles': circles.map((e) => e.toMap()).toList(),
    'unlockedSpellIds': unlockedSpellIds,
    'unlockedAbilityIds': unlockedAbilityIds,
    'unlockedPassiveIds': unlockedPassiveIds,
  };

  factory KnowledgeDefinition.fromMap(Map<dynamic, dynamic> map) {
    List<String> strings(dynamic raw) => raw is List
        ? raw.where((e) => e != null).map((e) => e.toString()).toList()
        : <String>[];

    List<KnowledgeCheckOption> checks(dynamic raw) => raw is List
        ? raw
              .whereType<Map>()
              .map((e) => KnowledgeCheckOption.fromMap(e))
              .toList()
        : <KnowledgeCheckOption>[];

    List<KnowledgeCircle> circleList(dynamic raw) => raw is List
        ? raw.whereType<Map>().map((e) => KnowledgeCircle.fromMap(e)).toList()
        : <KnowledgeCircle>[];

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
      rarity: map['rarity']?.toString() ?? '',
      difficulty: map['difficulty']?.toString() ?? '',
      levelLabel: map['levelLabel']?.toString() ?? '',
      studyRequirement: map['studyRequirement']?.toString() ?? '',
      checkOptions: checks(map['checkOptions']),
      circles: circleList(map['circles']),
      unlockedSpellIds: strings(map['unlockedSpellIds']),
      unlockedAbilityIds: strings(map['unlockedAbilityIds']),
      unlockedPassiveIds: strings(map['unlockedPassiveIds']),
    );
  }
}
