import 'package:flutter/material.dart';

import '../../../models/skill.dart';
import '../../../models/weapon_damage.dart';
import '../../common/section_header.dart';

class ItemWeaponSection extends StatelessWidget {
  final AbilityType attackAbility;
  final bool proficient;

  final TextEditingController magicBonusController;

  final List<WeaponDamage> damages;

  final ValueChanged<AbilityType> onAttackAbilityChanged;
  final ValueChanged<bool> onProficientChanged;

  final VoidCallback onAddDamage;
  final ValueChanged<int> onEditDamage;
  final ValueChanged<int> onDeleteDamage;

  const ItemWeaponSection({
    super.key,
    required this.attackAbility,
    required this.proficient,
    required this.magicBonusController,
    required this.damages,
    required this.onAttackAbilityChanged,
    required this.onProficientChanged,
    required this.onAddDamage,
    required this.onEditDamage,
    required this.onDeleteDamage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          icon: Icons.gavel_rounded,
          title: 'Arma',
          subtitle: 'Configura el ataque y los daños del arma',
        ),

        const SizedBox(height: 16),

        // =====================================================================
        // ATRIBUTO
        // =====================================================================
        DropdownButtonFormField<AbilityType>(
          initialValue: attackAbility,
          decoration: const InputDecoration(
            labelText: 'Atributo de ataque',
            prefixIcon: Icon(Icons.psychology_rounded),
          ),
          items: AbilityType.values.map((ability) {
            return DropdownMenuItem(value: ability, child: Text(ability.label));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onAttackAbilityChanged(value);
            }
          },
        ),

        const SizedBox(height: 14),

        // =====================================================================
        // COMPETENCIA
        // =====================================================================
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Competente con el arma',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: const Text(
            'Añade el bono de competencia a la tirada de ataque.',
          ),
          value: proficient,
          onChanged: onProficientChanged,
        ),

        const SizedBox(height: 10),

        // =====================================================================
        // BONUS MÁGICO
        // =====================================================================
        TextFormField(
          controller: magicBonusController,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: const InputDecoration(
            labelText: 'Bonificador mágico',
            hintText: '0',
            prefixIcon: Icon(Icons.auto_awesome_rounded),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';

            if (text.isEmpty) {
              return null;
            }

            if (int.tryParse(text) == null) {
              return 'Introduce un número válido';
            }

            return null;
          },
        ),

        const SizedBox(height: 24),

        // =====================================================================
        // DAÑOS
        // =====================================================================
        Row(
          children: [
            Expanded(
              child: Text(
                'Daños',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            FilledButton.tonalIcon(
              onPressed: onAddDamage,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Añadir'),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Text(
          'Puedes añadir varios tipos de daño a la misma arma.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 12),

        if (damages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.casino_outlined),
                SizedBox(height: 8),
                Text(
                  'Sin daño configurado',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          )
        else
          ...List.generate(damages.length, (index) {
            final damage = damages[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DamageCard(
                damage: damage,
                onEdit: () {
                  onEditDamage(index);
                },
                onDelete: () {
                  onDeleteDamage(index);
                },
              ),
            );
          }),
      ],
    );
  }
}

class _DamageCard extends StatelessWidget {
  final WeaponDamage damage;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DamageCard({
    required this.damage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final parts = <String>[];

    if (damage.diceNotation.isNotEmpty) {
      parts.add(damage.diceNotation);
    }

    if (damage.addAbilityModifier) {
      parts.add(damage.abilityType.shortLabel);
    }

    if (damage.bonus != 0) {
      parts.add(damage.bonus > 0 ? '+${damage.bonus}' : '${damage.bonus}');
    }

    final formula = parts.join(' + ').replaceAll('+ -', '- ');

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.casino_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      damage.name.trim().isNotEmpty
                          ? damage.name
                          : damage.damageType.trim().isNotEmpty
                          ? damage.damageType
                          : 'Daño',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      formula.isEmpty ? 'Sin fórmula' : formula,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    if (damage.damageType.trim().isNotEmpty &&
                        damage.name.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        damage.damageType,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Eliminar daño',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
