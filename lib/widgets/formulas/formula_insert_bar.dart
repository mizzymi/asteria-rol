import 'package:flutter/material.dart';

import '../../models/character.dart';

class FormulaInsertBar extends StatelessWidget {
  final Character? character;

  final ValueChanged<String> onInsert;

  const FormulaInsertBar({
    super.key,
    required this.character,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    final character = this.character;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        PopupMenuButton<String>(
          tooltip: 'Insertar variable',
          onSelected: onInsert,
          itemBuilder: (_) {
            return const [
              PopupMenuItem(value: 'level', child: Text('Nivel')),
              PopupMenuItem(value: 'health', child: Text('Vida actual')),
              PopupMenuItem(value: 'max_health', child: Text('Vida máxima')),
              PopupMenuItem(value: 'health_percent', child: Text('% de vida')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'FUE', child: Text('Fuerza')),
              PopupMenuItem(value: 'DES', child: Text('Destreza')),
              PopupMenuItem(value: 'CON', child: Text('Constitución')),
              PopupMenuItem(value: 'INT', child: Text('Inteligencia')),
              PopupMenuItem(value: 'SAB', child: Text('Sabiduría')),
              PopupMenuItem(value: 'CAR', child: Text('Carisma')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'FUE_MOD', child: Text('Mod. Fuerza')),
              PopupMenuItem(value: 'DES_MOD', child: Text('Mod. Destreza')),
              PopupMenuItem(value: 'CON_MOD', child: Text('Mod. Constitución')),
              PopupMenuItem(value: 'INT_MOD', child: Text('Mod. Inteligencia')),
              PopupMenuItem(value: 'SAB_MOD', child: Text('Mod. Sabiduría')),
              PopupMenuItem(value: 'CAR_MOD', child: Text('Mod. Carisma')),
            ];
          },
          child: const Chip(
            avatar: Icon(Icons.data_object_rounded, size: 18),
            label: Text('Variables'),
          ),
        ),

        if (character != null && character.resources.isNotEmpty)
          PopupMenuButton<String>(
            tooltip: 'Insertar recurso',
            onSelected: onInsert,
            itemBuilder: (_) {
              return [
                for (final resource in character.resources) ...[
                  PopupMenuItem(
                    value: 'resource(${resource.id})',
                    child: Text('${resource.name} · Actual'),
                  ),
                  if (resource.hasMaximum)
                    PopupMenuItem(
                      value: 'resourceMax(${resource.id})',
                      child: Text('${resource.name} · Máximo'),
                    ),
                  if (resource.hasMaximum)
                    PopupMenuItem(
                      value: 'resourcePercent(${resource.id})',
                      child: Text('${resource.name} · %'),
                    ),
                ],
              ];
            },
            child: const Chip(
              avatar: Icon(Icons.account_balance_wallet_rounded, size: 18),
              label: Text('Recursos'),
            ),
          ),

        if (character != null && character.counters.isNotEmpty)
          PopupMenuButton<String>(
            tooltip: 'Insertar contador',
            onSelected: onInsert,
            itemBuilder: (_) {
              return character.counters.map((counter) {
                return PopupMenuItem(
                  value: 'counter(${counter.id})',
                  child: Text(counter.name),
                );
              }).toList();
            },
            child: const Chip(
              avatar: Icon(Icons.tag_rounded, size: 18),
              label: Text('Contadores'),
            ),
          ),

        PopupMenuButton<String>(
          tooltip: 'Insertar función',
          onSelected: onInsert,
          itemBuilder: (_) {
            return const [
              PopupMenuItem(
                value: 'rounddown()',
                child: Text('Redondear abajo'),
              ),
              PopupMenuItem(
                value: 'roundup()',
                child: Text('Redondear arriba'),
              ),
              PopupMenuItem(value: 'round()', child: Text('Redondear')),
              PopupMenuItem(value: 'min(, )', child: Text('Mínimo')),
              PopupMenuItem(value: 'max(, )', child: Text('Máximo')),
              PopupMenuItem(value: 'abs()', child: Text('Valor absoluto')),
              PopupMenuItem(value: 'if(, , )', child: Text('Condición IF')),
            ];
          },
          child: const Chip(
            avatar: Icon(Icons.functions_rounded, size: 18),
            label: Text('Funciones'),
          ),
        ),
      ],
    );
  }
}
