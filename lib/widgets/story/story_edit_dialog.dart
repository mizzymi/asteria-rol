import 'package:flutter/material.dart';

class StoryEditDialog extends StatefulWidget {
  final String title;
  final String value;
  final String hint;

  final IconData icon;
  final Color color;

  const StoryEditDialog({
    super.key,
    required this.title,
    required this.value,
    required this.hint,
    required this.icon,
    required this.color,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String value,
    required String hint,
    required IconData icon,
    required Color color,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) {
        return StoryEditDialog(
          title: title,
          value: value,
          hint: hint,
          icon: icon,
          color: color,
        );
      },
    );
  }

  @override
  State<StoryEditDialog> createState() => _StoryEditDialogState();
}

class _StoryEditDialogState extends State<StoryEditDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
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
                      color: Color.lerp(
                        theme.colorScheme.surface,
                        widget.color,
                        0.22,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: widget.color),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      widget.title,
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
                minLines: 6,
                maxLines: 14,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context, controller.text.trim());
                      },
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
