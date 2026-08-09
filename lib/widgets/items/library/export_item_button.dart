import 'package:flutter/material.dart';

class ExportItemButton extends StatelessWidget {
  final VoidCallback onPressed;

  final bool compact;

  const ExportItemButton({
    super.key,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        tooltip: 'Compartir',
        onPressed: onPressed,
        icon: const Icon(Icons.share_rounded),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.share_rounded),
      label: const Text('Compartir objeto'),
    );
  }
}
