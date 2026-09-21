import 'dart:io';

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
        if (index >= 0) character.pets[index] = result;
      }
    });

    await _save();
  }

  Future<void> _openPet(Pet pet) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PetDetailScreen(character: character, pet: pet),
      ),
    );
    if (mounted) setState(() {});
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
      setState(() => character.pets.removeWhere((p) => p.id == pet.id));
      await _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pets = character.pets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mascotas y compañeros'),
        scrolledUnderElevation: 0,
      ),
      body: pets.isEmpty
          ? EmptyState(
              icon: Icons.pets_rounded,
              title: 'Sin mascotas',
              message:
                  'Añade familiares, bestias o compañeros de viaje para tu aventura.',
              actionLabel: 'Añadir mascota',
              onAction: () => _openForm(),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: pets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) => _buildPetCard(theme, pets[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva mascota'),
      ),
    );
  }

  Widget _buildPetCard(ThemeData theme, Pet pet) {
    final colors = theme.colorScheme;
    final hasImage = pet.avatarPath.isNotEmpty && File(pet.avatarPath).existsSync();
    final healthRatio = pet.maxHealth <= 0
        ? 0.0
        : (pet.currentHealth / pet.maxHealth).clamp(0.0, 1.0);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .55)),
      ),
      child: InkWell(
        onTap: () => _openPet(pet),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.file(
                      File(pet.avatarPath),
                      fit: BoxFit.cover,
                      alignment: Alignment(
                        pet.avatarAlignmentX,
                        pet.avatarAlignmentY,
                      ),
                    )
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primaryContainer,
                            colors.tertiaryContainer,
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.pets_rounded,
                        size: 68,
                        color: colors.onPrimaryContainer.withValues(alpha: .6),
                      ),
                    ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).colorScheme.surface.withValues(alpha: 0),
                            Theme.of(context).colorScheme.scrim.withValues(alpha: .72),
                          ],
                          stops: const [.28, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 54,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (pet.species.isNotEmpty)
                          Text(
                            pet.species,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onInverseSurface.withValues(alpha: .85),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: PopupMenuButton<String>(
                      iconColor: Theme.of(context).colorScheme.onInverseSurface,
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .35),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') _openForm(pet: pet);
                        if (value == 'delete') _deletePet(pet);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_rounded),
                            title: Text('Editar'),
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
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite_rounded, size: 18, color: colors.error),
                      const SizedBox(width: 7),
                      Text(
                        '${pet.currentHealth}/${pet.maxHealth} PV',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      _statChip(context, Icons.shield_rounded, 'CA ${pet.armorClass}'),
                      const SizedBox(width: 6),
                      _statChip(context, Icons.directions_run_rounded, '${pet.speed}'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: healthRatio,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(99),
                    backgroundColor: colors.surfaceContainerHighest,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(BuildContext context, IconData icon, String text) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
