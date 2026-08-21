import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rol/models/ability_effect_part.dart';

import 'dart:convert';

import '../models/skill.dart';
import '../models/character.dart';
import '../models/item.dart';
import '../models/ability.dart';
import '../models/dice_pool.dart';
import '../models/healing_bonus_result.dart';
import '../models/damage_bonus_result.dart';

import '../services/character_storage_service.dart';
import '../services/item_library_service.dart';

import '../widgets/weapons/weapon_damage_result_dialog.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/section_header.dart';

import '../widgets/items/item_card.dart';
import '../services/item_import_export_service.dart';
import 'item_library_screen.dart';
import 'item_form_screen.dart';

class ItemsScreen extends StatefulWidget {
  final Character character;

  const ItemsScreen({super.key, required this.character});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  Character get character => widget.character;

  // ===========================================================================
  // GUARDAR
  // ===========================================================================

  Future<void> save() async {
    character.normalizeHealth();

    await CharacterStorageService.saveCharacter(character);
  }

  // ===========================================================================
  // CREAR
  // ===========================================================================

  Future<void> createItem() async {
    final result = await Navigator.push<CharacterItem>(
      context,
      MaterialPageRoute(builder: (_) => const ItemFormScreen()),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _addOrStackItem(result);

      character.normalizeHealth();
    });

    await save();
  }

  // ===========================================================================
  // STACK / CANTIDADES
  // ===========================================================================

  String _itemStackKey(CharacterItem item) {
    final map = Map<String, dynamic>.from(item.toMap());

    /*
   * Campos que NO determinan si dos objetos
   * son el mismo tipo de objeto.
   */
    map.remove('id');
    map.remove('quantity');
    map.remove('equipped');
    map.remove('imagePath');

    /*
   * Los IDs de pasivas/habilidades cambian
   * cuando hacemos copias desde la biblioteca,
   * así que también los ignoramos.
   */
    void cleanIds(dynamic value) {
      if (value is Map) {
        value.remove('id');

        for (final child in value.values) {
          cleanIds(child);
        }
      } else if (value is List) {
        for (final child in value) {
          cleanIds(child);
        }
      }
    }

    cleanIds(map);

    return jsonEncode(map);
  }

  bool _sameStackableItem(CharacterItem a, CharacterItem b) {
    return _itemStackKey(a) == _itemStackKey(b);
  }

  // ===========================================================================
  // EDITAR
  // ===========================================================================

  Future<void> editItem(CharacterItem item) async {
    final result = await Navigator.push<CharacterItem>(
      context,
      MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)),
    );

    if (result == null) {
      return;
    }

    final index = character.items.indexWhere((value) => value.id == result.id);

    if (index < 0) {
      return;
    }

    setState(() {
      character.items[index] = result;

      /*
       * Si sigue equipado, volvemos a aplicar
       * la lógica de equipamiento por si cambió
       * el tipo o el slot.
       */
      if (result.equipped) {
        character.equipItem(result);
      }

      character.normalizeHealth();
    });

    await save();
  }

  // ===========================================================================
  // ELIMINAR
  // ===========================================================================

  Future<void> deleteItem(CharacterItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar objeto'),
          content: Text('¿Quieres eliminar "${item.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      character.removeItem(item.id);

      character.normalizeHealth();
    });

    await save();
  }

  // ===========================================================================
  // EQUIPAR / DESEQUIPAR
  // ===========================================================================

  Future<void> toggleEquip(CharacterItem item) async {
    setState(() {
      // =======================================================================
      // DESEQUIPAR
      // =======================================================================

      if (item.equipped) {
        character.unequipItem(item);

        item.equipped = false;
        item.quantity = 1;

        /*
       * Al volver al inventario se fusionará
       * con otra pila del mismo objeto.
       */
        _mergeInventoryStacks();

        character.normalizeHealth();

        return;
      }

      // =======================================================================
      // EQUIPAR
      // =======================================================================

      /*
     * Si tenemos varias unidades:
     *
     * Espada x4
     *
     * se convierte en:
     *
     * Inventario → Espada x3
     * Equipado   → Espada x1
     */
      if (item.quantity > 1) {
        item.quantity -= 1;

        final equippedCopy = CharacterItem.fromMap(item.toMap());

        equippedCopy.id = DateTime.now().microsecondsSinceEpoch.toString();

        equippedCopy.quantity = 1;
        equippedCopy.equipped = false;

        /*
       * Regeneramos también IDs internos.
       */
        for (var i = 0; i < equippedCopy.passives.length; i++) {
          equippedCopy.passives[i].id = '${equippedCopy.id}_passive_$i';
        }

        for (var i = 0; i < equippedCopy.abilities.length; i++) {
          equippedCopy.abilities[i].id = '${equippedCopy.id}_ability_$i';
        }

        character.addItem(equippedCopy);

        character.equipItem(equippedCopy);
      } else {
        /*
       * Solo hay una unidad:
       * simplemente equipamos esa misma.
       */
        item.quantity = 1;

        character.equipItem(item);
      }

      /*
     * Si equipItem ha desequipado automáticamente
     * otro objeto por ocupar un slot exclusivo,
     * lo fusionamos con su pila del inventario.
     */
      _mergeInventoryStacks();

      character.normalizeHealth();
    });

    await save();
  }

  // ===========================================================================
  // DAÑO DE ARMA
  // ===========================================================================

  Future<void> rollWeaponDamage(
    CharacterItem item, {
    bool critical = false,
  }) async {
    final weapon = item.weapon;

    if (weapon == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este objeto no tiene un arma configurada.'),
        ),
      );

      return;
    }

    final result = character.rollWeaponDamage(weapon, critical: critical);

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return WeaponDamageResultDialog(
          character: character,
          weapon: weapon,
          result: result,

          onReroll: () {
            Navigator.of(dialogContext).pop();

            rollWeaponDamage(item, critical: critical);
          },
        );
      },
    );
  }

  Future<void> editItemQuantityQuick(CharacterItem item) async {
    final baseValue = item.quantity;

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return _ItemQuantityCalculatorDialog(
          itemName: item.name,
          baseValue: baseValue,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      item.quantity = result;

      if (item.quantity <= 0) {
        character.removeItem(item.id);
      }
    });

    await save();
  }

  Future<void> rollWeaponAttack(CharacterItem item) async {
    final weapon = item.weapon;

    if (weapon == null) {
      return;
    }

    final mode = await showModalBottomSheet<_WeaponAttackMode>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tirada de ataque',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),

                const SizedBox(height: 16),

                ListTile(
                  leading: const Icon(Icons.casino_rounded),
                  title: const Text('Normal'),
                  onTap: () {
                    Navigator.pop(sheetContext, _WeaponAttackMode.normal);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.trending_up_rounded),
                  title: const Text('Ventaja'),
                  subtitle: const Text('Tira 2d20 y usa el mayor'),
                  onTap: () {
                    Navigator.pop(sheetContext, _WeaponAttackMode.advantage);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.trending_down_rounded),
                  title: const Text('Desventaja'),
                  subtitle: const Text('Tira 2d20 y usa el menor'),
                  onTap: () {
                    Navigator.pop(sheetContext, _WeaponAttackMode.disadvantage);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (mode == null || !mounted) {
      return;
    }

    _performWeaponAttackRoll(item, mode);
  }

  Future<void> _performWeaponAttackRoll(
    CharacterItem item,
    _WeaponAttackMode mode,
  ) async {
    final weapon = item.weapon;

    if (weapon == null) {
      return;
    }

    final random = Random();

    final firstRoll = random.nextInt(20) + 1;

    int? secondRoll;

    int naturalRoll;

    switch (mode) {
      case _WeaponAttackMode.normal:
        naturalRoll = firstRoll;
        break;

      case _WeaponAttackMode.advantage:
        secondRoll = random.nextInt(20) + 1;

        naturalRoll = max(firstRoll, secondRoll);
        break;

      case _WeaponAttackMode.disadvantage:
        secondRoll = random.nextInt(20) + 1;

        naturalRoll = min(firstRoll, secondRoll);
        break;
    }

    final bonus = character.attackBonus(weapon);

    final total = naturalRoll + bonus;

    final critical = naturalRoll == 20;

    final criticalFail = naturalRoll == 1;

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                critical
                    ? Icons.local_fire_department_rounded
                    : criticalFail
                    ? Icons.warning_rounded
                    : Icons.gps_fixed_rounded,
              ),

              const SizedBox(width: 10),

              Expanded(child: Text(weapon.name)),
            ],
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mode != _WeaponAttackMode.normal)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        mode == _WeaponAttackMode.advantage
                            ? 'Ventaja'
                            : 'Desventaja',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        '$firstRoll  /  $secondRoll',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

              Text('d20', style: Theme.of(context).textTheme.bodySmall),

              const SizedBox(height: 4),

              Text(
                '$naturalRoll',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bonificador '),

                  Text(
                    bonus >= 0 ? '+$bonus' : '$bonus',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              const Divider(),

              const SizedBox(height: 8),

              Text('TOTAL', style: Theme.of(context).textTheme.labelLarge),

              Text(
                '$total',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),

              if (critical) ...[
                const SizedBox(height: 8),

                const Text(
                  '💥 CRÍTICO',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ],

              if (criticalFail) ...[
                const SizedBox(height: 8),

                const Text(
                  '💀 PIFIA',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ],
          ),

          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);

                _performWeaponAttackRoll(item, mode);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Volver a atacar'),
            ),

            if (!criticalFail)
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);

                  rollWeaponDamage(item, critical: critical);
                },
                icon: Icon(
                  critical
                      ? Icons.local_fire_department_rounded
                      : Icons.casino_rounded,
                ),
                label: Text(critical ? 'Daño crítico' : 'Tirar daño'),
              ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // USAR CONSUMIBLE
  // ===========================================================================

  Future<void> useConsumable(CharacterItem item) async {
    final consumable = item.consumable;

    if (consumable == null) {
      return;
    }

    if (item.quantity <= 0) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No quedan unidades de este consumible.')),
      );

      return;
    }

    if (consumable.effects.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este consumible no tiene efectos configurados.'),
        ),
      );

      return;
    }

    // ===========================================================================
    // HABILIDAD TEMPORAL
    //
    // Los consumibles reutilizan el mismo sistema de efectos
    // que las habilidades.
    // ===========================================================================

    final consumableAbility = CharacterAbility(
      id: '${item.id}_consumable',
      name: item.name,
      abilityType: AbilityType.strength,
    );

    // ===========================================================================
    // TIRAR EFECTOS Y SUS COMPONENTES
    // ===========================================================================

    final rolledEffects = <_ConsumableRolledEffect>[];

    for (final effect in consumable.effects) {
      if (!effect.hasEffect) {
        continue;
      }

      final rolledParts = <_ConsumableRolledPart>[];

      for (final part in effect.parts) {
        if (!part.hasValue) {
          continue;
        }

        final result = character.rollAbilityEffectPart(
          consumableAbility,
          effect,
          part,
          critical: false,
        );

        rolledParts.add(_ConsumableRolledPart(part: part, result: result));
      }

      if (rolledParts.isEmpty) {
        continue;
      }

      rolledEffects.add(
        _ConsumableRolledEffect(effect: effect, parts: rolledParts),
      );
    }

    if (rolledEffects.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este consumible no tiene efectos utilizables.'),
        ),
      );

      return;
    }

    // ===========================================================================
    // TOTALES BASE
    // ===========================================================================

    int totalHealing = 0;
    int totalDamage = 0;

    for (final rolled in rolledEffects) {
      final effectTotal = rolled.total;

      if (rolled.effect.heals) {
        totalHealing += effectTotal;
      }

      if (rolled.effect.dealsDamage) {
        totalDamage += effectTotal;
      }
    }

    // ===========================================================================
    // BONOS GLOBALES DE CURACIÓN
    // ===========================================================================

    final healingBonuses = <HealingBonusResult>[];

    if (totalHealing > 0) {
      healingBonuses.addAll(character.rollActiveHealingBonuses());

      totalHealing += healingBonuses.fold<int>(
        0,
        (sum, result) => sum + result.total,
      );
    }

    // ===========================================================================
    // BONOS GLOBALES DE DAÑO
    // ===========================================================================

    final damageBonuses = <DamageBonusResult>[];

    if (totalDamage > 0) {
      damageBonuses.addAll(character.rollActiveDamageBonuses());

      totalDamage += damageBonuses.fold<int>(
        0,
        (sum, result) => sum + result.total,
      );
    }

    if (!mounted) {
      return;
    }

    // ===========================================================================
    // DIÁLOGO
    // ===========================================================================

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.science_rounded),

              const SizedBox(width: 10),

              Expanded(child: Text(item.name)),
            ],
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===============================================================
                // EFECTOS
                // ===============================================================
                ...rolledEffects.map((rolled) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===================================================
                          // NOMBRE DEL EFECTO
                          // ===================================================
                          Row(
                            children: [
                              Icon(
                                rolled.effect.heals
                                    ? Icons.favorite_rounded
                                    : rolled.effect.dealsDamage
                                    ? Icons.flash_on_rounded
                                    : Icons.auto_awesome_rounded,
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: Text(
                                  rolled.effect.name.trim().isNotEmpty
                                      ? rolled.effect.name
                                      : rolled.effect.effectType.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),

                              if (rolled.parts.length > 1)
                                Text(
                                  '${rolled.total}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // ===================================================
                          // COMPONENTES
                          // ===================================================
                          ...rolled.parts.map((rolledPart) {
                            final part = rolledPart.part;

                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 7),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          part.typeName.trim().isNotEmpty
                                              ? part.typeName
                                              : rolled.effect.effectType.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),

                                        if (part.diceNotation.isNotEmpty)
                                          Text(
                                            part.diceNotation,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  Text(
                                    '${rolledPart.result.total}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }),

                // ===============================================================
                // BONOS DE CURACIÓN
                // ===============================================================
                if (healingBonuses.isNotEmpty) ...[
                  const Divider(),

                  const Text(
                    'Bonos de curación',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 8),

                  ...healingBonuses.map(
                    (result) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.favorite_border_rounded),
                      title: Text(
                        result.bonus.name.trim().isNotEmpty
                            ? result.bonus.name
                            : 'Bonus de curación',
                      ),
                      trailing: Text(
                        '+${result.total}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],

                // ===============================================================
                // BONOS DE DAÑO
                // ===============================================================
                if (damageBonuses.isNotEmpty) ...[
                  const Divider(),

                  const Text(
                    'Bonos de daño',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 8),

                  ...damageBonuses.map(
                    (result) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bolt_rounded),
                      title: Text(
                        result.bonus.name.trim().isNotEmpty
                            ? result.bonus.name
                            : 'Bonus de daño',
                      ),
                      trailing: Text(
                        '+${result.total}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],

                // ===============================================================
                // TOTALES
                // ===============================================================
                const Divider(),

                if (totalHealing > 0)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.favorite_rounded),
                    title: const Text('Curación total'),
                    trailing: Text(
                      '$totalHealing',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                if (totalDamage > 0)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.flash_on_rounded),
                    title: const Text('Daño total'),
                    trailing: Text(
                      '$totalDamage',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                Text('Cantidad restante después de usar: ${item.quantity - 1}'),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(
                consumable.useText.trim().isEmpty ? 'Usar' : consumable.useText,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    // ===========================================================================
    // APLICAR CONSUMIBLE
    // ===========================================================================

    setState(() {
      if (totalHealing > 0) {
        character.heal(totalHealing);
      }

      item.quantity -= 1;

      // =========================================================================
      // CONSUMIBLE AGOTADO
      // =========================================================================

      if (item.quantity <= 0) {
        character.removeItem(item.id);
      }

      character.normalizeHealth();
    });

    await save();
  }

  // ===========================================================================
  // IMPORTAR / EXPORTAR
  // ===========================================================================

  Future<void> saveItemToLibrary(CharacterItem item) async {
    try {
      await ItemLibraryService.addItem(item);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} guardado en la biblioteca.'),
          action: SnackBarAction(
            label: 'Abrir',
            onPressed: () {
              openLibrary();
            },
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha podido guardar el objeto en la biblioteca.'),
        ),
      );
    }
  }

  Future<void> importItem() async {
    try {
      final item = await ItemImportExportService.pickAndImportItem();

      if (item == null || !mounted) {
        return;
      }

      /*
     * Antes de añadirlo podemos mostrar
     * una confirmación rápida.
     */
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Importar objeto'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),

                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 8),

                  Text(item.description),
                ],

                const SizedBox(height: 12),

                Text(item.type.label),

                if (item.passives.isNotEmpty)
                  Text('${item.passives.length} pasivas'),

                if (item.abilities.isNotEmpty)
                  Text('${item.abilities.length} habilidades'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Cancelar'),
              ),

              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                icon: const Icon(Icons.inventory_2_rounded),
                label: const Text('Añadir'),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) {
        return;
      }

      setState(() {
        _addOrStackItem(item);

        character.normalizeHealth();
      });

      await save();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} añadido al inventario.')),
      );
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido importar el objeto.')),
      );
    }
  }

  Future<void> exportItem(CharacterItem item) async {
    try {
      await ItemImportExportService.shareItem(item);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido compartir el objeto.')),
      );
    }
  }

  Future<void> openLibrary() async {
    final item = await Navigator.push<CharacterItem>(
      context,
      MaterialPageRoute(
        builder: (_) => const ItemLibraryScreen(mode: ItemLibraryMode.select),
      ),
    );

    if (item == null || !mounted) {
      return;
    }

    setState(() {
      _addOrStackItem(item);

      character.normalizeHealth();
    });

    await save();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} añadido al inventario.')),
    );
  }

  void _addOrStackItem(CharacterItem item) {
    /*
   * Un objeto equipado siempre debe existir
   * como una unidad independiente.
   */
    if (item.equipped) {
      item.quantity = 1;

      character.addItem(item);

      character.equipItem(item);

      return;
    }

    /*
   * Buscamos únicamente entre objetos
   * NO equipados.
   */
    final existingIndex = character.items.indexWhere(
      (existing) => !existing.equipped && _sameStackableItem(existing, item),
    );

    if (existingIndex >= 0) {
      character.items[existingIndex].quantity += item.quantity;
    } else {
      character.addItem(item);
    }
  }

  void _mergeInventoryStacks() {
    final inventory = character.items.where((item) => !item.equipped).toList();

    final processed = <CharacterItem>[];

    for (final item in inventory) {
      CharacterItem? existing;

      for (final candidate in processed) {
        if (_sameStackableItem(candidate, item)) {
          existing = candidate;
          break;
        }
      }

      if (existing == null) {
        processed.add(item);
        continue;
      }

      existing.quantity += item.quantity;

      character.removeItem(item.id);
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final equipped = character.items.where((item) => item.equipped).toList();

    final inventory = character.items.where((item) => !item.equipped).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Objetos'),
        actions: [
          IconButton(
            tooltip: 'Importar objeto',
            onPressed: importItem,
            icon: const Icon(Icons.file_download_rounded),
          ),

          IconButton(
            tooltip: 'Biblioteca',
            onPressed: openLibrary,
            icon: const Icon(Icons.local_library_rounded),
          ),
        ],
      ),

      body: character.items.isEmpty
          ? EmptyState(
              icon: Icons.inventory_2_rounded,
              title: 'Inventario vacío',
              message:
                  'Añade armaduras, accesorios, armas, consumibles y otros objetos.',
              actionLabel: 'Crear objeto',
              onAction: createItem,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
              children: [
                // =============================================================
                // EQUIPADOS
                // =============================================================
                if (equipped.isNotEmpty) ...[
                  SectionHeader(
                    icon: Icons.check_circle_rounded,
                    title: 'Equipados',
                    subtitle:
                        '${equipped.length} ${equipped.length == 1 ? 'objeto equipado' : 'objetos equipados'}',
                  ),

                  const SizedBox(height: 14),

                  ...equipped.map(
                    (item) => ItemCard(
                      item: item,

                      character: character,

                      onEquip: () {
                        toggleEquip(item);
                      },

                      onEdit: () {
                        editItem(item);
                      },

                      onDelete: () {
                        deleteItem(item);
                      },

                      onExport: () {
                        exportItem(item);
                      },

                      onSaveToLibrary: () {
                        saveItemToLibrary(item);
                      },

                      onQuickQuantityEdit: item.calculable
                          ? () {
                              editItemQuantityQuick(item);
                            }
                          : null,

                      // =========================================================
                      // ARMA
                      // =========================================================
                      onWeaponAttack: item.isWeapon
                          ? () {
                              rollWeaponAttack(item);
                            }
                          : null,

                      onWeaponDamage: item.isWeapon
                          ? () {
                              rollWeaponDamage(item);
                            }
                          : null,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],

                // =============================================================
                // INVENTARIO
                // =============================================================
                SectionHeader(
                  icon: Icons.backpack_rounded,
                  title: 'Inventario',
                  subtitle: inventory.isEmpty
                      ? 'No hay objetos sin equipar'
                      : '${inventory.length} ${inventory.length == 1 ? 'objeto disponible' : 'objetos disponibles'}',
                ),

                const SizedBox(height: 14),

                if (inventory.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 34,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Todos tus objetos equipables están equipados.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  )
                else
                  ...inventory.map(
                    (item) => ItemCard(
                      item: item,

                      character: character,

                      onEquip: () {
                        toggleEquip(item);
                      },

                      onEdit: () {
                        editItem(item);
                      },

                      onDelete: () {
                        deleteItem(item);
                      },

                      onExport: () {
                        exportItem(item);
                      },

                      onSaveToLibrary: () {
                        saveItemToLibrary(item);
                      },

                      onQuickQuantityEdit: item.calculable
                          ? () {
                              editItemQuantityQuick(item);
                            }
                          : null,

                      onConsumableUse:
                          item.type == ItemType.consumable &&
                              item.consumable != null
                          ? () {
                              useConsumable(item);
                            }
                          : null,
                    ),
                  ),
              ],
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: createItem,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo objeto'),
      ),
    );
  }
}

enum _WeaponAttackMode { normal, advantage, disadvantage }

class _ConsumableRolledPart {
  final AbilityEffectPart part;

  final DiceCalculationResult result;

  const _ConsumableRolledPart({required this.part, required this.result});
}

class _ConsumableRolledEffect {
  final AbilityEffect effect;

  final List<_ConsumableRolledPart> parts;

  const _ConsumableRolledEffect({required this.effect, required this.parts});

  int get total {
    return parts.fold<int>(0, (sum, part) => sum + part.result.total);
  }
}

class _ItemQuantityCalculatorDialog extends StatefulWidget {
  final String itemName;
  final int baseValue;

  const _ItemQuantityCalculatorDialog({
    required this.itemName,
    required this.baseValue,
  });

  @override
  State<_ItemQuantityCalculatorDialog> createState() =>
      _ItemQuantityCalculatorDialogState();
}

class _ItemQuantityCalculatorDialogState
    extends State<_ItemQuantityCalculatorDialog> {
  late final TextEditingController valueController;

  String operation = '+';

  @override
  void initState() {
    super.initState();

    valueController = TextEditingController();
  }

  @override
  void dispose() {
    valueController.dispose();

    super.dispose();
  }

  int get secondValue {
    return int.tryParse(valueController.text.trim()) ?? 0;
  }

  int get calculated {
    switch (operation) {
      case '+':
        return widget.baseValue + secondValue;

      case '-':
        return max(0, widget.baseValue - secondValue);

      case '×':
        return widget.baseValue * secondValue;

      case '÷':
        if (secondValue <= 0) {
          return widget.baseValue;
        }

        return widget.baseValue ~/ secondValue;

      default:
        return widget.baseValue;
    }
  }

  String get operationLabel {
    switch (operation) {
      case '+':
        return 'sumar';

      case '-':
        return 'restar';

      case '×':
        return 'multiplicar';

      case '÷':
        return 'dividir';

      default:
        return 'usar';
    }
  }

  void setQuickValue(int value) {
    setState(() {
      valueController.text = '$value';

      valueController.selection = TextSelection.collapsed(
        offset: valueController.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.calculate_rounded),

          const SizedBox(width: 10),

          Expanded(child: Text(widget.itemName)),
        ],
      ),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cantidad actual',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 4),

            Text(
              '${widget.baseValue}',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                for (final op in const ['+', '-', '×', '÷'])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: operation == op
                          ? FilledButton(
                              onPressed: () {
                                setState(() {
                                  operation = op;
                                });
                              },
                              child: Text(op),
                            )
                          : OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  operation = op;
                                });
                              },
                              child: Text(op),
                            ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: valueController,

              autofocus: true,

              keyboardType: TextInputType.number,

              textAlign: TextAlign.center,

              decoration: InputDecoration(
                labelText: 'Cantidad a $operationLabel',

                prefixIcon: const Icon(Icons.functions_rounded),
              ),

              onChanged: (_) {
                setState(() {});
              },
            ),

            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Resultado',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '$calculated',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '${widget.baseValue} '
                    '$operation '
                    '${valueController.text.trim().isEmpty ? '0' : valueController.text.trim()}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in const [1, 10, 100, 1000])
                  OutlinedButton(
                    onPressed: () {
                      setQuickValue(value);
                    },
                    child: Text('$value'),
                  ),
              ],
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),

        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop(calculated);
          },
          icon: const Icon(Icons.check_rounded),
          label: const Text('Aplicar'),
        ),
      ],
    );
  }
}