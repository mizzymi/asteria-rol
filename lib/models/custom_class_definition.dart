import 'ability.dart';
import 'passive.dart';
import 'skill.dart';

enum ClassProgressionRewardMode { automatic, choice }

enum ClassProgressionContentType { ability, passive }

class ClassProgressionContent {
  final ClassProgressionContentType type;
  final String contentId;
  final String name;
  final Map<String, dynamic> data;

  const ClassProgressionContent({
    required this.type,
    required this.contentId,
    required this.name,
    required this.data,
  });

  factory ClassProgressionContent.fromAbility(CharacterAbility ability) {
    return ClassProgressionContent(
      type: ClassProgressionContentType.ability,
      contentId: ability.id,
      name: ability.name,
      data: Map<String, dynamic>.from(ability.toMap()),
    );
  }

  factory ClassProgressionContent.fromPassive(CharacterPassive passive) {
    return ClassProgressionContent(
      type: ClassProgressionContentType.passive,
      contentId: passive.id,
      name: passive.name,
      data: Map<String, dynamic>.from(passive.toMap()),
    );
  }

  CharacterAbility? instantiateAbility({
    required String classId,
    required String rewardId,
  }) {
    if (type != ClassProgressionContentType.ability) return null;
    final map = Map<dynamic, dynamic>.from(data);
    map['id'] = contentId;
    map['sourceClassId'] = classId;
    map['sourceRewardId'] = rewardId;
    return CharacterAbility.fromMap(map);
  }

  CharacterPassive? instantiatePassive({
    required String classId,
    required String rewardId,
  }) {
    if (type != ClassProgressionContentType.passive) return null;
    final map = Map<dynamic, dynamic>.from(data);
    map['id'] = contentId;
    map['sourceType'] = PassiveSourceType.classFeature.name;
    map['sourceClassId'] = classId;
    map['sourceRewardId'] = rewardId;
    return CharacterPassive.fromMap(map);
  }

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'contentId': contentId,
    'name': name,
    'data': data,
  };

  factory ClassProgressionContent.fromMap(Map<dynamic, dynamic> map) {
    return ClassProgressionContent(
      type: ClassProgressionContentType.values.firstWhere(
        (value) => value.name == map['type']?.toString(),
        orElse: () => ClassProgressionContentType.ability,
      ),
      contentId: map['contentId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      data: map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : <String, dynamic>{},
    );
  }
}

class ClassProgressionReward {
  final String rewardId;
  final int level;
  final ClassProgressionRewardMode mode;
  final String name;
  final List<ClassProgressionContent> contents;

  const ClassProgressionReward({
    required this.rewardId,
    required this.level,
    required this.mode,
    required this.name,
    required this.contents,
  });

  bool get isValid => rewardId.trim().isNotEmpty && level > 0 && contents.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'rewardId': rewardId,
    'level': level,
    'mode': mode.name,
    'name': name,
    'contents': contents.map((item) => item.toMap()).toList(),
  };

  factory ClassProgressionReward.fromMap(Map<dynamic, dynamic> map) {
    final contents = <ClassProgressionContent>[];
    final rawContents = map['contents'];
    if (rawContents is List) {
      for (final raw in rawContents) {
        if (raw is Map) {
          contents.add(ClassProgressionContent.fromMap(raw));
        }
      }
    }
    return ClassProgressionReward(
      rewardId: map['rewardId']?.toString() ?? '',
      level: (map['level'] as num?)?.toInt() ?? 1,
      mode: ClassProgressionRewardMode.values.firstWhere(
        (value) => value.name == map['mode']?.toString(),
        orElse: () => ClassProgressionRewardMode.automatic,
      ),
      name: map['name']?.toString() ?? '',
      contents: contents,
    );
  }
}

class CustomClassDefinition {
  final String classId;
  final String campaignId;
  int version;
  String name;
  String description;
  int hitDie;
  Set<AbilityType> savingThrowProficiencies;
  List<ClassProgressionReward> rewards;

  CustomClassDefinition({
    required this.classId,
    required this.campaignId,
    this.version = 1,
    required this.name,
    this.description = '',
    this.hitDie = 8,
    Set<AbilityType>? savingThrowProficiencies,
    List<ClassProgressionReward>? rewards,
  }) : savingThrowProficiencies =
           Set<AbilityType>.from(savingThrowProficiencies ?? const {}),
       rewards = List<ClassProgressionReward>.from(rewards ?? const []);

  Map<String, dynamic> toMap() => {
    'classId': classId,
    'campaignId': campaignId,
    'version': version,
    'name': name,
    'description': description,
    'hitDie': hitDie,
    'savingThrowProficiencies': savingThrowProficiencies
        .map((value) => value.name)
        .toList(),
    'rewards': rewards.map((reward) => reward.toMap()).toList(),
  };

  factory CustomClassDefinition.fromMap(Map<dynamic, dynamic> map) {
    final saves = <AbilityType>{};
    final rawSaves = map['savingThrowProficiencies'];
    if (rawSaves is List) {
      for (final raw in rawSaves) {
        for (final ability in AbilityType.values) {
          if (ability.name == raw.toString()) {
            saves.add(ability);
            break;
          }
        }
      }
    }

    final rewards = <ClassProgressionReward>[];
    final rawRewards = map['rewards'];
    if (rawRewards is List) {
      for (final raw in rawRewards) {
        if (raw is Map) {
          final reward = ClassProgressionReward.fromMap(raw);
          if (reward.isValid) rewards.add(reward);
        }
      }
    }

    return CustomClassDefinition(
      classId: map['classId']?.toString() ?? '',
      campaignId: map['campaignId']?.toString() ?? '',
      version: (map['version'] as num?)?.toInt() ?? 1,
      name: map['name']?.toString() ?? 'Clase personalizada',
      description: map['description']?.toString() ?? '',
      hitDie: (map['hitDie'] as num?)?.toInt() ?? 8,
      savingThrowProficiencies: saves,
      rewards: rewards,
    );
  }
}
