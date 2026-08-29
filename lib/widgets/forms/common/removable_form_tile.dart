import 'package:flutter/material.dart';

class RemovableFormTile extends StatelessWidget {
  final String title;
  final String? subtitle;

  final IconData icon;

  final VoidCallback? onTap;

  final VoidCallback onDelete;

  const RemovableFormTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onDelete,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,

      onTap: onTap,

      leading: CircleAvatar(child: Icon(icon, size: 19)),

      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),

      subtitle: subtitle == null ? null : Text(subtitle!),

      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onTap != null) const Icon(Icons.edit_rounded, size: 18),

          const SizedBox(width: 4),

          IconButton(
            tooltip: 'Eliminar',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}
