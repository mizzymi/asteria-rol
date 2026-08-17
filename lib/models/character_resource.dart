import 'package:flutter/material.dart';

class CharacterResource {
  String id;

  String name;

  int currentValue;

  int maxValue;

  IconData icon;

  int colorValue;

  bool visible;

  CharacterResource({
    required this.id,
    required this.name,
    this.currentValue = 0,
    this.maxValue = 0,
    this.icon = Icons.bolt_rounded,
    this.colorValue = 0xFF8B5CF6,
    this.visible = true,
  });

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  Color get color => Color(colorValue);

  bool get isEmpty => currentValue <= 0;

  bool get isFull => currentValue >= maxValue;

  double get percentage {
    if (maxValue <= 0) {
      return 0;
    }

    return currentValue / maxValue;
  }

  String get displayText {
    return '$currentValue/$maxValue';
  }

  // ===========================================================================
  // OPERACIONES
  // ===========================================================================

  void consume(int amount) {
    if (amount <= 0) {
      return;
    }

    currentValue -= amount;

    if (currentValue < 0) {
      currentValue = 0;
    }
  }

  void restore(int amount) {
    if (amount <= 0) {
      return;
    }

    currentValue += amount;

    if (currentValue > maxValue) {
      currentValue = maxValue;
    }
  }

  void restoreFull() {
    currentValue = maxValue;
  }

  void empty() {
    currentValue = 0;
  }

  void normalize() {
    if (maxValue < 0) {
      maxValue = 0;
    }

    if (currentValue < 0) {
      currentValue = 0;
    }

    if (currentValue > maxValue) {
      currentValue = maxValue;
    }
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'currentValue': currentValue,
      'maxValue': maxValue,
      'iconCodePoint': icon.codePoint,
      'colorValue': colorValue,
      'visible': visible,
    };
  }

  factory CharacterResource.fromMap(Map<dynamic, dynamic> map) {
    final resource = CharacterResource(
      id: map['id']?.toString() ?? '',

      name: map['name']?.toString() ?? '',

      currentValue: (map['currentValue'] as num?)?.toInt() ?? 0,

      maxValue: (map['maxValue'] as num?)?.toInt() ?? 0,

      icon: IconData(
        (map['iconCodePoint'] as num?)?.toInt() ?? Icons.bolt_rounded.codePoint,
        fontFamily: 'MaterialIcons',
      ),

      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFF8B5CF6,

      visible: map['visible'] as bool? ?? true,
    );

    resource.normalize();

    return resource;
  }
}
