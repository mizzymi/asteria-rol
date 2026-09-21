import 'package:flutter/material.dart';

import 'character_home_colors.dart';

class HealthEditDialog extends StatefulWidget {
  final int currentHealth;
  final int maxHealth;

  const HealthEditDialog({
    super.key,
    required this.currentHealth,
    required this.maxHealth,
  });

  static Future<int?> show(
    BuildContext context, {
    required int currentHealth,
    required int maxHealth,
  }) {
    return showDialog<int>(
      context: context,
      builder: (_) {
        return HealthEditDialog(
          currentHealth: currentHealth,
          maxHealth: maxHealth,
        );
      },
    );
  }

  @override
  State<HealthEditDialog> createState() => _HealthEditDialogState();
}

class _HealthEditDialogState extends State<HealthEditDialog> {
  late final TextEditingController controller;

  late int value;

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    value = widget.currentHealth;

    controller = TextEditingController(text: '${widget.currentHealth}');

    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  // ===========================================================================
  // VALORES
  // ===========================================================================

  int _normalize(int input) {
    if (input < 0) {
      return 0;
    }

    if (input > widget.maxHealth) {
      return widget.maxHealth;
    }

    return input;
  }

  int get change {
    return value - widget.currentHealth;
  }

  bool get receivedDamage {
    return change < 0;
  }

  bool get receivedHealing {
    return change > 0;
  }

  bool get unchanged {
    return change == 0;
  }

  Color get changeColor {
    if (receivedHealing) {
      return CharacterHomeColors.speed(context);
    }

    if (receivedDamage) {
      return CharacterHomeColors.health(context);
    }

    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  IconData get changeIcon {
    if (receivedHealing) {
      return Icons.favorite_rounded;
    }

    if (receivedDamage) {
      return Icons.heart_broken_rounded;
    }

    return Icons.horizontal_rule_rounded;
  }

  String get changeTitle {
    if (receivedHealing) {
      return 'Curación recibida';
    }

    if (receivedDamage) {
      return 'Daño recibido';
    }

    return 'Sin cambios';
  }

  String get changeText {
    if (receivedHealing) {
      return '+$change PG';
    }

    if (receivedDamage) {
      return '${change.abs()} PG';
    }

    return '0 PG';
  }

  // ===========================================================================
  // CAMBIO
  // ===========================================================================

  void _readValue(String text) {
    final parsed = int.tryParse(text.trim());

    if (parsed == null) {
      return;
    }

    setState(() {
      value = _normalize(parsed);
    });
  }

  void _setValue(int newValue) {
    final normalized = _normalize(newValue);

    setState(() {
      value = normalized;

      controller.text = '$normalized';

      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    });
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),

      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),

        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              // ===============================================================
              // CABECERA
              // ===============================================================
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,

                    decoration: BoxDecoration(
                      color: CharacterHomeColors.tintedSurface(
                        context,
                        CharacterHomeColors.health(context),
                        lightStrength: 0.14,
                        darkStrength: 0.20,
                      ),

                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: Icon(
                      Icons.favorite_rounded,
                      color: CharacterHomeColors.health(context),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          'Puntos de golpe',

                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          'Establece la vida actual',

                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },

                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ===============================================================
              // VIDA ACTUAL
              // ===============================================================
              Container(
                width: double.infinity,

                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),

                decoration: BoxDecoration(
                  color: CharacterHomeColors.tintedSurface(
                    context,
                    CharacterHomeColors.health(context),
                    lightStrength: 0.08,
                    darkStrength: 0.13,
                  ),

                  borderRadius: BorderRadius.circular(20),

                  border: Border.all(
                    color: CharacterHomeColors.tintedBorder(
                      context,
                      CharacterHomeColors.health(context),
                    ),
                  ),
                ),

                child: Column(
                  children: [
                    Text(
                      'Vida actual',

                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,

                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),

                        children: [
                          TextSpan(
                            text: '${widget.currentHealth}',

                            style: TextStyle(
                              color: CharacterHomeColors.health(context),
                            ),
                          ),

                          TextSpan(
                            text: ' / ${widget.maxHealth}',

                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ===============================================================
              // VIDA FINAL
              // ===============================================================
              TextField(
                controller: controller,

                autofocus: true,

                keyboardType: TextInputType.number,

                textAlign: TextAlign.center,

                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,

                  color: CharacterHomeColors.health(context),
                ),

                decoration: InputDecoration(
                  labelText: 'Nueva vida',

                  helperText: 'Entre 0 y ${widget.maxHealth}',

                  prefixIcon: const Icon(Icons.favorite_border_rounded),
                ),

                onChanged: _readValue,

                onSubmitted: (_) {
                  Navigator.pop(context, value);
                },
              ),

              const SizedBox(height: 12),

              // ===============================================================
              // ACCESOS RÁPIDOS
              // ===============================================================
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _setValue(0);
                      },
                      child: const Text('0'),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _setValue(widget.maxHealth ~/ 2);
                      },
                      child: const Text('50%'),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _setValue(widget.maxHealth);
                      },
                      child: const Text('Máx.'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ===============================================================
              // PREVISUALIZACIÓN DEL EVENTO
              // ===============================================================
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),

                width: double.infinity,

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: CharacterHomeColors.tintedSurface(
                    context,
                    changeColor,
                    lightStrength: 0.09,
                    darkStrength: 0.15,
                  ),

                  borderRadius: BorderRadius.circular(18),

                  border: Border.all(
                    color: CharacterHomeColors.tintedBorder(
                      context,
                      changeColor,
                    ),
                  ),
                ),

                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,

                      decoration: BoxDecoration(
                        color: changeColor.withValues(alpha: 0.13),

                        borderRadius: BorderRadius.circular(13),
                      ),

                      child: Icon(changeIcon, color: changeColor),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            changeTitle,

                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            changeText,

                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: changeColor,

                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      '$value / ${widget.maxHealth}',

                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ===============================================================
              // GUARDAR
              // ===============================================================
              SizedBox(
                width: double.infinity,

                child: FilledButton.icon(
                  onPressed: unchanged
                      ? null
                      : () {
                          Navigator.pop(context, value);
                        },

                  icon: const Icon(Icons.check_rounded),

                  label: const Text('Aplicar cambio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
