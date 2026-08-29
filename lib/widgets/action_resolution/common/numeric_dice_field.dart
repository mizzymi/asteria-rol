import 'package:flutter/material.dart';

class NumericDiceField extends StatelessWidget {
  final int sides;

  final TextEditingController controller;

  final String? label;
  final String? errorText;

  final bool autofocus;

  const NumericDiceField({
    super.key,
    required this.sides,
    required this.controller,
    this.label,
    this.errorText,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: label ?? 'd$sides',
        errorText: errorText,
        prefixIcon: const Icon(Icons.casino_rounded),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
