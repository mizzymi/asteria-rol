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
  final amountController = TextEditingController();

  bool healing = false;

  int amount = 0;

  int _clampHealth(int value) {
    if (value < 0) {
      return 0;
    }

    if (value > widget.maxHealth) {
      return widget.maxHealth;
    }

    return value;
  }

  int get previewHealth {
    if (healing) {
      return _clampHealth(widget.currentHealth + amount);
    }

    return _clampHealth(widget.currentHealth - amount);
  }

  @override
  void dispose() {
    amountController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = healing
        ? const Color(0xFF55B96B)
        : CharacterHomeColors.health;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: CharacterHomeColors.background(
                        context,
                        color,
                        strength: 0.22,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      healing
                          ? Icons.favorite_rounded
                          : Icons.heart_broken_rounded,
                      color: color,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      'Modificar puntos de golpe',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
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

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CharacterHomeColors.background(
                    context,
                    CharacterHomeColors.health,
                    strength: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Vida actual',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${widget.currentHealth} / ${widget.maxHealth}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: CharacterHomeColors.health,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.heart_broken_rounded),
                    label: Text('Daño'),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.favorite_rounded),
                    label: Text('Curar'),
                  ),
                ],
                selected: {healing},
                onSelectionChanged: (values) {
                  setState(() {
                    healing = values.first;
                  });
                },
              ),

              const SizedBox(height: 18),

              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: healing ? 'Puntos a curar' : 'Daño recibido',
                  prefixIcon: Icon(
                    healing ? Icons.add_rounded : Icons.remove_rounded,
                    color: color,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    amount = int.tryParse(value) ?? 0;

                    if (amount < 0) {
                      amount = 0;
                    }
                  });
                },
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CharacterHomeColors.background(
                    context,
                    color,
                    strength: 0.18,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withValues(alpha: 0.20)),
                ),
                child: Column(
                  children: [
                    Text(
                      healing ? 'Después de curar' : 'Después del daño',
                      style: theme.textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '$previewHealth / ${widget.maxHealth}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: amount > 0
                      ? () {
                          Navigator.pop(context, previewHealth);
                        }
                      : null,
                  icon: Icon(
                    healing
                        ? Icons.favorite_rounded
                        : Icons.heart_broken_rounded,
                  ),
                  label: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
