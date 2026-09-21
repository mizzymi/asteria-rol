import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/character.dart';

class CharacterHeaderCard extends StatelessWidget {
  final Character character;

  final VoidCallback onEditLevel;
  final VoidCallback onEditClasses;

  final VoidCallback onAvatarTap;
  final VoidCallback onChangeAvatar;

  const CharacterHeaderCard({
    super.key,
    required this.character,
    required this.onEditLevel,
    required this.onEditClasses,
    required this.onAvatarTap,
    required this.onChangeAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final avatarPath = character.avatarPath;

    final hasAvatar =
        avatarPath != null &&
        avatarPath.isNotEmpty &&
        File(avatarPath).existsSync();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // =====================================================================
        // AVATAR
        // =====================================================================
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: hasAvatar ? onAvatarTap : onChangeAvatar,
              child: Hero(
                tag: 'character-avatar-${character.id}',
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surfaceContainerHighest,
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.32),
                      width: 3,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: CircleAvatar(
                    backgroundColor: colors.surfaceContainerHigh,

                    backgroundImage: hasAvatar
                        ? FileImage(File(avatarPath))
                        : null,

                    child: hasAvatar
                        ? null
                        : Text(
                            character.name.trim().isNotEmpty
                                ? character.name.trim()[0].toUpperCase()
                                : '?',

                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w900,

                              color: colors.primary,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            Positioned(
              right: -2,
              bottom: -2,
              child: Material(
                color: colors.primary,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  onTap: onChangeAvatar,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 17,
                      color: colors.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 18),

        // =====================================================================
        // INFORMACIÓN
        // =====================================================================
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                character.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),

              if (character.race.trim().isNotEmpty) ...[
                const SizedBox(height: 5),

                Text(
                  character.race.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeaderBadge(
                    icon: Icons.auto_awesome_rounded,
                    label: character.classSummary,
                    highlighted: true,
                    onTap: onEditClasses,
                  ),

                  _HeaderBadge(
                    icon: Icons.military_tech_rounded,
                    label: 'Nivel ${character.level}',
                    onTap: onEditLevel,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;
  final VoidCallback onTap;

  const _HeaderBadge({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final background = highlighted
        ? Color.lerp(
                colors.surface,
                colors.primary,
                theme.brightness == Brightness.dark ? 0.20 : 0.10,
              ) ??
              colors.surface
        : colors.surfaceContainerLow;

    final borderColor = highlighted
        ? colors.primary.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.40 : 0.22,
          )
        : colors.outlineVariant;

    final foreground = highlighted ? colors.primary : colors.onSurfaceVariant;

    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),

              const SizedBox(width: 6),

              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
