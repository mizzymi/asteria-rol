import 'package:flutter/material.dart';

import '../models/journal_entry.dart';

class JournalFormScreen extends StatefulWidget {
  final JournalEntry? entry;

  const JournalFormScreen({super.key, this.entry});

  @override
  State<JournalFormScreen> createState() => _JournalFormScreenState();
}

class _JournalFormScreenState extends State<JournalFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController titleController;

  late final TextEditingController contentController;

  late final TextEditingController dateController;

  late final TextEditingController sessionController;

  late final TextEditingController notesController;

  late JournalEntryType type;

  bool important = false;

  bool get editing => widget.entry != null;

  @override
  void initState() {
    super.initState();

    final entry = widget.entry;

    titleController = TextEditingController(text: entry?.title ?? '');

    contentController = TextEditingController(text: entry?.content ?? '');

    dateController = TextEditingController(text: entry?.dateText ?? '');

    sessionController = TextEditingController(text: entry?.sessionText ?? '');

    notesController = TextEditingController(text: entry?.notes ?? '');

    type = entry?.type ?? JournalEntryType.session;

    important = entry?.important ?? false;
  }

  void saveEntry() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final entry = JournalEntry(
      id: widget.entry?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      content: contentController.text.trim(),
      type: type,
      dateText: dateController.text.trim(),
      sessionText: sessionController.text.trim(),
      important: important,
      notes: notesController.text.trim(),
    );

    Navigator.pop(context, entry);
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    dateController.dispose();
    sessionController.dispose();
    notesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar entrada' : 'Nueva entrada'),
        actions: [
          IconButton(
            onPressed: saveEntry,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduce un título';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<JournalEntryType>(
                initialValue: type,
                decoration: const InputDecoration(
                  labelText: 'Tipo de entrada',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: JournalEntryType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.label));
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    type = value;
                  });
                },
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha',
                        hintText: 'Ej: Día 12',
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: TextFormField(
                      controller: sessionController,
                      decoration: const InputDecoration(
                        labelText: 'Sesión',
                        hintText: 'Ej: Sesión 4',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: important,
                title: const Text('Entrada importante'),
                subtitle: const Text('Se destacará en el diario'),
                onChanged: (value) {
                  setState(() {
                    important = value;
                  });
                },
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: contentController,
                minLines: 7,
                maxLines: 18,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Contenido',
                  alignLabelWithHint: true,
                  hintText: '¿Qué ocurrió?',
                ),
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: notesController,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 30),

              FilledButton.icon(
                onPressed: saveEntry,
                icon: const Icon(Icons.save_rounded),
                label: Text(editing ? 'Guardar cambios' : 'Crear entrada'),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
