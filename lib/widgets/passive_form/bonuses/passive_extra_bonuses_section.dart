import 'package:flutter/material.dart';

import '../../../models/critical_damage_bonus.dart';
import '../../../models/damage_bonus.dart';
import '../../../models/healing_bonus.dart';

import '../../forms/common/removable_form_tile.dart';

class PassiveExtraBonusesSection extends StatelessWidget {
  final List<DamageBonus> damageBonuses;

  final List<CriticalDamageBonus> criticalDamageBonuses;

  final List<HealingBonus> healingBonuses;

  final String Function(DamageBonus) damageText;

  final String Function(CriticalDamageBonus) criticalText;

  final String Function(HealingBonus) healingText;

  final VoidCallback onAddDamage;

  final VoidCallback onAddCritical;

  final VoidCallback onAddHealing;

  final ValueChanged<int> onEditDamage;

  final ValueChanged<int> onEditCritical;

  final ValueChanged<int> onEditHealing;

  final ValueChanged<int> onDeleteDamage;

  final ValueChanged<int> onDeleteCritical;

  final ValueChanged<int> onDeleteHealing;

  const PassiveExtraBonusesSection({
    super.key,
    required this.damageBonuses,
    required this.criticalDamageBonuses,
    required this.healingBonuses,
    required this.damageText,
    required this.criticalText,
    required this.healingText,
    required this.onAddDamage,
    required this.onAddCritical,
    required this.onAddHealing,
    required this.onEditDamage,
    required this.onEditCritical,
    required this.onEditHealing,
    required this.onDeleteDamage,
    required this.onDeleteCritical,
    required this.onDeleteHealing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BonusGroup(
          title: 'Daño',
          subtitle: 'Daño adicional al causar daño',
          icon: Icons.local_fire_department_rounded,
          count: damageBonuses.length,
          onAdd: onAddDamage,
          children: [
            for (var i = 0; i < damageBonuses.length; i++)
              RemovableFormTile(
                title: damageText(damageBonuses[i]),
                icon: Icons.local_fire_department_rounded,
                onTap: () {
                  onEditDamage(i);
                },
                onDelete: () {
                  onDeleteDamage(i);
                },
              ),
          ],
        ),

        const SizedBox(height: 12),

        _BonusGroup(
          title: 'Daño crítico',
          subtitle: 'Dados o daño adicional al realizar un crítico',
          icon: Icons.bolt_rounded,
          count: criticalDamageBonuses.length,
          onAdd: onAddCritical,
          children: [
            for (var i = 0; i < criticalDamageBonuses.length; i++)
              RemovableFormTile(
                title: criticalText(criticalDamageBonuses[i]),
                icon: Icons.bolt_rounded,
                onTap: () {
                  onEditCritical(i);
                },
                onDelete: () {
                  onDeleteCritical(i);
                },
              ),
          ],
        ),

        const SizedBox(height: 12),

        _BonusGroup(
          title: 'Curación',
          subtitle: 'Bonificación adicional al realizar curaciones',
          icon: Icons.favorite_rounded,
          count: healingBonuses.length,
          onAdd: onAddHealing,
          children: [
            for (var i = 0; i < healingBonuses.length; i++)
              RemovableFormTile(
                title: healingText(healingBonuses[i]),
                icon: Icons.favorite_rounded,
                onTap: () {
                  onEditHealing(i);
                },
                onDelete: () {
                  onDeleteHealing(i);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _BonusGroup extends StatelessWidget {
  final String title;

  final String subtitle;

  final IconData icon;

  final int count;

  final VoidCallback onAdd;

  final List<Widget> children;

  const _BonusGroup({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.count,
    required this.onAdd,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(child: Icon(icon, size: 19)),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                if (count > 0) Badge(label: Text('$count')),

                IconButton(
                  tooltip: 'Añadir',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),

            if (children.isNotEmpty) ...[const Divider(), ...children],
          ],
        ),
      ),
    );
  }
}
