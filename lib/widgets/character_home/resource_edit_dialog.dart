import 'package:flutter/material.dart';

import '../../models/character_resource.dart';
import '../../utils/number_format.dart';

class ResourceEditDialog {
  const ResourceEditDialog._();

  static Future<int?> show(
    BuildContext context, {
    required CharacterResource resource,
  }) {
    return showDialog<int>(
      context: context,
      builder: (_) {
        return _ResourceEditDialogContent(resource: resource);
      },
    );
  }
}

class _ResourceEditDialogContent extends StatefulWidget {
  final CharacterResource resource;

  const _ResourceEditDialogContent({required this.resource});

  @override
  State<_ResourceEditDialogContent> createState() =>
      _ResourceEditDialogContentState();
}

class _ResourceEditDialogContentState
    extends State<_ResourceEditDialogContent> {
  late int value;

  late final TextEditingController amountController;

  CharacterResource get resource => widget.resource;

  @override
  void initState() {
    super.initState();

    value = resource.currentValue;

    amountController = TextEditingController();
  }

  @override
  void dispose() {
    amountController.dispose();

    super.dispose();
  }

  int readAmount() {
    final text = amountController.text.trim().replaceAll('.', '');

    return int.tryParse(text) ?? 0;
  }

  int normalizeValue(int newValue) {
    if (newValue < 0) {
      return 0;
    }

    if (resource.hasMaximum && newValue > resource.maxValue) {
      return resource.maxValue;
    }

    return newValue;
  }

  void subtract() {
    final amount = readAmount();

    if (amount <= 0) {
      return;
    }

    setState(() {
      value = normalizeValue(value - amount);
    });
  }

  void add() {
    final amount = readAmount();

    if (amount <= 0) {
      return;
    }

    setState(() {
      value = normalizeValue(value + amount);
    });
  }

  void setExact() {
    final amount = readAmount();

    setState(() {
      value = normalizeValue(amount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(resource.icon, color: resource.colorFor(context)),

          const SizedBox(width: 10),

          Expanded(child: Text(resource.name)),
        ],
      ),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Valor actual', style: theme.textTheme.labelLarge),

            const SizedBox(height: 4),

            Text(
              formatThousands(value),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: resource.colorFor(context),
              ),
            ),

            const SizedBox(height: 4),

            Text(
              resource.hasMaximum
                  ? 'Máximo: ${formatThousands(resource.maxValue)}'
                  : 'Sin máximo',
              style: theme.textTheme.bodySmall,
            ),

            if (resource.hasMaximum) ...[
              const SizedBox(height: 14),

              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: resource.maxValue <= 0
                      ? 0
                      : (value / resource.maxValue).clamp(0.0, 1.0),
                  minHeight: 8,
                  color: resource.colorFor(context),
                  backgroundColor: resource.colorFor(context).withValues(alpha: 0.12),
                ),
              ),
            ],

            const SizedBox(height: 22),

            TextFormField(
              controller: amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                hintText: 'Ej. 25000',
                prefixIcon: Icon(Icons.calculate_rounded),
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: subtract,
                    icon: const Icon(Icons.remove_rounded),
                    label: const Text('Restar'),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: add,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Sumar'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: setExact,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Establecer valor'),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        value = 0;
                      });
                    },
                    icon: const Icon(Icons.battery_0_bar_rounded),
                    label: const Text('Vaciar'),
                  ),
                ),

                if (resource.hasMaximum) ...[
                  const SizedBox(width: 10),

                  Expanded(
                    child: TextButton.icon(
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
              ],
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),

        FilledButton(
          onPressed: () {
            Navigator.pop(context, value);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
