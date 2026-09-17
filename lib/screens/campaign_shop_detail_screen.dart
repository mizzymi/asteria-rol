import 'dart:io';

import 'package:flutter/material.dart';

import '../models/campaign.dart';
import '../models/campaign_shop.dart';
import '../models/character.dart';
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
    if (!widget.isMaster) return;
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
    if (!widget.isMaster) return;
    try {
      await CampaignShopImportExportService.shareShop(shop);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar la tienda: $error')),
      );
    }
  }

  Future<void> _import() async {
    try {
      final imported =
          await CampaignShopImportExportService.pickAndImportShop();
      if (imported == null) return;
      campaign.shops.add(imported);
      await CampaignStorageService.saveCampaign(campaign);
      await CampaignEconomyService.syncCampaignCurrencies(campaign);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tienda “${imported.name}” importada en ${campaign.name}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo importar la tienda: $error')),
      );
    }
  }

  Future<Character?> _chooseCharacter() async {
    if (widget.isMaster) return null;
    if (widget.buyer != null) return widget.buyer;
    if (characters.isEmpty) return null;
    if (characters.length == 1) return characters.first;
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
    if (widget.isMaster) return;
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
    if (character == null || !mounted) return;

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
                    '${shop.products.length}',
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
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              sliver: SliverList.separated(
                itemCount: shop.products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final product = shop.products[index];
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
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          d.type.label,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colors.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      if (d.type == ItemType.armor &&
                                          d.armor != null) ...[
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
                                                '${d.armor!.category.label} · CA ${d.armor!.baseArmorClass}',
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
                                    ],
                                  ),
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
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Colors.black,
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
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image_rounded,
                          color: Colors.white70,
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
                      color: Colors.transparent,
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
                                  color: Colors.black.withValues(alpha: .62),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.zoom_out_map_rounded,
                                      color: Colors.white,
                                      size: 17,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Ver imagen',
                                      style: TextStyle(
                                        color: Colors.white,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(definition.type.label)),
              if (definition.type == ItemType.armor && definition.armor != null)
                Chip(
                  avatar: const Icon(Icons.shield_rounded, size: 18),
                  label: Text(
                    '${definition.armor!.category.label} · CA ${definition.armor!.baseArmorClass}',
                  ),
                ),
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
