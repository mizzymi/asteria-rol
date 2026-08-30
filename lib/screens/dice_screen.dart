import 'package:flutter/material.dart';

import '../models/character.dart';
import '../models/dice_history_entry.dart';
import '../models/action_attack_roll_mode.dart';

import '../services/action_resolver.dart';
import '../services/action_dice_resolver.dart';
import '../services/character_storage_service.dart';

class DiceScreen extends StatefulWidget {
  final Character character;

  const DiceScreen({super.key, required this.character});

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> {
  Character get character => widget.character;

  final ActionDiceResolver diceResolver = const ActionDiceResolver();

  int selectedSides = 20;

  int diceCount = 1;

  int modifier = 0;

  AttackRollMode d20Mode = AttackRollMode.normal;

  final List<int> availableDice = [4, 6, 8, 10, 12, 20, 100];

  String bonusText(int value) {
    return value >= 0 ? '+$value' : '$value';
  }

  Future<void> save() async {
    await CharacterStorageService.saveCharacter(character);
  }

  int rollDie(int sides) {
    return diceResolver.rollDigitalDie(sides: sides);
  }

  Future<void> roll() async {
    if (selectedSides == 20 &&
        diceCount == 1 &&
        d20Mode != AttackRollMode.normal) {
      await rollD20Special();

      return;
    }

    final rolls = List<int>.generate(diceCount, (_) => rollDie(selectedSides));

    final diceTotal = rolls.fold<int>(0, (sum, value) => sum + value);

    final total = diceTotal + modifier;

    final notation =
        '${diceCount}d$selectedSides${modifier == 0
            ? ''
            : modifier > 0
            ? '+$modifier'
            : '$modifier'}';

    final entry = DiceHistoryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: 'Tirada',
      notation: notation,
      rolls: rolls,
      modifier: modifier,
      total: total,
      createdAt: DateTime.now(),
    );

    setState(() {
      character.addDiceHistory(entry);
    });

    await save();

    if (!mounted) {
      return;
    }

    showRollResult(
      title: notation,
      rolls: rolls,
      total: total,
      modifier: modifier,
      sides: selectedSides,
    );
  }

  Future<void> rollD20Special() async {
    final first = rollDie(20);

    final second = rollDie(20);

    final resolver = ActionResolver(character: character);

    final chosen = resolver.selectNaturalAttackRoll(
      mode: d20Mode,
      firstRoll: first,
      secondRoll: second,
    );

    final total = chosen + modifier;

    final label = d20Mode == AttackRollMode.advantage
        ? 'Ventaja'
        : 'Desventaja';

    final notation =
        '1d20 $label${modifier == 0 ? '' : ' ${bonusText(modifier)}'}';

    final entry = DiceHistoryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: label,
      notation: notation,
      rolls: [first, second],
      modifier: modifier,
      total: total,
      createdAt: DateTime.now(),
    );

    setState(() {
      character.addDiceHistory(entry);
    });

    await save();

    if (!mounted) {
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        final critical = chosen == 20;

        final criticalFail = chosen == 1;

        return AlertDialog(
          title: Text(label),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.casino_rounded, size: 52),

              const SizedBox(height: 14),

              Text(
                '$first  ·  $second',
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              const SizedBox(height: 8),

              Text(
                'Usamos: $chosen',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              Text(
                modifier == 0 ? '$chosen' : '$chosen ${bonusText(modifier)}',
              ),

              const SizedBox(height: 5),

              Text(
                'TOTAL $total',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (critical) ...[
                const SizedBox(height: 10),
                const Text(
                  '💥 20 natural',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],

              if (criticalFail) ...[
                const SizedBox(height: 10),
                const Text(
                  '💀 1 natural',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void showRollResult({
    required String title,
    required List<int> rolls,
    required int total,
    required int modifier,
    required int sides,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final critical = sides == 20 && rolls.length == 1 && rolls.first == 20;

        final criticalFail =
            sides == 20 && rolls.length == 1 && rolls.first == 1;

        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.casino_rounded, size: 54),

              const SizedBox(height: 14),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: rolls.map((value) {
                  return Chip(
                    label: Text(
                      '$value',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),

              if (modifier != 0) ...[
                const SizedBox(height: 14),

                Text('Modificador ${bonusText(modifier)}'),
              ],

              const SizedBox(height: 12),

              Text(
                'TOTAL $total',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (critical) ...[
                const SizedBox(height: 10),
                const Text(
                  '💥 20 natural',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],

              if (criticalFail) ...[
                const SizedBox(height: 10),
                const Text(
                  '💀 1 natural',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cerrar'),
            ),

            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                roll();
              },
              icon: const Icon(Icons.casino_rounded),
              label: const Text('Repetir'),
            ),
          ],
        );
      },
    );
  }

  Future<void> clearHistory() async {
    if (character.diceHistory.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Borrar historial'),
          content: const Text('¿Quieres borrar todas las tiradas guardadas?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      character.clearDiceHistory();
    });

    await save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados'),
        actions: [
          if (character.diceHistory.isNotEmpty)
            IconButton(
              tooltip: 'Borrar historial',
              onPressed: clearHistory,
              icon: const Icon(Icons.delete_sweep_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
          children: [
            Text(
              'Elige el dado',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableDice.map((sides) {
                return ChoiceChip(
                  label: Text('d$sides'),
                  selected: selectedSides == sides,
                  onSelected: (_) {
                    setState(() {
                      selectedSides = sides;

                      if (sides != 20) {
                        d20Mode = AttackRollMode.normal;
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            Text(
              'Cantidad',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: diceCount > 1
                      ? () {
                          setState(() {
                            diceCount--;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove_rounded),
                ),

                const SizedBox(width: 16),

                Text(
                  '$diceCount',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(width: 16),

                IconButton.filledTonal(
                  onPressed: diceCount < 20
                      ? () {
                          setState(() {
                            diceCount++;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              'Modificador',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () {
                    setState(() {
                      modifier--;
                    });
                  },
                  icon: const Icon(Icons.remove_rounded),
                ),

                const SizedBox(width: 16),

                Text(
                  bonusText(modifier),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(width: 16),

                IconButton.filledTonal(
                  onPressed: () {
                    setState(() {
                      modifier++;
                    });
                  },
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),

            if (selectedSides == 20 && diceCount == 1) ...[
              const SizedBox(height: 24),

              Text(
                'Modo d20',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              SegmentedButton<AttackRollMode>(
                segments: const [
                  ButtonSegment<AttackRollMode>(
                    value: AttackRollMode.normal,
                    label: Text('Normal'),
                  ),
                  ButtonSegment<AttackRollMode>(
                    value: AttackRollMode.advantage,
                    label: Text('Ventaja'),
                  ),
                  ButtonSegment<AttackRollMode>(
                    value: AttackRollMode.disadvantage,
                    label: Text('Desventaja'),
                  ),
                ],
                selected: {d20Mode},
                onSelectionChanged: (values) {
                  setState(() {
                    d20Mode = values.first;
                  });
                },
              ),
            ],

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: roll,
                icon: const Icon(Icons.casino_rounded),
                label: Text('Tirar ${diceCount}d$selectedSides'),
              ),
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Historial',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Text('${character.diceHistory.length}/50'),
              ],
            ),

            const SizedBox(height: 12),

            if (character.diceHistory.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Todavía no hay tiradas.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...character.diceHistory.map((entry) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.casino_rounded),
                    title: Text(
                      entry.notation,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(entry.rolls.join(' · ')),
                    trailing: Text(
                      '${entry.total}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
