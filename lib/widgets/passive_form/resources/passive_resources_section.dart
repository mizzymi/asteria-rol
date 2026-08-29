import 'package:flutter/material.dart';

import '../../../models/character.dart';
import '../../../models/passive_resource_modifier.dart';

import '../../forms/common/form_empty_state.dart';
import '../../forms/common/removable_form_tile.dart';

class PassiveResourcesSection extends StatelessWidget {
  final Character? character;

  final List<PassiveResourceModifier> modifiers;

  final String Function(PassiveResourceModifier modifier) textBuilder;

  final VoidCallback onAdd;

  final ValueChanged<int> onEdit;

  final ValueChanged<int> onDelete;

  const PassiveResourcesSection({
    super.key,
    required this.character,
    required this.modifiers,
    required this.textBuilder,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  bool get canAdd {
    return character != null && character!.resources.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (character == null) {
      return const FormEmptyState(
        icon: Icons.info_outline_rounded,
        text: 'No hay un personaje disponible para configurar recursos.',
      );
    }

    if (character!.resources.isEmpty) {
      return const FormEmptyState(
        icon: Icons.account_balance_wallet_outlined,
        text: 'Este personaje no tiene recursos.',
      );
    }

    if (modifiers.isEmpty) {
      return const FormEmptyState(
        icon: Icons.account_balance_wallet_rounded,
        text: 'Esta pasiva no modifica recursos.',
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            for (var index = 0; index < modifiers.length; index++) ...[
              RemovableFormTile(
                title: textBuilder(modifiers[index]),

                icon: Icons.account_balance_wallet_rounded,

                onTap: () {
                  onEdit(index);
                },

                onDelete: () {
                  onDelete(index);
                },
              ),

              if (index < modifiers.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}
