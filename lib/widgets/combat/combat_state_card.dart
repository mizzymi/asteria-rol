import 'package:flutter/material.dart';

import '../../models/character.dart';
import '../character_home/character_home_colors.dart';

class CombatStateCard extends StatelessWidget {
  final Character character;

  final VoidCallback onToggleCombat;
  final VoidCallback onToggleTurn;
  final VoidCallback onNextRound;

  const CombatStateCard({
    super.key,
    required this.character,
    required this.onToggleCombat,
    required this.onToggleTurn,
    required this.onNextRound,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final combatColor = CharacterHomeColors.combat(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CharacterHomeColors.tintedSurface(
          context,
          combatColor,
          lightStrength: 0.07,
          darkStrength: 0.12,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CharacterHomeColors.tintedBorder(
            context,
            combatColor,
            lightAlpha: 0.18,
            darkAlpha: 0.30,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: CharacterHomeColors.tintedSurface(
                    context,
                    combatColor,
                    lightStrength: 0.18,
                    darkStrength: 0.28,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.sports_martial_arts_rounded,
                  color: combatColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.combatActive
                          ? 'Combate activo'
                          : 'Fuera de combate',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      character.combatActive
                          ? 'Ronda ${character.combatRound} · '
                                '${character.turnActive ? 'Turno activo' : 'Sin turno activo'}'
                          : 'Inicia el combate cuando estés preparado',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===============================================================
          // COMBATE
          // ===============================================================
          SizedBox(
            width: double.infinity,
            child: character.combatActive
                ? OutlinedButton.icon(
                    onPressed: onToggleCombat,
                    icon: const Icon(Icons.stop_circle_rounded),
                    label: const Text('Acabar combate'),
                  )
                : FilledButton.icon(
                    onPressed: onToggleCombat,
                    icon: const Icon(Icons.play_circle_rounded),
                    label: const Text('Empezar combate'),
                  ),
          ),

          if (character.combatActive) ...[
            const SizedBox(height: 8),

            // =============================================================
            // TURNO + RONDA
            // =============================================================
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onToggleTurn,
                    icon: Icon(
                      character.turnActive
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(
                      character.turnActive ? 'Terminar turno' : 'Empezar turno',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onNextRound,
                    icon: const Icon(Icons.repeat_rounded),
                    label: const Text('Siguiente ronda'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
