import 'dart:io';
import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../models/character.dart';
import '../services/campaign_storage_service.dart';
import '../services/app_mode_service.dart';
import '../services/character_storage_service.dart';
import 'campaign_form_screen.dart';
import 'character_selection_screen.dart';
import 'master_campaign_screen.dart';

class MasterScreen extends StatefulWidget {
  const MasterScreen({super.key});
  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  List<Campaign> campaigns = [];
  List<Character> characters = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    campaigns = CampaignStorageService.getCampaigns();
    characters = CharacterStorageService.getCharacters();
    if (mounted) setState(() {});
  }

  Future<void> _newCampaign() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CampaignFormScreen()),
    );
    _reload();
  }

  int _npcCount(String campaignId) => characters
      .where((c) => c.campaignId == campaignId && c.ownerType == 'npc')
      .length;

  int _creatureCount(String campaignId) => characters
      .where((c) => c.campaignId == campaignId && c.ownerType == 'creatureHost')
      .fold<int>(0, (sum, c) => sum + c.pets.length);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final totalNpc = campaigns.fold<int>(0, (s, c) => s + _npcCount(c.id));
    final totalCreatures = campaigns.fold<int>(
      0,
      (s, c) => s + _creatureCount(c.id),
    );

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.shield_rounded, color: colors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mesa del Master',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Tu mundo, tus historias',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: _newCampaign,
                      tooltip: 'Nueva campaña',
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: _PlayerModeCard(
                  onTap: () async {
                    await AppModeService.setMode(AsteriaAppMode.player);
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const CharacterSelectionScreen()),
                      (_) => false,
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.castle_rounded,
                        value: '${campaigns.length}',
                        label: 'Campañas',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people_alt_rounded,
                        value: '$totalNpc',
                        label: 'NPC',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.pets_rounded,
                        value: '$totalCreatures',
                        label: 'Criaturas',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tus campañas',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _newCampaign,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Nueva'),
                    ),
                  ],
                ),
              ),
            ),
            if (campaigns.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyCampaigns(onCreate: _newCampaign),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                sliver: SliverList.separated(
                  itemCount: campaigns.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) {
                    final campaign = campaigns[i];
                    return _CampaignCard(
                      campaign: campaign,
                      npcCount: _npcCount(campaign.id),
                      creatureCount: _creatureCount(campaign.id),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MasterCampaignScreen(campaign: campaign),
                          ),
                        );
                        _reload();
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayerModeCard extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayerModeCard({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.sports_esports_rounded,
                  color: colors.onPrimary,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entrar como Jugador',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text('Volver a tus campañas y personajes'),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .55)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final int npcCount;
  final int creatureCount;
  final VoidCallback onTap;
  const _CampaignCard({
    required this.campaign,
    required this.npcCount,
    required this.creatureCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasImage =
        campaign.imagePath != null &&
        campaign.imagePath!.isNotEmpty &&
        File(campaign.imagePath!).existsSync();
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .6)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
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
                        size: 62,
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
                          Colors.black.withValues(alpha: .72),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Text(
                      campaign.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (campaign.description.trim().isNotEmpty) ...[
                    Text(
                      campaign.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _CountChip(
                        icon: Icons.people_alt_rounded,
                        text: '$npcCount NPC',
                      ),
                      _CountChip(
                        icon: Icons.pets_rounded,
                        text: '$creatureCount criaturas',
                      ),
                      _CountChip(
                        icon: Icons.storefront_rounded,
                        text: '${campaign.shops.length} tiendas',
                      ),
                      _CountChip(
                        icon: Icons.flag_rounded,
                        text: '${campaign.missions.length} misiones',
                      ),
                    ],
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

class _CountChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _CountChip({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _EmptyCampaigns extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyCampaigns({required this.onCreate});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.castle_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text(
            'Todavía no hay campañas',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Crea tu primera campaña para empezar a preparar el mundo.',
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Crear campaña'),
          ),
        ],
      ),
    ),
  );
}
