import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/item.dart';
import 'item_type_colors.dart';

class ItemImage extends StatelessWidget {
  final CharacterItem item;

  final double size;

  final VoidCallback? onTap;

  const ItemImage({super.key, required this.item, this.size = 58, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = ItemTypeColors.color(item.type);

    final hasImage =
        item.imagePath.isNotEmpty && File(item.imagePath).existsSync();

    final child = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ItemTypeColors.background(context, item.type, strength: 0.22),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.file(File(item.imagePath), fit: BoxFit.cover)
          : Icon(
              ItemTypeColors.icon(item.type),
              color: color,
              size: size * 0.46,
            ),
    );

    if (onTap == null) {
      return child;
    }

    return GestureDetector(
      onTap: onTap,
      child: Hero(tag: 'item-image-${item.id}', child: child),
    );
  }
}
