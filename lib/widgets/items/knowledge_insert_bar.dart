import 'package:flutter/material.dart';

import '../../models/character.dart';

class KnowledgeInsertBar extends StatelessWidget {
  final Character? character;
  final ValueChanged<String> onInsert;
  final VoidCallback? onCreateKnowledge; // <-- Callback para crear nuevo saber

  const KnowledgeInsertBar({
    super.key,
    required this.character,
    required this.onInsert,
    this.onCreateKnowledge,
  });

  @override
  Widget build(BuildContext context) {
    final character = this.character;
    final hasKnowledges = character != null && character.knowledges.isNotEmpty;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Menú desplegable dinámico (Saberes / Aviso de vacío + Opción de crear)
        PopupMenuButton<String>(
          tooltip: 'Saberes y Grimorios',
          onSelected: (value) {
            if (value == '__create_new__') {
              onCreateKnowledge?.call();
            } else {
              onInsert(value);
            }
          },
          itemBuilder: (_) {
            final items = <PopupMenuEntry<String>>[];

            if (!hasKnowledges) {
              items.add(
                const PopupMenuItem<String>(
                  enabled: false,
                  child: Text('No hay ningún conocimiento creado.'),
                ),
              );
              items.add(const PopupMenuDivider());
            } else {
              for (final k in character.knowledges) {
                items.add(
                  PopupMenuItem<String>(
                    value: k.knowledgeId,
                    child: Row(
                      children: [
                        const Icon(Icons.bookmark_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text(k.knowledgeId),
                      ],
                    ),
                  ),
                );
              }
              items.add(const PopupMenuDivider());
            }

            // Opción fija para crear un nuevo saber
            items.add(
              PopupMenuItem<String>(
                value: '__create_new__',
                child: Row(
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: Theme.of(context).colorScheme.secondary),
                    SizedBox(width: 8),
                    Text(
                      '¿Deseas crear uno nuevo?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            );

            return items;
          },
          child: Chip(
            avatar: const Icon(Icons.auto_stories_rounded, size: 18),
            label: Text(
              hasKnowledges ? 'Saberes conocidos' : 'Crear nuevo saber...',
            ),
          ),
        ),
      ],
    );
  }
}
