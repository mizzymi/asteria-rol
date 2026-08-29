import 'package:flutter/material.dart';

enum CombatActionChoice { attack, damage, critical, heal, use }

class CombatActionSheet {
  const CombatActionSheet._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,

    bool canAttack = false,
    bool canDamage = false,
    bool canCritical = false,
    bool canHeal = false,
    bool canUse = false,

    VoidCallback? onAttack,
    VoidCallback? onDamage,
    VoidCallback? onCritical,
    VoidCallback? onHeal,
    VoidCallback? onUse,
  }) async {
    final choice = await showModalBottomSheet<CombatActionChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============================================================
                // CABECERA
                // ============================================================
                Row(
                  children: [
                    const CircleAvatar(
                      child: Icon(Icons.sports_martial_arts_rounded),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(sheetContext).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),

                          if (subtitle != null &&
                              subtitle.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),

                            Text(
                              subtitle,
                              style: Theme.of(sheetContext).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ============================================================
                // ATAQUE
                // ============================================================
                if (canAttack)
                  _CombatActionTile(
                    icon: Icons.gps_fixed_rounded,
                    title: 'Ataque',
                    subtitle: 'Realizar tirada de ataque',
                    onTap: onAttack == null
                        ? null
                        : () {
                            Navigator.pop(
                              sheetContext,
                              CombatActionChoice.attack,
                            );
                          },
                  ),

                // ============================================================
                // DAÑO
                // ============================================================
                if (canDamage)
                  _CombatActionTile(
                    icon: Icons.local_fire_department_rounded,
                    title: 'Daño',
                    subtitle: 'Resolver daño normal',
                    onTap: onDamage == null
                        ? null
                        : () {
                            Navigator.pop(
                              sheetContext,
                              CombatActionChoice.damage,
                            );
                          },
                  ),

                // ============================================================
                // CRÍTICO
                // ============================================================
                if (canCritical)
                  _CombatActionTile(
                    icon: Icons.bolt_rounded,
                    title: 'Crítico',
                    subtitle: 'Resolver el daño como golpe crítico',
                    onTap: onCritical == null
                        ? null
                        : () {
                            Navigator.pop(
                              sheetContext,
                              CombatActionChoice.critical,
                            );
                          },
                  ),

                // ============================================================
                // CURACIÓN
                // ============================================================
                if (canHeal)
                  _CombatActionTile(
                    icon: Icons.favorite_rounded,
                    title: 'Curación',
                    subtitle: 'Resolver la curación',
                    onTap: onHeal == null
                        ? null
                        : () {
                            Navigator.pop(
                              sheetContext,
                              CombatActionChoice.heal,
                            );
                          },
                  ),

                // ============================================================
                // USAR
                // ============================================================
                if (canUse)
                  _CombatActionTile(
                    icon: Icons.touch_app_rounded,
                    title: 'Usar',
                    subtitle: 'Activar o consumir',
                    onTap: onUse == null
                        ? null
                        : () {
                            Navigator.pop(sheetContext, CombatActionChoice.use);
                          },
                  ),
              ],
            ),
          ),
        );
      },
    );

    // =========================================================================
    // IMPORTANTE
    //
    // Llegamos aquí únicamente cuando el bottom sheet YA se ha cerrado.
    //
    // Solo entonces abrimos cualquier diálogo perteneciente a la acción.
    // =========================================================================

    switch (choice) {
      case CombatActionChoice.attack:
        onAttack?.call();
        break;

      case CombatActionChoice.damage:
        onDamage?.call();
        break;

      case CombatActionChoice.critical:
        onCritical?.call();
        break;

      case CombatActionChoice.heal:
        onHeal?.call();
        break;

      case CombatActionChoice.use:
        onUse?.call();
        break;

      case null:
        break;
    }
  }
}

class _CombatActionTile extends StatelessWidget {
  final IconData icon;

  final String title;

  final String subtitle;

  final VoidCallback? onTap;

  const _CombatActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: onTap != null,

      contentPadding: EdgeInsets.zero,

      onTap: onTap,

      leading: CircleAvatar(child: Icon(icon)),

      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),

      subtitle: Text(subtitle),

      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
