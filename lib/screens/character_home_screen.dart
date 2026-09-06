import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/character.dart';
import '../models/character_resource.dart';
import '../models/character_effect.dart';
import '../models/passive.dart';

import '../services/avatar_storage_service.dart';
import '../services/character_storage_service.dart';

import '../widgets/character_home/character_quick_actions.dart';
import '../widgets/character_home/character_home_navigation_section.dart';
import '../widgets/character_home/quick_resource_card.dart';
import '../widgets/character_home/active_effect_chip.dart';
import '../widgets/character_home/resource_edit_dialog.dart';
import '../widgets/character_home/avatar_viewer.dart';
import '../widgets/character_home/character_header_card.dart';
import '../widgets/character_home/character_home_colors.dart';
import '../widgets/character_home/combat_stat_card.dart';
import '../widgets/character_home/health_edit_dialog.dart';
import '../widgets/character_home/level_edit_dialog.dart';

import 'rest_screen.dart';
import 'combat_screen.dart';
import 'character_counters_screen.dart';
import 'abilities_screen.dart';
import 'class_editor_screen.dart';
import 'dice_screen.dart';
import 'items_screen.dart';
import 'journal_screen.dart';
import 'stats_screen.dart';
import 'story_screen.dart';
import 'resources_screen.dart';
import 'effects_screen.dart';
import 'knowledge_screen.dart';
import 'pets_screen.dart';

class CharacterHomeScreen extends StatefulWidget {
  final Character character;

  const CharacterHomeScreen({super.key, required this.character});

  @override
  State<CharacterHomeScreen> createState() => _CharacterHomeScreenState();
}

class _CharacterHomeScreenState extends State<CharacterHomeScreen> {
  Character get character => widget.character;

  final ImagePicker imagePicker = ImagePicker();

  // ===========================================================================
  // GUARDAR
  // ===========================================================================

  Future<void> saveCharacter() async {
    await CharacterStorageService.saveCharacter(character);
  }

  // ===========================================================================
  // NAVEGACIÓN
  // ===========================================================================

  Future<void> openScreen(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> openResources() async {
    await openScreen(ResourcesScreen(character: character));
  }

  Future<void> openCounters() async {
    await openScreen(
      CharacterCountersScreen(character: character, onSave: saveCharacter),
    );
  }

  // ===========================================================================
  // AVATAR
  // ===========================================================================

  Future<void> showAvatar() async {
    final path = character.avatarPath;

    if (path == null || path.isEmpty) {
      return;
    }

    await AvatarViewer.show(
      context,
      imagePath: path,
      heroTag: 'character-avatar-${character.id}',
    );
  }

  Future<void> changeAvatar() async {
    final image = await imagePicker.pickImage(
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

    await saveCharacter();
  }

  // ===========================================================================
  // NIVEL
  // ===========================================================================

  Future<void> editLevel() async {
    final result = await LevelEditDialog.show(
      context,
      currentLevel: character.level,
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

  // ===========================================================================
  // NOMBRE
  // ===========================================================================

  Future<void> editCharacterName() async {
    var newName = character.name;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cambiar nombre'),
          content: TextFormField(
            initialValue: character.name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre del personaje',
              prefixIcon: Icon(Icons.person_rounded),
            ),
            onChanged: (value) {
              newName = value;
            },
            onFieldSubmitted: (_) {
              final name = newName.trim();

              if (name.isEmpty) {
                return;
              }

              Navigator.pop(dialogContext, name);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                final name = newName.trim();

                if (name.isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext, name);
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
      character.name = result;
    });

    await saveCharacter();
  }

  // ===========================================================================
  // CLASES
  // ===========================================================================

  Future<void> editClasses() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClassEditorScreen(character: character),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ===========================================================================
  // VIDA
  // ===========================================================================

  Future<void> editHealth() async {
    final result = await HealthEditDialog.show(
      context,
      currentHealth: character.currentHealth,
      maxHealth: character.maxHealth,
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      character.setHealth(result);
    });

    await saveCharacter();
  }

  // ===========================================================================
  // COMBATE / TRIGGERS
  // ===========================================================================

  Future<void> applyDamage() async {
    final amount = await _askCombatAmount(
      title: 'Recibir daño',
      label: 'Daño',
      icon: Icons.heart_broken_rounded,
    );

    if (amount == null || amount <= 0) {
      return;
    }

    setState(() {
      character.takeDamage(amount);
    });

    await saveCharacter();
  }

  Future<void> applyHealing() async {
    final amount = await _askCombatAmount(
      title: 'Recibir curación',
      label: 'Curación',
      icon: Icons.favorite_rounded,
    );

    if (amount == null || amount <= 0) {
      return;
    }

    setState(() {
      character.heal(amount);
    });

    await saveCharacter();
  }

  Future<int?> _askCombatAmount({
    required String title,
    required String label,
    required IconData icon,
  }) {
    final controller = TextEditingController();

    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),

          content: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
            ),
            onFieldSubmitted: (_) {
              final value = int.tryParse(controller.text.trim());

              if (value != null && value > 0) {
                Navigator.pop(dialogContext, value);
              }
            },
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());

                if (value == null || value <= 0) {
                  return;
                }

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> registerKill() async {
    character.incrementCounter('kills', 1);

    character.dispatchPassiveTrigger(
      PassiveTriggerEvent.enemyKilled,
      eventVariables: const {'kills_gained': 1},
    );

    await saveCharacter();

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  String bonusText(int value) {
    return value >= 0 ? '+$value' : '$value';
  }

  Future<void> editResourceQuick(CharacterResource resource) async {
    final result = await ResourceEditDialog.show(context, resource: resource);

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      character.setResourceValue(resource.id, result);
    });

    await saveCharacter();
  }

  List<_EffectStack> get stackedEnabledEffects {
    final stacks = <String, _EffectStack>{};

    for (final effect in character.enabledEffects) {
      final map = Map<String, dynamic>.from(effect.toMap());

      map.remove('id');

      final key = _stableEffectKey(map);

      final existing = stacks[key];

      if (existing == null) {
        stacks[key] = _EffectStack(effect: effect, count: 1);
      } else {
        existing.count++;
      }
    }

    return stacks.values.toList();
  }

  String _stableEffectKey(dynamic value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();

      return keys
          .map((key) {
            return '$key:${_stableEffectKey(value[key])}';
          })
          .join('|');
    }

    if (value is List) {
      return value.map(_stableEffectKey).join(',');
    }

    return value.toString();
  }

  String _signed(int value) {
    if (value > 0) {
      return '+$value';
    }

    return '$value';
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final quickResources = character.resources
        .where((resource) => resource.visible)
        .take(2)
        .toList(growable: false);

    final homeEffectStacks = stackedEnabledEffects
        .take(4)
        .toList(growable: false);

    final hiddenEffectCount =
        stackedEnabledEffects.length - homeEffectStacks.length;

    return Scaffold(
      backgroundColor: colors.surface,

      // =========================================================================
      // APP BAR
      // =========================================================================
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        title: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: editCharacterName,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    character.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),

                const SizedBox(width: 6),

                Icon(
                  Icons.edit_rounded,
                  size: 15,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),

      // =========================================================================
      // BODY
      // =========================================================================
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
          children: [
            // ===================================================================
            // PERSONAJE
            // ===================================================================
            CharacterHeaderCard(
              character: character,
              onEditLevel: editLevel,
              onEditClasses: editClasses,
              onAvatarTap: showAvatar,
              onChangeAvatar: changeAvatar,
            ),

            const SizedBox(height: 24),

            // ===================================================================
            // STATS PRINCIPALES
            // ===================================================================
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CombatStatCard(
                    icon: Icons.favorite_rounded,
                    title: 'PG',
                    value: '${character.currentHealth}/${character.maxHealth}',
                    color: CharacterHomeColors.health,
                    onTap: editHealth,
                    editable: true,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: CombatStatCard(
                    icon: Icons.shield_rounded,
                    title: 'CA',
                    value: '${character.calculatedArmorClass}',
                    color: CharacterHomeColors.armor,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: CombatStatCard(
                    icon: Icons.bolt_rounded,
                    title: 'INI',
                    value: _signed(character.initiative),
                    color: CharacterHomeColors.initiative,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: CombatStatCard(
                    icon: Icons.directions_run_rounded,
                    title: 'VEL',
                    value: '${character.totalSpeed}',
                    color: CharacterHomeColors.speed,
                  ),
                ),
              ],
            ),

            // ===================================================================
            // RECURSOS RÁPIDOS
            // ===================================================================
            if (quickResources.isNotEmpty) ...[
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recursos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: openResources,
                    child: const Text('Ver todos'),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: QuickResourceCard(
                      resource: quickResources[0],
                      effectiveCurrent: character.resourceEffectiveCurrent(
                        quickResources[0],
                      ),
                      effectiveMax: character.resourceEffectiveMax(
                        quickResources[0],
                      ),
                      onTap: () {
                        editResourceQuick(quickResources[0]);
                      },
                    ),
                  ),

                  if (quickResources.length > 1) ...[
                    const SizedBox(width: 8),

                    Expanded(
                      child: QuickResourceCard(
                        resource: quickResources[1],
                        effectiveCurrent: character.resourceEffectiveCurrent(
                          quickResources[1],
                        ),
                        effectiveMax: character.resourceEffectiveMax(
                          quickResources[1],
                        ),
                        onTap: () {
                          editResourceQuick(quickResources[1]);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // ===================================================================
            // ESTADOS ACTIVOS
            // ===================================================================
            if (character.enabledEffects.isNotEmpty) ...[
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Estados activos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      openScreen(EffectsScreen(character: character));
                    },
                    child: const Text('Ver todos'),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...homeEffectStacks.map(
                    (stack) => ActiveEffectChip(
                      effect: stack.effect,
                      count: stack.count,
                      onTap: () {
                        openScreen(EffectsScreen(character: character));
                      },
                    ),
                  ),

                  if (hiddenEffectCount > 0)
                    _MoreEffectsChip(
                      count: hiddenEffectCount,
                      onTap: () {
                        openScreen(EffectsScreen(character: character));
                      },
                    ),
                ],
              ),
            ],

            const SizedBox(height: 26),

            CharacterQuickActions(
              onCombat: () {
                openScreen(CombatScreen(character: character));
              },

              onRest: () {
                openScreen(RestScreen(character: character));
              },

              onPets: () {
                openScreen(PetsScreen(character: character));
              },

              petCount:
              character.pets.length, // <--- Añadido conteo de mascotas

            ),
            // ===================================================================
            // NAVEGACIÓN
            // ===================================================================
            const SizedBox(height: 28),

            CharacterHomeNavigationSection(
              activeEffectsCount: character.enabledEffects.length,
              resourceCount: character.resources.length,
              counterCount: character.counters.length,
              onStats: () {
                openScreen(StatsScreen(character: character));
              },

              onAbilities: () {
                openScreen(
                  AbilitiesScreen(
                    character: character,
                    onCharacterChanged: () async {
                      if (!mounted) {
                        return;
                      }

                      setState(() {});
                    },
                  ),
                );
              },

              onEffects: () {
                openScreen(EffectsScreen(character: character));
              },

              onItems: () {
                openScreen(ItemsScreen(character: character));
              },

              onStory: () {
                openScreen(StoryScreen(character: character));
              },

              onJournal: () {
                openScreen(JournalScreen(character: character));
              },

              onResources: openResources,

              onCounters: openCounters,

              onDice: () {
                openScreen(DiceScreen(character: character));
              },

              onKnowledge: () {
                openScreen(KnowledgeScreen(character: character));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreEffectsChip extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _MoreEffectsChip({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            '+$count',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _EffectStack {
  final CharacterEffect effect;
  int count;

  _EffectStack({required this.effect, required this.count});
}
