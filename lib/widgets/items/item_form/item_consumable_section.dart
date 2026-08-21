import 'package:flutter/material.dart';

import '../../../models/ability.dart';
import '../../../models/character_resource.dart';

import '../../abilities/ability_form/ability_effects_section.dart';
import '../../common/section_header.dart';

class ItemConsumableSection extends StatelessWidget {
  final String useText;

  final ValueChanged<String> onUseTextChanged;

  final List<AbilityEffect> effects;

  final List<CharacterResource> resources;

  final VoidCallback onAddEffect;

  final void Function(int index, AbilityEffect effect) onEffectChanged;

  final ValueChanged<int> onRemoveEffect;

  final ValueChanged<int> onMoveUp;

  final ValueChanged<int> onMoveDown;

  const ItemConsumableSection({
    super.key,
    required this.useText,
    required this.onUseTextChanged,
    required this.effects,
    required this.resources,
    required this.onAddEffect,
    required this.onEffectChanged,
    required this.onRemoveEffect,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: useText);

    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          icon: Icons.science_rounded,
          title: 'Consumible',
          subtitle: 'Configura qué ocurre al utilizar este objeto',
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Texto del botón',
            hintText: 'Usar, Beber, Comer, Lanzar...',
            prefixIcon: Icon(Icons.touch_app_rounded),
          ),
          onChanged: onUseTextChanged,
        ),

        const SizedBox(height: 24),

        AbilityEffectsSection(
          effects: effects,

          resources: resources,

          onAddEffect: onAddEffect,

          onEffectChanged: onEffectChanged,

          onRemoveEffect: onRemoveEffect,

          onMoveUp: onMoveUp,

          onMoveDown: onMoveDown,
        ),
      ],
    );
  }
}
