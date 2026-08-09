import 'package:flutter/material.dart';

import '../models/character.dart';

import '../services/character_storage_service.dart';

import '../widgets/common/section_header.dart';

import '../widgets/story/story_colors.dart';
import '../widgets/story/story_edit_dialog.dart';
import '../widgets/story/story_header.dart';
import '../widgets/story/story_section_card.dart';

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

  Future<void> _edit({
    required String title,
    required String value,
    required String hint,
    required IconData icon,
    required Color color,
    required ValueChanged<String> onSaved,
  }) async {
    final result = await StoryEditDialog.show(
      context,
      title: title,
      value: value,
      hint: hint,
      icon: icon,
      color: color,
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      onSaved(result);
    });

    await save();
  }

  Future<void> editBackstory() {
    return _edit(
      title: 'Historia',
      value: character.backstory,
      hint:
          'Cuenta el pasado del personaje, de dónde viene, qué le ocurrió y cómo llegó hasta aquí...',
      icon: Icons.history_edu_rounded,
      color: StoryColors.backstory,
      onSaved: (value) {
        character.backstory = value;
      },
    );
  }

  Future<void> editAppearance() {
    return _edit(
      title: 'Apariencia',
      value: character.appearance,
      hint: 'Describe su aspecto, ropa, rasgos distintivos, cicatrices...',
      icon: Icons.visibility_rounded,
      color: StoryColors.appearance,
      onSaved: (value) {
        character.appearance = value;
      },
    );
  }

  Future<void> editPersonality() {
    return _edit(
      title: 'Personalidad',
      value: character.personality,
      hint: '¿Cómo se comporta? ¿Cómo habla? ¿Cómo trata a los demás?',
      icon: Icons.psychology_rounded,
      color: StoryColors.personality,
      onSaved: (value) {
        character.personality = value;
      },
    );
  }

  Future<void> editIdeals() {
    return _edit(
      title: 'Ideales',
      value: character.ideals,
      hint: '¿En qué cree? ¿Qué principios intenta seguir?',
      icon: Icons.lightbulb_rounded,
      color: StoryColors.ideals,
      onSaved: (value) {
        character.ideals = value;
      },
    );
  }

  Future<void> editBonds() {
    return _edit(
      title: 'Vínculos',
      value: character.bonds,
      hint:
          'Personas, lugares, organizaciones o recuerdos importantes para el personaje...',
      icon: Icons.link_rounded,
      color: StoryColors.bonds,
      onSaved: (value) {
        character.bonds = value;
      },
    );
  }

  Future<void> editFlaws() {
    return _edit(
      title: 'Defectos',
      value: character.flaws,
      hint:
          'Miedos, debilidades, malos hábitos, prejuicios o problemas personales...',
      icon: Icons.warning_amber_rounded,
      color: StoryColors.flaws,
      onSaved: (value) {
        character.flaws = value;
      },
    );
  }

  Future<void> editGoals() {
    return _edit(
      title: 'Objetivos',
      value: character.goals,
      hint:
          '¿Qué quiere conseguir? ¿Qué objetivos tiene a corto o largo plazo?',
      icon: Icons.flag_rounded,
      color: StoryColors.goals,
      onSaved: (value) {
        character.goals = value;
      },
    );
  }

  Future<void> editNotes() {
    return _edit(
      title: 'Notas',
      value: character.storyNotes,
      hint: 'Cualquier información adicional sobre el personaje...',
      icon: Icons.notes_rounded,
      color: StoryColors.notes,
      onSaved: (value) {
        character.storyNotes = value;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historia')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
          children: [
            StoryHeader(character: character),

            const SizedBox(height: 28),

            const SectionHeader(
              icon: Icons.person_rounded,
              title: 'El personaje',
              subtitle: 'Quién es, cómo es y de dónde viene',
            ),

            const SizedBox(height: 12),

            StorySectionCard(
              icon: Icons.history_edu_rounded,
              color: StoryColors.backstory,
              title: 'Historia',
              value: character.backstory,
              emptyText: 'Todavía no has escrito su historia.',
              onEdit: editBackstory,
            ),

            StorySectionCard(
              icon: Icons.visibility_rounded,
              color: StoryColors.appearance,
              title: 'Apariencia',
              value: character.appearance,
              emptyText: 'Sin descripción física.',
              onEdit: editAppearance,
            ),

            StorySectionCard(
              icon: Icons.psychology_rounded,
              color: StoryColors.personality,
              title: 'Personalidad',
              value: character.personality,
              emptyText: 'Sin personalidad definida.',
              onEdit: editPersonality,
            ),

            const SizedBox(height: 20),

            const SectionHeader(
              icon: Icons.theater_comedy_rounded,
              title: 'Interpretación',
              subtitle: 'Principios, vínculos y debilidades',
            ),

            const SizedBox(height: 12),

            StorySectionCard(
              icon: Icons.lightbulb_rounded,
              color: StoryColors.ideals,
              title: 'Ideales',
              value: character.ideals,
              emptyText: 'Sin ideales definidos.',
              onEdit: editIdeals,
            ),

            StorySectionCard(
              icon: Icons.link_rounded,
              color: StoryColors.bonds,
              title: 'Vínculos',
              value: character.bonds,
              emptyText: 'Sin vínculos definidos.',
              onEdit: editBonds,
            ),

            StorySectionCard(
              icon: Icons.warning_amber_rounded,
              color: StoryColors.flaws,
              title: 'Defectos',
              value: character.flaws,
              emptyText: 'Sin defectos definidos.',
              onEdit: editFlaws,
            ),

            const SizedBox(height: 20),

            const SectionHeader(
              icon: Icons.explore_rounded,
              title: 'Motivaciones',
              subtitle: 'Qué busca y qué quieres recordar',
            ),

            const SizedBox(height: 12),

            StorySectionCard(
              icon: Icons.flag_rounded,
              color: StoryColors.goals,
              title: 'Objetivos',
              value: character.goals,
              emptyText: 'Todavía no tiene objetivos escritos.',
              onEdit: editGoals,
            ),

            StorySectionCard(
              icon: Icons.notes_rounded,
              color: StoryColors.notes,
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
