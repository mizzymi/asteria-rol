import 'dart:io';

import 'package:flutter/material.dart';

import '../models/campaign.dart';
import '../models/campaign_shop.dart';
import '../models/character.dart';
import '../models/dnd_class.dart';
import '../models/inventory_item.dart';
import '../models/item_definition.dart';
import '../services/campaign_economy_service.dart';
import '../services/campaign_shop_import_export_service.dart';
import '../services/campaign_storage_service.dart';
import '../services/character_storage_service.dart';
import 'campaign_shop_form_screen.dart';

class CampaignShopDetailScreen extends StatefulWidget {
  final Campaign campaign;
  final CampaignShop shop;
  final Character? buyer;
  final bool isMaster;

  const CampaignShopDetailScreen({
    super.key,
    required this.campaign,
    required this.shop,
    this.buyer,
    this.isMaster = false,
  });

  @override
  State<CampaignShopDetailScreen> createState() =>
      _CampaignShopDetailScreenState();
}

class _CampaignShopDetailScreenState extends State<CampaignShopDetailScreen> {
  late Campaign campaign;
  late CampaignShop shop;
  List<Character> characters = [];

  String _search = '';
  final Set<ItemType> _typeFilters = <ItemType>{};
  final Set<ArmorCategory> _armorFilters = <ArmorCategory>{};
  int? _minPrice;
  int? _maxPrice;
  bool? _hasAbilities;
  bool? _hasPassives;
  bool? _prohibited;
  final Set<String> _classFilters = <String>{};
  bool _groupByClass = false;
  String _sort = 'name';

  List<CampaignShopProduct> get _filteredProducts {
    final query = _search.trim().toLowerCase();
    final result = shop.products.where((product) {
      final d = product.definition;
      if (query.isNotEmpty &&
          !d.name.toLowerCase().contains(query) &&
          !d.description.toLowerCase().contains(query) &&
          !d.type.label.toLowerCase().contains(query) &&
          !d.recommendedClasses.any(
            (className) => className.toLowerCase().contains(query),
          ) &&
          !d.abilities.any(
            (a) =>
                a.name.toLowerCase().contains(query) ||
                a.description.toLowerCase().contains(query),
          ) &&
          !d.passives.any(
            (p) =>
                p.name.toLowerCase().contains(query) ||
                p.description.toLowerCase().contains(query),
          )) {
        return false;
      }
      if (_typeFilters.isNotEmpty && !_typeFilters.contains(d.type)) {
        return false;
      }
      if (_armorFilters.isNotEmpty &&
          (d.armor == null || !_armorFilters.contains(d.armor!.category))) {
        return false;
      }
      if (_minPrice != null && product.price < _minPrice!) {
        return false;
      }
      if (_maxPrice != null && product.price > _maxPrice!) {
        return false;
      }
      if (_hasAbilities != null && d.abilities.isNotEmpty != _hasAbilities!) {
        return false;
      }
      if (_hasPassives != null && d.passives.isNotEmpty != _hasPassives!) {
        return false;
      }
      if (_prohibited != null && product.prohibited != _prohibited!) {
        return false;
      }
      if (_classFilters.isNotEmpty &&
          !d.recommendedClasses.any(_classFilters.contains)) {
        return false;
      }
      return true;
    }).toList();
    result.sort((a, b) {
      switch (_sort) {
        case 'priceAsc':
          return a.price.compareTo(b.price);
        case 'priceDesc':
          return b.price.compareTo(a.price);
        case 'nameDesc':
          return b.definition.name.toLowerCase().compareTo(
            a.definition.name.toLowerCase(),
          );
        case 'caDesc':
          return (b.definition.armor?.baseArmorClass ?? -1).compareTo(
            a.definition.armor?.baseArmorClass ?? -1,
          );
        default:
          return a.definition.name.toLowerCase().compareTo(
            b.definition.name.toLowerCase(),
          );
      }
    });
    return result;
  }

  List<Object> get _displayEntries {
    final products = _filteredProducts;
    if (!_groupByClass) {
      return List<Object>.from(products);
    }
    final entries = <Object>[];
    final classes =
        products.expand((p) => p.definition.recommendedClasses).toSet().toList()
          ..sort();
    for (final className in classes) {
      final matching = products
          .where((p) => p.definition.recommendedClasses.contains(className))
          .toList();
      if (matching.isEmpty) {
        continue;
      }
      entries.add('Recomendado para $className');
      entries.addAll(matching);
    }
    final unclassified = products
        .where((p) => p.definition.recommendedClasses.isEmpty)
        .toList();
    if (unclassified.isNotEmpty) {
      entries.add('Otros objetos');
      entries.addAll(unclassified);
    }
    return entries;
  }

  int get _activeFilterCount =>
      _typeFilters.length +
      _armorFilters.length +
      (_minPrice != null ? 1 : 0) +
      (_maxPrice != null ? 1 : 0) +
      (_hasAbilities != null ? 1 : 0) +
      (_hasPassives != null ? 1 : 0) +
      (_prohibited != null ? 1 : 0) +
      _classFilters.length +
      (_groupByClass ? 1 : 0);

  void _clearFilters() => setState(() {
    _typeFilters.clear();
    _armorFilters.clear();
    _minPrice = null;
    _maxPrice = null;
    _hasAbilities = null;
    _hasPassives = null;
    _prohibited = null;
    _classFilters.clear();
    _groupByClass = false;
  });

  Future<void> _showFilters() async {
    var types = Set<ItemType>.from(_typeFilters);
    var armors = Set<ArmorCategory>.from(_armorFilters);
    var minPrice = _minPrice?.toString() ?? '';
    var maxPrice = _maxPrice?.toString() ?? '';
    var hasAbilities = _hasAbilities;
    var hasPassives = _hasPassives;
    var prohibited = _prohibited;
    var classFilters = Set<String>.from(_classFilters);
    var groupByClass = _groupByClass;
    final classOptions = <String>{
      ...DndClass.values.map((dndClass) => dndClass.label),
      ...shop.products.expand((p) => p.definition.recommendedClasses),
    }.toList()..sort();
    var sort = _sort;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, modalSetState) {
          Widget triChoice(
            String title,
            bool? value,
            ValueChanged<bool?> onChanged,
          ) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  ctx,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              SegmentedButton<bool?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('Todos')),
                  ButtonSegment(value: true, label: Text('Sí')),
                  ButtonSegment(value: false, label: Text('No')),
                ],
                selected: {value},
                onSelectionChanged: (v) => onChanged(v.first),
              ),
            ],
          );
          return FractionallySizedBox(
            heightFactor: .9,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              children: [
                Text(
                  'Filtrar productos',
                  style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Tipo de objeto',
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: ItemType.values
                      .map(
                        (type) => FilterChip(
                          label: Text(type.label),
                          selected: types.contains(type),
                          onSelected: (v) => modalSetState(
                            () => v ? types.add(type) : types.remove(type),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                Text(
                  'Tipo de armadura',
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: ArmorCategory.values
                      .map(
                        (cat) => FilterChip(
                          label: Text(cat.label),
                          selected: armors.contains(cat),
                          onSelected: (v) => modalSetState(
                            () => v ? armors.add(cat) : armors.remove(cat),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: minPrice,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Precio mínimo',
                          prefixIcon: Icon(Icons.paid_rounded),
                        ),
                        onChanged: (v) => minPrice = v,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: maxPrice,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Precio máximo',
                          prefixIcon: Icon(Icons.paid_rounded),
                        ),
                        onChanged: (v) => maxPrice = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                triChoice(
                  'Con habilidades activas',
                  hasAbilities,
                  (v) => modalSetState(() => hasAbilities = v),
                ),
                const SizedBox(height: 14),
                triChoice(
                  'Con pasivas',
                  hasPassives,
                  (v) => modalSetState(() => hasPassives = v),
                ),
                const SizedBox(height: 14),
                triChoice(
                  'Objetos prohibidos',
                  prohibited,
                  (v) => modalSetState(() => prohibited = v),
                ),
                const SizedBox(height: 18),
                Text(
                  'Buscar por clase',
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Muestra objetos recomendados para cualquiera de las clases seleccionadas.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: classOptions
                      .map(
                        (name) => FilterChip(
                          label: Text(name),
                          selected: classFilters.contains(name),
                          onSelected: (v) => modalSetState(
                            () => v
                                ? classFilters.add(name)
                                : classFilters.remove(name),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Separar por clase'),
                  subtitle: const Text(
                    'Crea apartados como “Recomendado para Guerrero”',
                  ),
                  value: groupByClass,
                  onChanged: (v) => modalSetState(() => groupByClass = v),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: sort,
                  decoration: const InputDecoration(
                    labelText: 'Ordenar por',
                    prefixIcon: Icon(Icons.sort_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Nombre A–Z')),
                    DropdownMenuItem(
                      value: 'nameDesc',
                      child: Text('Nombre Z–A'),
                    ),
                    DropdownMenuItem(
                      value: 'priceAsc',
                      child: Text('Precio: menor a mayor'),
                    ),
                    DropdownMenuItem(
                      value: 'priceDesc',
                      child: Text('Precio: mayor a menor'),
                    ),
                    DropdownMenuItem(
                      value: 'caDesc',
                      child: Text('CA: mayor a menor'),
                    ),
                  ],
                  onChanged: (v) => modalSetState(() => sort = v ?? 'name'),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          modalSetState(() {
                            types.clear();
                            armors.clear();
                            minPrice = '';
                            maxPrice = '';
                            hasAbilities = null;
                            hasPassives = null;
                            prohibited = null;
                            classFilters.clear();
                            groupByClass = false;
                          });
                        },
                        icon: const Icon(Icons.filter_alt_off_rounded),
                        label: const Text('Limpiar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(ctx, true),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    if (applied == true && mounted) {
      setState(() {
        _typeFilters
          ..clear()
          ..addAll(types);
        _armorFilters
          ..clear()
          ..addAll(armors);
        _minPrice = int.tryParse(minPrice.trim());
        _maxPrice = int.tryParse(maxPrice.trim());
        _hasAbilities = hasAbilities;
        _hasPassives = hasPassives;
        _prohibited = prohibited;
        _classFilters
          ..clear()
          ..addAll(classFilters);
        _groupByClass = groupByClass;
        _sort = sort;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    campaign = widget.campaign;
    shop = widget.shop;
    _reload();
  }

  void _reload() {
    final latest = CampaignStorageService.getCampaign(campaign.id) ?? campaign;
    campaign = latest;
    shop = campaign.shops.firstWhere(
      (s) => s.id == shop.id,
      orElse: () => shop,
    );
    // Nunca permitimos que NPC o hosts de criaturas aparezcan como compradores.
    characters = CharacterStorageService.getCharacters()
        .where((c) => c.campaignId == campaign.id && c.ownerType == 'player')
        .toList();
    if (mounted) setState(() {});
  }

  Future<void> _edit() async {
    if (!widget.isMaster) {
      return;
    }
    final edited = await Navigator.push<CampaignShop>(
      context,
      MaterialPageRoute(builder: (_) => CampaignShopFormScreen(shop: shop)),
    );
    if (edited == null) {
      return;
    }
    final index = campaign.shops.indexWhere((s) => s.id == shop.id);
    if (index >= 0) {
      campaign.shops[index] = edited;
    }
    await CampaignStorageService.saveCampaign(campaign);
    await CampaignEconomyService.syncCampaignCurrencies(campaign);
    if (!mounted) {
      return;
    }
    shop = edited;
    _reload();
  }

  Future<void> _export() async {
    if (!widget.isMaster) {
      return;
    }
    try {
      await CampaignShopImportExportService.shareShop(shop);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar la tienda: $error')),
      );
    }
  }

  Future<void> _import() async {
    try {
      final imported =
          await CampaignShopImportExportService.pickAndImportShop();
      if (imported == null) {
        return;
      }
      campaign.shops.add(imported);
      await CampaignStorageService.saveCampaign(campaign);
      await CampaignEconomyService.syncCampaignCurrencies(campaign);
      if (!mounted) {
        return;
      }
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tienda “${imported.name}” importada en ${campaign.name}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo importar la tienda: $error')),
      );
    }
  }

  Future<Character?> _chooseCharacter() async {
    if (widget.isMaster) {
      return null;
    }
    if (widget.buyer != null) {
      return widget.buyer;
    }
    if (characters.isEmpty) {
      return null;
    }
    if (characters.length == 1) {
      return characters.first;
    }
    return showModalBottomSheet<Character>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          children: [
            const ListTile(title: Text('¿Quién compra?')),
            ...characters.map(
              (c) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
                title: Text(c.name),
                trailing: Text(_balanceText(c)),
                onTap: () => Navigator.pop(sheetContext, c),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _resourceBalance(Character character) {
    final name = shop.currencyName.trim();
    for (final r in character.resources) {
      if (r.name.toLowerCase() == name.toLowerCase() ||
          r.id == CampaignEconomyService.resourceIdFor(campaign.id, name)) {
        return r.currentValue;
      }
    }
    return 0;
  }

  int _itemBalance(Character character) {
    final itemId = shop.currencyItem?.id;
    if (itemId == null) {
      return 0;
    }
    return character.inventoryItems
        .where((e) => e.itemId == itemId)
        .fold<int>(0, (sum, e) => sum + e.quantity);
  }

  String _balanceText(Character character) {
    final value = shop.currencyKind == CampaignShopCurrencyKind.resource
        ? _resourceBalance(character)
        : _itemBalance(character);
    return '$value ${shop.currencyName}';
  }

  Future<void> _buy(CampaignShopProduct product) async {
    if (widget.isMaster) {
      return;
    }
    if (product.prohibited) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este objeto está prohibido y no se puede comprar.'),
          ),
        );
      }
      return;
    }
    final character = await _chooseCharacter();
    if (character == null || !mounted) {
      return;
    }

    final price = product.price < 0 ? 0 : product.price;
    if (shop.currencyKind == CampaignShopCurrencyKind.resource) {
      final name = shop.currencyName.trim().isEmpty
          ? 'Oro'
          : shop.currencyName.trim();
      final id = CampaignEconomyService.resourceIdFor(campaign.id, name);
      final resourceIndex = character.resources.indexWhere(
        (r) => r.id == id || r.name.toLowerCase() == name.toLowerCase(),
      );
      if (resourceIndex < 0 ||
          character.resources[resourceIndex].currentValue < price) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${character.name} no tiene suficiente $name.'),
          ),
        );
        return;
      }
      character.resources[resourceIndex].currentValue -= price;
    } else {
      final currencyId = shop.currencyItem?.id;
      if (currencyId == null || _itemBalance(character) < price) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${character.name} no tiene suficientes ${shop.currencyName}.',
            ),
          ),
        );
        return;
      }
      var remaining = price;
      for (final entry
          in character.inventoryItems
              .where((e) => e.itemId == currencyId)
              .toList()) {
        if (remaining <= 0) {
          break;
        }
        final spent = entry.quantity < remaining ? entry.quantity : remaining;
        entry.quantity -= spent;
        remaining -= spent;
      }
      character.inventoryItems.removeWhere((e) => e.quantity <= 0);
    }

    final definition = product.definition;
    if (!character.itemDefinitions.any((d) => d.id == definition.id)) {
      character.itemDefinitions.add(definition);
    }
    final existingIndex = character.inventoryItems.indexWhere(
      (e) => e.itemId == definition.id && !e.equipped,
    );
    if (existingIndex >= 0 && definition.stackable) {
      character.inventoryItems[existingIndex].quantity += 1;
    } else {
      character.inventoryItems.add(
        InventoryItem(
          id: 'inventory_${DateTime.now().microsecondsSinceEpoch}',
          characterId: character.id,
          itemId: definition.id,
          quantity: 1,
        ),
      );
    }

    await CharacterStorageService.saveCharacter(character);
    if (!mounted) {
      return;
    }
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${character.name} ha comprado ${definition.name}.'),
      ),
    );
  }

  void _showProduct(CampaignShopProduct product) {
    final d = product.definition;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .86,
        child: _ProductDetails(
          definition: d,
          price: product.price,
          currencyName: shop.currencyName,
          showBuy: !widget.isMaster,
          prohibited: product.prohibited,
          onBuy: () {
            Navigator.pop(sheetContext);
            _buy(product);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final player = !widget.isMaster;
    final fixedBuyer = widget.buyer;

    return Scaffold(
      appBar: AppBar(
        title: Text(shop.name),
        actions: [
          IconButton(
            onPressed: _import,
            tooltip: 'Importar tienda',
            icon: const Icon(Icons.file_download_rounded),
          ),
          if (widget.isMaster) ...[
            IconButton(
              onPressed: _export,
              tooltip: 'Exportar tienda',
              icon: const Icon(Icons.ios_share_rounded),
            ),
            IconButton(
              onPressed: _edit,
              tooltip: 'Editar tienda',
              icon: const Icon(Icons.edit_rounded),
            ),
          ],
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primaryContainer,
                      colors.surfaceContainerHighest,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        color: colors.onPrimary,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (shop.description.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              shop.description,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                avatar: const Icon(
                                  Icons.paid_rounded,
                                  size: 18,
                                ),
                                label: Text(shop.currencyName),
                              ),
                              Chip(
                                avatar: const Icon(
                                  Icons.inventory_2_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  '${shop.products.length} productos',
                                ),
                              ),
                              if (player && fixedBuyer != null)
                                Chip(
                                  avatar: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 18,
                                  ),
                                  label: Text(_balanceText(fixedBuyer)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText:
                          'Buscar por nombre, clase, descripción, habilidad…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () => setState(() => _search = ''),
                              icon: const Icon(Icons.close_rounded),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onChanged: (value) => setState(() => _search = value),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _showFilters,
                          icon: const Icon(Icons.tune_rounded),
                          label: Text(
                            _activeFilterCount == 0
                                ? 'Filtros'
                                : 'Filtros ($_activeFilterCount)',
                          ),
                        ),
                      ),
                      if (_activeFilterCount > 0) ...[
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: _clearFilters,
                          tooltip: 'Limpiar filtros',
                          icon: const Icon(Icons.filter_alt_off_rounded),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 10),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Productos',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${_filteredProducts.length}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (shop.products.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Esta tienda todavía no tiene productos.'),
                ),
              ),
            )
          else if (_filteredProducts.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No hay productos que coincidan con los filtros.',
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              sliver: SliverList.separated(
                itemCount: _displayEntries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final entry = _displayEntries[index];
                  if (entry is String) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 2),
                      child: Text(
                        entry,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colors.primary,
                        ),
                      ),
                    );
                  }
                  final product = entry as CampaignShopProduct;
                  final d = product.definition;
                  return Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _showProduct(product),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            _ProductImage(path: d.imagePath, size: 82),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    d.type.label,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (d.type == ItemType.armor &&
                                      d.armor != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            d.armor!.category.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color:
                                                      colors.onSurfaceVariant,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.primaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.shield_rounded,
                                                size: 14,
                                                color:
                                                    colors.onPrimaryContainer,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'CA ${d.armor!.baseArmorClass}',
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: colors
                                                          .onPrimaryContainer,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (product.prohibited) ...[
                                    const SizedBox(height: 5),
                                    Chip(
                                      visualDensity: VisualDensity.compact,
                                      avatar: const Icon(
                                        Icons.block_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('Prohibido'),
                                    ),
                                  ],
                                  if (d.description.trim().isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      d.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.paid_rounded,
                                        size: 17,
                                        color: colors.primary,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${product.price} ${shop.currencyName}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (player)
                              product.prohibited
                                  ? FilledButton.icon(
                                      onPressed: null,
                                      icon: const Icon(Icons.block_rounded),
                                      label: const Text('Prohibido'),
                                    )
                                  : FilledButton(
                                      onPressed: () => _buy(product),
                                      child: const Text('Comprar'),
                                    )
                            else
                              Icon(
                                Icons.chevron_right_rounded,
                                color: colors.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? path;
  final double size;
  const _ProductImage({this.path, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final valid =
        path != null && path!.trim().isNotEmpty && File(path!).existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: size,
        height: size,
        child: valid
            ? Image.file(File(path!), fit: BoxFit.cover)
            : ColoredBox(
                color: colors.primaryContainer,
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: colors.onPrimaryContainer,
                  size: size * .42,
                ),
              ),
      ),
    );
  }
}

class _ProductDetails extends StatelessWidget {
  final ItemDefinition definition;
  final int price;
  final String currencyName;
  final bool showBuy;
  final bool prohibited;
  final VoidCallback onBuy;

  const _ProductDetails({
    required this.definition,
    required this.price,
    required this.currencyName,
    required this.showBuy,
    required this.prohibited,
    required this.onBuy,
  });

  void _openFullscreenImage(BuildContext context, String path) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Theme.of(context).colorScheme.scrim,
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.scrim,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 5.0,
                    boundaryMargin: const EdgeInsets.all(80),
                    child: Center(
                      child: Image.file(
                        File(path),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.broken_image_rounded,
                          color: Theme.of(context).colorScheme.onInverseSurface
                              .withValues(alpha: 0.70),
                          size: 72,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Cerrar',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final path = definition.imagePath;
    final hasImage =
        path != null && path.trim().isNotEmpty && File(path).existsSync();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: hasImage
                  ? Material(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0),
                      child: InkWell(
                        onTap: () => _openFullscreenImage(context, path),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(File(path), fit: BoxFit.cover),
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.scrim.withValues(alpha: .62),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.zoom_out_map_rounded,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onInverseSurface,
                                      size: 17,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Ver imagen',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onInverseSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ColoredBox(
                      color: colors.primaryContainer,
                      child: Icon(
                        Icons.inventory_2_rounded,
                        size: 72,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            definition.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            definition.type.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (definition.type == ItemType.armor &&
                  definition.armor != null) ...[
                Chip(label: Text(definition.armor!.category.label)),
                Chip(
                  avatar: const Icon(Icons.shield_rounded, size: 18),
                  label: Text('CA ${definition.armor!.baseArmorClass}'),
                ),
              ],
              Chip(
                avatar: const Icon(Icons.paid_rounded, size: 18),
                label: Text('$price $currencyName'),
              ),
              if (prohibited)
                const Chip(
                  avatar: Icon(Icons.block_rounded, size: 18),
                  label: Text('Prohibido'),
                ),
              if (definition.weight > 0)
                Chip(
                  avatar: const Icon(Icons.scale_rounded, size: 18),
                  label: Text('${definition.weight}'),
                ),
            ],
          ),
          if (definition.description.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Descripción',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(definition.description),
          ],
          if (definition.abilities.isNotEmpty ||
              definition.passives.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Contenido',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            if (definition.abilities.isNotEmpty) ...[
              Text(
                'Habilidades activas',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              ...definition.abilities.map((ability) {
                final abilityImage =
                    ability.imagePath != null &&
                    ability.imagePath!.trim().isNotEmpty &&
                    File(ability.imagePath!).existsSync();
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: colors.primaryContainer,
                      backgroundImage: abilityImage
                          ? FileImage(File(ability.imagePath!))
                          : null,
                      child: abilityImage
                          ? null
                          : const Icon(Icons.auto_awesome_rounded),
                    ),
                    title: Text(
                      ability.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(ability.actionType.name),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ability.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(ability.description),
                        const SizedBox(height: 12),
                      ],
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text('Tipo: ${ability.actionType.name}')),
                          if (ability.requiresAttackRoll)
                            const Chip(label: Text('Tirada de ataque')),
                          if (ability.effects.isNotEmpty)
                            Chip(
                              label: Text('${ability.effects.length} efectos'),
                            ),
                          if (ability.linkedEffects.isNotEmpty)
                            Chip(
                              label: Text(
                                '${ability.linkedEffects.length} efectos vinculados',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (definition.passives.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Habilidades pasivas',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              ...definition.passives.map((passive) {
                final passiveImage =
                    passive.imagePath != null &&
                    passive.imagePath!.trim().isNotEmpty &&
                    File(passive.imagePath!).existsSync();
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: colors.primaryContainer,
                      backgroundImage: passiveImage
                          ? FileImage(File(passive.imagePath!))
                          : null,
                      child: passiveImage
                          ? null
                          : const Icon(Icons.shield_rounded),
                    ),
                    title: Text(
                      passive.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(passive.enabled ? 'Activa' : 'Desactivada'),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (passive.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(passive.description),
                        const SizedBox(height: 12),
                      ],
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (passive.triggers.isNotEmpty)
                            Chip(
                              label: Text(
                                '${passive.triggers.length} triggers',
                              ),
                            ),
                          if (passive.hasCharges)
                            Chip(
                              label: Text(
                                'Cargas: ${passive.currentCharges}/${passive.maxCharges}',
                              ),
                            ),
                          if (passive.linkedEffects.isNotEmpty)
                            Chip(
                              label: Text(
                                '${passive.linkedEffects.length} efectos vinculados',
                              ),
                            ),
                          if (passive.damageBonuses.isNotEmpty)
                            Chip(
                              label: Text(
                                '${passive.damageBonuses.length} bonus de daño',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
          if (showBuy) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: prohibited
                  ? FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.block_rounded),
                      label: const Text('Objeto prohibido · No disponible'),
                    )
                  : FilledButton.icon(
                      onPressed: onBuy,
                      icon: const Icon(Icons.shopping_bag_rounded),
                      label: Text('Comprar · $price $currencyName'),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
