import 'package:flutter/material.dart';

import '../utils/number_format.dart';

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

  /// Si es true, un descanso largo restaura este recurso a su máximo.
  /// Por defecto está desactivado.
  bool restoreOnLongRest;

  CharacterResource({
    required this.id,
    required this.name,
    this.currentValue = 0,
    this.maxValue = 0,
    this.hasMaximum = true,
    this.icon = Icons.bolt_rounded,
    this.colorValue = 0,
    this.visible = true,
    this.spendable = true,
    this.restoreOnLongRest = false,
  });

  Color colorFor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (colorValue.abs() % 8) {
      case 0:
        return scheme.primary;
      case 1:
        return scheme.secondary;
      case 2:
        return scheme.tertiary;
      case 3:
        return scheme.error;
      case 4:
        return scheme.primaryContainer;
      case 5:
        return scheme.secondaryContainer;
      case 6:
        return scheme.tertiaryContainer;
      default:
        return scheme.onSurfaceVariant;
    }
  }

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

  void normalize() {
    if (!hasMaximum) {
      maxValue = 0;
      restoreOnLongRest = false;

      if (currentValue < 0) {
        currentValue = 0;
      }

      return;
    }

    if (maxValue < 1) {
      maxValue = 1;
    }

    if (currentValue < 0) {
      currentValue = 0;
    }
  }

  // ===========================================================================
  // ICONOS
  // ===========================================================================

  static const Map<String, IconData> _icons = {
    'bolt': Icons.bolt_rounded,
    'favorite': Icons.favorite_rounded,
    'water': Icons.water_drop_rounded,
    'shield': Icons.shield_rounded,
    'fire': Icons.local_fire_department_rounded,
    'star': Icons.star_rounded,
    'magic': Icons.auto_awesome_rounded,
    'energy': Icons.flash_on_rounded,
  };

  static IconData iconFromId(String? id) {
    return _icons[id] ?? Icons.bolt_rounded;
  }

  static String iconIdFromIcon(IconData icon) {
    for (final entry in _icons.entries) {
      if (entry.value == icon) {
        return entry.key;
      }
    }

    return 'bolt';
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
      'hasMaximum': hasMaximum,

      // Nuevo sistema.
      'iconId': iconIdFromIcon(icon),

      // Lo dejamos temporalmente para compatibilidad de lectura antigua.
      'iconCodePoint': icon.codePoint,

      'colorValue': colorValue,
      'visible': visible,
      'spendable': spendable,
      'restoreOnLongRest': restoreOnLongRest,
    };
  }

  factory CharacterResource.fromMap(Map<dynamic, dynamic> map) {
    final iconId = map['iconId']?.toString();

    final resource = CharacterResource(
      id: map['id']?.toString() ?? '',

      name: map['name']?.toString() ?? '',

      currentValue: (map['currentValue'] as num?)?.toInt() ?? 0,

      maxValue: (map['maxValue'] as num?)?.toInt() ?? 0,

      hasMaximum: map['hasMaximum'] as bool? ?? true,

      icon: iconFromId(iconId),

      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0,

      visible: map['visible'] as bool? ?? true,

      spendable: map['spendable'] as bool? ?? true,

      // Compatibilidad: los recursos creados antes de esta opción no se
      // recuperan automáticamente durante un descanso largo.
      restoreOnLongRest: map['restoreOnLongRest'] as bool? ?? false,
    );

    resource.normalize();

    return resource;
  }
}
