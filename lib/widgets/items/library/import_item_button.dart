import 'package:flutter/material.dart';

class ImportItemButton extends StatelessWidget {
  final VoidCallback onPressed;

  final bool expanded;

  const ImportItemButton({
    super.key,
    required this.onPressed,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (expanded) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: const Icon(Icons.file_download_rounded),
          label: const Text('Importar objeto'),
        ),
      );
    }

    return IconButton(
      tooltip: 'Importar objeto',
      onPressed: onPressed,
      icon: const Icon(Icons.file_download_rounded),
    );
  }
}
