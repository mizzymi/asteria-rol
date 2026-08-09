import 'package:flutter/material.dart';

import '../../../models/ability.dart';
import '../../../models/skill.dart';

class AbilityGeneralSection extends StatelessWidget {
  final TextEditingController nameController;

  final TextEditingController descriptionController;

  final AbilityActionType actionType;
  final AbilityType abilityType;

  final ValueChanged<AbilityActionType> onActionTypeChanged;

  final ValueChanged<AbilityType> onAbilityTypeChanged;

  const AbilityGeneralSection({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.actionType,
    required this.abilityType,
    required this.onActionTypeChanged,
    required this.onAbilityTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.auto_awesome_rounded,
          title: 'Información general',
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            prefixIcon: Icon(Icons.auto_awesome_rounded),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Introduce un nombre';
            }

            return null;
          },
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller: descriptionController,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            alignLabelWithHint: true,
          ),
        ),

        const SizedBox(height: 14),

        DropdownButtonFormField<AbilityActionType>(
          initialValue: actionType,
          decoration: const InputDecoration(
            labelText: 'Tipo de acción',
            prefixIcon: Icon(Icons.bolt_rounded),
          ),
          items: AbilityActionType.values.map((type) {
            return DropdownMenuItem(value: type, child: Text(type.label));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onActionTypeChanged(value);
            }
          },
        ),

        const SizedBox(height: 14),

        DropdownButtonFormField<AbilityType>(
          initialValue: abilityType,
          decoration: const InputDecoration(
            labelText: 'Atributo usado',
            helperText: 'Se usa para ataque, modificadores y CD',
            prefixIcon: Icon(Icons.psychology_rounded),
          ),
          items: AbilityType.values.map((ability) {
            return DropdownMenuItem(value: ability, child: Text(ability.label));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onAbilityTypeChanged(value);
            }
          },
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),

        const SizedBox(width: 8),

        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
