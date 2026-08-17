import 'package:flutter/material.dart';

import '../models/character.dart';
import '../models/character_resource.dart';

import '../services/character_storage_service.dart';

import '../widgets/common/empty_state.dart';
import '../widgets/resources/resource_card.dart';

import 'resource_form_screen.dart';

class ResourcesScreen extends StatefulWidget {
  final Character character;

  const ResourcesScreen({super.key, required this.character});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  Character get character => widget.character;

  // ===========================================================================
  // GUARDAR
  // ===========================================================================

  Future<void> save() async {
    await CharacterStorageService.saveCharacter(character);
  }

  // ===========================================================================
  // CREAR
  // ===========================================================================

  Future<void> createResource() async {
    final resource = await Navigator.push<CharacterResource>(
      context,
      MaterialPageRoute(builder: (_) => const ResourceFormScreen()),
    );

    if (resource == null) {
      return;
    }

    setState(() {
      character.addResource(resource);
    });

    await save();
  }

  // ===========================================================================
  // EDITAR
  // ===========================================================================

  Future<void> editResource(CharacterResource resource) async {
    final result = await Navigator.push<CharacterResource>(
      context,
      MaterialPageRoute(builder: (_) => ResourceFormScreen(resource: resource)),
    );

    if (result == null) {
      return;
    }

    setState(() {
      character.updateResource(result);
    });

    await save();
  }

  // ===========================================================================
  // GASTAR
  // ===========================================================================

  Future<void> decreaseResource(CharacterResource resource) async {
    setState(() {
      resource.consume(1);
    });

    await save();
  }

  // ===========================================================================
  // RECUPERAR
  // ===========================================================================

  Future<void> increaseResource(CharacterResource resource) async {
    setState(() {
      resource.restore(1);
    });

    await save();
  }

  // ===========================================================================
  // ELIMINAR
  // ===========================================================================

  Future<void> deleteResource(CharacterResource resource) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar recurso'),
          content: Text('¿Quieres eliminar "${resource.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      character.removeResource(resource.id);
    });

    await save();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final resources = character.resources
        .where((resource) => resource.visible)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Recursos')),

      body: resources.isEmpty
          ? EmptyState(
              icon: Icons.battery_charging_full_rounded,
              title: 'Sin recursos',
              message:
                  'Añade maná, ki, energía, furia o cualquier recurso personalizado.',
              actionLabel: 'Crear recurso',
              onAction: createResource,
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
              itemCount: resources.length,
              itemBuilder: (context, index) {
                final resource = resources[index];

                return Dismissible(
                  key: ValueKey(resource.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    await deleteResource(resource);

                    return false;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  child: ResourceCard(
                    resource: resource,
                    onDecrease: () {
                      decreaseResource(resource);
                    },
                    onIncrease: () {
                      increaseResource(resource);
                    },
                    onTap: () {
                      editResource(resource);
                    },
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: createResource,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo recurso'),
      ),
    );
  }
}
