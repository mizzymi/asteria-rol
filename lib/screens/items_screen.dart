import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/character.dart';
import '../models/ability.dart';
import '../models/item.dart';
import '../models/character_content_folder.dart';

import '../services/action_resolution_flow.dart';
import '../services/character_storage_service.dart';
import '../services/campaign_storage_service.dart';
import '../services/inventory_service.dart';
import '../services/item_import_export_service.dart';
import '../services/item_library_service.dart';

import '../theme/item_type_colors.dart';
import '../utils/number_format.dart';

import '../widgets/items/slot_selection_dialog.dart';
import '../widgets/action_resolution/result/action_resolution_result_dialog.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/section_header.dart';
import '../widgets/items/item_card.dart';
import '../widgets/items/item_extended_content.dart';
import '../widgets/items/item_grid_card.dart';
import '../widgets/items/item_image.dart';
import '../widgets/items/equipment_slots_config_dialog.dart';
import '../widgets/items/item_image_viewer.dart';

import 'item_form_screen.dart';
import 'campaign_shop_detail_screen.dart';

typedef InventoryItemView = ({
  InventoryItem inventory,
  ItemDefinition definition,
});

class ItemsScreen extends StatefulWidget {
  final Character character;

  const ItemsScreen({super.key, required this.character});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  Character get character => widget.character;

  static const String _gridViewPreferenceKey = 'items_grid_view';
  final _inventoryService = const InventoryService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  bool gridView = false;
  bool viewPreferenceLoaded = false;

  // Estado de navegación por carpetas de objetos
  String? _currentFolderId;

  CharacterContentFolder? get _currentFolder {
    return character.contentFolderById(_currentFolderId);
  }

  void _openFolder(String folderId) {
    setState(() {
      _currentFolderId = folderId;
    });
  }

  bool get _canGoBackInsideContent {
    return _currentFolderId != null;
  }

  void _goBackInsideContent() {
    final folder = _currentFolder;
    if (folder != null) {
      setState(() {
        _currentFolderId = folder.parentId;
      });
    }
  }

  String get _screenTitle {
    final folder = _currentFolder;
    if (folder != null) {
      return folder.name;
    }
    return 'Objetos';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalizeSearchText(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
  }

  Set<String> _itemFolderSearchScope() {
    final result = <String>{};

    void visit(String? parentId) {
      for (final folder in character.itemFoldersInside(parentId)) {
        if (result.add(folder.id)) {
          visit(folder.id);
        }
      }
    }

    visit(_currentFolderId);
    return result;
  }

  bool _matchesItemSearch(InventoryItemView entry, String query) {
    final inventory = entry.inventory;
    final definition = entry.definition;

    // La búsqueda de un objeto también incluye el contenido que concede:
    // habilidades activas y pasivas. Así, por ejemplo, buscar el nombre de
    // una pasiva devuelve el objeto que la contiene.
    final abilitySearchText = definition.abilities.map((ability) {
      return '${ability.name} ${ability.description} ${ability.notes} ${ability.actionType.label}';
    }).join(' ');

    final passiveSearchText = definition.passives.map((passive) {
      final triggerText = passive.triggers.map((trigger) {
        final actionText = trigger.actions
            .map((action) => action.type.name)
            .join(' ');
        return '${trigger.event.name} ${trigger.customEvent ?? ''} $actionText';
      }).join(' ');

      return '${passive.name} ${passive.description} ${passive.notes} '
          '${passive.rechargeDescription} ${passive.sourceType.name} $triggerText';
    }).join(' ');

    final haystack = _normalizeSearchText(
      '${inventory.customName ?? ''} ${inventory.notes ?? ''} '
      '${definition.name} ${definition.description} ${definition.notes} '
      '${definition.type.label} ${definition.actionDefinition?.name ?? ''} '
      '$abilitySearchText $passiveSearchText',
    );

    return haystack.contains(query);
  }

  Widget _buildSearchField() {
    final colors = Theme.of(context).colorScheme;
    final searching = _searchQuery.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: SearchBar(
        controller: _searchController,
        hintText: 'Buscar en esta carpeta y subcarpetas',
        leading: const Icon(Icons.search_rounded),
        trailing: [
          if (searching)
            IconButton(
              tooltip: 'Limpiar búsqueda',
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              icon: const Icon(Icons.close_rounded),
            ),
        ],
        onChanged: (value) => setState(() => _searchQuery = value),
        backgroundColor: WidgetStatePropertyAll(
          colors.surfaceContainerHighest.withValues(alpha: 0.55),
        ),
        elevation: const WidgetStatePropertyAll(0),
      ),
    );
  }

  // ===========================================================================
  // GUARDAR
  // ===========================================================================

  Future<void> save() async {
    character.normalizeHealth();
    await CharacterStorageService.saveCharacter(character);
  }

  // ===========================================================================
  // CREAR / GESTIÓN DE CARPETAS
  // ===========================================================================

  Future<void> _createFolder() async {
    var folderName = '';

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nueva carpeta de objetos'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.folder_rounded),
            ),
            onChanged: (value) => folderName = value,
            onSubmitted: (value) {
              final name = value.trim();
              if (name.isEmpty) return;
              Navigator.of(dialogContext).pop(name);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final name = folderName.trim();
                if (name.isEmpty) return;
                Navigator.of(dialogContext).pop(name);
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    if (result == null || result.trim().isEmpty || !mounted) return;

    setState(() {
      character.createContentFolder(
        name: result.trim(),
        parentId: _currentFolderId,
        isItemFolder: true, // <--- EXCLUSIVO PARA OBJETOS
      );
    });

    await save();
  }

  Future<void> _renameCurrentFolder() async {
    final folder = _currentFolder;
    if (folder == null) return;

    var folderName = folder.name;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Renombrar carpeta'),
          content: TextFormField(
            initialValue: folder.name,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.folder_rounded),
            ),
            onChanged: (value) => folderName = value,
            onFieldSubmitted: (value) {
              final name = value.trim();
              if (name.isEmpty) return;
              Navigator.of(dialogContext).pop(name);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final name = folderName.trim();
                if (name.isEmpty) return;
                Navigator.of(dialogContext).pop(name);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result == null || result.trim().isEmpty || !mounted) return;

    setState(() {
      character.renameContentFolder(folder.id, result.trim());
    });

    await save();
  }

  Future<void> _deleteCurrentFolder() async {
    final folder = _currentFolder;
    if (folder == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar carpeta'),
          content: Text(
            '¿Quieres eliminar "${folder.name}"? Su contenido subirá a la carpeta anterior.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final parentId = folder.parentId;
    setState(() {
      character.removeContentFolder(folder.id);
      _currentFolderId = parentId;
    });

    await save();
  }

  List<_FolderOption> _folderOptions() {
    final result = <_FolderOption>[];

    void visit(String? parentId, int depth) {
      final folders = character.itemFoldersInside(parentId);
      for (final folder in folders) {
        result.add(_FolderOption(folder: folder, depth: depth));
        visit(folder.id, depth + 1);
      }
    }

    visit(null, 0);
    return result;
  }

  Future<String?> _pickFolder({required String? currentFolderId}) async {
    final options = _folderOptions();

    return showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colors = theme.colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Mover a carpeta',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.home_outlined),
                        title: const Text('Sin carpeta (Raíz)'),
                        trailing: currentFolderId == null
                            ? Icon(Icons.check_rounded, color: colors.primary)
                            : null,
                        onTap: () => Navigator.pop(sheetContext, '__root__'),
                      ),
                      if (options.isNotEmpty) const Divider(),
                      ...options.map((option) {
                        final folder = option.folder;
                        final selected = folder.id == currentFolderId;

                        return ListTile(
                          contentPadding: EdgeInsets.only(
                            left: 16 + (option.depth * 20),
                            right: 12,
                          ),
                          leading: Icon(
                            Icons.folder_rounded,
                            color: colors.primary,
                          ),
                          title: Text(
                            folder.name,
                            style: TextStyle(
                              fontWeight: option.depth == 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                          trailing: selected
                              ? Icon(Icons.check_rounded, color: colors.primary)
                              : null,
                          onTap: () => Navigator.pop(sheetContext, folder.id),
                        );
                      }),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.create_new_folder_rounded),
                        title: const Text('Nueva carpeta'),
                        onTap: () => Navigator.pop(sheetContext, '__create__'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> moveInventoryItem(InventoryItem inventory) async {
    var selected = await _pickFolder(currentFolderId: inventory.folderId);
    if (selected == null || !mounted) return;

    if (selected == '__create__') {
      await _createFolder();
      if (!mounted) return;
      selected = await _pickFolder(currentFolderId: inventory.folderId);
      if (selected == null || selected == '__create__' || !mounted) return;
    }

    final folderId = selected == '__root__' ? null : selected;
    setState(() {
      inventory.folderId = folderId;
    });
    await save();
  }

  Future<void> createItem() async {
    final definition = await Navigator.push<ItemDefinition>(
      context,
      MaterialPageRoute(builder: (_) => ItemFormScreen(character: character)),
    );

    if (definition == null || !mounted) {
      return;
    }

    setState(() {
      _inventoryService.addItem(
        character: character,
        definition: definition,
        quantity: 1,
      );

      // Asignar la carpeta actual al último objeto añadido
      if (character.inventoryItems.isNotEmpty) {
        final addedItem = character.inventoryItems.lastWhere(
          (item) => item.itemId == definition.id,
          orElse: () => character.inventoryItems.last,
        );
        addedItem.folderId = _currentFolderId;
      }

      character.normalizeHealth();
    });

    await save();
  }

  ItemDefinition? _definitionFor(InventoryItem inventory) {
    return character.definitionForInventoryItem(inventory);
  }

  List<InventoryItemView> get _resolvedInventory {
    final result = <InventoryItemView>[];

    for (final inventory in character.inventoryItems) {
      final definition = _definitionFor(inventory);

      if (definition == null) {
        continue;
      }

      result.add((inventory: inventory, definition: definition));
    }

    return List<InventoryItemView>.unmodifiable(result);
  }

  // ===========================================================================
  // EDITAR
  // ===========================================================================

  Future<void> editItem(
    InventoryItem inventory,
    ItemDefinition definition,
  ) async {
    final updatedDefinition = await Navigator.push<ItemDefinition>(
      context,
      MaterialPageRoute(
        builder: (_) => ItemFormScreen(
          definition: ItemDefinition.fromMap(definition.toMap()),
          character: character,
        ),
      ),
    );

    if (updatedDefinition == null || !mounted) {
      return;
    }

    setState(() {
      final normalized = ItemDefinition.fromMap(updatedDefinition.toMap());
      final map = normalized.toMap();
      map['id'] = definition.id;

      final newDef = ItemDefinition.fromMap(map);
      character.registerItemDefinition(newDef);

      if (inventory.equipped) {
        if (!newDef.isEquippable) {
          _inventoryService.unequipItem(character: character, item: inventory);
        } else if (inventory.equippedSlotId != null) {
          _inventoryService.equipItemInSlot(
            character: character,
            item: inventory,
            slotId: inventory.equippedSlotId!,
          );
        } else {
          _inventoryService.equipItem(character: character, item: inventory);
        }
      }

      character.normalizeHealth();
    });

    await save();
  }

  // ===========================================================================
  // ELIMINAR
  // ===========================================================================

  Future<void> deleteItem(
    InventoryItem inventory,
    ItemDefinition definition,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar objeto'),
          content: Text('¿Quieres eliminar "${definition.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _inventoryService.removeItem(
        character: character,
        inventoryItemId: inventory.id,
        quantity: inventory.quantity,
      );
      character.normalizeHealth();
    });

    await save();
  }

  // ===========================================================================
  // EQUIPAR / DESEQUIPAR
  // ===========================================================================

  Future<void> toggleEquip(
    InventoryItem inventory,
    ItemDefinition definition,
  ) async {
    if (!definition.isEquippable) {
      return;
    }

    if (inventory.equipped) {
      setState(() {
        _inventoryService.unequipItem(character: character, item: inventory);
        _mergeInventoryItemStacks(definition.id);
        character.normalizeHealth();
      });
      await save();
      return;
    }

    String? targetSlotId;
    final availableSlots = definition.equipmentSlotIds.isNotEmpty
        ? definition.equipmentSlotIds
        : [definition.type.defaultEquipmentSlotId];

    if (availableSlots.length > 1) {
      targetSlotId = await SlotSelectionDialog.show(
        context,
        character: character,
        definition: definition,
        item: inventory,
      );
      if (targetSlotId == null || !mounted) return;
    } else {
      targetSlotId = availableSlots.first;
    }

    setState(() {
      if (inventory.quantity > 1) {
        inventory.quantity -= 1;
        final equippedInventory = InventoryItem(
          id: 'inventory_item_${DateTime.now().microsecondsSinceEpoch}',
          itemId: inventory.itemId,
          quantity: 1,
          equipped: false,
          equippedSlotId: null,
          folderId: inventory.folderId, // Hereda la carpeta
        );
        character.inventoryItems.add(equippedInventory);
        _inventoryService.equipItemInSlot(
          character: character,
          item: equippedInventory,
          slotId: targetSlotId!,
        );
      } else {
        _inventoryService.equipItemInSlot(
          character: character,
          item: inventory,
          slotId: targetSlotId!,
        );
      }

      character.normalizeHealth();
    });

    await save();
  }

  void _mergeInventoryItemStacks(String itemId) {
    final definition = character.itemDefinitionById(itemId);

    if (definition == null || !definition.stackable) {
      return;
    }

    InventoryItem? destination;
    final duplicates = <InventoryItem>[];

    for (final inventory in character.inventoryItems) {
      if (inventory.itemId != itemId || inventory.equipped) {
        continue;
      }

      if (destination == null) {
        destination = inventory;
        continue;
      }

      destination.quantity += inventory.quantity;
      duplicates.add(inventory);
    }

    final duplicateIds = duplicates.map((item) => item.id).toSet();
    character.inventoryItems.removeWhere(
      (item) => duplicateIds.contains(item.id),
    );
  }

  // ===========================================================================
  // DAÑO DE ARMA Y CONSUMIBLES
  // ===========================================================================

  Future<void> resolveWeapon(ItemDefinition definition) async {
    final weapon = definition.weapon;

    if (weapon == null) {
      if (!mounted) return;
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
      if (execution == null) return;

      await save();

      if (!mounted) return;
      setState(() {});

      await showActionResolutionResultDialog(
        context,
        character: character,
        execution: execution,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se ha podido resolver el ataque: $error')),
      );
    }
  }

  Future<void> useConsumable(
    InventoryItem inventory,
    ItemDefinition definition,
  ) async {
    final success = await _inventoryService.useConsumable(
      context: context,
      character: character,
      inventoryItem: inventory,
    );

    if (!success || !mounted) {
      return;
    }

    setState(() {
      character.normalizeHealth();
    });

    await save();
  }

  Future<void> editItemQuantityQuick(
    InventoryItem inventory,
    ItemDefinition definition,
  ) async {
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return _ItemQuantityCalculatorDialog(
          itemName: definition.name,
          baseValue: inventory.quantity,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      if (result <= 0) {
        _inventoryService.removeItem(
          character: character,
          inventoryItemId: inventory.id,
          quantity: inventory.quantity,
        );
      } else {
        inventory.quantity = result;
      }
    });

    await save();
  }

  // ===========================================================================
  // IMPORTAR / EXPORTAR / BIBLIOTECA
  // ===========================================================================

  Future<void> saveItemToLibrary(ItemDefinition definition) async {
    try {
      await ItemLibraryService.addDefinition(definition);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${definition.name} guardado en la biblioteca.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha podido guardar el objeto en la biblioteca.'),
        ),
      );
    }
  }

  Future<void> importItem() async {
    try {
      final item = await ItemImportExportService.pickAndImportDefinition();
      if (item == null || !mounted) return;

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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.inventory_2_rounded),
                label: const Text('Añadir'),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) return;

      setState(() {
        _inventoryService.addItem(
          character: character,
          definition: item,
          quantity: 1,
        );

        if (character.inventoryItems.isNotEmpty) {
          final addedItem = character.inventoryItems.lastWhere(
            (i) => i.itemId == item.id,
            orElse: () => character.inventoryItems.last,
          );
          addedItem.folderId = _currentFolderId;
        }

        character.normalizeHealth();
      });

      await save();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} añadido al inventario.')),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido importar el objeto.')),
      );
    }
  }

  Future<void> exportItem(ItemDefinition definition) async {
    try {
      await ItemImportExportService.shareDefinition(definition);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido compartir el objeto.')),
      );
    }
  }

  Future<void> openShop() async {
    final campaignId = character.campaignId;
    if (campaignId == null || campaignId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este personaje todavía no pertenece a una campaña.')),
      );
      return;
    }

    final campaign = CampaignStorageService.getCampaign(campaignId);
    if (campaign == null || campaign.shops.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta campaña todavía no tiene tiendas.')),
      );
      return;
    }

    var shop = campaign.shops.first;
    if (campaign.shops.length > 1) {
      final selected = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            children: [
              const ListTile(
                leading: Icon(Icons.storefront_rounded),
                title: Text('Tiendas de la campaña'),
                subtitle: Text('Elige dónde quiere comprar este personaje.'),
              ),
              ...campaign.shops.map(
                (candidate) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.store_rounded)),
                  title: Text(candidate.name),
                  subtitle: Text(
                    candidate.description.trim().isEmpty
                        ? 'Moneda: ${candidate.currencyName}'
                        : candidate.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(sheetContext, candidate.id),
                ),
              ),
            ],
          ),
        ),
      );
      if (selected == null || !mounted) return;
      shop = campaign.shops.firstWhere((candidate) => candidate.id == selected);
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CampaignShopDetailScreen(
          campaign: campaign,
          shop: shop,
          buyer: character,
        ),
      ),
    );

    if (!mounted) return;
    setState(() {});
  }

  Future<void> openItemFromGrid(
    InventoryItem inventory,
    ItemDefinition definition,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final color = ItemTypeColors.of(definition.type);

        return FractionallySizedBox(
          heightFactor: 0.92,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (definition.hasImage) ...[
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        ItemImageViewer.show(sheetContext, definition);
                      },
                      child: SizedBox(
                        width: double.infinity,
                        height: 240,
                        child: ItemImage(
                          definition: definition,
                          size: double.infinity,
                        ),
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
                      ItemTypeColors.icon(definition.type),
                      size: 54,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        definition.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Editar',
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        editItem(inventory, definition);
                      },
                      icon: const Icon(Icons.edit_rounded),
                    ),
                  ],
                ),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: Icon(
                        ItemTypeColors.icon(definition.type),
                        size: 17,
                        color: color,
                      ),
                      label: Text(definition.type.label),
                    ),
                    Chip(
                      avatar: const Icon(Icons.layers_rounded, size: 17),
                      label: Text('×${formatThousands(inventory.quantity)}'),
                    ),
                    if (inventory.equipped)
                      const Chip(
                        avatar: Icon(Icons.check_circle_rounded, size: 17),
                        label: Text('Equipado'),
                      ),
                  ],
                ),

                if (definition.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    definition.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],

                const SizedBox(height: 18),

                ItemExtendedContent(
                  inventoryItem: inventory,
                  definition: definition,
                  character: character,
                  padding: EdgeInsets.zero,
                  onEquip: () {
                    Navigator.pop(sheetContext);
                    toggleEquip(inventory, definition);
                  },
                  onWeaponAttack: definition.isWeapon && inventory.equipped
                      ? () {
                          Navigator.pop(sheetContext);
                          resolveWeapon(definition);
                        }
                      : null,
                  onConsumableUse:
                      (definition.type == ItemType.consumable ||
                          definition.type == ItemType.potion ||
                          definition.consumable != null)
                      ? () {
                          Navigator.pop(sheetContext);
                          useConsumable(inventory, definition);
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

    if (!mounted) return;
    setState(() {});
  }

  Widget buildItemGrid(List<InventoryItemView> items) {
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
            final entry = items[index];

            return ItemGridCard(
              inventoryItem: entry.inventory,
              definition: entry.definition,
              onTap: () {
                openItemFromGrid(entry.inventory, entry.definition);
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

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGridView = prefs.getBool(_gridViewPreferenceKey) ?? false;

    if (!mounted) return;

    setState(() {
      gridView = savedGridView;
      viewPreferenceLoaded = true;
    });
  }

  Future<void> _showCreateMenu() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.inventory_2_rounded),
                  title: const Text('Nuevo objeto'),
                  subtitle: const Text('Crear un objeto desde cero'),
                  onTap: () => Navigator.pop(sheetContext, 'item'),
                ),
                ListTile(
                  leading: const Icon(Icons.create_new_folder_rounded),
                  title: const Text('Nueva carpeta'),
                  subtitle: const Text('Organiza tus objetos'),
                  onTap: () => Navigator.pop(sheetContext, 'folder'),
                ),
              ],
            ),
          ),
        );
      },
    );

    switch (result) {
      case 'item':
        await createItem();
        break;
      case 'folder':
        await _createFolder();
        break;
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final allItems = _resolvedInventory;
    final query = _normalizeSearchText(_searchQuery.trim());
    final searching = query.isNotEmpty;

    // En modo normal solo mostramos el nivel actual. Durante una búsqueda,
    // el alcance incluye este nivel y todas sus subcarpetas descendientes.
    final folders = searching
        ? <CharacterContentFolder>[]
        : character.itemFoldersInside(_currentFolderId);

    final searchFolderIds = searching ? _itemFolderSearchScope() : <String>{};

    final itemsInFolder = allItems.where((entry) {
      if (!searching) {
        return entry.inventory.folderId == _currentFolderId;
      }

      final folderId = entry.inventory.folderId;
      final inScope = folderId == _currentFolderId ||
          (folderId != null && searchFolderIds.contains(folderId));

      return inScope && _matchesItemSearch(entry, query);
    }).toList(growable: false);

    final equipped = itemsInFolder
        .where((entry) => entry.inventory.equipped)
        .toList(growable: false);

    final inventory = itemsInFolder
        .where((entry) => !entry.inventory.equipped)
        .toList(growable: false);

    final hasContent = searching
        ? itemsInFolder.isNotEmpty
        : folders.isNotEmpty || itemsInFolder.isNotEmpty;

    return PopScope(
      canPop: !_canGoBackInsideContent,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBackInsideContent();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _canGoBackInsideContent
              ? IconButton(
                  onPressed: _goBackInsideContent,
                  icon: const Icon(Icons.arrow_back_rounded),
                )
              : null,
          title: Text(_screenTitle),
          actions: [
            IconButton(
              tooltip: gridView ? 'Vista de lista' : 'Vista de cuadrícula',
              onPressed: _toggleViewMode,
              icon: Icon(
                gridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              ),
            ),
            IconButton(
              tooltip: 'Configurar ranuras',
              onPressed: () {
                EquipmentSlotsConfigDialog.show(
                  context,
                  character: character,
                  onSaved: () async {
                    setState(() {});
                    await save();
                  },
                );
              },
              icon: const Icon(Icons.tune_rounded),
            ),
            if (_currentFolder != null)
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'rename':
                      await _renameCurrentFolder();
                      break;
                    case 'delete':
                      await _deleteCurrentFolder();
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'rename',
                    child: ListTile(
                      leading: Icon(Icons.edit_rounded),
                      title: Text('Renombrar'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline_rounded),
                      title: Text('Eliminar'),
                    ),
                  ),
                ],
              ),
            IconButton(
              tooltip: 'Importar objeto',
              onPressed: importItem,
              icon: const Icon(Icons.file_download_rounded),
            ),
            IconButton(
              tooltip: 'Tiendas',
              onPressed: openShop,
              icon: const Icon(Icons.storefront_rounded),
            ),
          ],
        ),
        body: !viewPreferenceLoaded
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildSearchField(),
                  Expanded(
                    child: !hasContent
                        ? EmptyState(
                            icon: searching
                                ? Icons.search_off_rounded
                                : Icons.inventory_2_rounded,
                            title: searching
                                ? 'Sin resultados'
                                : 'Carpeta vacía',
                            message: searching
                                ? 'No hay objetos que coincidan en esta carpeta ni en sus subcarpetas.'
                                : 'Añade objetos, equipo o subcarpetas.',
                            actionLabel: searching ? null : 'Añadir',
                            onAction: searching ? null : _showCreateMenu,
                          )
                        : ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
                children: [
                  if (searching)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        '${itemsInFolder.length} ${itemsInFolder.length == 1 ? 'resultado' : 'resultados'} · Incluye subcarpetas',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  // =======================================================================
                  // SUBCARPETAS
                  // =======================================================
                  ...folders.map(
                    (folder) => _ContentFolderTile(
                      icon: Icons.folder_rounded,
                      name: folder.name,
                      count: character.itemCountInFolder(
                        folder.id,
                      ), 
                      onTap: () => _openFolder(folder.id),
                    ),
                  ),

                  if (folders.isNotEmpty && itemsInFolder.isNotEmpty)
                    const SizedBox(height: 14),

                  // =======================================================
                  // EQUIPADOS (si aplica en la vista actual)
                  // =======================================================
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
                      ...equipped.map((entry) {
                        final inventoryItem = entry.inventory;
                        final definition = entry.definition;

                        return ItemCard(
                          inventoryItem: inventoryItem,
                          definition: definition,
                          character: character,
                          onEquip: () => toggleEquip(inventoryItem, definition),
                          onEdit: () => editItem(inventoryItem, definition),
                          onDelete: () => deleteItem(inventoryItem, definition),
                          onMove: () => moveInventoryItem(inventoryItem),
                          onExport: () => exportItem(definition),
                          onSaveToLibrary: () => saveItemToLibrary(definition),
                          onQuickQuantityEdit: definition.calculable
                              ? () => editItemQuantityQuick(
                                  inventoryItem,
                                  definition,
                                )
                              : null,
                          onWeaponAttack:
                              definition.isWeapon && inventoryItem.equipped
                              ? () => resolveWeapon(definition)
                              : null,
                        );
                      }),
                    const SizedBox(height: 24),
                  ],

                  // =======================================================
                  // INVENTARIO / DISPONIBLES
                  // =======================================================
                  if (inventory.isNotEmpty || equipped.isEmpty) ...[
                    SectionHeader(
                      icon: Icons.backpack_rounded,
                      title: 'Inventario',
                      subtitle: inventory.isEmpty
                          ? 'No hay objetos sin equipar en esta carpeta'
                          : '${inventory.length} ${inventory.length == 1 ? 'objeto disponible' : 'objetos disponibles'}',
                    ),
                    const SizedBox(height: 14),

                    if (inventory.isEmpty && equipped.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant
                                .withValues(alpha: 0.45),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 34,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Esta carpeta está vacía.',
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
                      ...inventory.map((entry) {
                        final inventoryItem = entry.inventory;
                        final definition = entry.definition;

                        return ItemCard(
                          inventoryItem: inventoryItem,
                          definition: definition,
                          character: character,
                          onEquip: () => toggleEquip(inventoryItem, definition),
                          onEdit: () => editItem(inventoryItem, definition),
                          onDelete: () => deleteItem(inventoryItem, definition),
                          onMove: () => moveInventoryItem(inventoryItem),
                          onExport: () => exportItem(definition),
                          onSaveToLibrary: () => saveItemToLibrary(definition),
                          onQuickQuantityEdit: definition.calculable
                              ? () => editItemQuantityQuick(
                                  inventoryItem,
                                  definition,
                                )
                              : null,
                          onWeaponAttack:
                              definition.isWeapon && inventoryItem.equipped
                              ? () => resolveWeapon(definition)
                              : null,
                          onConsumableUse:
                              (definition.type == ItemType.consumable ||
                                  definition.type == ItemType.potion ||
                                  definition.consumable != null)
                              ? () => useConsumable(inventoryItem, definition)
                              : null,
                        );
                      }),
                  ],
                ],
              ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateMenu,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Añadir'),
        ),
      ),
    );
  }
}

class _ContentFolderTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final int count;
  final VoidCallback onTap;

  const _ContentFolderTile({
    required this.icon,
    required this.name,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: colors.onPrimaryContainer),
        ),
        title: Text(
          name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text('$count ${count == 1 ? 'elemento' : 'elementos'}'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _FolderOption {
  final CharacterContentFolder folder;
  final int depth;

  const _FolderOption({required this.folder, required this.depth});
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
        if (secondValue <= 0) return widget.baseValue;
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
                              onPressed: () => setState(() => operation = op),
                              child: Text(op),
                            )
                          : OutlinedButton(
                              onPressed: () => setState(() => operation = op),
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
              onChanged: (_) => setState(() {}),
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
                    '${widget.baseValue} $operation '
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
                    onPressed: () => setQuickValue(value),
                    child: Text('$value'),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(calculated),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Aplicar'),
        ),
      ],
    );
  }
}
