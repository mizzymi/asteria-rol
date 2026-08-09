import 'dnd_class.dart';

class CharacterClassLevel {
  DndClass dndClass;
  int level;

  CharacterClassLevel({required this.dndClass, this.level = 1});

  Map<String, dynamic> toMap() {
    return {'dndClass': dndClass.name, 'level': level};
  }

  factory CharacterClassLevel.fromMap(Map<dynamic, dynamic> map) {
    return CharacterClassLevel(
      dndClass: DndClassData.fromString(map['dndClass']?.toString()),
      level: (map['level'] as num?)?.toInt() ?? 1,
    );
  }
}
