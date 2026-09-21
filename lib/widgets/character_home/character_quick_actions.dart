import 'package:flutter/material.dart';

import 'character_home_colors.dart';

class CharacterQuickActions extends StatelessWidget {
  final VoidCallback onCombat;
  final VoidCallback onRest;
  final VoidCallback onPets; // <--- 1. Añadimos el callback de mascotas
  final int
  petCount; // <--- 2. Recibimos el número de mascotas para el subtítulo o tooltip dinámico (opcional)

  const CharacterQuickActions({
    super.key,
    required this.onCombat,
    required this.onRest,
    required this.onPets,
    this.petCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.70),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===================================================================
          // TÍTULO
          // ===================================================================
          Text(
            'Acceso rápido',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 12),

          // ===================================================================
          // ACCIONES (Ahora 4 botones distribuidos en una fila o rejilla)
          // ===================================================================
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.sports_martial_arts_rounded,
                  label: 'Combate',
                  color: CharacterHomeColors.combat(context),
                  onTap: onCombat,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _QuickActionButton(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Descansar',
                  color: CharacterHomeColors.rest(context),
                  onTap: onRest,
                ),
              ),

              const SizedBox(width: 8),

              // ===============================================================
              // BOTÓN DE MASCOTAS (NUEVO)
              // ===============================================================
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.pets_rounded,
                  label: petCount > 0 ? 'Mascotas ($petCount)' : 'Mascotas',
                  color: CharacterHomeColors.effects(context), // Color cohesivo con efectos/magia
                  onTap: onPets,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ACCIÓN
// =============================================================================

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final background = CharacterHomeColors.tintedSurface(
      context,
      color,
      lightStrength: 0.10,
      darkStrength: 0.18,
    );

    final iconBackground = CharacterHomeColors.tintedSurface(
      context,
      color,
      lightStrength: 0.22,
      darkStrength: 0.30,
    );

    final borderColor = CharacterHomeColors.tintedBorder(
      context,
      color,
      lightAlpha: 0.18,
      darkAlpha: 0.30,
    );

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===============================================================
              // ICONO
              // ===============================================================
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 21, color: color),
              ),

              const SizedBox(height: 7),

              // ===============================================================
              // TEXTO
              // ===============================================================
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
