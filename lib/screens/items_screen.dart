import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/skill.dart';
import '../models/character.dart';
import '../models/item.dart';
import '../models/ability.dart';

import '../services/character_storage_service.dart';
import '../services/item_library_service.dart';
import '../services/action_resolution_flow.dart';

import '../utils/number_format.dart';

import '../widgets/action_resolution/result/action_resolution_result_dialog.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/section_header.dart';
import '../widgets/items/item_card.dart';
import '../widgets/items/item_grid_card.dart';
import '../widgets/items/item_extended_content.dart';
import '../widgets/items/item_image.dart';
import '../widgets/items/item_image_viewer.dart';
import '../widgets/items/item_type_colors.dart';
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

  static const String _gridViewPreferenceKey = 'items_grid_view';

  bool gridView = false;
  bool viewPreferenceLoaded = false;
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
      character.updateItem(result);

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
  Future<void> resolveWeapon(CharacterItem item) async {
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

    final flow = ActionResolutionFlow(character: character);

    try {
      final execution = await flow.resolveWeapon(context, weapon: weapon);

      if (execution == null) {
        return;
      }

      await save();

      if (!mounted) {
        return;
      }

      setState(() {});

      await showActionResolutionResultDialog(
        context,
        character: character,
        execution: execution,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se ha podido resolver el ataque: $error')),
      );
    }
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
    // El consumible reutiliza exactamente el mismo motor de resolución
    // que una habilidad normal.
    // ===========================================================================

    final consumableAbility = CharacterAbility(
      id: '${item.id}_consumable',
      name: item.name,

      abilityType: AbilityType.strength,

      targetType: AbilityTargetType.self,

      requiresAttackRoll: false,

      effects: consumable.effects
          .map((effect) => AbilityEffect.fromMap(effect.toMap()))
          .toList(),
    );

    final flow = ActionResolutionFlow(character: character);

    final execution = await flow.resolveAbility(
      context,
      ability: consumableAbility,
    );

    if (execution == null || !mounted) {
      return;
    }

    // ===========================================================================
    // CONSUMIR UNIDAD
    //
    // ActionResolutionFlow ya hizo commit de daño/curación/efectos.
    // Aquí solamente consumimos físicamente el objeto.
    // ===========================================================================

    setState(() {
      item.quantity -= 1;

      if (item.quantity <= 0) {
        character.removeItem(item.id);
      }

      character.normalizeHealth();
    });

    await save();

    if (!mounted) {
      return;
    }

    await showActionResolutionResultDialog(
      context,
      character: character,
      execution: execution,
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

  Future<void> openItemFromGrid(CharacterItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final color = ItemTypeColors.color(item.type);

        return FractionallySizedBox(
          heightFactor: 0.92,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===============================================================
                // IMAGEN
                // ===============================================================
                if (item.hasImage) ...[
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        ItemImageViewer.show(sheetContext, item);
                      },
                      child: SizedBox(
                        width: double.infinity,
                        height: 240,
                        child: ItemImage(item: item, size: double.infinity),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                ] else ...[
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Color.lerp(theme.colorScheme.surface, color, 0.12),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      ItemTypeColors.icon(item.type),
                      size: 54,
                      color: color,
                    ),
                  ),

                  const SizedBox(height: 18),
                ],

                // ===============================================================
                // NOMBRE
                // ===============================================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),

                    IconButton(
                      tooltip: 'Editar',
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        editItem(item);
                      },
                      icon: const Icon(Icons.edit_rounded),
                    ),
                  ],
                ),

                // ===============================================================
                // TIPO / CANTIDAD
                // ===============================================================
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: Icon(
                        ItemTypeColors.icon(item.type),
                        size: 17,
                        color: color,
                      ),
                      label: Text(item.type.label),
                    ),

                    Chip(
                      avatar: const Icon(Icons.layers_rounded, size: 17),
                      label: Text('×${formatThousands(item.quantity)}'),
                    ),

                    if (item.equipped)
                      const Chip(
                        avatar: Icon(Icons.check_circle_rounded, size: 17),
                        label: Text('Equipado'),
                      ),
                  ],
                ),

                // ===============================================================
                // DESCRIPCIÓN
                // ===============================================================
                if (item.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),

                  Text(item.description, style: theme.textTheme.bodyMedium),
                ],

                const SizedBox(height: 18),

                // ===============================================================
                // CONTENIDO EXTENDIDO
                // ===============================================================
                ItemExtendedContent(
                  item: item,
                  character: character,
                  padding: EdgeInsets.zero,

                  onEquip: () {
                    Navigator.pop(sheetContext);
                    toggleEquip(item);
                  },

                  onWeaponAttack: item.isWeapon && item.equipped
                      ? () {
                          Navigator.pop(sheetContext);
                          resolveWeapon(item);
                        }
                      : null,

                  onConsumableUse:
                      item.type == ItemType.consumable &&
                          item.consumable != null
                      ? () {
                          Navigator.pop(sheetContext);
                          useConsumable(item);
                        }
                      : null,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Widget buildItemGrid(List<CharacterItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var columns = 3;

        if (constraints.maxWidth < 360) {
          columns = 2;
        } else if (constraints.maxWidth >= 700) {
          columns = 4;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return ItemGridCard(
              item: item,
              onTap: () {
                openItemFromGrid(item);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _toggleViewMode() async {
    final newValue = !gridView;

    setState(() {
      gridView = newValue;
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_gridViewPreferenceKey, newValue);
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================
  @override
  void initState() {
    super.initState();

    _loadViewPreference();
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();

    final savedGridView = prefs.getBool(_gridViewPreferenceKey) ?? false;

    if (!mounted) {
      return;
    }

    setState(() {
      gridView = savedGridView;
      viewPreferenceLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final equipped = character.items.where((item) => item.equipped).toList();

    final inventory = character.items.where((item) => !item.equipped).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Objetos'),
        actions: [
          IconButton(
            tooltip: gridView ? 'Vista de lista' : 'Vista de cuadrícula',
            onPressed: _toggleViewMode,
            icon: Icon(
              gridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
          ),

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

      body: !viewPreferenceLoaded
          ? const Center(child: CircularProgressIndicator())
          : character.items.isEmpty
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

                  if (gridView)
                    buildItemGrid(equipped)
                  else
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

                        onWeaponAttack: item.isWeapon && item.equipped
                            ? () {
                                resolveWeapon(item);
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
                else if (gridView)
                  buildItemGrid(inventory)
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
