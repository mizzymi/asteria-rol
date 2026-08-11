import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/character.dart';

import '../services/avatar_storage_service.dart';
import '../services/character_storage_service.dart';

import '../widgets/common/section_header.dart';

import '../widgets/character_home/avatar_viewer.dart';
import '../widgets/character_home/character_header_card.dart';
import '../widgets/character_home/character_home_colors.dart';
import '../widgets/character_home/character_menu_card.dart';
import '../widgets/character_home/combat_stat_card.dart';
import '../widgets/character_home/health_edit_dialog.dart';
import '../widgets/character_home/health_resource_card.dart';
import '../widgets/character_home/level_edit_dialog.dart';

import 'abilities_screen.dart';
import 'class_editor_screen.dart';
import 'dice_screen.dart';
import 'items_screen.dart';
import 'journal_screen.dart';
import 'stats_screen.dart';
import 'story_screen.dart';

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
  // HELPERS
  // ===========================================================================

  String bonusText(int value) {
    return value >= 0 ? '+$value' : '$value';
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(character.name)),

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
