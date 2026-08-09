import 'package:flutter/material.dart';

class AbilityUsesSection extends StatelessWidget {
  final TextEditingController maxUsesController;

  final TextEditingController notesController;

  const AbilityUsesSection({
    super.key,
    required this.maxUsesController,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.repeat_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(width: 8),

            Text(
              'Usos',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        const SizedBox(height: 12),

        TextFormField(
          controller: maxUsesController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Usos máximos',
            helperText: '0 = usos ilimitados',
            prefixIcon: Icon(Icons.repeat_rounded),
          ),
          validator: (value) {
            final number = int.tryParse(value ?? '');

            if (number == null) {
              return 'Introduce un número';
            }

            if (number < 0) {
              return 'No puede ser negativo';
            }

            return null;
          },
        ),

        const SizedBox(height: 28),

        Row(
          children: [
            Icon(
              Icons.notes_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(width: 8),

            Text(
              'Notas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        const SizedBox(height: 12),

        TextFormField(
          controller: notesController,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Notas adicionales',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
