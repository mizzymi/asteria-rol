import 'package:flutter/material.dart';

import 'character_home_colors.dart';
import 'character_menu_card.dart';

class CharacterHomeNavigationSection extends StatelessWidget {
  final int activeEffectsCount;
  final int resourceCount;
  final int counterCount;

  final VoidCallback onStats;
  final VoidCallback onAbilities;
  final VoidCallback onEffects;
  final VoidCallback onItems;
  final VoidCallback onStory;
  final VoidCallback onJournal;
  final VoidCallback onResources;
  final VoidCallback onCounters;
  final VoidCallback onDice;

  const CharacterHomeNavigationSection({
    super.key,
    required this.activeEffectsCount,
    required this.resourceCount,
    required this.counterCount,
    required this.onStats,
    required this.onAbilities,
    required this.onEffects,
    required this.onItems,
    required this.onStory,
    required this.onJournal,
    required this.onResources,
    required this.onCounters,
    required this.onDice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // =====================================================================
        // CABECERA
        // =====================================================================
        Text(
          'Personaje',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'Ficha, habilidades y aventura',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 14),

        // =====================================================================
        // STATS
        // =====================================================================
        CharacterMenuCard(
          icon: Icons.bar_chart_rounded,
          title: 'Stats',
          subtitle: 'Atributos, salvaciones y habilidades',
          color: CharacterHomeColors.stats,
          onTap: onStats,
        ),

        const SizedBox(height: 8),

        // =====================================================================
        // HABILIDADES
        // =====================================================================
        CharacterMenuCard(
          icon: Icons.flash_on_rounded,
          title: 'Habilidades',
          subtitle: 'Ataques, poderes y técnicas',
          color: CharacterHomeColors.abilities,
          onTap: onAbilities,
        ),

        const SizedBox(height: 8),

        // =====================================================================
        // EFECTOS
        // =====================================================================
        CharacterMenuCard(
          icon: Icons.auto_awesome_rounded,
          title: 'Estados y efectos',
          subtitle: activeEffectsCount == 0
              ? 'Sin efectos activos'
              : activeEffectsCount == 1
              ? '1 efecto activo'
              : '$activeEffectsCount efectos activos',
          color: CharacterHomeColors.effects,
          onTap: onEffects,
        ),

        const SizedBox(height: 8),

        // =====================================================================
        // CONTADORES
        // =====================================================================
        CharacterMenuCard(
          icon: Icons.tag_rounded,
          title: 'Contadores',
          subtitle: counterCount == 0
              ? 'Kills, críticos, combos y otros contadores'
              : counterCount == 1
              ? '1 contador configurado'
              : '$counterCount contadores configurados',
          color: CharacterHomeColors.counters,
          onTap: onCounters,
        ),

        const SizedBox(height: 8),

        // =====================================================================
        // OBJETOS
        // =====================================================================
        CharacterMenuCard(
          icon: Icons.inventory_2_rounded,
          title: 'Objetos',
          subtitle: 'Inventario y equipo',
          color: CharacterHomeColors.items,
          onTap: onItems,
        ),

        const SizedBox(height: 8),

        // =====================================================================
        // HISTORIA
        // =====================================================================
        CharacterMenuCard(
          icon: Icons.menu_book_rounded,
          title: 'Historia',
          subtitle: 'Trasfondo, personalidad y objetivos',
          color: CharacterHomeColors.story,
          onTap: onStory,
        ),

        const SizedBox(height: 8),

        // =====================================================================
        // DIARIO
        // =====================================================================
        CharacterMenuCard(
          icon: Icons.history_edu_rounded,
          title: 'Diario',
          subtitle: 'Sesiones, misiones y acontecimientos',
          color: CharacterHomeColors.journal,
          onTap: onJournal,
        ),

        const SizedBox(height: 8),

        // =====================================================================
        // RECURSOS
        // =====================================================================
        CharacterMenuCard(
          icon: Icons.battery_charging_full_rounded,
          title: 'Recursos',
          subtitle: resourceCount == 0
              ? 'Maná, energía, ki y otros recursos'
              : resourceCount == 1
              ? '1 recurso configurado'
              : '$resourceCount recursos configurados',
          color: CharacterHomeColors.resources,
          onTap: onResources,
        ),

        const SizedBox(height: 8),

        // =====================================================================
        // DADOS
        // =====================================================================
        CharacterMenuCard(
          icon: Icons.casino_rounded,
          title: 'Dados',
          subtitle: 'd4, d6, d8, d10, d12, d20 y d100',
          color: CharacterHomeColors.dice,
          onTap: onDice,
        ),
      ],
    );
  }
}
