import 'package:flutter/material.dart';

import '../models/campaign.dart';
import '../models/campaign_shop.dart';
import '../models/character.dart';
import '../services/campaign_storage_service.dart';
import '../services/character_storage_service.dart';

class CampaignShopScreen extends StatefulWidget {
  final Campaign campaign;
  final String shopId;
  const CampaignShopScreen({
    super.key,
    required this.campaign,
    required this.shopId,
  });

  @override
  State<CampaignShopScreen> createState() => _CampaignShopScreenState();
}

class _CampaignShopScreenState extends State<CampaignShopScreen> {
  late Campaign campaign;
  CampaignShop? shop;
  List<Character> characters = [];
  Character? selectedCharacter;

  @override
  void initState() {
    super.initState();
    campaign = widget.campaign;
    _reload();
  }

  void _reload() {
    campaign = CampaignStorageService.getCampaign(campaign.id) ?? campaign;
    shop = campaign.shops.where((e) => e.id == widget.shopId).firstOrNull;
    characters = CharacterStorageService.getCharacters()
        .where((e) => e.campaignId == campaign.id)
        .toList();
    if (selectedCharacter != null) {
      selectedCharacter = characters
          .where((e) => e.id == selectedCharacter!.id)
          .firstOrNull;
    }
    selectedCharacter ??= characters.firstOrNull;
    if (mounted) setState(() {});
  }

  Future<void> _buy(CampaignShopStockItem item) async {
    final character = selectedCharacter;
    final currentShop = shop;
    if (character == null || currentShop == null) return;
    final ok = await CampaignStorageService.purchase(
      campaign: campaign,
      shop: currentShop,
      character: character,
      stockItem: item,
    );
    if (!mounted) return;
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${item.definition.name} comprado para ${character.name}.'
              : 'No tienes suficiente ${currentShop.currencyName}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentShop = shop;
    if (currentShop == null)
      return const Scaffold(body: Center(child: Text('Tienda no encontrada')));
    final balance = selectedCharacter == null
        ? 0
        : CampaignStorageService.currencyBalance(
            selectedCharacter!,
            campaign,
            currentShop,
          );
    return Scaffold(
      appBar: AppBar(title: Text(currentShop.name)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentShop.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (currentShop.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(currentShop.description),
                  ],
                  const SizedBox(height: 14),
                  DropdownButtonFormField<Character>(
                    value: selectedCharacter,
                    decoration: const InputDecoration(
                      labelText: 'Comprar para',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    items: characters
                        .map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.name)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedCharacter = v),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded),
                      const SizedBox(width: 8),
                      Text(
                        '$balance ${currentShop.currencyName}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Productos',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (currentShop.stock.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Esta tienda todavía no tiene productos.'),
              ),
            )
          else
            ...currentShop.stock.map(
              (item) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.inventory_2_rounded),
                  ),
                  title: Text(item.definition.name),
                  subtitle: Text('${item.price} ${currentShop.currencyName}'),
                  trailing: FilledButton(
                    onPressed:
                        selectedCharacter != null && balance >= item.price
                        ? () => _buy(item)
                        : null,
                    child: const Text('Comprar'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
