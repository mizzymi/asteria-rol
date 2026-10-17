import 'dnd_class.dart';
import 'skill.dart';

class CharacterClassLevel {
  /// Clase base usada por compatibilidad con fichas antiguas.
  /// Para clases personalizadas se conserva un fallback interno, pero la UI y
  /// las reglas deben usar classId, label, hitDie y savingThrowProficiencies.
  DndClass dndClass;

  /// ID estable. Las clases oficiales usan core:<enum>; las personalizadas
  /// conservan el classId definido por el Máster.
  String classId;

  /// Snapshot mínimo de la definición personalizada para que la ficha siga
  /// siendo legible aunque el catálogo local cambie.
  String? customName;
  int? customHitDie;
  Set<AbilityType>? customSavingThrowProficiencies;

  int level;

  CharacterClassLevel({
    required this.dndClass,
    String? classId,
    this.customName,
    this.customHitDie,
    Set<AbilityType>? customSavingThrowProficiencies,
    this.level = 1,
  }) : classId = classId ?? 'core:${dndClass.name}',
       customSavingThrowProficiencies =
           customSavingThrowProficiencies == null
           ? null
           : Set<AbilityType>.from(customSavingThrowProficiencies);

  bool get isCustom => !classId.startsWith('core:');

  String get label => customName?.trim().isNotEmpty == true
      ? customName!.trim()
      : dndClass.label;

  int get hitDie => customHitDie ?? dndClass.hitDie;

  Set<AbilityType> get savingThrowProficiencies =>
      customSavingThrowProficiencies ?? dndClass.savingThrowProficiencies;

  Map<String, dynamic> toMap() {
    return {
      'dndClass': dndClass.name,
      'classId': classId,
      'customName': customName,
      'customHitDie': customHitDie,
      'customSavingThrowProficiencies':
          customSavingThrowProficiencies?.map((value) => value.name).toList(),
      'level': level,
    };
  }

  factory CharacterClassLevel.fromMap(Map<dynamic, dynamic> map) {
    final dndClass = DndClassData.fromString(map['dndClass']?.toString());
    final customSaves = <AbilityType>{};
    final rawSaves = map['customSavingThrowProficiencies'];
    if (rawSaves is List) {
      for (final raw in rawSaves) {
        for (final ability in AbilityType.values) {
          if (ability.name == raw.toString()) {
            customSaves.add(ability);
            break;
          }
        }
      }
    }

    return CharacterClassLevel(
      dndClass: dndClass,
      classId: map['classId']?.toString() ?? 'core:${dndClass.name}',
      customName: map['customName']?.toString(),
      customHitDie: (map['customHitDie'] as num?)?.toInt(),
      customSavingThrowProficiencies:
          rawSaves is List ? customSaves : null,
      level: (map['level'] as num?)?.toInt() ?? 1,
    );
  }
}
