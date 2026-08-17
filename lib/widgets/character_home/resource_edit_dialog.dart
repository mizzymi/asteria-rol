import 'package:flutter/material.dart';

import '../../models/character_resource.dart';

class ResourceEditDialog {
  const ResourceEditDialog._();

  static Future<int?> show(
    BuildContext context, {
    required CharacterResource resource,
  }) async {
    int value = resource.currentValue;

    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            void decrease() {
              if (value <= 0) {
                return;
              }

              setState(() {
                value--;
              });
            }

            void increase() {
              if (value >= resource.maxValue) {
                return;
              }

              setState(() {
                value++;
              });
            }

            return AlertDialog(
              title: Row(
                children: [
                  Icon(resource.icon, color: resource.color),

                  const SizedBox(width: 10),

                  Expanded(child: Text(resource.name)),
                ],
              ),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: value > 0 ? decrease : null,
                        icon: const Icon(Icons.remove_rounded),
                      ),

                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '$value',
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: resource.color,
                                  ),
                            ),

                            Text(
                              'de ${resource.maxValue}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),

                      IconButton.filledTonal(
                        onPressed: value < resource.maxValue ? increase : null,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: resource.maxValue <= 0
                          ? 0
                          : value / resource.maxValue,
                      minHeight: 8,
                      color: resource.color,
                      backgroundColor: resource.color.withValues(alpha: 0.12),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              value = 0;
                            });
                          },
                          icon: const Icon(Icons.battery_0_bar_rounded),
                          label: const Text('Vaciar'),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () {
                            setState(() {
                              value = resource.maxValue;
                            });
                          },
                          icon: const Icon(Icons.battery_full_rounded),
                          label: const Text('Llenar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),

                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, value);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
