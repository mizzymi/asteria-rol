import 'dart:io';

import 'package:flutter/material.dart';

import '../models/campaign.dart';
import '../models/campaign_shop.dart';
import '../models/character.dart';
import '../models/inventory_item.dart';
import '../services/campaign_economy_service.dart';
import '../services/campaign_shop_import_export_service.dart';
import '../services/campaign_storage_service.dart';
import '../services/character_storage_service.dart';
import 'campaign_shop_form_screen.dart';

class CampaignShopDetailScreen extends StatefulWidget {
  final Campaign campaign;
  final CampaignShop shop;
  final Character? buyer;

  const CampaignShopDetailScreen({
    super.key,
    required this.campaign,
    required this.shop,
    this.buyer,
  });

  @override
  State<CampaignShopDetailScreen> createState() => _CampaignShopDetailScreenState();
}

class _CampaignShopDetailScreenState extends State<CampaignShopDetailScreen> {
  late Campaign campaign;
  late CampaignShop shop;
  List<Character> characters = [];

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
    characters = CharacterStorageService.getCharacters()
        .where((c) => c.campaignId == campaign.id)
        .toList();
    if (mounted) setState(() {});
  }

  Future<void> _edit() async {
    final edited = await Navigator.push<CampaignShop>(
      context,
      MaterialPageRoute(builder: (_) => CampaignShopFormScreen(shop: shop)),
    );
    if (edited == null) return;
    final index = campaign.shops.indexWhere((s) => s.id == shop.id);
    if (index >= 0) campaign.shops[index] = edited;
    await CampaignStorageService.saveCampaign(campaign);
    await CampaignEconomyService.syncCampaignCurrencies(campaign);
    if (!mounted) return;
    shop = edited;
    _reload();
  }

  Future<void> _export() async {
    try {
      await CampaignShopImportExportService.shareShop(shop);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar la tienda: $error')),
      );
    }
  }

  Future<Character?> _chooseCharacter() async {
    if (widget.buyer != null) return widget.buyer;
    if (characters.isEmpty) return null;
    if (characters.length == 1) return characters.first;
    return showModalBottomSheet<Character>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(12),
          children: [
            const ListTile(title: Text('¿Quién compra?')),
            ...characters.map((c) => ListTile(
                  title: Text(c.name),
                  trailing: Text(_balanceText(c)),
                  onTap: () => Navigator.pop(sheetContext, c),
                )),
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
    if (itemId == null) return 0;
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
    final character = await _chooseCharacter();
    if (character == null || !mounted) return;

    final price = product.price < 0 ? 0 : product.price;
    if (shop.currencyKind == CampaignShopCurrencyKind.resource) {
      final name = shop.currencyName.trim().isEmpty ? 'Oro' : shop.currencyName.trim();
      final id = CampaignEconomyService.resourceIdFor(campaign.id, name);
      final resourceIndex = character.resources.indexWhere(
        (r) => r.id == id || r.name.toLowerCase() == name.toLowerCase(),
      );
      if (resourceIndex < 0 || character.resources[resourceIndex].currentValue < price) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${character.name} no tiene suficiente $name.')),
        );
        return;
      }
      character.resources[resourceIndex].currentValue -= price;
    } else {
      final currencyId = shop.currencyItem?.id;
      if (currencyId == null || _itemBalance(character) < price) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${character.name} no tiene suficientes ${shop.currencyName}.')),
        );
        return;
      }
      var remaining = price;
      for (final entry in character.inventoryItems.where((e) => e.itemId == currencyId).toList()) {
        if (remaining <= 0) break;
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
    if (!mounted) return;
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${character.name} ha comprado ${definition.name}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(shop.name),
        actions: [
          IconButton(onPressed: _export, tooltip: 'Exportar tienda', icon: const Icon(Icons.ios_share_rounded)),
          IconButton(onPressed: _edit, tooltip: 'Editar', icon: const Icon(Icons.edit_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    CircleAvatar(backgroundColor: colors.primaryContainer, child: const Icon(Icons.storefront_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(shop.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                  ]),
                  if (shop.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(shop.description),
                  ],
                  const SizedBox(height: 12),
                  Chip(avatar: const Icon(Icons.paid_rounded, size: 18), label: Text('Moneda: ${shop.currencyName}')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Productos', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (shop.products.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Esta tienda todavía no tiene productos.')))
          else
            ...shop.products.map((product) => Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: _ProductImage(path: product.definition.imagePath),
                    title: Text(product.definition.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${product.price} ${shop.currencyName}'),
                    trailing: FilledButton(onPressed: () => _buy(product), child: const Text('Comprar')),
                  ),
                )),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? path;
  const _ProductImage({this.path});
  @override
  Widget build(BuildContext context) {
    if (path != null && path!.isNotEmpty && File(path!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(File(path!), width: 48, height: 48, fit: BoxFit.cover),
      );
    }
    return const CircleAvatar(child: Icon(Icons.inventory_2_rounded));
  }
}
