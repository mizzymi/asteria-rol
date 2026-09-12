import 'dart:io';

import 'package:flutter/material.dart';

import '../models/campaign.dart';
import '../models/character.dart';
import '../services/campaign_image_service.dart';
import '../services/campaign_storage_service.dart';
import '../services/character_storage_service.dart';
import 'campaign_form_screen.dart';
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
    if (!mounted) return;
    setState(() {
      campaign = CampaignStorageService.getCampaign(campaign.id) ?? campaign;
      characters = CharacterStorageService.getCharacters()
          .where((c) => c.campaignId == campaign.id)
          .toList();
    });
  }

  Future<void> _createCharacter() async {
    final result = await Navigator.push<Character>(
      context,
      MaterialPageRoute(builder: (_) => CharacterFormScreen(initialCampaignId: campaign.id)),
    );
    if (result != null) _reload();
  }

  Future<void> _openCharacter(Character character) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CharacterHomeScreen(character: character)));
    _reload();
  }

  Future<void> _editCampaign() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CampaignFormScreen(campaign: campaign)));
    _reload();
  }

  Future<void> _deleteCampaign() async {
    if (characters.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mueve o elimina los personajes de esta campaña antes de borrarla.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar campaña'),
        content: Text('¿Quieres eliminar “${campaign.name}”?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await CampaignImageService.deleteImage(campaign.imagePath);
    await CampaignStorageService.deleteCampaign(campaign.id);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 255,
            pinned: true,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _editCampaign();
                  if (value == 'delete') _deleteCampaign();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_rounded), title: Text('Editar'))),
                  PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline_rounded), title: Text('Eliminar'))),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (campaign.imagePath != null && File(campaign.imagePath!).existsSync())
                    Image.file(File(campaign.imagePath!), fit: BoxFit.cover)
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [colors.primaryContainer, colors.secondaryContainer],
                        ),
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: .7)],
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
                        Text(campaign.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                        if (campaign.description.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(campaign.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(child: _Stat(icon: Icons.groups_rounded, value: '${characters.length}', label: 'Personajes')),
                  const SizedBox(width: 10),
                  Expanded(child: _Stat(icon: Icons.favorite_rounded, value: '${characters.fold<int>(0, (sum, c) => sum + c.currentHealth)}', label: 'PV actuales')),
                  const SizedBox(width: 10),
                  Expanded(child: _Stat(icon: Icons.backpack_rounded, value: '${characters.fold<int>(0, (sum, c) => sum + c.inventoryItems.length)}', label: 'Objetos')),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text('Personajes', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const Spacer(),
                  FilledButton.tonalIcon(onPressed: _createCharacter, icon: const Icon(Icons.add_rounded), label: const Text('Añadir')),
                ],
              ),
            ),
          ),
          if (characters.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded, size: 64, color: colors.primary),
                      const SizedBox(height: 14),
                      Text('Esta campaña aún no tiene personajes', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      const Text('Añade tu primer personaje para empezar la aventura.', textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      FilledButton.icon(onPressed: _createCharacter, icon: const Icon(Icons.add_rounded), label: const Text('Crear personaje')),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index.isOdd) return const SizedBox(height: 10);
                    final character = characters[index ~/ 2];
                    return _CharacterTile(
                      character: character,
                      onTap: () => _openCharacter(character),
                    );
                  },
                  childCount: characters.length * 2 - 1,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: characters.isEmpty ? null : FloatingActionButton(onPressed: _createCharacter, child: const Icon(Icons.add_rounded)),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Stat({required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(18), border: Border.all(color: colors.outlineVariant)),
      child: Column(children: [Icon(icon, color: colors.primary), const SizedBox(height: 5), Text(value, style: Theme.of(context).textTheme.titleLarge), Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center)]),
    );
  }
}

class _CharacterTile extends StatelessWidget {
  final Character character;
  final VoidCallback onTap;
  const _CharacterTile({required this.character, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxHealth = character.maxHealth <= 0 ? 1 : character.maxHealth;
    final health = (character.currentHealth / maxHealth).clamp(0.0, 1.0);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            CircleAvatar(
              radius: 31,
              backgroundImage: character.avatarPath != null && File(character.avatarPath!).existsSync() ? FileImage(File(character.avatarPath!)) : null,
              child: character.avatarPath == null ? Text(character.name.isEmpty ? '?' : character.name[0].toUpperCase()) : null,
            ),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(character.name, style: Theme.of(context).textTheme.titleMedium),
              Text('${character.dndClass.name} · Nivel ${character.level}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: health, minHeight: 6)),
              const SizedBox(height: 4),
              Text('${character.currentHealth} / ${character.maxHealth} PV', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.primary)),
            ])),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
      ),
    );
  }
}
