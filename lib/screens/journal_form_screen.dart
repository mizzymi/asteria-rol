import 'package:flutter/material.dart';

import '../models/journal_entry.dart';

import '../widgets/journal/journal_form/journal_content_section.dart';
import '../widgets/journal/journal_form/journal_general_section.dart';
import '../widgets/journal/journal_form/journal_meta_section.dart';

class JournalFormScreen extends StatefulWidget {
  final JournalEntry? entry;

  const JournalFormScreen({super.key, this.entry});

  @override
  State<JournalFormScreen> createState() => _JournalFormScreenState();
}

class _JournalFormScreenState extends State<JournalFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ===========================================================================
  // CONTROLADORES
  // ===========================================================================

  late final TextEditingController titleController;

  late final TextEditingController contentController;

  late final TextEditingController dateController;

  late final TextEditingController sessionController;

  late final TextEditingController notesController;

  // ===========================================================================
  // ESTADO
  // ===========================================================================

  late JournalEntryType type;

  bool important = false;

  bool get editing {
    return widget.entry != null;
  }

  // ===========================================================================
  // INIT
  // ===========================================================================

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

  // ===========================================================================
  // GUARDAR
  // ===========================================================================

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

    Navigator.pop<JournalEntry>(context, entry);
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    titleController.dispose();

    contentController.dispose();

    dateController.dispose();

    sessionController.dispose();

    notesController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar entrada' : 'Nueva entrada'),
        actions: [
          IconButton(
            tooltip: 'Guardar',
            onPressed: saveEntry,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
            children: [
              // ===============================================================
              // GENERAL
              // ===============================================================
              JournalGeneralSection(
                titleController: titleController,
                type: type,
                onTypeChanged: (value) {
                  setState(() {
                    type = value;
                  });
                },
              ),

              const SizedBox(height: 28),

              // ===============================================================
              // CONTEXTO
              // ===============================================================
              JournalMetaSection(
                dateController: dateController,
                sessionController: sessionController,
                important: important,
                onImportantChanged: (value) {
                  setState(() {
                    important = value;
                  });
                },
              ),

              const SizedBox(height: 28),

              // ===============================================================
              // CONTENIDO
              // ===============================================================
              JournalContentSection(
                contentController: contentController,
                notesController: notesController,
              ),

              const SizedBox(height: 30),

              // ===============================================================
              // GUARDAR
              // ===============================================================
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
