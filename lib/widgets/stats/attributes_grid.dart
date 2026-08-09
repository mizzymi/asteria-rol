import 'package:flutter/material.dart';

import '../../models/character.dart';
import '../../models/skill.dart';
import 'attribute_card.dart';

class AttributesGrid extends StatelessWidget {
  final Character character;

  final void Function(AbilityType ability) onEdit;

  const AttributesGrid({
    super.key,
    required this.character,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final attributes = [
      (
        type: AbilityType.strength,
        score: character.abilities.strength,
        modifier: character.strengthModifier,
      ),
      (
        type: AbilityType.dexterity,
        score: character.abilities.dexterity,
        modifier: character.dexterityModifier,
      ),
      (
        type: AbilityType.constitution,
        score: character.abilities.constitution,
        modifier: character.constitutionModifier,
      ),
      (
        type: AbilityType.intelligence,
        score: character.abilities.intelligence,
        modifier: character.intelligenceModifier,
      ),
      (
        type: AbilityType.wisdom,
        score: character.abilities.wisdom,
        modifier: character.wisdomModifier,
      ),
      (
        type: AbilityType.charisma,
        score: character.abilities.charisma,
        modifier: character.charismaModifier,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 6 : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: attributes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,

            // Más altura para evitar overflow.
            mainAxisExtent: columns == 3 ? 142 : 150,
          ),
          itemBuilder: (context, index) {
            final attribute = attributes[index];

            return AttributeCard(
              ability: attribute.type,
              score: attribute.score,
              modifier: attribute.modifier,
              onTap: () {
                onEdit(attribute.type);
              },
            );
          },
        );
      },
    );
  }
}
