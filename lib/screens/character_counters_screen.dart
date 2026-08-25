import 'package:flutter/material.dart';

import '../models/character.dart';
import '../models/character_counter.dart';
import '../widgets/characters/counter_card.dart';

class CharacterCountersScreen extends StatefulWidget {
  final Character character;

  final Future<void> Function()? onSave;

  const CharacterCountersScreen({
    super.key,
    required this.character,
    this.onSave,
  });

  @override
  State<CharacterCountersScreen> createState() =>
      _CharacterCountersScreenState();
}

class _CharacterCountersScreenState extends State<CharacterCountersScreen> {
  Character get character => widget.character;

  Future<void> _save() async {
    await widget.onSave?.call();
  }

  Future<void> addCounter() async {
    final result = await _showCounterDialog();

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      character.counters.add(result);
    });

    await _save();
  }

  Future<void> editCounter(CharacterCounter counter) async {
    final result = await _showCounterDialog(
      counter: CharacterCounter.fromMap(counter.toMap()),
    );

    if (result == null || !mounted) {
      return;
    }

    final index = character.counters.indexWhere(
      (item) => item.id == counter.id,
    );

    if (index < 0) {
      return;
    }

    setState(() {
      character.counters[index] = result;
    });

    await _save();
  }

  Future<CharacterCounter?> _showCounterDialog({CharacterCounter? counter}) {
    return showDialog<CharacterCounter>(
      context: context,
      builder: (_) {
        return _CounterEditorDialog(counter: counter);
      },
    );
  }

  Future<void> deleteCounter(CharacterCounter counter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar contador'),
          content: Text('¿Quieres eliminar "${counter.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      character.counters.removeWhere((item) => item.id == counter.id);
    });

    await _save();
  }

  Future<void> increase(CharacterCounter counter) async {
    setState(() {
      counter.increase();
    });

    await _save();
  }

  Future<void> decrease(CharacterCounter counter) async {
    setState(() {
      counter.decrease();
    });

    await _save();
  }

  Future<void> reset(CharacterCounter counter) async {
    setState(() {
      counter.reset();
    });

    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contadores'),
        actions: [
          IconButton(
            tooltip: 'Añadir contador',
            onPressed: addCounter,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: character.counters.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tag_rounded, size: 52),

                    const SizedBox(height: 12),

                    Text(
                      'Sin contadores',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Puedes crear contadores para kills, combos, críticos y otras mecánicas.',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    FilledButton.icon(
                      onPressed: addCounter,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Crear contador'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: character.counters.length,
              itemBuilder: (context, index) {
                final counter = character.counters[index];

                return Dismissible(
                  key: ValueKey(counter.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    await deleteCounter(counter);
                    return false;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete_rounded),
                  ),
                  child: CounterCard(
                    counter: counter,
                    onDecrease: () {
                      decrease(counter);
                    },
                    onIncrease: () {
                      increase(counter);
                    },
                    onReset: () {
                      reset(counter);
                    },
                    onTap: () {
                      editCounter(counter);
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _CounterEditorDialog extends StatefulWidget {
  final CharacterCounter? counter;

  const _CounterEditorDialog({this.counter});

  @override
  State<_CounterEditorDialog> createState() => _CounterEditorDialogState();
}

class _CounterEditorDialogState extends State<_CounterEditorDialog> {
  late final TextEditingController nameController;

  late final TextEditingController valueController;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.counter?.name ?? '');

    valueController = TextEditingController(
      text: '${widget.counter?.value ?? 0}',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    valueController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.counter == null ? 'Nuevo contador' : 'Editar contador',
      ),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Kills',
              prefixIcon: Icon(Icons.tag_rounded),
            ),
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: valueController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Valor actual',
              hintText: '0',
              prefixIcon: Icon(Icons.numbers_rounded),
            ),
          ),
        ],
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),

        FilledButton(
          onPressed: () {
            final name = nameController.text.trim();

            if (name.isEmpty) {
              return;
            }

            final value = int.tryParse(valueController.text.trim()) ?? 0;

            Navigator.pop(
              context,
              CharacterCounter(
                id:
                    widget.counter?.id ??
                    '${DateTime.now().microsecondsSinceEpoch}_counter',
                name: name,
                value: value < 0 ? 0 : value,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
