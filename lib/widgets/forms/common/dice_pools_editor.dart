import 'package:flutter/material.dart';

import '../../../models/dice_pool.dart';

class DicePoolsEditor extends StatelessWidget {
  final List<DicePool> pools;

  final VoidCallback onAdd;

  final VoidCallback onChanged;

  final List<int> availableDice;

  final int maximumCount;

  const DicePoolsEditor({
    super.key,
    required this.pools,
    required this.onAdd,
    required this.onChanged,
    this.availableDice = const [4, 6, 8, 10, 12, 20],
    this.maximumCount = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < pools.length; index++) ...[
          _DicePoolRow(
            pool: pools[index],
            availableDice: availableDice,
            maximumCount: maximumCount,

            onChanged: onChanged,

            onDelete: () {
              pools.removeAt(index);
              onChanged();
            },
          ),

          if (index < pools.length - 1) const SizedBox(height: 8),
        ],

        const SizedBox(height: 8),

        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Añadir dados'),
          ),
        ),
      ],
    );
  }
}

class _DicePoolRow extends StatelessWidget {
  final DicePool pool;

  final List<int> availableDice;

  final int maximumCount;

  final VoidCallback onChanged;

  final VoidCallback onDelete;

  const _DicePoolRow({
    required this.pool,
    required this.availableDice,
    required this.maximumCount,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: pool.count,
            decoration: const InputDecoration(labelText: 'Cantidad'),
            items: List.generate(maximumCount, (index) => index + 1).map((
              value,
            ) {
              return DropdownMenuItem(value: value, child: Text('$value'));
            }).toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              pool.count = value;

              onChanged();
            },
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: pool.sides,
            decoration: const InputDecoration(labelText: 'Dado'),
            items: availableDice.map((value) {
              return DropdownMenuItem(value: value, child: Text('d$value'));
            }).toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              pool.sides = value;

              onChanged();
            },
          ),
        ),

        IconButton(
          tooltip: 'Eliminar dado',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    );
  }
}
