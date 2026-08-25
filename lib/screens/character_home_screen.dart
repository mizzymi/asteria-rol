import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/character.dart';
import '../models/character_resource.dart';
import '../models/character_effect.dart';
import '../models/passive.dart';

import '../services/avatar_storage_service.dart';
import '../services/character_storage_service.dart';

import '../widgets/common/section_header.dart';
import '../widgets/character_home/resource_edit_dialog.dart';
import '../widgets/character_home/avatar_viewer.dart';
import '../widgets/character_home/character_header_card.dart';
import '../widgets/character_home/character_home_colors.dart';
import '../widgets/character_home/character_menu_card.dart';
import '../widgets/character_home/combat_stat_card.dart';
import '../widgets/character_home/health_edit_dialog.dart';
import '../widgets/character_home/health_resource_card.dart';
import '../widgets/character_home/level_edit_dialog.dart';

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
      character.currentHealth = result;
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

  Future<void> showCombatActions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          child: Icon(
                            character.turnActive
                                ? Icons.sports_martial_arts_rounded
                                : Icons.shield_rounded,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Combate',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                'Ronda $character.combatRound · '
                                '${character.turnActive ? 'Turno activo' : 'Esperando turno'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: character.turnActive
                                ? null
                                : () async {
                                    Navigator.pop(sheetContext);

                                    character.startTurn();

                                    await saveCharacter();

                                    if (!mounted) {
                                      return;
                                    }

                                    setState(() {});
                                  },
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Empezar turno'),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: !character.turnActive
                                ? null
                                : () async {
                                    Navigator.pop(sheetContext);

                                    character.endTurn();

                                    await saveCharacter();

                                    if (!mounted) {
                                      return;
                                    }

                                    setState(() {});
                                  },
                            icon: const Icon(Icons.stop_rounded),
                            label: const Text('Terminar'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.repeat_rounded),
                      ),
                      title: const Text('Siguiente ronda'),
                      subtitle: Text(
                        'Ronda $character.combatRound → ${character.combatRound + 1}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        Navigator.pop(sheetContext);

                        character.startNextRound();

                        await saveCharacter();

                        if (!mounted) {
                          return;
                        }

                        setState(() {});
                      },
                    ),

                    const Divider(),

                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.heart_broken_rounded),
                      ),
                      title: const Text('Recibir daño'),
                      subtitle: Text(
                        '${character.currentHealth} / ${character.maxHealth} PG',
                      ),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await applyDamage();
                      },
                    ),

                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.favorite_rounded),
                      ),
                      title: const Text('Recibir curación'),
                      subtitle: Text(
                        '${character.currentHealth} / ${character.maxHealth} PG',
                      ),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await applyHealing();
                      },
                    ),

                    const Divider(),

                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.sports_mma_rounded),
                      ),
                      title: const Text('Registrar enemigo derrotado'),
                      subtitle: const Text('Dispara el evento enemyKilled'),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await registerKill();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
      resource.currentValue = result;

      resource.normalize();
    });

    await saveCharacter();
  }

  List<_EffectStack> get stackedEnabledEffects {
    final stacks = <String, _EffectStack>{};

    for (final effect in character.enabledEffects) {
      final map = Map<String, dynamic>.from(effect.toMap());

      // Campos que identifican la instancia,
      // pero no el contenido real del efecto.
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

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: editCharacterName,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(character.name, overflow: TextOverflow.ellipsis),
                ),

                const SizedBox(width: 6),

                const Icon(Icons.edit_rounded, size: 16),
              ],
            ),
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Combate',
            onPressed: showCombatActions,
            icon: Badge(
              isLabelVisible: character.turnActive,
              child: const Icon(Icons.sports_martial_arts_rounded),
            ),
          ),

          const SizedBox(width: 6),
        ],
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
          children: [
            // =================================================================
            // PERSONAJE
            // =================================================================
            CharacterHeaderCard(
              character: character,

              onEditLevel: editLevel,

              onEditClasses: editClasses,

              onAvatarTap: showAvatar,

              onChangeAvatar: changeAvatar,
            ),

            const SizedBox(height: 18),

            // =================================================================
            // VIDA
            // =================================================================
            HealthResourceCard(
              current: character.currentHealth,
              max: character.maxHealth,
              onTap: editHealth,
            ),

            const SizedBox(height: 12),

            if (character.resources.isNotEmpty) ...[
              const SizedBox(height: 12),

              ...character.resources
                  .where((resource) => resource.visible)
                  .map(
                    (resource) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _QuickResourceCard(
                        resource: resource,

                        effectiveCurrent: character.resourceEffectiveCurrent(
                          resource,
                        ),

                        effectiveMax: character.resourceEffectiveMax(resource),

                        onTap: () {
                          editResourceQuick(resource);
                        },
                      ),
                    ),
                  ),

              const SizedBox(height: 12),
            ],

            if (character.enabledEffects.isNotEmpty) ...[
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Estados activos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                children: stackedEnabledEffects
                    .map(
                      (stack) => _ActiveEffectChip(
                        effect: stack.effect,
                        count: stack.count,
                        onTap: () {
                          openScreen(EffectsScreen(character: character));
                        },
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 18),
            ],

            // =================================================================
            // COMBATE
            // =================================================================
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: [
                CombatStatCard(
                  icon: Icons.shield_rounded,
                  title: 'CA',
                  value: '${character.calculatedArmorClass}',
                  color: CharacterHomeColors.armor,
                ),

                CombatStatCard(
                  icon: Icons.bolt_rounded,
                  title: 'Iniciativa',
                  value: bonusText(character.initiative),
                  color: CharacterHomeColors.initiative,
                ),

                CombatStatCard(
                  icon: Icons.military_tech_rounded,
                  title: 'Competencia',
                  value: '+${character.proficiencyBonus}',
                  color: CharacterHomeColors.proficiency,
                ),

                CombatStatCard(
                  icon: Icons.directions_run_rounded,
                  title: 'Velocidad',
                  value: '${character.totalSpeed} pies',
                  color: CharacterHomeColors.speed,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // =================================================================
            // MENÚ
            // =================================================================
            const SectionHeader(
              icon: Icons.person_rounded,
              title: 'Personaje',
              subtitle: 'Ficha, habilidades y aventura',
            ),

            const SizedBox(height: 12),

            CharacterMenuCard(
              icon: Icons.bar_chart_rounded,
              title: 'Stats',
              subtitle: 'Atributos, salvaciones y habilidades',
              color: CharacterHomeColors.stats,
              onTap: () {
                openScreen(StatsScreen(character: character));
              },
            ),

            CharacterMenuCard(
              icon: Icons.flash_on_rounded,
              title: 'Habilidades',
              subtitle: 'Ataques, poderes y técnicas',
              color: CharacterHomeColors.abilities,
              onTap: () {
                openScreen(AbilitiesScreen(character: character));
              },
            ),

            CharacterMenuCard(
              icon: Icons.auto_awesome_rounded,
              title: 'Estados y efectos',
              subtitle: character.enabledEffects.isEmpty
                  ? 'Sin efectos activos'
                  : '${character.enabledEffects.length} activos',
              color: const Color(0xFF9B6CE8),
              onTap: () {
                openScreen(EffectsScreen(character: character));
              },
            ),

            CharacterMenuCard(
              icon: Icons.inventory_2_rounded,
              title: 'Objetos',
              subtitle: 'Inventario y equipo',
              color: CharacterHomeColors.items,
              onTap: () {
                openScreen(ItemsScreen(character: character));
              },
            ),

            CharacterMenuCard(
              icon: Icons.menu_book_rounded,
              title: 'Historia',
              subtitle: 'Trasfondo, personalidad y objetivos',
              color: CharacterHomeColors.story,
              onTap: () {
                openScreen(StoryScreen(character: character));
              },
            ),

            CharacterMenuCard(
              icon: Icons.history_edu_rounded,
              title: 'Diario',
              subtitle: 'Sesiones, misiones y acontecimientos',
              color: CharacterHomeColors.journal,
              onTap: () {
                openScreen(JournalScreen(character: character));
              },
            ),

            CharacterMenuCard(
              icon: Icons.battery_charging_full_rounded,
              title: 'Recursos',
              subtitle: character.resources.isEmpty
                  ? 'Gestiona maná, energía, ki y otros recursos'
                  : '${character.resources.length} recursos configurados',
              color: Colors.teal,
              onTap: openResources,
            ),

            CharacterMenuCard(
              icon: Icons.tag_rounded,
              title: 'Contadores',
              subtitle: character.counters.isEmpty
                  ? 'Kills, críticos, combos y otros contadores'
                  : '${character.counters.length} contadores configurados',
              color: const Color(0xFF6C8CD5),
              onTap: openCounters,
            ),

            CharacterMenuCard(
              icon: Icons.casino_rounded,
              title: 'Dados',
              subtitle: 'd4, d6, d8, d10, d12, d20 y d100',
              color: CharacterHomeColors.dice,
              onTap: () {
                openScreen(DiceScreen(character: character));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickResourceCard extends StatelessWidget {
  final CharacterResource resource;

  final int effectiveCurrent;
  final int? effectiveMax;

  final VoidCallback onTap;

  const _QuickResourceCard({
    required this.resource,
    required this.effectiveCurrent,
    required this.effectiveMax,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shownMax = effectiveMax ?? resource.maxValue;

    final progress = resource.hasMaximum
        ? shownMax <= 0
              ? 0.0
              : (effectiveCurrent / shownMax).clamp(0.0, 1.0)
        : 0.0;

    final displayText = resource.hasMaximum
        ? '$effectiveCurrent/$shownMax'
        : '$effectiveCurrent';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: resource.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: resource.color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(resource.icon, color: resource.color),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    resource.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),

                Text(
                  displayText,
                  style: TextStyle(
                    color: resource.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),

            if (resource.hasMaximum) ...[
              const SizedBox(height: 16),

              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(value: progress, minHeight: 6),
              ),
            ],
          ],
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

class _ActiveEffectChip extends StatelessWidget {
  final CharacterEffect effect;
  final int count;
  final VoidCallback onTap;

  const _ActiveEffectChip({
    required this.effect,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _effectColor(effect);
    final icon = _effectIcon(effect);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color),

              const SizedBox(width: 6),

              Text(
                count > 1 ? '${effect.name} ×$count' : effect.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),

              if (effect.hasDuration) ...[
                const SizedBox(width: 6),

                Text(
                  '· ${effect.durationText}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _effectColor(CharacterEffect effect) {
    if (!effect.enabled) {
      return Colors.grey;
    }

    if (effect.expired) {
      return Colors.grey;
    }

    switch (effect.type) {
      case CharacterEffectType.buff:
        return const Color(0xFF4CAF7D);

      case CharacterEffectType.debuff:
        return const Color(0xFFE45D68);

      case CharacterEffectType.condition:
        return const Color(0xFF9B6CE8);

      case CharacterEffectType.neutral:
        return const Color(0xFF5F8FD8);
    }
  }

  IconData _effectIcon(CharacterEffect effect) {
    if (effect.expired) {
      return Icons.timer_off_rounded;
    }

    if (!effect.enabled) {
      return Icons.visibility_off_rounded;
    }

    switch (effect.type) {
      case CharacterEffectType.buff:
        return Icons.trending_up_rounded;

      case CharacterEffectType.debuff:
        return Icons.trending_down_rounded;

      case CharacterEffectType.condition:
        return Icons.warning_amber_rounded;

      case CharacterEffectType.neutral:
        return Icons.auto_awesome_rounded;
    }
  }
}
