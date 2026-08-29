import 'package:flutter/material.dart';

import '../../../models/character_effect.dart';

import '../../forms/common/form_empty_state.dart';

class PassiveLinkedEffectsSection extends StatelessWidget {
  final List<CharacterEffect> effects;

  final ValueChanged<int> onEdit;

  final ValueChanged<int> onDelete;

  const PassiveLinkedEffectsSection({
    super.key,
    required this.effects,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) {
      return const FormEmptyState(
        icon: Icons.auto_awesome_rounded,
        text: 'Esta pasiva no tiene efectos vinculados.',
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < effects.length; i++) ...[
            PassiveLinkedEffectTile(
              effect: effects[i],

              onEdit: () {
                onEdit(i);
              },

              onDelete: () {
                onDelete(i);
              },
            ),

            if (i < effects.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class PassiveLinkedEffectTile extends StatelessWidget {
  final CharacterEffect effect;

  final VoidCallback onEdit;

  final VoidCallback onDelete;

  const PassiveLinkedEffectTile({
    super.key,
    required this.effect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onEdit,

      leading: CircleAvatar(child: Icon(_iconForType(effect.type))),

      title: Text(
        effect.name.trim().isNotEmpty ? effect.name : 'Efecto sin nombre',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),

      subtitle: Text(_subtitle(effect)),

      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Editar',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
          ),

          IconButton(
            tooltip: 'Eliminar',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  static IconData _iconForType(CharacterEffectType type) {
    switch (type) {
      case CharacterEffectType.buff:
        return Icons.trending_up_rounded;

      case CharacterEffectType.debuff:
        return Icons.trending_down_rounded;

      case CharacterEffectType.condition:
        return Icons.warning_amber_rounded;

      case CharacterEffectType.neutral:
        return Icons.auto_awesome_rounded;
    }
  }

  static String _subtitle(CharacterEffect effect) {
    final pieces = <String>[];

    final description = effect.description.trim();

    if (description.isNotEmpty) {
      pieces.add(description);
    }

    pieces.add(effect.durationText);

    return pieces.join(' · ');
  }
}
