import 'package:flutter/material.dart';

import '../../models/item.dart';

import '../../utils/number_format.dart';

import '../../theme/item_type_colors.dart';

import 'item_image.dart';

class ItemGridCard extends StatelessWidget {
  final InventoryItem inventoryItem;

  final ItemDefinition definition;

  final VoidCallback onTap;

  const ItemGridCard({
    super.key,
    required this.inventoryItem,
    required this.definition,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = ItemTypeColors.of(context, definition.type);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ItemImage(definition: definition, size: double.infinity),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 58,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0),
                        Theme.of(
                          context,
                        ).colorScheme.scrim.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.scrim.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '×${formatThousands(inventoryItem.quantity)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

            if (inventoryItem.equipped)
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onInverseSurface,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
