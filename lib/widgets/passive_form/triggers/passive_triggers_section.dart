import 'package:flutter/material.dart';

import '../../../models/passive.dart';

import '../../forms/common/form_empty_state.dart';
import '../../forms/common/removable_form_tile.dart';

import 'passive_trigger_labels.dart';

class PassiveTriggersSection extends StatelessWidget {
  final List<PassiveTrigger> triggers;

  final VoidCallback onAdd;

  final ValueChanged<int> onEdit;

  final ValueChanged<int> onDelete;

  final String Function(PassiveTrigger trigger) subtitleBuilder;

  const PassiveTriggersSection({
    super.key,
    required this.triggers,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.subtitleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (triggers.isEmpty) {
      return const FormEmptyState(
        icon: Icons.bolt_rounded,
        text: 'Esta pasiva no tiene triggers.',
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            for (var i = 0; i < triggers.length; i++) ...[
              RemovableFormTile(
                title: triggers[i].event.label,

                subtitle: subtitleBuilder(triggers[i]),

                icon: Icons.bolt_rounded,

                onTap: () {
                  onEdit(i);
                },

                onDelete: () {
                  onDelete(i);
                },
              ),

              if (i < triggers.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}
