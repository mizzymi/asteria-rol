import 'package:flutter/foundation.dart';

enum EquipmentSlotCategory {
  mainHand,
  offHand,
  head,
  chest,
  legs,
  feet,
  hands,
  neck,
  back,
  ring,
  waist,
  custom,
}

@immutable
class EquipmentSlotDefinition {
  final String id;
  final String name;
  final EquipmentSlotCategory category;
  final List<String> allowedItemCategories;
  final int maxEquipped;

  const EquipmentSlotDefinition({
    required this.id,
    required this.name,
    required this.category,
    this.allowedItemCategories = const [],
    this.maxEquipped = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'allowedItemCategories': allowedItemCategories,
    'maxEquipped': maxEquipped,
  };

  factory EquipmentSlotDefinition.fromJson(Map<String, dynamic> json) {
    return EquipmentSlotDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      category: EquipmentSlotCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => EquipmentSlotCategory.custom,
      ),
      allowedItemCategories:
          (json['allowedItemCategories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      maxEquipped: (json['maxEquipped'] as num?)?.toInt() ?? 1,
    );
  }

  EquipmentSlotDefinition copyWith({
    String? id,
    String? name,
    EquipmentSlotCategory? category,
    List<String>? allowedItemCategories,
    int? maxEquipped,
  }) {
    return EquipmentSlotDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      allowedItemCategories:
          allowedItemCategories ?? this.allowedItemCategories,
      maxEquipped: maxEquipped ?? this.maxEquipped,
    );
  }
}

// =============================================================================
// RANURAS POR DEFECTO
// =============================================================================

const defaultEquipmentSlots = <EquipmentSlotDefinition>[
  EquipmentSlotDefinition(
    id: 'main_hand',
    name: 'Mano principal',
    category: EquipmentSlotCategory.mainHand,
    maxEquipped: 1,
  ),
  EquipmentSlotDefinition(
    id: 'off_hand',
    name: 'Mano secundaria',
    category: EquipmentSlotCategory.offHand,
    maxEquipped: 1,
  ),
  EquipmentSlotDefinition(
    id: 'head',
    name: 'Cabeza',
    category: EquipmentSlotCategory.head,
    maxEquipped: 1,
  ),
  EquipmentSlotDefinition(
    id: 'chest',
    name: 'Pecho / Armadura',
    category: EquipmentSlotCategory.chest,
    maxEquipped: 1,
  ),
  EquipmentSlotDefinition(
    id: 'hands',
    name: 'Guantes / Manos',
    category: EquipmentSlotCategory.hands,
    maxEquipped: 1,
  ),
  EquipmentSlotDefinition(
    id: 'legs',
    name: 'Piernas',
    category: EquipmentSlotCategory.legs,
    maxEquipped: 1,
  ),
  EquipmentSlotDefinition(
    id: 'feet',
    name: 'Pies / Botas',
    category: EquipmentSlotCategory.feet,
    maxEquipped: 1,
  ),
  EquipmentSlotDefinition(
    id: 'neck',
    name: 'Cuello / Amuleto',
    category: EquipmentSlotCategory.neck,
    maxEquipped: 1,
  ),
  EquipmentSlotDefinition(
    id: 'back',
    name: 'Espalda / Capa',
    category: EquipmentSlotCategory.back,
    maxEquipped: 1,
  ),
  EquipmentSlotDefinition(
    id: 'ring',
    name: 'Anillos',
    category: EquipmentSlotCategory.ring,
    maxEquipped: 2,
  ),
  EquipmentSlotDefinition(
    id: 'waist',
    name: 'Cinturón',
    category: EquipmentSlotCategory.waist,
    maxEquipped: 1,
  ),
];
