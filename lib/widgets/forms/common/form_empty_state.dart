import 'package:flutter/material.dart';

class FormEmptyState extends StatelessWidget {
  final String text;

  final IconData icon;

  const FormEmptyState({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),

          const SizedBox(width: 12),

          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
