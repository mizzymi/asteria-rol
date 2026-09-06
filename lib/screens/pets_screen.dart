import 'package:flutter/material.dart';

import '../models/character.dart';
import '../models/pet.dart';
import '../services/character_storage_service.dart';
import '../widgets/common/empty_state.dart';
import 'pet_detail_screen.dart';
import 'pet_form_screen.dart';

class PetsScreen extends StatefulWidget {
  final Character character;

  const PetsScreen({super.key, required this.character});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  Character get character => widget.character;

  Future<void> _save() async {
    await CharacterStorageService.saveCharacter(character);
    if (mounted) setState(() {});
  }

  Future<void> _openForm({Pet? pet}) async {
    final result = await Navigator.push<Pet>(
      context,
      MaterialPageRoute(builder: (_) => PetFormScreen(pet: pet)),
    );

    if (result == null || !mounted) return;

    setState(() {
      if (pet == null) {
        character.pets.add(result);
      } else {
        final index = character.pets.indexWhere((p) => p.id == result.id);
        if (index >= 0) {
          character.pets[index] = result;
        }
      }
    });

    await _save();
  }

  Future<void> _deletePet(Pet pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar mascota'),
        content: Text('¿Deseas eliminar a "${pet.name}" de tus compañeros?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        character.pets.removeWhere((p) => p.id == pet.id);
      });
      await _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pets = character.pets;

    return Scaffold(
      appBar: AppBar(title: const Text('Mascotas y Compañeros')),
      body: pets.isEmpty
          ? EmptyState(
              icon: Icons.pets_rounded,
              title: 'Sin mascotas',
              message:
                  'Añade familiares, bestias o compañeros de viaje para tu aventura.',
              actionLabel: 'Añadir mascota',
              onAction: () => _openForm(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: pets.map((pet) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.pets_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      pet.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${pet.species.isNotEmpty ? pet.species : "Compañero"} • PV: ${pet.currentHealth}/${pet.maxHealth} • CA: ${pet.armorClass}',
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') _openForm(pet: pet);
                        if (val == 'delete') _deletePet(pet);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_rounded),
                            title: Text('Editar atributos'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline_rounded),
                            title: Text('Eliminar'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PetDetailScreen(character: character, pet: pet),
                        ),
                      );
                      setState(() {});
                    },
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva mascota'),
      ),
    );
  }
}
