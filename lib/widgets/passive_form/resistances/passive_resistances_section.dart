import 'package:flutter/material.dart';

import '../../../models/damage_resistance.dart';

class PassiveResistancesSection extends StatelessWidget {
  final List<DamageResistance> values;
  final ValueChanged<List<DamageResistance>> onChanged;

  const PassiveResistancesSection({
    super.key,
    required this.values,
    required this.onChanged,
  });

  Future<DamageResistance?> _edit(
    BuildContext context, {
    DamageResistance? initial,
  }) async {
    final controller = TextEditingController(text: initial?.damageType ?? '');
    var tier = initial?.tier ?? DamageResistanceTier.minor;

    final result = await showDialog<DamageResistance>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                initial == null ? 'Añadir resistencia' : 'Editar resistencia',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de daño',
                      hintText: 'Fuego, frío, radiante, cortante...',
                      prefixIcon: Icon(Icons.local_fire_department_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<DamageResistanceTier>(
                    initialValue: tier,
                    decoration: const InputDecoration(
                      labelText: 'Nivel',
                      prefixIcon: Icon(Icons.shield_rounded),
                    ),
                    items: DamageResistanceTier.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => tier = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '2 menores = normal · 2 normales = mayor · '
                    '2 mayores = inmunidad',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final damageType = controller.text.trim();
                    if (damageType.isEmpty) {
                      return;
                    }
                    Navigator.pop(
                      dialogContext,
                      DamageResistance(
                        damageType: damageType,
                        tier: tier,
                      ),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  child: Icon(Icons.shield_rounded, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resistencias al daño',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Menor reduce 25 %, normal 50 %, mayor 75 % e '
                        'inmunidad 100 %. Se apilan por tipo.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Añadir resistencia',
                  onPressed: () async {
                    final result = await _edit(context);
                    if (result == null) {
                      return;
                    }
                    onChanged([...values, result]);
                  },
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ),
          if (values.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Sin resistencias.'),
              ),
            )
          else ...[
            const Divider(height: 1),
            for (var index = 0; index < values.length; index++)
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: Text(
                  values[index].damageType,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(values[index].tier.label),
                onTap: () async {
                  final result = await _edit(
                    context,
                    initial: values[index],
                  );
                  if (result == null) {
                    return;
                  }
                  final updated = List<DamageResistance>.from(values);
                  updated[index] = result;
                  onChanged(updated);
                },
                trailing: IconButton(
                  tooltip: 'Eliminar',
                  onPressed: () {
                    final updated = List<DamageResistance>.from(values)
                      ..removeAt(index);
                    onChanged(updated);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
