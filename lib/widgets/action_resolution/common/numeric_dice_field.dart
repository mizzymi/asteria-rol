import 'package:flutter/material.dart';

class NumericDiceField extends StatelessWidget {
  final int sides;
  final int? value;
  final ValueChanged<int?> onChanged;
  final String? errorText;
  final String? label;
  final bool autofocus;

  const NumericDiceField({
    super.key,
    required this.sides,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.label,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label ?? 'd$sides',
        errorText: errorText,
        border: const OutlineInputBorder(),
      ),
      onChanged: (text) {
        onChanged(int.tryParse(text.trim()));
      },
    );
  }
}
