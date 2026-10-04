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
        // =====================================================================
        // MENÚ DE DADOS (NUEVO)
        // =====================================================================
        PopupMenuButton<String>(
          tooltip: 'Insertar dados',
          onSelected: onInsert,
          itemBuilder: (_) {
            return const [
              PopupMenuItem(value: '1d4', child: Text('1 Dado de 4 (1d4)')),
              PopupMenuItem(value: '1d6', child: Text('1 Dado de 6 (1d6)')),
              PopupMenuItem(value: '1d8', child: Text('1 Dado de 8 (1d8)')),
              PopupMenuItem(value: '1d10', child: Text('1 Dado de 10 (1d10)')),
              PopupMenuItem(value: '1d12', child: Text('1 Dado de 12 (1d12)')),
              PopupMenuItem(value: '1d20', child: Text('1 Dado de 20 (1d20)')),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'level*d4',
                child: Text('Nivel x d4 (level*d4)'),
              ),
              PopupMenuItem(
                value: 'level*d6',
                child: Text('Nivel x d6 (level*d6)'),
              ),
              PopupMenuItem(
                value: 'level*d8',
                child: Text('Nivel x d8 (level*d8)'),
              ),
              PopupMenuItem(
                value: 'level*d10',
                child: Text('Nivel x d10 (level*d10)'),
              ),
            ];
          },
          child: const Chip(
            avatar: Icon(Icons.casino_rounded, size: 18),
            label: Text('Dados'),
          ),
        ),

        // =====================================================================
        // MENÚ DE VARIABLES
        // =====================================================================
        PopupMenuButton<String>(
          tooltip: 'Insertar variable',
          onSelected: onInsert,
          itemBuilder: (_) {
            return const [
              PopupMenuItem(value: 'level', child: Text('Nivel')),
              PopupMenuItem(
                value: 'competencia',
                child: Text('Competencia'),
              ),
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

        // =====================================================================
        // MENÚ DE RECURSOS
        // =====================================================================
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

        PopupMenuButton<String>(
          tooltip: 'Insertar cargas',
          onSelected: onInsert,
          itemBuilder: (_) {
            return const [
              PopupMenuItem(value: 'charges', child: Text('Cargas actuales')),
              PopupMenuItem(
                value: 'max_charges',
                child: Text('Cargas máximas'),
              ),
              PopupMenuItem(
                value: 'charges_percent',
                child: Text('% de cargas'),
              ),
            ];
          },
          child: const Chip(
            avatar: Icon(Icons.bolt_rounded, size: 18),
            label: Text('Cargas'),
          ),
        ),

        // =====================================================================
        // MENÚ DE CONTADORES
        // =====================================================================
        if (character != null && character.counters.isNotEmpty)
          PopupMenuButton<String>(
            tooltip: 'Insertار contador',
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

        // =====================================================================
        // MENÚ DE FUNCIONES
        // =====================================================================
        PopupMenuButton<String>(
          tooltip: 'Insertar función',
          onSelected: onInsert,
          itemBuilder: (_) {
            return const [
              PopupMenuItem(
                value: 'competencia',
                child: Text('Competencia'),
              ),
              PopupMenuDivider(),
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
