import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rol/screens/passives_screen.dart';
import 'package:rol/screens/story_screen.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/avatar_storage_service.dart';
import '../services/character_storage_service.dart';
import '../models/character.dart';

import 'items_screen.dart';
import 'class_editor_screen.dart';
import 'abilities_screen.dart';
import 'dice_screen.dart';
import 'journal_screen.dart';
import 'stats_screen.dart';

class CharacterHomeScreen extends StatefulWidget {
  final Character character;

  const CharacterHomeScreen({super.key, required this.character});

  @override
  State<CharacterHomeScreen> createState() => _CharacterHomeScreenState();
}

class _CharacterHomeScreenState extends State<CharacterHomeScreen> {
  Character get character => widget.character;

  final ImagePicker _imagePicker = ImagePicker();

  Future<void> saveCharacter() async {
    await CharacterStorageService.saveCharacter(character);
  }

  void showAvatar() {
    final avatarPath = character.avatarPath;

    if (avatarPath == null || avatarPath.isEmpty) {
      return;
    }

    final file = File(avatarPath);

    if (!file.existsSync()) {
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(file, fit: BoxFit.contain),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton.filled(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> changeAvatar() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (image == null) {
      return;
    }

    final savedPath = await AvatarStorageService.saveAvatar(
      characterId: character.id,
      sourcePath: image.path,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      character.avatarPath = savedPath;
    });

    await CharacterStorageService.saveCharacter(character);
  }

  int clampHealth(int value) {
    if (value < 0) {
      return 0;
    }

    if (value > character.maxHealth) {
      return character.maxHealth;
    }

    return value;
  }

  // ---------------------------------------------------------------------------
  // EDITAR NIVEL
  // ---------------------------------------------------------------------------

  Future<void> editLevel() async {
    int newLevel = character.level;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cambiar nivel'),
          content: TextFormField(
            initialValue: '${character.level}',
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: 'Nivel',
              helperText: 'Entre 1 y 20',
            ),
            onChanged: (value) {
              newLevel = int.tryParse(value) ?? character.level;
            },
            onFieldSubmitted: (_) {
              if (newLevel >= 1 && newLevel <= 20) {
                Navigator.of(dialogContext).pop(newLevel);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (newLevel < 1 || newLevel > 20) {
                  return;
                }

                Navigator.of(dialogContext).pop(newLevel);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      character.level = result;
      character.normalizeHealth();
    });

    await saveCharacter();
  }

  // ---------------------------------------------------------------------------
  // EDITAR VIDA ACTUAL
  // ---------------------------------------------------------------------------

  Future<void> editHealth() async {
    int amount = 0;
    bool healing = false;

    final amountController = TextEditingController();

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final previewHealth = healing
                ? clampHealth(character.currentHealth + amount)
                : clampHealth(character.currentHealth - amount);

            return AlertDialog(
              title: const Text('Modificar puntos de golpe'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${character.currentHealth} / ${character.maxHealth}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        icon: Icon(Icons.heart_broken_rounded),
                        label: Text('Daño'),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        icon: Icon(Icons.favorite_rounded),
                        label: Text('Curar'),
                      ),
                    ],
                    selected: {healing},
                    onSelectionChanged: (values) {
                      setDialogState(() {
                        healing = values.first;
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  TextField(
                    controller: amountController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: healing ? 'Puntos a curar' : 'Daño recibido',
                      prefixIcon: Icon(
                        healing ? Icons.add_rounded : Icons.remove_rounded,
                      ),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        amount = int.tryParse(value) ?? 0;

                        if (amount < 0) {
                          amount = 0;
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Text(
                          healing ? 'Después de curar' : 'Después del daño',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),

                        const SizedBox(height: 6),

                        Text(
                          '$previewHealth / ${character.maxHealth}',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),

                FilledButton(
                  onPressed: amount > 0
                      ? () {
                          Navigator.of(dialogContext).pop(previewHealth);
                        }
                      : null,
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      character.currentHealth = result;
    });

    await saveCharacter();
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(character.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _CharacterHeader(
              character: character,
              onEditLevel: editLevel,
              onEditClasses: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClassEditorScreen(character: character),
                  ),
                );

                if (mounted) {
                  setState(() {});
                }
              },
              onAvatarTap: showAvatar,
              onChangeAvatar: changeAvatar,
            ),

            const SizedBox(height: 24),

            _ResourceCard(
              icon: Icons.favorite_rounded,
              title: 'Puntos de golpe',
              current: character.currentHealth,
              max: character.maxHealth,
              onTap: editHealth,
            ),

            const SizedBox(height: 12),

            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.shield_rounded,
                        title: 'CA',
                        value: '${character.calculatedArmorClass}',
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _InfoCard(
                        icon: Icons.bolt_rounded,
                        title: 'Iniciativa',
                        value: _bonusText(character.initiative),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.military_tech_rounded,
                        title: 'Competencia',
                        value: '+${character.proficiencyBonus}',
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _InfoCard(
                        icon: Icons.directions_run_rounded,
                        title: 'Velocidad',
                        value: '${character.totalSpeed} pies',
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 26),

            Text(
              'Personaje',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _MenuCard(
              icon: Icons.bar_chart_rounded,
              title: 'Stats',
              subtitle: 'Atributos, salvaciones y habilidades',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StatsScreen(character: character),
                  ),
                );

                if (mounted) {
                  setState(() {});
                }
              },
            ),

            _MenuCard(
              icon: Icons.flash_on_rounded,
              title: 'Habilidades',
              subtitle: 'Ataques, poderes y técnicas',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AbilitiesScreen(character: character),
                  ),
                );

                if (mounted) {
                  setState(() {});
                }
              },
            ),

            _MenuCard(
              icon: Icons.auto_awesome_rounded,
              title: 'Pasivas',
              subtitle: 'Rasgos y bonificaciones permanentes',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PassivesScreen(character: character),
                  ),
                );

                if (mounted) {
                  setState(() {});
                }
              },
            ),

            _MenuCard(
              icon: Icons.inventory_2_rounded,
              title: 'Objetos',
              subtitle: 'Inventario y equipo',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemsScreen(character: character),
                  ),
                );

                if (mounted) {
                  setState(() {});
                }
              },
            ),

            _MenuCard(
              icon: Icons.menu_book_rounded,
              title: 'Historia',
              subtitle: 'Trasfondo, personalidad y objetivos',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoryScreen(character: character),
                  ),
                );

                if (mounted) {
                  setState(() {});
                }
              },
            ),

            _MenuCard(
              icon: Icons.history_edu_rounded,
              title: 'Diario',
              subtitle: 'Sesiones, misiones y acontecimientos',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JournalScreen(character: character),
                  ),
                );

                if (mounted) {
                  setState(() {});
                }
              },
            ),

            _MenuCard(
              icon: Icons.casino_rounded,
              title: 'Dados',
              subtitle: 'd4, d6, d8, d10, d12, d20 y d100',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiceScreen(character: character),
                  ),
                );

                if (mounted) {
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _bonusText(int value) {
    return value >= 0 ? '+$value' : '$value';
  }
}

// =============================================================================
// HEADER
// =============================================================================

class _CharacterHeader extends StatelessWidget {
  final Character character;

  final VoidCallback onEditLevel;
  final VoidCallback onAvatarTap;
  final VoidCallback onChangeAvatar;
  final VoidCallback onEditClasses;

  const _CharacterHeader({
    required this.character,
    required this.onEditLevel,
    required this.onEditClasses,
    required this.onAvatarTap,
    required this.onChangeAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final avatarPath = character.avatarPath;

    final hasAvatar =
        avatarPath != null &&
        avatarPath.isNotEmpty &&
        File(avatarPath).existsSync();

    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: hasAvatar ? onAvatarTap : onChangeAvatar,
              child: Hero(
                tag: 'character-avatar-${character.id}',
                child: CircleAvatar(
                  radius: 45,
                  backgroundImage: hasAvatar
                      ? FileImage(File(avatarPath))
                      : null,
                  child: hasAvatar
                      ? null
                      : Text(
                          character.name.isNotEmpty
                              ? character.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),

            Positioned(
              right: -4,
              bottom: -4,
              child: Material(
                color: Theme.of(context).colorScheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onChangeAvatar,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 18),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                character.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(character.race),

              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onEditClasses,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text(character.classSummary)),
                      const SizedBox(width: 5),
                      const Icon(Icons.edit_rounded, size: 15),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),

              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onEditLevel,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Nivel ${character.level}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(width: 5),

                      Icon(
                        Icons.edit_rounded,
                        size: 15,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// VIDA
// =============================================================================

class _ResourceCard extends StatelessWidget {
  final IconData icon;
  final String title;

  final int current;
  final int max;

  final VoidCallback onTap;

  const _ResourceCard({
    required this.icon,
    required this.title,
    required this.current,
    required this.max,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 30,
                    color: Theme.of(context).colorScheme.primary,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(width: 5),

                  const Icon(Icons.edit_rounded, size: 16),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                '$current / $max',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              LinearProgressIndicator(
                value: progress.toDouble(),
                minHeight: 8,
                borderRadius: BorderRadius.circular(20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// INFO COMBATE
// =============================================================================

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),

            const SizedBox(height: 5),

            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 2),

            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MENÚ
// =============================================================================

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
