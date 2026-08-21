import 'package:flutter/material.dart';

import '../../../models/item.dart';

class ItemCalculationSection extends StatelessWidget {
  final bool calculable;

  /// Objetos que pueden utilizarse como coste.
  ///
  /// En el inventario serán normalmente los objetos del personaje.
  /// En biblioteca pueden ser las plantillas disponibles.
  final List<CharacterItem> availableItems;

  final List<ItemCalculationCost> costs;

  final ValueChanged<bool> onCalculableChanged;

  final VoidCallback onAddCost;

  final void Function(int index, String itemId) onCostItemChanged;

  final void Function(int index, int quantity) onCostQuantityChanged;

  final ValueChanged<int> onRemoveCost;

  const ItemCalculationSection({
    super.key,
    required this.calculable,
    required this.availableItems,
    required this.costs,
    required this.onCalculableChanged,
    required this.onAddCost,
    required this.onCostItemChanged,
    required this.onCostQuantityChanged,
    required this.onRemoveCost,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.calculate_rounded,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(width: 12),

            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calculadora',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 2),
                  Text('Define qué objetos se necesitan por unidad'),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: calculable,
          onChanged: onCalculableChanged,
          title: const Text(
            'Objeto calculable',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: const Text(
            'Permite calcular cuántas unidades pueden obtenerse según otros objetos.',
          ),
        ),

        if (calculable) ...[
          const SizedBox(height: 10),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Coste por unidad',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),

              Text(
                '${costs.length}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Puedes usar monedas, materiales o cualquier otro objeto.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 12),

          if (costs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 30),
                  SizedBox(height: 8),
                  Text(
                    'Sin objetos de coste',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Añade al menos uno para utilizar la calculadora.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...List.generate(costs.length, (index) {
              final cost = costs[index];

              final selectedExists = availableItems.any(
                (item) =>
                    item.templateId == cost.itemId || item.id == cost.itemId,
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedExists ? cost.itemId : null,
                        decoration: const InputDecoration(
                          labelText: 'Objeto',
                          isDense: true,
                          prefixIcon: Icon(Icons.inventory_2_rounded),
                        ),
                        items: availableItems
                            .where((item) {
                              final key = item.templateId.isNotEmpty
                                  ? item.templateId
                                  : item.id;

                              final usedElsewhere = costs.asMap().entries.any(
                                (entry) =>
                                    entry.key != index &&
                                    entry.value.itemId == key,
                              );

                              return !usedElsewhere;
                            })
                            .map((item) {
                              final key = item.templateId.isNotEmpty
                                  ? item.templateId
                                  : item.id;

                              return DropdownMenuItem<String>(
                                value: key,
                                child: Text(
                                  item.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            })
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          onCostItemChanged(index, value);
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    SizedBox(
                      width: 82,
                      child: TextFormField(
                        initialValue: '${cost.quantityPerUnit}',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cant.',
                          isDense: true,
                        ),
                        onChanged: (value) {
                          final quantity = int.tryParse(value);

                          if (quantity == null || quantity < 1) {
                            return;
                          }

                          onCostQuantityChanged(index, quantity);
                        },
                      ),
                    ),

                    IconButton(
                      tooltip: 'Eliminar coste',
                      onPressed: () {
                        onRemoveCost(index);
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 4),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: availableItems.isNotEmpty ? onAddCost : null,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Añadir objeto al coste'),
            ),
          ),
        ],
      ],
    );
  }
}
