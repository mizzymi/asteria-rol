import 'dart:io';

import 'package:flutter/material.dart';

import '../models/campaign.dart';
import '../models/campaign_mission.dart';
import '../models/campaign_shop.dart';
import '../models/character.dart';
import '../services/campaign_economy_service.dart';
import '../services/campaign_image_service.dart';
import '../services/campaign_shop_import_export_service.dart';
import '../services/campaign_storage_service.dart';
import '../services/character_storage_service.dart';
import 'campaign_form_screen.dart';
import 'campaign_mission_detail_screen.dart';
import 'campaign_mission_form_screen.dart';
import 'campaign_shop_detail_screen.dart';
import 'campaign_shop_form_screen.dart';
import 'character_form_screen.dart';
import 'character_home_screen.dart';

class CampaignDetailScreen extends StatefulWidget {
  final Campaign campaign;
  const CampaignDetailScreen({super.key, required this.campaign});
  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  late Campaign campaign;
  List<Character> characters = [];

  @override
  void initState() {
    super.initState();
    campaign = widget.campaign;
    _reload();
  }

  void _reload() {
    campaign = CampaignStorageService.getCampaign(campaign.id) ?? campaign;
    characters = CharacterStorageService.getCharacters()
        .where((c) => c.campaignId == campaign.id)
        .toList();
    if (mounted) setState(() {});
  }

  Future<void> _createCharacter() async {
    final result = await Navigator.push<Character>(
      context,
      MaterialPageRoute(
        builder: (_) => CharacterFormScreen(initialCampaignId: campaign.id),
      ),
    );
    if (result != null) {
      await CampaignEconomyService.ensureCharacterCurrencies(result, campaign);
      _reload();
    }
  }

  Future<void> _openCharacter(Character c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CharacterHomeScreen(character: c)),
    );
    _reload();
  }

  Future<void> _editCampaign() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CampaignFormScreen(campaign: campaign)),
    );
    _reload();
  }

  Future<void> _createShop() async {
    final shop = await Navigator.push<CampaignShop>(
      context,
      MaterialPageRoute(builder: (_) => const CampaignShopFormScreen()),
    );
    if (shop == null) return;
    campaign.shops.add(shop);
    await CampaignStorageService.saveCampaign(campaign);
    await CampaignEconomyService.syncCampaignCurrencies(campaign);
    _reload();
  }

  Future<void> _importShop() async {
    try {
      final shop = await CampaignShopImportExportService.pickAndImportShop();
      if (shop == null) return;
      campaign.shops.add(shop);
      await CampaignStorageService.saveCampaign(campaign);
      await CampaignEconomyService.syncCampaignCurrencies(campaign);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tienda “${shop.name}” importada.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo importar la tienda: $error')),
      );
    }
  }

  Future<void> _createMission() async {
    final mission = await Navigator.push<CampaignMission>(
      context,
      MaterialPageRoute(builder: (_) => const CampaignMissionFormScreen()),
    );
    if (mission == null) return;
    campaign.missions.add(mission);
    await CampaignStorageService.saveCampaign(campaign);
    _reload();
  }

  Future<void> _deleteCampaign() async {
    if (characters.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mueve o elimina los personajes antes de borrar la campaña.',
          ),
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar campaña'),
        content: Text('¿Quieres eliminar “${campaign.name}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await CampaignImageService.deleteImage(campaign.imagePath);
    await CampaignStorageService.deleteCampaign(campaign.id);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _editCampaign();
                  if (v == 'delete') _deleteCampaign();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_rounded),
                      title: Text('Editar campaña'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline_rounded),
                      title: Text('Eliminar campaña'),
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (campaign.imagePath != null &&
                      File(campaign.imagePath!).existsSync())
                    Image.file(File(campaign.imagePath!), fit: BoxFit.cover)
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.primaryContainer,
                            colors.secondaryContainer,
                          ],
                        ),
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: .72),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign.name,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        if (campaign.description.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            campaign.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: _Stat(
                      icon: Icons.groups_rounded,
                      value: '${characters.length}',
                      label: 'Personajes',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Stat(
                      icon: Icons.flag_rounded,
                      value: '${campaign.missions.length}',
                      label: 'Misiones',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Stat(
                      icon: Icons.storefront_rounded,
                      value: '${campaign.shops.length}',
                      label: 'Tiendas',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionTitle(
              title: 'Tiendas',
              actions: [
                IconButton(
                  onPressed: _importShop,
                  tooltip: 'Importar tienda',
                  icon: const Icon(Icons.file_download_rounded),
                ),
                FilledButton.tonalIcon(
                  onPressed: _createShop,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nueva'),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 132,
              child: campaign.shops.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Card(
                        child: Center(
                          child: Text('Aún no hay tiendas en esta campaña.'),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      scrollDirection: Axis.horizontal,
                      itemCount: campaign.shops.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final shop = campaign.shops[i];
                        return _ShopCard(
                          shop: shop,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CampaignShopDetailScreen(
                                  campaign: campaign,
                                  shop: shop,
                                ),
                              ),
                            );
                            _reload();
                          },
                        );
                      },
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionTitle(
              title: 'Misiones',
              actions: [
                FilledButton.tonalIcon(
                  onPressed: _createMission,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nueva'),
                ),
              ],
            ),
          ),
          if (campaign.missions.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('Aún no hay misiones.'),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((_, i) {
                  final mission = campaign.missions[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          mission.completed
                              ? Icons.check_rounded
                              : Icons.flag_rounded,
                        ),
                      ),
                      title: Text(mission.title),
                      subtitle: Text(
                        '${mission.acceptedCharacterIds.length} personajes · ${mission.completed ? 'Completada' : 'Activa'}',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CampaignMissionDetailScreen(
                              campaign: campaign,
                              mission: mission,
                            ),
                          ),
                        );
                        _reload();
                      },
                    ),
                  );
                }, childCount: campaign.missions.length),
              ),
            ),
          SliverToBoxAdapter(
            child: _SectionTitle(
              title: 'Personajes',
              actions: [
                FilledButton.tonalIcon(
                  onPressed: _createCharacter,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Añadir'),
                ),
              ],
            ),
          ),
          if (characters.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, 28),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Text('Esta campaña aún no tiene personajes.'),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((_, i) {
                  final c = characters[i];
                  final hasAvatar =
                      c.avatarPath != null &&
                      c.avatarPath!.isNotEmpty &&
                      File(c.avatarPath!).existsSync();
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: colors.primaryContainer,
                        backgroundImage: hasAvatar
                            ? FileImage(File(c.avatarPath!))
                            : null,
                        child: !hasAvatar
                            ? Text(
                                c.name.isEmpty ? '?' : c.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                      title: Text(c.name),
                      subtitle: Text('${c.race} · Nivel ${c.level}'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _openCharacter(c),
                    ),
                  );
                }, childCount: characters.length),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  const _SectionTitle({required this.title, required this.actions});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        ...actions,
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Stat({required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 5),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            maxLines: 1,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _ShopCard extends StatelessWidget {
  final CampaignShop shop;
  final VoidCallback onTap;
  const _ShopCard({required this.shop, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.storefront_rounded),
              const Spacer(),
              Text(
                shop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                '${shop.products.length} productos · ${shop.currencyName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
