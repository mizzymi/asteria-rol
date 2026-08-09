import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/character.dart';

import '../common/app_card.dart';
import '../common/info_badge.dart';

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

    final avatarPath = character.avatarPath;

    final hasAvatar =
        avatarPath != null &&
        avatarPath.isNotEmpty &&
        File(avatarPath).existsSync();

    return AppCard(
      emphasized: true,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ===============================================================
          // AVATAR
          // ===============================================================
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: hasAvatar ? onAvatarTap : onChangeAvatar,
                child: Hero(
                  tag: 'character-avatar-${character.id}',
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.25,
                        ),
                        width: 3,
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      backgroundImage: hasAvatar
                          ? FileImage(File(avatarPath))
                          : null,
                      child: hasAvatar
                          ? null
                          : Text(
                              character.name.isNotEmpty
                                  ? character.name[0].toUpperCase()
                                  : '?',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w900,
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
                  color: theme.colorScheme.primary,
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

          // ===============================================================
          // DATOS
          // ===============================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),

                if (character.race.isNotEmpty) ...[
                  const SizedBox(height: 4),

                  Text(
                    character.race,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onEditClasses,
                      child: InfoBadge(
                        icon: Icons.auto_awesome_rounded,
                        text: character.classSummary,
                        highlighted: true,
                      ),
                    ),

                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onEditLevel,
                      child: InfoBadge(
                        icon: Icons.military_tech_rounded,
                        text: 'Nivel ${character.level}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
