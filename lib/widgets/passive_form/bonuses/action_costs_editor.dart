import 'package:flutter/material.dart';

import '../../../models/action_cost.dart';
import '../../../models/character.dart';

class ActionCostsEditor extends StatelessWidget {
  final List<ActionCost> costs;

  final Character? character;

  final String ownerPassiveId;

  final bool ownerUsesCharges;

  final VoidCallback onChanged;

  const ActionCostsEditor({
    super.key,
    required this.costs,
    required this.character,
    required this.ownerPassiveId,
    required this.ownerUsesCharges,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Costes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            PopupMenuButton<_CostAddType>(
              tooltip: 'Añadir coste',

              onSelected: (type) {
                _addCost(type);
              },

              itemBuilder: (context) => [
                if (character != null && character!.resources.isNotEmpty)
                  const PopupMenuItem(
                    value: _CostAddType.resource,
                    child: ListTile(
                      leading: Icon(Icons.account_balance_wallet_rounded),
                      title: Text('Recurso'),
                    ),
                  ),

                if (ownerUsesCharges)
                  const PopupMenuItem(
                    value: _CostAddType.passiveCharge,
                    child: ListTile(
                      leading: Icon(Icons.battery_charging_full_rounded),
                      title: Text('Carga de esta pasiva'),
                    ),
                  ),

                if (character != null &&
                    character!.availableAbilities.isNotEmpty)
                  const PopupMenuItem(
                    value: _CostAddType.abilityUse,
                    child: ListTile(
                      leading: Icon(Icons.auto_awesome_rounded),
                      title: Text('Uso de habilidad'),
                    ),
                  ),
              ],

              child: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (costs.isEmpty)
          Text(
            'Sin costes adicionales.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...List.generate(costs.length, (index) {
            final cost = costs[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ActionCostRow(
                cost: cost,

                character: character,

                ownerPassiveId: ownerPassiveId,

                onChanged: (value) {
                  costs[index] = value;
                  onChanged();
                },

                onDelete: () {
                  costs.removeAt(index);
                  onChanged();
                },
              ),
            );
          }),
      ],
    );
  }

  void _addCost(_CostAddType type) {
    switch (type) {
      case _CostAddType.resource:
        final character = this.character;

        if (character == null || character.resources.isEmpty) {
          return;
        }

        final resource = character.resources.first;

        costs.add(
          ActionCost.resource(
            resourceId: resource.id,
            amount: 1,
            label: resource.name,
          ),
        );

        break;

      case _CostAddType.passiveCharge:
        costs.add(
          ActionCost.passiveCharge(
            passiveId: ownerPassiveId,
            amount: 1,
            label: 'Cargas',
          ),
        );

        break;

      case _CostAddType.abilityUse:
        final character = this.character;

        if (character == null || character.availableAbilities.isEmpty) {
          return;
        }

        final ability = character.availableAbilities.first;

        costs.add(
          ActionCost.abilityUse(
            abilityId: ability.id,
            amount: 1,
            label: ability.name,
          ),
        );

        break;
    }

    onChanged();
  }
}

enum _CostAddType { resource, passiveCharge, abilityUse }

class _ActionCostRow extends StatelessWidget {
  final ActionCost cost;

  final Character? character;

  final String ownerPassiveId;

  final ValueChanged<ActionCost> onChanged;

  final VoidCallback onDelete;

  const _ActionCostRow({
    required this.cost,
    required this.character,
    required this.ownerPassiveId,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 3, child: _sourceField()),

        const SizedBox(width: 8),

        Expanded(
          child: TextFormField(
            initialValue: '${cost.amount}',

            keyboardType: TextInputType.number,

            decoration: const InputDecoration(labelText: 'Cantidad'),

            onChanged: (value) {
              final amount = int.tryParse(value) ?? 1;

              onChanged(
                ActionCost(
                  type: cost.type,

                  sourceId: cost.sourceId,

                  amount: amount < 1 ? 1 : amount,

                  label: cost.label,
                ),
              );
            },
          ),
        ),

        IconButton(
          tooltip: 'Eliminar coste',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    );
  }

  Widget _sourceField() {
    switch (cost.type) {
      case ActionCostType.resource:
        final resources = character?.resources ?? [];

        return DropdownButtonFormField<String>(
          initialValue:
              resources.any((resource) => resource.id == cost.sourceId)
              ? cost.sourceId
              : resources.isEmpty
              ? null
              : resources.first.id,

          decoration: const InputDecoration(labelText: 'Recurso'),

          items: resources
              .map(
                (resource) => DropdownMenuItem(
                  value: resource.id,
                  child: Text(resource.name),
                ),
              )
              .toList(),

          onChanged: (value) {
            if (value == null) {
              return;
            }

            final resource = character?.resourceById(value);

            onChanged(
              ActionCost.resource(
                resourceId: value,
                amount: cost.amount,
                label: resource?.name,
              ),
            );
          },
        );

      case ActionCostType.passiveCharge:
        return InputDecorator(
          decoration: const InputDecoration(labelText: 'Fuente'),
          child: const Text('Cargas de esta pasiva'),
        );

      case ActionCostType.abilityUse:
        final abilities = character?.availableAbilities ?? [];

        return DropdownButtonFormField<String>(
          initialValue: abilities.any((ability) => ability.id == cost.sourceId)
              ? cost.sourceId
              : abilities.isEmpty
              ? null
              : abilities.first.id,

          decoration: const InputDecoration(labelText: 'Habilidad'),

          items: abilities
              .map(
                (ability) => DropdownMenuItem(
                  value: ability.id,
                  child: Text(ability.name),
                ),
              )
              .toList(),

          onChanged: (value) {
            if (value == null) {
              return;
            }

            final ability = abilities
                .where((ability) => ability.id == value)
                .firstOrNull;

            onChanged(
              ActionCost.abilityUse(
                abilityId: value,
                amount: cost.amount,
                label: ability?.name,
              ),
            );
          },
        );
    }
  }
}
