import 'dart:io';
import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../models/campaign_shop.dart';
import '../models/character.dart';
import '../models/pet.dart';
import '../services/campaign_storage_service.dart';
import '../services/character_storage_service.dart';
import '../services/campaign_economy_service.dart';
import '../services/campaign_shop_import_export_service.dart';
import '../services/campaign_import_export_service.dart';
import 'character_form_screen.dart';
import 'character_home_screen.dart';
import 'pet_form_screen.dart';
import 'pet_detail_screen.dart';
import 'campaign_shop_detail_screen.dart';
import 'campaign_shop_form_screen.dart';
import 'campaign_mission_detail_screen.dart';
import 'campaign_mission_form_screen.dart';

class MasterCampaignScreen extends StatefulWidget {
  final Campaign campaign;
  const MasterCampaignScreen({super.key, required this.campaign});
  @override
  State<MasterCampaignScreen> createState() => _MasterCampaignScreenState();
}

class _MasterCampaignScreenState extends State<MasterCampaignScreen> {
  late Campaign campaign;
  List<Character> npcs = [];
  List<Character> creatureHosts = [];
  int _index = 0;

  @override
  void initState() {
    super.initState();
    campaign = widget.campaign;
    _reload();
  }

  void _reload() {
    campaign = CampaignStorageService.getCampaign(campaign.id) ?? campaign;
    final all = CharacterStorageService.getCharacters().where(
      (x) => x.campaignId == campaign.id,
    );
    npcs = all.where((x) => x.ownerType == 'npc').toList();
    creatureHosts = all
        .where((x) => x.ownerType == 'creatureHost' && x.pets.isNotEmpty)
        .toList();
    if (mounted) setState(() {});
  }

  Future<void> _newNpc() async {
    final x = await Navigator.push<Character>(
      context,
      MaterialPageRoute(
        builder: (_) => CharacterFormScreen(
          initialCampaignId: campaign.id,
          ownerType: 'npc',
        ),
      ),
    );
    if (x != null) _reload();
  }

  Future<void> _newCreature() async {
    final pet = await Navigator.push<Pet>(
      context,
      MaterialPageRoute(builder: (_) => const PetFormScreen()),
    );
    if (pet == null) return;
    final host = Character(
      id: 'creature_${DateTime.now().microsecondsSinceEpoch}',
      name: '[Criatura] ${pet.name}',
      campaignId: campaign.id,
      ownerType: 'creatureHost',
      pets: [pet],
    );
    await CharacterStorageService.saveCharacter(host);
    _reload();
  }

  Future<void> _newShop() async {
    final x = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CampaignShopFormScreen()),
    );
    if (x == null) return;
    campaign.shops.add(x);
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

  Future<void> _deleteShop(CampaignShop shop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: const Text('Eliminar tienda'),
        content: Text(
          '¿Quieres eliminar “${shop.name}” de esta campaña? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            icon: const Icon(Icons.delete_rounded),
            label: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    campaign.shops.removeWhere((entry) => entry.id == shop.id);
    await CampaignStorageService.saveCampaign(campaign);
    await CampaignEconomyService.syncCampaignCurrencies(campaign);
    if (!mounted) return;
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tienda “${shop.name}” eliminada.')),
    );
  }

  Future<void> _newMission() async {
    final x = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CampaignMissionFormScreen()),
    );
    if (x == null) return;
    campaign.missions.add(x);
    await CampaignStorageService.saveCampaign(campaign);
    _reload();
  }

  int get _creatureCount =>
      creatureHosts.fold<int>(0, (sum, h) => sum + h.pets.length);

  Future<void> _exportCampaign() async {
    try {
      await CampaignImportExportService.shareCampaign(campaign);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar la campaña: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _overview(),
      _npcPage(),
      _creaturesPage(),
      _shopsPage(),
      _missionsPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(campaign.name),
        actions: [
          IconButton(
            onPressed: _exportCampaign,
            tooltip: 'Exportar campaña completa',
            icon: const Icon(Icons.ios_share_rounded),
          ),
          IconButton(
            onPressed: _reload,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Resumen',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_alt_rounded),
            label: 'NPC',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets_rounded),
            label: 'Criaturas',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Tiendas',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag_rounded),
            label: 'Misiones',
          ),
        ],
      ),
    );
  }

  Widget _overview() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasImage =
        campaign.imagePath != null &&
        campaign.imagePath!.isNotEmpty &&
        File(campaign.imagePath!).existsSync();
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 230,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  Image.file(File(campaign.imagePath!), fit: BoxFit.cover)
                else
                  Container(
                    color: colors.primaryContainer,
                    child: Icon(
                      Icons.landscape_rounded,
                      size: 76,
                      color: colors.primary,
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: .8),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (campaign.description.trim().isNotEmpty) ...[
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
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          sliver: SliverList.list(
            children: [
              Text(
                'Panel de campaña',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.65,
                children: [
                  _OverviewTile(
                    icon: Icons.people_alt_rounded,
                    label: 'NPC',
                    value: '${npcs.length}',
                    onTap: () => setState(() => _index = 1),
                  ),
                  _OverviewTile(
                    icon: Icons.pets_rounded,
                    label: 'Criaturas',
                    value: '$_creatureCount',
                    onTap: () => setState(() => _index = 2),
                  ),
                  _OverviewTile(
                    icon: Icons.storefront_rounded,
                    label: 'Tiendas',
                    value: '${campaign.shops.length}',
                    onTap: () => setState(() => _index = 3),
                  ),
                  _OverviewTile(
                    icon: Icons.flag_rounded,
                    label: 'Misiones',
                    value: '${campaign.missions.length}',
                    onTap: () => setState(() => _index = 4),
                  ),
                ],
              ),
              if (npcs.isNotEmpty) ...[
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'NPC recientes',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _index = 1),
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: npcs.take(6).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _NpcMiniCard(
                      character: npcs[i],
                      onTap: () => _openNpc(npcs[i]),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _npcPage() => _VisualSection(
    title: 'NPC',
    subtitle: '${npcs.length} personajes del Master',
    emptyTitle: 'Aún no hay NPC',
    emptySubtitle: 'Crea personajes completos para dar vida a tu campaña.',
    emptyIcon: Icons.people_alt_rounded,
    onAdd: _newNpc,
    addLabel: 'Nuevo NPC',
    child: LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 800
            ? 4
            : constraints.maxWidth >= 540
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: npcs.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: .78,
          ),
          itemBuilder: (_, i) =>
              _NpcCard(character: npcs[i], onTap: () => _openNpc(npcs[i])),
        );
      },
    ),
    isEmpty: npcs.isEmpty,
  );

  Widget _creaturesPage() {
    final entries = <({Character host, Pet pet})>[];
    for (final host in creatureHosts) {
      for (final pet in host.pets) {
        entries.add((host: host, pet: pet));
      }
    }
    return _VisualSection(
      title: 'Criaturas',
      subtitle: '${entries.length} criaturas de la campaña',
      emptyTitle: 'Aún no hay criaturas',
      emptySubtitle: 'Añade criaturas con sus ataques, habilidades y pasivas.',
      emptyIcon: Icons.pets_rounded,
      onAdd: _newCreature,
      addLabel: 'Nueva criatura',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 800
              ? 4
              : constraints.maxWidth >= 540
              ? 3
              : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .75,
            ),
            itemBuilder: (_, i) => _CreatureCard(
              host: entries[i].host,
              pet: entries[i].pet,
              onTap: () => _openCreature(entries[i].host, entries[i].pet),
            ),
          );
        },
      ),
      isEmpty: entries.isEmpty,
    );
  }

  Widget _shopsPage() => _VisualSection(
    title: 'Tiendas',
    subtitle: '${campaign.shops.length} comercios disponibles',
    emptyTitle: 'Aún no hay tiendas',
    emptySubtitle: 'Crea o importa una tienda para esta campaña.',
    emptyIcon: Icons.storefront_rounded,
    onAdd: _newShop,
    addLabel: 'Nueva tienda',
    secondaryAction: IconButton.filledTonal(
      onPressed: _importShop,
      tooltip: 'Importar tienda',
      icon: const Icon(Icons.file_download_rounded),
    ),
    child: Column(
      children: campaign.shops
          .map(
            (shop) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _WideEntityCard(
                icon: Icons.storefront_rounded,
                title: shop.name,
                subtitle: shop.description.trim().isEmpty
                    ? '${shop.products.length} productos · ${shop.currencyName}'
                    : shop.description,
                meta:
                    '${shop.products.length} productos  ·  ${shop.currencyName}',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CampaignShopDetailScreen(
                        campaign: campaign,
                        shop: shop,
                        isMaster: true,
                      ),
                    ),
                  );
                  _reload();
                },
                trailing: PopupMenuButton<String>(
                  tooltip: 'Opciones de tienda',
                  onSelected: (value) {
                    if (value == 'delete') _deleteShop(shop);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline_rounded),
                        title: Text('Eliminar tienda'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    ),
    isEmpty: campaign.shops.isEmpty,
  );

  Widget _missionsPage() => _VisualSection(
    title: 'Misiones',
    subtitle:
        '${campaign.missions.where((m) => !m.completed).length} activas · ${campaign.missions.where((m) => m.completed).length} completadas',
    emptyTitle: 'Aún no hay misiones',
    emptySubtitle: 'Prepara objetivos y aventuras para la campaña.',
    emptyIcon: Icons.flag_rounded,
    onAdd: _newMission,
    addLabel: 'Nueva misión',
    child: Column(
      children: campaign.missions
          .map(
            (mission) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _WideEntityCard(
                icon: mission.completed
                    ? Icons.task_alt_rounded
                    : Icons.flag_rounded,
                title: mission.title,
                subtitle: mission.description.trim().isEmpty
                    ? (mission.completed
                          ? 'Misión completada'
                          : 'Misión activa')
                    : mission.description,
                meta: mission.completed ? 'Completada' : 'Activa',
                completed: mission.completed,
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
            ),
          )
          .toList(),
    ),
    isEmpty: campaign.missions.isEmpty,
  );

  Future<void> _openNpc(Character character) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CharacterHomeScreen(character: character),
      ),
    );
    _reload();
  }

  Future<void> _openCreature(Character host, Pet pet) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PetDetailScreen(character: host, pet: pet),
      ),
    );
    _reload();
  }
}

class _VisualSection extends StatelessWidget {
  final String title, subtitle, emptyTitle, emptySubtitle, addLabel;
  final IconData emptyIcon;
  final VoidCallback onAdd;
  final Widget child;
  final Widget? secondaryAction;
  final bool isEmpty;
  const _VisualSection({
    required this.title,
    required this.subtitle,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
    required this.onAdd,
    required this.addLabel,
    required this.child,
    required this.isEmpty,
    this.secondaryAction,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(addLabel),
                    ),
                    if (secondaryAction != null) ...[
                      const SizedBox(width: 8),
                      secondaryAction!,
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(
              icon: emptyIcon,
              title: emptyTitle,
              subtitle: emptySubtitle,
              onAdd: onAdd,
              addLabel: addLabel,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
            sliver: SliverToBoxAdapter(child: child),
          ),
      ],
    );
  }
}

class _OverviewTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback onTap;
  const _OverviewTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colors.primary),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NpcCard extends StatelessWidget {
  final Character character;
  final VoidCallback onTap;
  const _NpcCard({required this.character, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final has =
        character.avatarPath != null &&
        character.avatarPath!.isNotEmpty &&
        File(character.avatarPath!).existsSync();
    return _ImageEntityCard(
      imagePath: has ? character.avatarPath : null,
      fallbackIcon: Icons.person_rounded,
      title: character.name,
      subtitle: '${character.race} · Nivel ${character.level}',
      onTap: onTap,
    );
  }
}

class _CreatureCard extends StatelessWidget {
  final Character host;
  final Pet pet;
  final VoidCallback onTap;
  const _CreatureCard({
    required this.host,
    required this.pet,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final has = pet.avatarPath.isNotEmpty && File(pet.avatarPath).existsSync();
    return _ImageEntityCard(
      imagePath: has ? pet.avatarPath : null,
      fallbackIcon: Icons.pets_rounded,
      title: pet.name,
      subtitle:
          '${pet.species}\n${pet.currentHealth}/${pet.maxHealth} PV · CA ${pet.armorClass}',
      onTap: onTap,
    );
  }
}

class _ImageEntityCard extends StatelessWidget {
  final String? imagePath;
  final IconData fallbackIcon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ImageEntityCard({
    required this.imagePath,
    required this.fallbackIcon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .55)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: imagePath != null
                  ? Image.file(File(imagePath!), fit: BoxFit.cover)
                  : Container(
                      color: colors.primaryContainer,
                      child: Icon(
                        fallbackIcon,
                        size: 50,
                        color: colors.primary,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NpcMiniCard extends StatelessWidget {
  final Character character;
  final VoidCallback onTap;
  const _NpcMiniCard({required this.character, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final has =
        character.avatarPath != null &&
        character.avatarPath!.isNotEmpty &&
        File(character.avatarPath!).existsSync();
    return SizedBox(
      width: 112,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundImage: has
                  ? FileImage(File(character.avatarPath!))
                  : null,
              child: has ? null : const Icon(Icons.person_rounded, size: 34),
            ),
            const SizedBox(height: 7),
            Text(
              character.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Nv. ${character.level}',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideEntityCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, meta;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool completed;
  const _WideEntityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.onTap,
    this.trailing,
    this.completed = false,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .55)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: completed
                      ? colors.secondaryContainer
                      : colors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: completed ? colors.secondary : colors.primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meta,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ?? const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, addLabel;
  final VoidCallback onAdd;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onAdd,
    required this.addLabel,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 58, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center),
          const SizedBox(height: 17),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(addLabel),
          ),
        ],
      ),
    ),
  );
}
