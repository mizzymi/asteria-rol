import 'package:flutter/material.dart';
import 'package:rol/utils/number_format.dart';

class CharacterResource {
  String id;
  String name;

  int currentValue;
  int maxValue;

  /// false = el recurso puede crecer sin límite.
  bool hasMaximum;

  IconData icon;
  int colorValue;
  bool visible;
  bool spendable;

  CharacterResource({
    required this.id,
    required this.name,
    this.currentValue = 0,
    this.maxValue = 0,
    this.hasMaximum = true,
    this.icon = Icons.bolt_rounded,
    this.colorValue = 0xFF8B5CF6,
    this.visible = true,
    this.spendable = true,
  });

  Color get color => Color(colorValue);

  bool get isEmpty => currentValue <= 0;

  bool get isUnlimited => !hasMaximum;

  bool get isFull {
    if (!hasMaximum) {
      return false;
    }

    return currentValue >= maxValue;
  }

  double get percentage {
    if (!hasMaximum || maxValue <= 0) {
      return 0;
    }

    return (currentValue / maxValue).clamp(0.0, 1.0);
  }

  String get displayText {
    if (!hasMaximum) {
      return formatThousands(currentValue);
    }

    return '${formatThousands(currentValue)}/${formatThousands(maxValue)}';
  }

  void consume(int amount) {
    if (amount <= 0) {
      return;
    }

    currentValue -= amount;

    if (currentValue < 0) {
      currentValue = 0;
    }
  }

  void restore(int amount, {int? maximum}) {
    if (amount <= 0) {
      return;
    }

    currentValue += amount;

    if (maximum != null && currentValue > maximum) {
      currentValue = maximum;
    }
  }

  void restoreFull({required int maximum}) {
    currentValue = maximum;
  }

  void empty() {
    currentValue = 0;
  }

  void normalize() {
    // Recurso sin máximo.
    if (!hasMaximum) {
      maxValue = 0;

      if (currentValue < 0) {
        currentValue = 0;
      }

      return;
    }

    // El máximo BASE mínimo es 1.
    if (maxValue < 1) {
      maxValue = 1;
    }

    if (currentValue < 0) {
      currentValue = 0;
    }

    // IMPORTANTE:
    // No limitar currentValue contra maxValue aquí.
    //
    // maxValue es el máximo BASE.
    // El máximo real puede ser superior debido a pasivas.
    //
    // El límite contra el máximo EFECTIVO
    // se hará desde Character.normalizeResource().
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'currentValue': currentValue,
      'maxValue': maxValue,
      'hasMaximum': hasMaximum,
      'iconCodePoint': icon.codePoint,
      'colorValue': colorValue,
      'visible': visible,
      'spendable': spendable,
    };
  }

  factory CharacterResource.fromMap(Map<dynamic, dynamic> map) {
    final resource = CharacterResource(
      id: map['id']?.toString() ?? '',

      name: map['name']?.toString() ?? '',

      currentValue: (map['currentValue'] as num?)?.toInt() ?? 0,

      maxValue: (map['maxValue'] as num?)?.toInt() ?? 0,

      // Los recursos antiguos no tenían este campo,
      // así que siguen teniendo máximo.
      hasMaximum: map['hasMaximum'] as bool? ?? true,

      icon: IconData(
        (map['iconCodePoint'] as num?)?.toInt() ?? Icons.bolt_rounded.codePoint,
        fontFamily: 'MaterialIcons',
      ),

      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFF8B5CF6,

      visible: map['visible'] as bool? ?? true,

      spendable: map['spendable'] as bool? ?? true,
    );

    resource.normalize();

    return resource;
  }
}
