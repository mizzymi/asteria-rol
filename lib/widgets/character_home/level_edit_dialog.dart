import 'package:flutter/material.dart';

class LevelEditDialog extends StatefulWidget {
  final int currentLevel;

  const LevelEditDialog({super.key, required this.currentLevel});

  static Future<int?> show(BuildContext context, {required int currentLevel}) {
    return showDialog<int>(
      context: context,
      builder: (_) {
        return LevelEditDialog(currentLevel: currentLevel);
      },
    );
  }

  @override
  State<LevelEditDialog> createState() => _LevelEditDialogState();
}

class _LevelEditDialogState extends State<LevelEditDialog> {
  late final TextEditingController controller;

  int? value;

  @override
  void initState() {
    super.initState();

    value = widget.currentLevel;

    controller = TextEditingController(text: '${widget.currentLevel}');
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  bool get valid {
    final current = value;

    return current != null && current >= 1 && current <= 20;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.military_tech_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      'Cambiar nivel',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'Nivel',
                  helperText: 'Entre 1 y 20',
                  prefixIcon: Icon(Icons.stars_rounded),
                ),
                onChanged: (text) {
                  setState(() {
                    value = int.tryParse(text);
                  });
                },
                onSubmitted: (_) {
                  if (valid) {
                    Navigator.pop(context, value);
                  }
                },
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: valid
                      ? () {
                          Navigator.pop(context, value);
                        }
                      : null,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
