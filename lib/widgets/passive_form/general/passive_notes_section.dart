import 'package:flutter/material.dart';

class PassiveNotesSection extends StatelessWidget {
  final TextEditingController controller;

  const PassiveNotesSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: TextFormField(
          controller: controller,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Notas adicionales',
            hintText: 'Reglas especiales, recordatorios, aclaraciones...',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.notes_rounded),
          ),
        ),
      ),
    );
  }
}
