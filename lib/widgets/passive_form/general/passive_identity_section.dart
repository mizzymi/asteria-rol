import 'package:flutter/material.dart';

import '../../../models/passive.dart';
import '../../abilities/ability_image_selector.dart';

class PassiveIdentitySection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  final String? imagePath;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveImage;
  final VoidCallback? onAdjustImageFraming;
  final double imageAlignmentX;
  final double imageAlignmentY;

  final PassiveSourceType sourceType;

  final bool enabled;

  final ValueChanged<PassiveSourceType> onSourceTypeChanged;
  final ValueChanged<bool> onEnabledChanged;

  const PassiveIdentitySection({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.imagePath,
    required this.onPickImage,
    this.onRemoveImage,
    this.onAdjustImageFraming,
    this.imageAlignmentX = 0,
    this.imageAlignmentY = 0,
    required this.sourceType,
    required this.enabled,
    required this.onSourceTypeChanged,
    required this.onEnabledChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Información general',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 16),

            AbilityImageSelector(
              imagePath: imagePath,
              onPick: onPickImage,
              onRemove: onRemoveImage,
              onAdjustFraming: onAdjustImageFraming,
              alignmentX: imageAlignmentX,
              alignmentY: imageAlignmentY,
              fallbackIcon: Icons.auto_awesome_rounded,
              label: 'Añadir imagen',
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
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<PassiveSourceType>(
              initialValue: sourceType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Origen',
                prefixIcon: Icon(Icons.category_rounded),
              ),
              items: PassiveSourceType.values.map((source) {
                return DropdownMenuItem(
                  value: source,
                  child: Text(source.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                onSourceTypeChanged(value);
              },
            ),

            const SizedBox(height: 8),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: enabled,
              secondary: Icon(
                enabled
                    ? Icons.check_circle_rounded
                    : Icons.pause_circle_outline_rounded,
              ),
              title: const Text(
                'Pasiva activa',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                enabled
                    ? 'Sus bonificaciones y triggers están activos.'
                    : 'La pasiva se conserva, pero no aplica sus efectos.',
              ),
              onChanged: onEnabledChanged,
            ),
          ],
        ),
      ),
    );
  }
}
