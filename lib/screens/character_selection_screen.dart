import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rol/models/dnd_class.dart';

import '../models/character.dart';
import '../services/character_storage_service.dart';
import 'character_form_screen.dart';
import 'character_home_screen.dart';

class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  List<Character> characters = [];

  String search = '';

  @override
  void initState() {
    super.initState();

    loadCharacters();
  }

  void loadCharacters() {
    setState(() {
      characters = CharacterStorageService.getCharacters();
    });
  }

  Future<void> createCharacter() async {
    final result = await Navigator.push<Character>(
      context,
      MaterialPageRoute(builder: (_) => const CharacterFormScreen()),
    );

    if (result != null) {
      loadCharacters();
    }
  }

  Future<void> openCharacter(Character character) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CharacterHomeScreen(character: character),
      ),
    );

    loadCharacters();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCharacters = characters.where((character) {
      return character.name.toLowerCase().contains(search.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis personajes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              TextField(
                onChanged: (value) {
                  setState(() {
                    search = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Buscar personaje...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: filteredCharacters.isEmpty
                    ? _EmptyState(
                        hasSearch: search.isNotEmpty,
                        onCreate: createCharacter,
                      )
                    : ListView.builder(
                        itemCount: filteredCharacters.length,
                        itemBuilder: (context, index) {
                          final character = filteredCharacters[index];

                          return _CharacterCard(
                            character: character,
                            onTap: () {
                              openCharacter(character);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createCharacter,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo personaje'),
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final Character character;
  final VoidCallback onTap;

  const _CharacterCard({required this.character, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundImage: character.avatarPath != null
                    ? FileImage(File(character.avatarPath!))
                    : null,
                child: character.avatarPath == null
                    ? Text(
                        character.name.isNotEmpty
                            ? character.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${character.race} · ${character.dndClass.label}'),
                    const SizedBox(height: 3),
                    Text(
                      'Nivel ${character.level}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onCreate;

  const _EmptyState({required this.hasSearch, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearch
                  ? Icons.search_off_rounded
                  : Icons.person_add_alt_1_rounded,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(height: 18),

            Text(
              hasSearch
                  ? 'No encontramos ese personaje'
                  : 'Todavía no tienes personajes',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            if (!hasSearch)
              const Text(
                'Crea tu primer personaje para comenzar la aventura.',
                textAlign: TextAlign.center,
              ),

            if (!hasSearch) ...[
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crear personaje'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
