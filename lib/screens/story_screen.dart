import 'package:flutter/material.dart';

import '../models/character.dart';
import '../services/character_storage_service.dart';

class StoryScreen extends StatefulWidget {
  final Character character;

  const StoryScreen({super.key, required this.character});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  Character get character => widget.character;

  Future<void> save() async {
    await CharacterStorageService.saveCharacter(character);
  }

  Future<String?> editSection({
    required String title,
    required String value,
    required String hint,
  }) async {
    String newValue = value;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: TextFormField(
              initialValue: value,
              autofocus: true,
              minLines: 5,
              maxLines: 12,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: hint,
                alignLabelWithHint: true,
              ),
              onChanged: (text) {
                newValue = text;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(newValue.trim());
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> editBackstory() async {
    final result = await editSection(
      title: 'Historia',
      value: character.backstory,
      hint:
          'Cuenta el pasado del personaje, de dónde viene, qué le ocurrió y cómo llegó hasta aquí...',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      character.backstory = result;
    });

    await save();
  }

  Future<void> editAppearance() async {
    final result = await editSection(
      title: 'Apariencia',
      value: character.appearance,
      hint: 'Describe su aspecto, ropa, rasgos distintivos, cicatrices...',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      character.appearance = result;
    });

    await save();
  }

  Future<void> editPersonality() async {
    final result = await editSection(
      title: 'Personalidad',
      value: character.personality,
      hint: '¿Cómo se comporta? ¿Cómo habla? ¿Cómo trata a los demás?',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      character.personality = result;
    });

    await save();
  }

  Future<void> editIdeals() async {
    final result = await editSection(
      title: 'Ideales',
      value: character.ideals,
      hint: '¿En qué cree? ¿Qué principios intenta seguir?',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      character.ideals = result;
    });

    await save();
  }

  Future<void> editBonds() async {
    final result = await editSection(
      title: 'Vínculos',
      value: character.bonds,
      hint:
          'Personas, lugares, organizaciones o recuerdos importantes para el personaje...',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      character.bonds = result;
    });

    await save();
  }

  Future<void> editFlaws() async {
    final result = await editSection(
      title: 'Defectos',
      value: character.flaws,
      hint:
          'Miedos, debilidades, malos hábitos, prejuicios o problemas personales...',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      character.flaws = result;
    });

    await save();
  }

  Future<void> editGoals() async {
    final result = await editSection(
      title: 'Objetivos',
      value: character.goals,
      hint:
          '¿Qué quiere conseguir? ¿Qué objetivos tiene a corto o largo plazo?',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      character.goals = result;
    });

    await save();
  }

  Future<void> editNotes() async {
    final result = await editSection(
      title: 'Notas',
      value: character.storyNotes,
      hint: 'Cualquier información adicional sobre el personaje...',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      character.storyNotes = result;
    });

    await save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historia')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
          children: [
            _StoryHeader(character: character),

            const SizedBox(height: 24),

            _SectionTitle(title: 'El personaje'),

            const SizedBox(height: 10),

            _StoryCard(
              icon: Icons.history_edu_rounded,
              title: 'Historia',
              value: character.backstory,
              emptyText:
                  'Todavía no has escrito la historia de ${character.name}.',
              onEdit: editBackstory,
            ),

            _StoryCard(
              icon: Icons.visibility_rounded,
              title: 'Apariencia',
              value: character.appearance,
              emptyText: 'Sin descripción física.',
              onEdit: editAppearance,
            ),

            _StoryCard(
              icon: Icons.psychology_rounded,
              title: 'Personalidad',
              value: character.personality,
              emptyText: 'Sin personalidad definida.',
              onEdit: editPersonality,
            ),

            const SizedBox(height: 18),

            _SectionTitle(title: 'Interpretación'),

            const SizedBox(height: 10),

            _StoryCard(
              icon: Icons.lightbulb_rounded,
              title: 'Ideales',
              value: character.ideals,
              emptyText: 'Sin ideales definidos.',
              onEdit: editIdeals,
            ),

            _StoryCard(
              icon: Icons.link_rounded,
              title: 'Vínculos',
              value: character.bonds,
              emptyText: 'Sin vínculos definidos.',
              onEdit: editBonds,
            ),

            _StoryCard(
              icon: Icons.warning_amber_rounded,
              title: 'Defectos',
              value: character.flaws,
              emptyText: 'Sin defectos definidos.',
              onEdit: editFlaws,
            ),

            const SizedBox(height: 18),

            _SectionTitle(title: 'Motivaciones'),

            const SizedBox(height: 10),

            _StoryCard(
              icon: Icons.flag_rounded,
              title: 'Objetivos',
              value: character.goals,
              emptyText: 'El personaje todavía no tiene objetivos escritos.',
              onEdit: editGoals,
            ),

            _StoryCard(
              icon: Icons.notes_rounded,
              title: 'Notas',
              value: character.storyNotes,
              emptyText: 'Sin notas adicionales.',
              onEdit: editNotes,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryHeader extends StatelessWidget {
  final Character character;

  const _StoryHeader({required this.character});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 34,
          child: Text(
            character.name.isEmpty ? '?' : character.name[0].toUpperCase(),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                character.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 3),

              Text(character.race),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final IconData icon;

  final String title;
  final String value;
  final String emptyText;

  final VoidCallback onEdit;

  const _StoryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.emptyText,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = value.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        Icon(
                          Icons.edit_rounded,
                          size: 17,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Text(
                      hasContent ? value : emptyText,
                      style: TextStyle(
                        color: hasContent
                            ? null
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: hasContent
                            ? FontStyle.normal
                            : FontStyle.italic,
                        height: 1.4,
                      ),
                      maxLines: hasContent ? 6 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
