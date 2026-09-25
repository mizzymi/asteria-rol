import 'package:flutter/material.dart';

import '../../../models/skill.dart';
import '../../../models/weapon_damage.dart';
import '../../common/section_header.dart';

class ItemWeaponSection extends StatelessWidget {
  final AbilityType attackAbility;
  final bool proficient;

  final TextEditingController magicBonusController;
  final int criticalMinimumNaturalRoll;

  final bool empoweredCritical;

  final int empoweredCriticalMultiplier;
  final TextEditingController empoweredCriticalFormulaController;

  final ValueChanged<int> onCriticalMinimumNaturalRollChanged;

  final ValueChanged<bool> onEmpoweredCriticalChanged;

  final ValueChanged<int> onEmpoweredCriticalMultiplierChanged;
  final List<WeaponDamage> damages;

  final ValueChanged<AbilityType> onAttackAbilityChanged;
  final ValueChanged<bool> onProficientChanged;

  final VoidCallback onAddDamage;
  final ValueChanged<int> onEditDamage;
  final ValueChanged<int> onDeleteDamage;
  final ValueChanged<int> onEditCriticalDamage;
  final ValueChanged<int> onDamageChanged;

  const ItemWeaponSection({
    super.key,
    required this.attackAbility,
    required this.proficient,
    required this.magicBonusController,
    required this.criticalMinimumNaturalRoll,
    required this.empoweredCritical,
    required this.empoweredCriticalMultiplier,
    required this.empoweredCriticalFormulaController,
    required this.onCriticalMinimumNaturalRollChanged,
    required this.onEmpoweredCriticalChanged,
    required this.onEmpoweredCriticalMultiplierChanged,
    required this.damages,
    required this.onAttackAbilityChanged,
    required this.onProficientChanged,
    required this.onAddDamage,
    required this.onEditDamage,
    required this.onDeleteDamage,
    required this.onEditCriticalDamage,
    required this.onDamageChanged,
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

        const SizedBox(height: 16),

        DropdownButtonFormField<int>(
          initialValue: criticalMinimumNaturalRoll,
          decoration: const InputDecoration(
            labelText: 'Rango crítico',
            helperText: 'Valor natural mínimo del d20 que produce crítico.',
            prefixIcon: Icon(Icons.local_fire_department_rounded),
          ),
          items: List.generate(20, (index) {
            final value = 20 - index;

            return DropdownMenuItem<int>(
              value: value,
              child: Text(value == 20 ? '20' : '$value–20'),
            );
          }),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            onCriticalMinimumNaturalRollChanged(value);
          },
        ),

        const SizedBox(height: 8),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,

          value: empoweredCritical,

          title: const Text(
            'Crítico potenciado',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),

          subtitle: const Text(
            'Los críticos realizados con esta arma '
            'usan la regla potenciada.',
          ),

          onChanged: onEmpoweredCriticalChanged,
        ),

        if (empoweredCritical) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: empoweredCriticalFormulaController,
            decoration: const InputDecoration(
              labelText: 'Fórmula de crítico',
              helperText: 'TIRADA, MAX, MOD, TURNO, CARGAS, RECURSO("Ki"), CONTADOR("Combo")',
              prefixIcon: Icon(Icons.functions_rounded),
            ),
          ),
        ],

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

                onEditCritical: () {
                  onEditCriticalDamage(index);
                },

                onParticipatesInCriticalChanged: (value) {
                  damage.participatesInCritical = value;
                  onDamageChanged(index);
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

  final VoidCallback onEditCritical;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onParticipatesInCriticalChanged;

  const _DamageCard({
    required this.damage,
    required this.onEditCritical,
    required this.onEdit,
    required this.onDelete,
    required this.onParticipatesInCriticalChanged,
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

    final criticalFormula = damage.criticalDiceNotation;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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

                      if (criticalFormula.isNotEmpty) ...[
                        const SizedBox(height: 6),

                        Row(
                          children: [
                            Icon(
                              Icons.flash_on_rounded,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),

                            const SizedBox(width: 5),

                            Expanded(
                              child: Text(
                                'Crítico: +$criticalFormula',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
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

            const SizedBox(height: 10),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,

              value: damage.participatesInCritical,

              title: const Text(
                'Participa en crítico',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),

              subtitle: const Text(
                'Este componente recibe la transformación '
                'crítica del arma.',
              ),

              secondary: const Icon(Icons.local_fire_department_rounded),

              onChanged: onParticipatesInCriticalChanged,
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.casino_rounded),
                    label: const Text('Editar daño'),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onEditCritical,
                    icon: const Icon(Icons.flash_on_rounded),
                    label: Text(
                      criticalFormula.isEmpty
                          ? 'Añadir crítico'
                          : 'Editar crítico',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
