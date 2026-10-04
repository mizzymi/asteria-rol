import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/campaign.dart';
import '../models/character.dart';
import '../models/dnd_class.dart';
import '../services/app_mode_service.dart';
import '../services/campaign_storage_service.dart';
import '../services/campaign_economy_service.dart';
import '../services/character_import_export_service.dart';
import '../services/character_storage_service.dart';
import '../services/theme_preference_service.dart';
import '../theme/asteria_semantic_colors.dart';
import '../theme/rainbow_action_style.dart';
import 'campaign_detail_screen.dart';
import 'campaign_form_screen.dart';
import 'character_form_screen.dart';
import 'character_home_screen.dart';
import 'item_library_screen.dart';
import 'master_screen.dart';

class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  List<Campaign> campaigns = [];
  List<Character> characters = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      campaigns = CampaignStorageService.getCampaigns();
      characters = CharacterStorageService.getCharacters()
          .where((c) => c.ownerType == 'player')
          .toList();
    });
  }

  Campaign? _campaignFor(Character character) {
    for (final campaign in campaigns) {
      if (campaign.id == character.campaignId) return campaign;
    }
    return null;
  }

  Future<void> _createCampaign() async {
    final result = await Navigator.push<Campaign>(
      context,
      MaterialPageRoute(builder: (_) => const CampaignFormScreen()),
    );
    if (result != null) _reload();
  }

  Future<void> _openCampaign(Campaign campaign) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CampaignDetailScreen(campaign: campaign),
      ),
    );
    _reload();
  }

  Future<void> _openCharacter(Character character) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CharacterHomeScreen(character: character),
      ),
    );
    _reload();
  }

  Future<void> _deleteCharacter(Character character) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final semantic =
            theme.extension<AsteriaSemanticColors>() ??
            AsteriaSemanticColors.asteria(theme.colorScheme);

        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.delete_forever_rounded),
              SizedBox(width: 10),
              Text('Eliminar personaje'),
            ],
          ),
          content: Text(
            '¿Quieres eliminar a "${character.name}"? '
            'Esta acción eliminará el personaje guardado de Asteria.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: RainbowActionStyle.filledButton(
                dialogContext,
                semantic.delete,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await CharacterStorageService.deleteCharacter(character.id);

    if (!mounted) {
      return;
    }

    _reload();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${character.name} ha sido eliminado.')),
    );
  }

  Future<void> _exportCharacter(Character character) async {
    try {
      await CharacterImportExportService.shareCharacter(character);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar el personaje: $error')),
      );
    }
  }

  Future<Campaign?> _chooseCampaign({String title = 'Elegir campaña'}) async {
    if (campaigns.isEmpty) {
      await _createCampaign();
      if (campaigns.isEmpty) return null;
    }
    if (campaigns.length == 1) return campaigns.first;
    if (!mounted) return null;
    return showModalBottomSheet<Campaign>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...campaigns.map(
                (campaign) => ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.auto_stories_rounded),
                  ),
                  title: Text(campaign.name),
                  subtitle: Text(
                    '${characters.where((c) => c.campaignId == campaign.id).length} personajes',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(sheetContext, campaign),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createCharacter() async {
    final campaign = await _chooseCampaign(title: '¿En qué campaña estará?');
    if (campaign == null || !mounted) return;
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

  Future<void> _importCharacter() async {
    try {
      final campaign = await _chooseCampaign(title: 'Importar personaje en…');
      if (campaign == null) return;
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['asteria', 'json'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) {
        throw const FormatException('No se pudo acceder al archivo.');
      }
      final character = await CharacterImportExportService.importFileAsCopy(
        File(path),
      );
      character.campaignId = campaign.id;
      character.ownerType = 'player';
      await CharacterStorageService.saveCharacter(character);
      await CampaignEconomyService.ensureCharacterCurrencies(
        character,
        campaign,
      );
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${character.name} añadido a ${campaign.name}.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo importar el personaje: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final semantic =
        theme.extension<AsteriaSemanticColors>() ??
        AsteriaSemanticColors.asteria(colors);

    final totalShops = campaigns.fold<int>(
      0,
      (sum, campaign) => sum + campaign.shops.length,
    );
    final recentCharacters = characters.take(7).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              sliver: SliverToBoxAdapter(
                child: _Header(onMenu: () => _showMenu(context)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.primaryContainer,
                        colors.secondaryContainer.withValues(alpha: .72),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: colors.surface.withValues(alpha: .72),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.castle_rounded,
                          size: 32,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tu aventura continúa',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              campaigns.isEmpty
                                  ? 'Crea una campaña para empezar a reunir a tus personajes.'
                                  : 'Entra en una campaña y continúa donde lo dejaste.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.auto_awesome_rounded, color: colors.primary),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 2),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.bookmarks_rounded,
                        value: '${campaigns.length}',
                        label: 'Campañas',
                        color: semantic.neutral,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.groups_rounded,
                        value: '${characters.length}',
                        label: 'Personajes',
                        color: semantic.create,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.storefront_rounded,
                        value: '$totalShops',
                        label: 'Tiendas',
                        color: semantic.shop,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Mis campañas',
                  actionLabel: 'Nueva',
                  icon: Icons.add_rounded,
                  onPressed: _createCampaign,
                ),
              ),
            ),
            if (campaigns.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _EmptyCampaigns(onCreate: _createCampaign),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 228,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: campaigns.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final campaign = campaigns[index];
                      final count = characters
                          .where((c) => c.campaignId == campaign.id)
                          .length;
                      return _CampaignCard(
                        campaign: campaign,
                        characterCount: count,
                        onTap: () => _openCampaign(campaign),
                      );
                    },
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Mis personajes',
                  actionLabel: 'Añadir',
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: _createCharacter,
                ),
              ),
            ),
            if (recentCharacters.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: const Text(
                      'Cuando añadas personajes a una campaña aparecerán aquí para acceder a ellos rápidamente.',
                    ),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 178,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: recentCharacters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final character = recentCharacters[index];
                      return _CharacterQuickCard(
                        character: character,
                        campaignName:
                            _campaignFor(character)?.name ?? 'Campaña',
                        onTap: () => _openCharacter(character),
                        onExport: () => _exportCharacter(character),
                        onDelete: () => _deleteCharacter(character),
                      );
                    },
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 34),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.local_library_rounded,
                        title: 'Biblioteca',
                        subtitle: 'Objetos y equipo',
                        color: semantic.library,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ItemLibraryScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.file_download_rounded,
                        title: 'Importar',
                        subtitle: 'Añadir personaje',
                        color: semantic.importAction,
                        onTap: _importCharacter,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: campaigns.isEmpty
          ? FloatingActionButton.extended(
              backgroundColor: semantic.isRainbow
                  ? RainbowActionStyle.background(context, semantic.create)
                  : null,
              foregroundColor: semantic.isRainbow
                  ? RainbowActionStyle.foreground(context)
                  : null,
              onPressed: _createCampaign,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nueva campaña'),
            )
          : null,
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.shield_rounded),
                title: const Text('Entrar como Master'),
                subtitle: const Text(
                  'Gestionar NPC, criaturas, tiendas y misiones',
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await AppModeService.setMode(AsteriaAppMode.master);
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MasterScreen()),
                    (_) => false,
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.settings_rounded,
                  color:
                      (Theme.of(context).extension<AsteriaSemanticColors>() ??
                              AsteriaSemanticColors.asteria(
                                Theme.of(context).colorScheme,
                              ))
                          .settings,
                ),
                title: const Text('Ajustes'),
                subtitle: const Text('Tema y apariencia'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showSettings(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.add_rounded,
                  color:
                      (Theme.of(context).extension<AsteriaSemanticColors>() ??
                              AsteriaSemanticColors.asteria(
                                Theme.of(context).colorScheme,
                              ))
                          .create,
                ),
                title: const Text('Nueva campaña'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _createCampaign();
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1_rounded),
                title: const Text('Nuevo personaje'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _createCharacter();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.file_download_rounded,
                  color:
                      (Theme.of(context).extension<AsteriaSemanticColors>() ??
                              AsteriaSemanticColors.asteria(
                                Theme.of(context).colorScheme,
                              ))
                          .importAction,
                ),
                title: const Text('Importar personaje'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _importCharacter();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSettings(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 22),
            child: ValueListenableBuilder<AsteriaVisualTheme>(
              valueListenable: ThemePreferenceService.current,
              builder: (context, currentTheme, _) {
                final theme = Theme.of(context);
                final colors = theme.colorScheme;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_rounded, color: colors.primary),
                        const SizedBox(width: 10),
                        Text(
                          'Ajustes',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Elige el estilo visual de Asteria. El modo claro u '
                      'oscuro sigue el ajuste del sistema.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Tema',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final option in AsteriaVisualTheme.values) ...[
                      _ThemeOptionCard(
                        option: option,
                        selected: currentTheme == option,
                        onTap: () {
                          ThemePreferenceService.setTheme(option);
                        },
                      ),
                      if (option != AsteriaVisualTheme.values.last)
                        const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  final AsteriaVisualTheme option;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final previewColors = option == AsteriaVisualTheme.rainbow
        ? const [
            Color(0xFFD81B60),
            Color(0xFFD32F2F),
            Color(0xFFEF6C00),
            Color(0xFF2E7D32),
            Color(0xFF1565C0),
            Color(0xFF6A1B9A),
          ]
        : [colors.primary, colors.secondary, colors.tertiary];

    return Material(
      color: selected
          ? colors.primaryContainer.withValues(alpha: 0.55)
          : colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
          width: selected ? 1.6 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  children: previewColors
                      .map(
                        (color) => Container(
                          width: 15,
                          height: previewColors.length > 3 ? 23 : 52,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      option.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? colors.primary : colors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onMenu;
  const _Header({required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [colors.primary, colors.tertiary]),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: Theme.of(context).colorScheme.onInverseSurface,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido a Asteria',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Tu aventura continúa.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final semantic =
                theme.extension<AsteriaSemanticColors>() ??
                AsteriaSemanticColors.asteria(theme.colorScheme);

            return IconButton.filledTonal(
              style: RainbowActionStyle.iconButton(context, semantic.settings),
              tooltip: 'Más opciones',
              onPressed: onMenu,
              icon: const Icon(Icons.more_horiz_rounded),
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleMedium),
                Text(label, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final IconData icon;
  final VoidCallback onPressed;
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.icon,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final int characterCount;
  final VoidCallback onTap;
  const _CampaignCard({
    required this.campaign,
    required this.characterCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasImage =
        campaign.imagePath != null && File(campaign.imagePath!).existsSync();
    return SizedBox(
      width: 270,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      Image.file(File(campaign.imagePath!), fit: BoxFit.cover)
                    else
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colors.primaryContainer,
                              colors.secondaryContainer,
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.castle_rounded,
                          size: 62,
                          color: colors.primary.withValues(alpha: .75),
                        ),
                      ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface.withValues(alpha: .88),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.groups_rounded,
                              size: 15,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 5),
                            Text('$characterCount'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      campaign.description.isEmpty
                          ? '$characterCount personajes'
                          : campaign.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
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

class _CharacterQuickCard extends StatelessWidget {
  final Character character;
  final String campaignName;
  final VoidCallback onTap;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const _CharacterQuickCard({
    required this.character,
    required this.campaignName,
    required this.onTap,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxHp = character.maxHealth <= 0 ? 1 : character.maxHealth;
    final progress = (character.currentHealth / maxHp).clamp(0.0, 1.0);
    final hasAvatar =
        character.avatarPath != null &&
        File(character.avatarPath!).existsSync();
    return SizedBox(
      width: 132,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: colors.primaryContainer,
                    backgroundImage: hasAvatar
                        ? FileImage(File(character.avatarPath!))
                        : null,
                    child: !hasAvatar
                        ? Text(
                            character.name.isEmpty
                                ? '?'
                                : character.name[0].toUpperCase(),
                            style: Theme.of(context).textTheme.headlineSmall,
                          )
                        : null,
                  ),
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Material(
                      color: colors.surfaceContainerHighest,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: PopupMenuButton<String>(
                        tooltip: 'Opciones del personaje',
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_horiz_rounded, size: 20),
                        onSelected: (value) {
                          if (value == 'export') {
                            onExport();
                          }
                          if (value == 'delete') {
                            onDelete();
                          }
                        },
                        itemBuilder: (menuContext) {
                          final theme = Theme.of(menuContext);
                          final semantic =
                              theme.extension<AsteriaSemanticColors>() ??
                              AsteriaSemanticColors.asteria(theme.colorScheme);

                          return [
                            const PopupMenuItem(
                              value: 'export',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.ios_share_rounded),
                                title: Text('Exportar PJ'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.delete_forever_rounded,
                                  color: semantic.delete,
                                ),
                                title: Text(
                                  'Eliminar personaje',
                                  style: TextStyle(color: semantic.delete),
                                ),
                              ),
                            ),
                          ];
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                character.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                '${character.dndClass.label} · Nv. ${character.level}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                campaignName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colors.primary),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(value: progress, minHeight: 5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rainbow = RainbowActionStyle.enabled(context);
    final foreground = rainbow ? RainbowActionStyle.foreground(context) : color;
    final background = rainbow
        ? RainbowActionStyle.background(context, color)
        : Color.lerp(colors.surfaceContainerLow, color, 0.14) ??
              colors.surfaceContainerLow;

    return Card(
      color: background,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: rainbow
                    ? foreground.withValues(alpha: 0.10)
                    : color.withValues(alpha: 0.16),
                child: Icon(icon, color: foreground),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCampaigns extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyCampaigns({required this.onCreate});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_stories_rounded, size: 52, color: colors.primary),
          const SizedBox(height: 10),
          Text(
            'Crea tu primera campaña',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'Los personajes vivirán dentro de sus campañas para tener tus aventuras bien organizadas.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nueva campaña'),
          ),
        ],
      ),
    );
  }
}
