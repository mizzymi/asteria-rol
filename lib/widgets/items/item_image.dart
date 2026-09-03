import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/item.dart';
import '../../theme/item_type_colors.dart';

class ItemImage extends StatelessWidget {
  final ItemDefinition definition;

  /// Tamaño fijo del widget.
  ///
  /// Si recibe double.infinity, ocupará todo el espacio disponible
  /// sin propagar Infinity al Icon ni al BorderRadius.
  final double size;

  final VoidCallback? onTap;

  const ItemImage({
    super.key,
    required this.definition,
    this.size = 58,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = ItemTypeColors.of(definition.type);

    final hasImage =
        definition.imagePath.isNotEmpty &&
        File(definition.imagePath).existsSync();

    final expanded = !size.isFinite;

    Widget buildContent(double width, double height) {
      final shortestSide = width < height ? width : height;

      final safeBaseSize = shortestSide.isFinite && shortestSide > 0
          ? shortestSide
          : 58.0;

      final borderRadius = safeBaseSize * 0.20;

      final iconSize = (safeBaseSize * 0.46).clamp(24.0, 72.0);

      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: ItemTypeColors.background(
            context,
            definition.type,
            strength: 0.22,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Image.file(
                File(definition.imagePath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      ItemTypeColors.icon(definition.type),
                      color: color,
                      size: iconSize,
                    ),
                  );
                },
              )
            : Center(
                child: Icon(
                  ItemTypeColors.icon(definition.type),
                  color: color,
                  size: iconSize,
                ),
              ),
      );
    }

    Widget child;

    if (expanded) {
      child = LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 58.0;

          final height = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : width;

          return buildContent(width, height);
        },
      );
    } else {
      child = buildContent(size, size);
    }

    if (onTap == null) {
      return child;
    }

    return GestureDetector(
      onTap: onTap,
      child: Hero(tag: 'item-image-${definition.id}', child: child),
    );
  }
}
