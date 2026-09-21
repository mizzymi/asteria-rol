import 'package:flutter/material.dart';

import '../../services/character_storage_service.dart';

import '../../models/knowledge_definition.dart';
import '../../models/ability.dart';
import '../../models/skill.dart';
import '../../models/character.dart';
import '../../models/item.dart';

import '../common/section_header.dart';
import '../knowledge/study_dialog.dart';
import 'item_ability_preview.dart';
import 'item_passive_preview.dart';

import '../../theme/item_type_colors.dart';

class ItemExtendedContent extends StatelessWidget {
  final InventoryItem inventoryItem;

  final ItemDefinition definition;

  final Character character;

  final VoidCallback onEquip;

  final VoidCallback? onWeaponAttack;

  final VoidCallback? onConsumableUse;

  final EdgeInsetsGeometry padding;

  const ItemExtendedContent({
    super.key,
    required this.inventoryItem,
    required this.definition,
    required this.character,
    required this.onEquip,
    this.onWeaponAttack,
    this.onConsumableUse,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = ItemTypeColors.of(context, definition.type);

    final weapon = definition.weapon;

    final armor = definition.armor;

    final consumable = definition.consumable;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),

          // ===================================================================
          // INFORMACIÓN DEL ARMA
          // ===================================================================
          if (definition.type == ItemType.weapon && weapon != null) ...[
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Color.lerp(theme.colorScheme.surface, color, 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.20)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color.lerp(theme.colorScheme.surface, color, 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.gavel_rounded, color: color),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Arma',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 8),

                        ...weapon.damages.map((damage) {
                          final parts = <String>[];

                          // ===============================================
                          // DADOS NORMALES
                          // ===============================================

                          if (damage.diceNotation.isNotEmpty) {
                            parts.add(damage.diceNotation);
                          }

                          // ===============================================
                          // MODIFICADOR DE ATRIBUTO
                          // ===============================================

                          if (damage.addAbilityModifier) {
                            parts.add(damage.abilityType.name);
                          }

                          // ===============================================
                          // BONUS FIJO
                          // ===============================================

                          if (damage.bonus != 0) {
                            parts.add(
                              damage.bonus > 0
                                  ? '+${damage.bonus}'
                                  : '${damage.bonus}',
                            );
                          }

                          final formula = parts
                              .join(' + ')
                              .replaceAll('+ -', '- ');

                          final hasCriticalDice =
                              damage.criticalDiceNotation.isNotEmpty;

                          final damageName = damage.name.trim();

                          final damageType = damage.damageType.trim();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // =========================================
                                // NOMBRE
                                // =========================================
                                if (damageName.isNotEmpty)
                                  Text(
                                    damageName,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),

                                if (damageName.isNotEmpty)
                                  const SizedBox(height: 2),

                                // =========================================
                                // DAÑO NORMAL
                                // =========================================
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.casino_rounded,
                                      size: 17,
                                      color: color,
                                    ),

                                    const SizedBox(width: 6),

                                    Expanded(
                                      child: Text(
                                        [
                                          if (formula.isNotEmpty) formula,
                                          if (damageType.isNotEmpty) damageType,
                                        ].join(' · '),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),

                                // =========================================
                                // DADOS EXTRA DE CRÍTICO
                                // =========================================
                                if (hasCriticalDice) ...[
                                  const SizedBox(height: 5),

                                  Row(
                                    children: [
                                      Icon(
                                        Icons.flash_on_rounded,
                                        size: 17,
                                        color: color,
                                      ),

                                      const SizedBox(width: 6),

                                      Expanded(
                                        child: Text(
                                          'Crítico: +${damage.criticalDiceNotation}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: color,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ===================================================================
          // ARMADURA
          // ===================================================================
          if (definition.type == ItemType.armor && armor != null) ...[
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Color.lerp(theme.colorScheme.surface, color, 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color.lerp(theme.colorScheme.surface, color, 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.shield_rounded, color: color),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Armadura ${armor.category.label.toLowerCase()}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          'CA base ${armor.baseArmorClass}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ===================================================================
          // CONSUMIBLE
          // ===================================================================
          if ((definition.type == ItemType.consumable ||
                  definition.type == ItemType.potion ||
                  definition.consumable != null) &&
              consumable != null) ...[
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Color.lerp(theme.colorScheme.surface, color, 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.20)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color.lerp(theme.colorScheme.surface, color, 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.science_rounded, color: color),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consumible',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          '${inventoryItem.quantity} '
                          '${inventoryItem.quantity == 1 ? 'unidad' : 'unidades'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),

                        if (consumable.effects.isNotEmpty) ...[
                          const SizedBox(height: 8),

                          ...consumable.effects.map((effect) {
                            final pieces = <String>[];

                            if (effect.diceNotation.isNotEmpty) {
                              pieces.add(effect.diceNotation);
                            }

                            for (final entry
                                in effect.abilityModifierMultipliers.entries) {
                              if (entry.value == 0) {
                                continue;
                              }

                              if (entry.value == 1) {
                                pieces.add(entry.key.shortLabel);
                              } else {
                                pieces.add(
                                  '${entry.value}×${entry.key.shortLabel}',
                                );
                              }
                            }

                            if (effect.effectBonus != 0) {
                              pieces.add(
                                effect.effectBonus > 0
                                    ? '+${effect.effectBonus}'
                                    : '${effect.effectBonus}',
                              );
                            }

                            final formula = pieces.isEmpty
                                ? effect.effectType.label
                                : pieces.join(' + ');

                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    effect.heals
                                        ? Icons.favorite_rounded
                                        : Icons.bolt_rounded,
                                    size: 17,
                                    color: color,
                                  ),

                                  const SizedBox(width: 6),

                                  Expanded(
                                    child: Text(
                                      effect.effectTypeName.isNotEmpty
                                          ? '$formula · ${effect.effectTypeName}'
                                          : formula,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ===================================================================
          // CALCULADORA
          // ===================================================================
          if (definition.calculable &&
              definition.calculationCosts.isNotEmpty) ...[
            const SizedBox(height: 16),

            _CalculationPreview(definition: definition, character: character),
          ],

          // ===================================================================
          // ACCIONES DEL ARMA
          // ===================================================================
          if (definition.isWeapon &&
              inventoryItem.equipped &&
              onWeaponAttack != null) ...[
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onWeaponAttack,
                icon: const Icon(Icons.sports_martial_arts_rounded),
                label: const Text('Atacar'),
              ),
            ),
          ],

          // ===================================================================
          // ACCIONES DEL CONSUMIBLE
          // ===================================================================
          if ((definition.type == ItemType.consumable ||
                  definition.type == ItemType.potion ||
                  definition.consumable != null) &&
              onConsumableUse != null) ...[
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: inventoryItem.quantity > 0 ? onConsumableUse : null,
                icon: const Icon(Icons.local_drink_rounded),
                label: Text(
                  inventoryItem.quantity <= 0
                      ? 'Agotado'
                      : consumable?.useText.trim().isNotEmpty == true
                      ? consumable!.useText
                      : 'Usar',
                ),
              ),
            ),
          ],

          if (definition.relatedKnowledgeId != null &&
              definition.relatedKnowledgeId!.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final kId = definition.relatedKnowledgeId!;
                  final kDef = KnowledgeDefinition(
                    id: kId,
                    name: definition.name,
                    description: definition.description,
                  );

                  final result = await showStudyDialog(
                    context,
                    character: character,
                    definition: kDef,
                  );

                  if (result != null) {
                    await CharacterStorageService.saveCharacter(character);
                  }
                },
                icon: const Icon(Icons.auto_stories_rounded),
                label: const Text('Leer / Estudiar'),
              ),
            ),
          ],

          // ===================================================================
          // PASIVAS
          // ===================================================================
          if (definition.passives.isNotEmpty) ...[
            const SizedBox(height: 18),

            SectionHeader(
              icon: Icons.auto_awesome_rounded,
              title: definition.passives.length == 1 ? 'Pasiva' : 'Pasivas',
              subtitle: 'Bonificaciones mientras el objeto esté equipado',
            ),

            const SizedBox(height: 10),

            ...definition.passives.map(
              (passive) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ItemPassivePreview(passive: passive),
              ),
            ),
          ],

          // ===================================================================
          // HABILIDADES
          // ===================================================================
          if (definition.abilities.isNotEmpty) ...[
            const SizedBox(height: 18),

            SectionHeader(
              icon: Icons.flash_on_rounded,
              title: definition.abilities.length == 1
                  ? 'Habilidad'
                  : 'Habilidades',
              subtitle: 'Disponibles mientras el objeto esté equipado',
            ),

            const SizedBox(height: 10),

            ...definition.abilities.map(
              (ability) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ItemAbilityPreview(ability: ability),
              ),
            ),
          ],

          // ===================================================================
          // NOTAS
          // ===================================================================
          if (definition.notes.isNotEmpty) ...[
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),

                  const SizedBox(width: 8),

                  Expanded(child: Text(definition.notes)),
                ],
              ),
            ),
          ],

          // ===================================================================
          // EQUIPAR
          // ===================================================================
          if (definition.type.isEquipable) ...[
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: inventoryItem.equipped
                  ? FilledButton.tonalIcon(
                      onPressed: onEquip,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Equipado · Desequipar'),
                    )
                  : FilledButton.icon(
                      onPressed: onEquip,
                      icon: const Icon(Icons.inventory_2_rounded),
                      label: const Text('Equipar'),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// CALCULADORA
// =============================================================================

class _CalculationPreview extends StatelessWidget {
  final ItemDefinition definition;

  final Character character;

  const _CalculationPreview({
    required this.definition,
    required this.character,
  });

  // ===========================================================================
  // DEFINICIÓN DEL OBJETO DE COSTE
  // ===========================================================================

  ItemDefinition? _findDefinition(String itemId) {
    return character.itemDefinitionById(itemId);
  }

  // ===========================================================================
  // CANTIDAD DISPONIBLE
  //
  // Sumamos todas las instancias del mismo ItemDefinition.
  // ===========================================================================
  int _available(String itemId) {
    var total = 0;

    for (final inventory in character.inventoryItems) {
      if (inventory.itemId != itemId) {
        continue;
      }

      total += inventory.quantity;
    }

    return total;
  }

  // ===========================================================================
  // MÁXIMO CALCULABLE
  // ===========================================================================

  int get maximum {
    int? result;

    for (final cost in definition.calculationCosts) {
      if (cost.quantityPerUnit <= 0) {
        continue;
      }

      final available = _available(cost.itemId);

      final possible = available ~/ cost.quantityPerUnit;

      if (result == null || possible < result) {
        result = possible;
      }
    }

    return result ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = ItemTypeColors.of(context, definition.type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color.lerp(theme.colorScheme.surface, color, 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color.lerp(theme.colorScheme.surface, color, 0.20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calculate_rounded, color: color),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calculadora',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Coste por unidad',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ...definition.calculationCosts.map((cost) {
            final costDefinition = _findDefinition(cost.itemId);

            final available = _available(cost.itemId);

            final enough = available >= cost.quantityPerUnit;

            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, size: 18),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          costDefinition?.name ?? 'Objeto no disponible',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),

                        Text(
                          'Tienes $available',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: enough
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '×${cost.quantityPerUnit}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            );
          }),

          const Divider(height: 24),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Puedes obtener',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      '$maximum '
                      '${maximum == 1 ? 'unidad' : 'unidades'}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                maximum > 0 ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: maximum > 0 ? color : theme.colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
