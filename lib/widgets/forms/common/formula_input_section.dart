import 'package:flutter/material.dart';

import '../../../models/character.dart';
import '../../formulas/formula_insert_bar.dart';
import '../../../services/formula_display_formatter.dart';

class FormulaInputSection extends StatefulWidget {
  final TextEditingController controller;

  final Character? character;

  final String title;
  final String label;
  final String hint;

  final String? description;

  final ValueChanged<String>? onChanged;

  const FormulaInputSection({
    super.key,
    required this.controller,
    required this.title,
    required this.label,
    required this.hint,
    this.character,
    this.description,
    this.onChanged,
  });

  @override
  State<FormulaInputSection> createState() => _FormulaInputSectionState();
}

class _FormulaInputSectionState extends State<FormulaInputSection> {
  bool showTools = false;

  void _insert(String text) {
    final controller = widget.controller;

    final selection = controller.selection;
    final current = controller.text;

    final start = selection.isValid ? selection.start : current.length;

    final end = selection.isValid ? selection.end : current.length;

    final newText = current.replaceRange(start, end, text);

    var cursor = start + text.length;

    final emptyParentheses = text.indexOf('()');

    if (emptyParentheses >= 0) {
      cursor = start + emptyParentheses + 1;
    } else {
      final opening = text.indexOf('(');

      if (opening >= 0) {
        cursor = start + opening + 1;
      }
    }

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor),
    );

    widget.onChanged?.call(controller.text);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final friendly = FormulaDisplayFormatter.format(
      widget.controller.text,
      widget.character,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),

        if (widget.description != null) ...[
          const SizedBox(height: 5),

          Text(
            widget.description!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        const SizedBox(height: 10),

        TextFormField(
          controller: widget.controller,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.functions_rounded),
          ),
          onChanged: (value) {
            widget.onChanged?.call(value);
            setState(() {});
          },
        ),

        const SizedBox(height: 6),

        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                showTools = !showTools;
              });
            },
            icon: Icon(
              showTools ? Icons.expand_less_rounded : Icons.functions_rounded,
            ),
            label: Text(
              showTools ? 'Ocultar herramientas' : 'Insertar en fórmula',
            ),
          ),
        ),

        if (showTools) ...[
          const SizedBox(height: 4),

          FormulaInsertBar(character: widget.character, onInsert: _insert),
        ],

        if (widget.controller.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),

          Text(
            'Lectura: $friendly',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
