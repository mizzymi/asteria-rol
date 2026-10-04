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
  }) {
    return showDialog<DamageResistance>(
      context: context,
      builder: (_) => _DamageResistanceEditorDialog(initial: initial),
    );
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
                const CircleAvatar(child: Icon(Icons.shield_rounded, size: 19)),
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
                  final result = await _edit(context, initial: values[index]);
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

class _DamageResistanceEditorDialog extends StatefulWidget {
  final DamageResistance? initial;

  const _DamageResistanceEditorDialog({this.initial});

  @override
  State<_DamageResistanceEditorDialog> createState() =>
      _DamageResistanceEditorDialogState();
}

class _DamageResistanceEditorDialogState
    extends State<_DamageResistanceEditorDialog> {
  late final TextEditingController _damageTypeController;
  late DamageResistanceTier _tier;

  @override
  void initState() {
    super.initState();
    _damageTypeController = TextEditingController(
      text: widget.initial?.damageType ?? '',
    );
    _tier = widget.initial?.tier ?? DamageResistanceTier.minor;
  }

  @override
  void dispose() {
    _damageTypeController.dispose();
    super.dispose();
  }

  void _save() {
    final damageType = _damageTypeController.text.trim();
    if (damageType.isEmpty) {
      return;
    }

    Navigator.of(
      context,
    ).pop(DamageResistance(damageType: damageType, tier: _tier));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initial == null ? 'Añadir resistencia' : 'Editar resistencia',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _damageTypeController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Tipo de daño',
              hintText: 'Fuego, frío, radiante, cortante...',
              prefixIcon: Icon(Icons.local_fire_department_rounded),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<DamageResistanceTier>(
            initialValue: _tier,
            decoration: const InputDecoration(
              labelText: 'Nivel',
              prefixIcon: Icon(Icons.shield_rounded),
            ),
            items: DamageResistanceTier.values
                .map(
                  (value) =>
                      DropdownMenuItem(value: value, child: Text(value.label)),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _tier = value;
              });
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
