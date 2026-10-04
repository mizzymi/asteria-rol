import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/character_content_folder.dart';
import '../models/item_definition.dart';
import '../models/ability.dart';
import '../models/character.dart';
import '../models/passive.dart';
import '../models/external_action_transfer.dart';

import '../services/external_action_transfer_storage_service.dart';
import '../services/character_effect_application_service.dart';
import '../services/action_resolution_flow.dart';
import '../services/character_storage_service.dart';
import '../services/action_result_applier.dart';

import '../widgets/common/empty_state.dart';
import '../widgets/passives/passive_roll_dialog.dart';
import '../widgets/combat/combat_action_sheet.dart';
import '../widgets/abilities/ability_card.dart';
import '../widgets/passives/passive_card.dart';
import '../widgets/action_resolution/result/action_resolution_result_dialog.dart';
import '../widgets/action_resolution/result/external_action_import_dialog.dart';

import 'ability_form_screen.dart';
import 'passive_form_screen.dart';

class AbilitiesScreen extends StatefulWidget {
  final Character character;

  final Future<void> Function()? onCharacterChanged;

  const AbilitiesScreen({
    super.key,
    required this.character,
    this.onCharacterChanged,
  });

  @override
  State<AbilitiesScreen> createState() => _AbilitiesScreenState();
}

class _AbilitiesScreenState extends State<AbilitiesScreen> {
  static const String _gridViewPreferenceKey = 'abilities_grid_view';

  Character get character => widget.character;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool gridView = false;
  bool viewPreferenceLoaded = false;

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

  Future<void> _toggleViewMode() async {
    final newValue = !gridView;
    setState(() => gridView = newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gridViewPreferenceKey, newValue);
  }

  String? _currentFolderId;

  bool _showingItemsRoot = false;

  bool _showingSpellsRoot = false;

  String? _currentItemId;

  CharacterContentFolder? get _currentFolder {
    return character.contentFolderById(_currentFolderId);
  }

  ItemDefinition? get _currentItem {
    final id = _currentItemId;

    if (id == null) {
      return null;
    }

    return character.itemDefinitionById(id);
  }

  void _openFolder(String folderId) {
    setState(() {
      _currentFolderId = folderId;
      _showingItemsRoot = false;
      _showingSpellsRoot = false;
      _currentItemId = null;
    });
  }

  void _openItemsRoot() {
    setState(() {
      _currentFolderId = null;
      _showingItemsRoot = true;
      _showingSpellsRoot = false;
      _currentItemId = null;
    });
  }

  void _openItemFolder(ItemDefinition item) {
    setState(() {
      _currentFolderId = null;
      _showingItemsRoot = false;
      _showingSpellsRoot = false;
      _currentItemId = item.id;
    });
  }

  bool get _canGoBackInsideContent {
    return _currentFolderId != null ||
        _showingItemsRoot ||
        _showingSpellsRoot ||
        _currentItemId != null;
  }

  void _goBackInsideContent() {
    if (_currentItemId != null) {
      setState(() {
        _currentItemId = null;
        _showingItemsRoot = true;
      });
      return;
    }

    if (_showingItemsRoot || _showingSpellsRoot) {
      setState(() {
        _showingItemsRoot = false;
        _showingSpellsRoot = false;
      });
      return;
    }

    final folder = _currentFolder;
    if (folder != null) {
      setState(() {
        _currentFolderId = folder.parentId;
      });
    }
  }

  String get _screenTitle {
    final item = _currentItem;

    if (item != null) {
      return item.name;
    }

    if (_showingItemsRoot) {
      return 'Objetos';
    }

    if (_showingSpellsRoot) {
      return 'Grimorio (Conjuros)';
    }

    final folder = _currentFolder;

    if (folder != null) {
      return folder.name;
    }

    return 'Habilidades y pasivas';
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

  Set<String> _abilityFolderSearchScope() {
    final result = <String>{};

    void visit(String? parentId) {
      for (final folder in character.abilityFoldersInside(parentId)) {
        if (result.add(folder.id)) {
          visit(folder.id);
        }
      }
    }

    visit(_currentFolderId);
    return result;
  }

  bool _matchesAbilitySearch(CharacterAbility ability, String query) {
    final haystack = _normalizeSearchText(
      '${ability.name} ${ability.description} ${ability.notes} ${ability.actionType.label}',
    );
    return haystack.contains(query);
  }

  bool _matchesPassiveSearch(CharacterPassive passive, String query) {
    final haystack = _normalizeSearchText(
      '${passive.name} ${passive.description} ${passive.notes}',
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
        hintText: 'Buscar aquí y en subcarpetas',
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

  Future<void> _createFolder() async {
    var folderName = '';

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nueva carpeta'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.folder_rounded),
            ),
            onChanged: (value) {
              folderName = value;
            },
            onSubmitted: (value) {
              final name = value.trim();
              if (name.isEmpty) {
                return;
              }
              Navigator.of(dialogContext).pop(name);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final name = folderName.trim();
                if (name.isEmpty) {
                  return;
                }
                Navigator.of(dialogContext).pop(name);
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    if (result == null || result.trim().isEmpty || !mounted) {
      return;
    }

    setState(() {
      character.createContentFolder(
        name: result.trim(),
        parentId: _currentFolderId,
      );
    });

    await save();
  }

  Future<void> _renameCurrentFolder() async {
    final folder = _currentFolder;
    if (folder == null) {
      return;
    }

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
            onChanged: (value) {
              folderName = value;
            },
            onFieldSubmitted: (value) {
              final name = value.trim();
              if (name.isEmpty) {
                return;
              }
              Navigator.of(dialogContext).pop(name);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final name = folderName.trim();
                if (name.isEmpty) {
                  return;
                }
                Navigator.of(dialogContext).pop(name);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result == null || result.trim().isEmpty || !mounted) {
      return;
    }

    setState(() {
      character.renameContentFolder(folder.id, result.trim());
    });

    await save();
  }

  Future<void> _deleteCurrentFolder() async {
    final folder = _currentFolder;
    if (folder == null) {
      return;
    }

    final confirmed = await _confirmDelete(
      title: 'Eliminar carpeta',
      message:
          '¿Quieres eliminar "${folder.name}"? '
          'Su contenido subirá a la carpeta anterior.',
    );

    if (!confirmed || !mounted) {
      return;
    }

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
      final folders = character.contentFoldersInside(parentId);
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
                        title: const Text('Sin carpeta'),
                        trailing: currentFolderId == null
                            ? Icon(Icons.check_rounded, color: colors.primary)
                            : null,
                        onTap: () {
                          Navigator.pop(sheetContext, '__root__');
                        },
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
                          onTap: () {
                            Navigator.pop(sheetContext, folder.id);
                          },
                        );
                      }),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.create_new_folder_rounded),
                        title: const Text('Nueva carpeta'),
                        onTap: () async {
                          Navigator.pop(sheetContext, '__create__');
                        },
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

  Future<void> moveAbility(CharacterAbility ability) async {
    var selected = await _pickFolder(currentFolderId: ability.folderId);
    if (selected == null || !mounted) return;

    if (selected == '__create__') {
      await _createFolder();
      if (!mounted) return;
      selected = await _pickFolder(currentFolderId: ability.folderId);
      if (selected == null || selected == '__create__' || !mounted) return;
    }

    final folderId = selected == '__root__' ? null : selected;
    setState(() {
      character.moveAbilityToFolder(ability, folderId);
    });
    await save();
  }

  Future<void> movePassive(CharacterPassive passive) async {
    var selected = await _pickFolder(currentFolderId: passive.folderId);
    if (selected == null || !mounted) return;

    if (selected == '__create__') {
      await _createFolder();
      if (!mounted) return;
      selected = await _pickFolder(currentFolderId: passive.folderId);
      if (selected == null || selected == '__create__' || !mounted) return;
    }

    final folderId = selected == '__root__' ? null : selected;
    setState(() {
      character.movePassiveToFolder(passive, folderId);
    });
    await save();
  }

  Future<void> _importExternalAction() async {
    await showExternalActionImportDialog(
      context,
      character: character,
      onCharacterChanged: () async {
        await save();
      },
      onConfirmTransfer: (transfer) {
        return _confirmExternalTransfer(transfer: transfer);
      },
    );

    if (!mounted) return;
    setState(() {});
    await widget.onCharacterChanged?.call();
  }

  Future<bool> _confirmExternalTransfer({
    required ExternalActionTransfer transfer,
  }) async {
    if (!transfer.isConfirmed) {
      throw StateError('La transferencia recibida no es una confirmación.');
    }

    final outcome = transfer.confirmedOutcome;
    if (outcome == null) {
      throw StateError('La confirmación no contiene resultado.');
    }

    final alreadyConfirmed =
        await ExternalActionTransferStorageService.hasConfirmed(
          transfer.transferId,
        );

    if (alreadyConfirmed) {
      return false;
    }

    final confirmationContext =
        await ExternalActionTransferStorageService.getConfirmationContext(
          transfer.transferId,
        );

    if (confirmationContext == null) {
      throw StateError(
        'No se encuentra la acción original de esta confirmación.',
      );
    }

    final applier = ActionResultApplier(character: character);

    applier.dispatchExternalConfirmation(
      context: confirmationContext,
      outcome: outcome,
    );

    await save();
    await ExternalActionTransferStorageService.markConfirmed(
      transfer.transferId,
    );
    await ExternalActionTransferStorageService.removeConfirmationContext(
      transfer.transferId,
    );
    await widget.onCharacterChanged?.call();

    return true;
  }

  Future<void> save() {
    return CharacterStorageService.saveCharacter(character);
  }

  // ===========================================================================
  // ACTION RESOLUTION
  // ===========================================================================

  Future<void> _resolveAbility(CharacterAbility ability) async {
    final flow = ActionResolutionFlow(character: character);

    try {
      final execution = await flow.resolveAbility(context, ability: ability);
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
        SnackBar(content: Text('No se ha podido resolver la acción: $error')),
      );
    }
  }

  // ===========================================================================
  // COMBAT ACTIONS
  // ===========================================================================

  Future<void> showAbilityCombatActions(CharacterAbility ability) async {
    final requiresAttack = ability.requiresAttackRoll;
    final hasDamage = ability.dealsDamage;
    final hasHealing = ability.heals;
    final hasEffects = ability.effects.any((effect) => effect.hasEffect);
    final hasLinkedEffects = ability.linkedEffects.isNotEmpty;
    final canUse =
        !requiresAttack &&
        !hasDamage &&
        !hasHealing &&
        (hasEffects || hasLinkedEffects);

    await CombatActionSheet.show(
      context,
      title: ability.name,
      subtitle: 'Habilidad',
      canAttack: requiresAttack,
      canDamage: !requiresAttack && hasDamage,
      canHeal: !requiresAttack && hasHealing,
      canUse: canUse,
      canCritical: false,
      onAttack: () => _resolveAbility(ability),
      onDamage: () => _resolveAbility(ability),
      onHeal: () => _resolveAbility(ability),
      onUse: () => _resolveAbility(ability),
      onCritical: null,
    );
  }

  Future<void> rollPassive(CharacterPassive passive) async {
    if (!passive.enabled || !passive.hasRoll) return;

    await showPassiveRollDialog(
      context,
      character: character,
      passive: passive,
    );
  }

  Future<void> applyPassiveLinkedEffects(CharacterPassive passive) async {
    if (!passive.enabled || passive.linkedEffects.isEmpty) return;

    final service = CharacterEffectApplicationService(character: character);
    final applied = service.applyTemplates(passive.linkedEffects);
    if (applied.isEmpty) return;

    if (mounted) setState(() {});
    await save();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          applied.length == 1
              ? 'Se ha aplicado ${applied.first.name}.'
              : 'Se han aplicado ${applied.length} efectos.',
        ),
      ),
    );
  }

  // ===========================================================================
  // ABILITIES CRUD
  // ===========================================================================

  Future<void> createAbility() async {
    final ability = await Navigator.push<CharacterAbility>(
      context,
      MaterialPageRoute(
        builder: (_) => AbilityFormScreen(character: character),
      ),
    );
    if (ability == null) return;

    // Al crear una habilidad dentro de una carpeta, la colocamos
    // directamente en la carpeta desde la que se abrió el formulario.
    ability.folderId ??= _currentFolderId;

    setState(() {
      character.addCharacterAbility(ability);
    });
    await save();
  }

  Future<void> editAbility(CharacterAbility ability) async {
    final result = await Navigator.push<CharacterAbility>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AbilityFormScreen(ability: ability, character: character),
      ),
    );
    if (result == null) return;

    setState(() {
      character.updateCharacterAbility(result);
    });
    await save();
  }

  Future<void> deleteAbility(CharacterAbility ability) async {
    final confirmed = await _confirmDelete(
      title: 'Eliminar habilidad',
      message: '¿Quieres eliminar "${ability.name}"?',
    );
    if (!confirmed) return;

    setState(() {
      character.removeCharacterAbility(ability.id);
    });
    await save();
  }

  Future<void> restoreAbility(CharacterAbility ability) async {
    setState(() {
      character.restoreCharacterAbility(ability);
    });
    await save();
  }

  Future<void> restoreAllAbilities() async {
    setState(() {
      character.restoreAllAbilities();
    });
    await save();
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Usos restaurados.')));
  }

  // ===========================================================================
  // PASSIVES CRUD
  // ===========================================================================

  Future<void> createPassive() async {
    final passive = await Navigator.push<CharacterPassive>(
      context,
      MaterialPageRoute(
        builder: (_) => PassiveFormScreen(character: character),
      ),
    );
    if (passive == null) return;

    setState(() {
      character.addPassive(passive);
    });
    await save();
  }

  Future<void> editPassive(CharacterPassive passive) async {
    final result = await Navigator.push<CharacterPassive>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PassiveFormScreen(character: character, passive: passive),
      ),
    );
    if (result == null) return;

    setState(() {
      character.updatePassive(result);
    });
    await save();
  }

  Future<void> deletePassive(CharacterPassive passive) async {
    final confirmed = await _confirmDelete(
      title: 'Eliminar pasiva',
      message: '¿Quieres eliminar "${passive.name}"?',
    );
    if (!confirmed) return;

    setState(() {
      character.removePassive(passive.id);
    });
    await save();
  }

  Future<void> togglePassive(CharacterPassive passive, bool value) async {
    setState(() {
      character.setPassiveEnabled(passive, value);
    });
    await save();
  }

  Future<void> restorePassiveCharge(CharacterPassive passive) async {
    character.addPassiveCharges(passive.id, 1);
    if (mounted) setState(() {});
    await save();
  }

  Future<bool> _confirmDelete({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    return result == true;
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
                  leading: const Icon(Icons.flash_on_rounded),
                  title: const Text('Nueva habilidad'),
                  subtitle: const Text(
                    'Ataques, poderes, curaciones y técnicas',
                  ),
                  onTap: () => Navigator.pop(sheetContext, 'ability'),
                ),
                ListTile(
                  leading: const Icon(Icons.auto_awesome_rounded),
                  title: const Text('Nueva pasiva'),
                  subtitle: const Text(
                    'Rasgos, bonificaciones y efectos permanentes',
                  ),
                  onTap: () => Navigator.pop(sheetContext, 'passive'),
                ),
                ListTile(
                  leading: const Icon(Icons.create_new_folder_rounded),
                  title: const Text('Nueva carpeta'),
                  subtitle: const Text('Organiza habilidades y pasivas'),
                  onTap: () => Navigator.pop(sheetContext, 'folder'),
                ),
              ],
            ),
          ),
        );
      },
    );

    switch (result) {
      case 'ability':
        await createAbility();
        break;
      case 'passive':
        await createPassive();
        break;
      case 'folder':
        await _createFolder();
        break;
    }
  }

  Future<void> _showImageFullscreen({
    required String imagePath,
    required String title,
  }) async {
    final file = File(imagePath);
    if (!file.existsSync()) return;
    await showDialog<void>(
      context: context,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .92),
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Theme.of(context).colorScheme.scrim,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: .8,
                maxScale: 5,
                child: Center(child: Image.file(file, fit: BoxFit.contain)),
              ),
            ),
            SafeArea(
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.scrim),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w800,
                      ),
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

  Widget _detailImageHero({
    required String? imagePath,
    required double alignmentX,
    required double alignmentY,
    required String title,
  }) {
    final path = imagePath?.trim();
    if (path == null || path.isEmpty || !File(path).existsSync()) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0),
          child: InkWell(
            onTap: () => _showImageFullscreen(imagePath: path, title: title),
            child: SizedBox(
              height: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    alignment: Alignment(alignmentX, alignmentY),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Theme.of(context).colorScheme.surface.withValues(alpha: 0), Theme.of(context).colorScheme.scrim.withValues(alpha: 0.60)],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.60),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(9),
                        child: Icon(
                          Icons.zoom_out_map_rounded,
                          color: Theme.of(context).colorScheme.onInverseSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAbilityGridDetails(CharacterAbility ability) async {
    final abilityId = ability.id;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            // El formulario de edición reemplaza la instancia de la habilidad
            // dentro del personaje. Mientras este bottom sheet siga abierto
            // debemos volver a leerla por id para no seguir mostrando la copia
            // antigua capturada al abrir la cuadrícula.
            final currentAbility =
                character.characterAbilityById(abilityId) ?? ability;
            final sourceItem = character.itemForAbility(currentAbility);

            return FractionallySizedBox(
              heightFactor: 0.88,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                child: Column(
                  children: [
                    _detailImageHero(
                      imagePath: currentAbility.imagePath,
                      alignmentX: currentAbility.imageAlignmentX,
                      alignmentY: currentAbility.imageAlignmentY,
                      title: currentAbility.name,
                    ),
                    AbilityCard(
                      key: ValueKey(
                        'grid-detail-${currentAbility.id}-'
                        '${currentAbility.name}-'
                        '${currentAbility.currentUses}',
                      ),
                      ability: currentAbility,
                      character: character,
                      sourceItem: sourceItem,
                      onMove: sourceItem == null
                          ? () async {
                              await moveAbility(currentAbility);
                              if (sheetContext.mounted) {
                                setSheetState(() {});
                              }
                            }
                          : null,
                      onEdit: sourceItem == null
                          ? () async {
                              await editAbility(currentAbility);
                              if (sheetContext.mounted) {
                                setSheetState(() {});
                              }
                            }
                          : null,
                      onDelete: sourceItem == null
                          ? () async {
                              await deleteAbility(currentAbility);
                              if (!sheetContext.mounted) {
                                return;
                              }

                              if (character.characterAbilityById(abilityId) ==
                                  null) {
                                Navigator.of(sheetContext).pop();
                              } else {
                                setSheetState(() {});
                              }
                            }
                          : null,
                      onRestore: currentAbility.hasLimitedUses
                          ? () async {
                              await restoreAbility(currentAbility);
                              if (sheetContext.mounted) {
                                setSheetState(() {});
                              }
                            }
                          : null,
                      onCombatActions: () async {
                        await showAbilityCombatActions(currentAbility);
                        if (sheetContext.mounted) {
                          setSheetState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showPassiveGridDetails(CharacterPassive passive) async {
    final sourceItem = character.itemForPassive(passive);
    final fromItem = sourceItem != null;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.88,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          child: Column(
            children: [
              _detailImageHero(
                imagePath: passive.imagePath,
                alignmentX: passive.imageAlignmentX,
                alignmentY: passive.imageAlignmentY,
                title: passive.name,
              ),
              PassiveCard(
                passive: passive,
                character: character,
                sourceItem: sourceItem,
                showPassiveBadge: true,
                onMove: fromItem ? null : () => movePassive(passive),
                onRoll: passive.hasRoll ? () => rollPassive(passive) : null,
                onApplyLinkedEffects:
                    passive.linkedEffects.isNotEmpty &&
                        !passive.hasAutomaticLinkedEffectTriggers
                    ? () => applyPassiveLinkedEffects(passive)
                    : null,
                onRestoreCharges: passive.usesCharges
                    ? () => restorePassiveCharge(passive)
                    : null,
                onToggle: fromItem
                    ? null
                    : (value) => togglePassive(passive, value),
                onEdit: fromItem ? null : () => editPassive(passive),
                onDelete: fromItem ? null : () => deletePassive(passive),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridContent({
    required BuildContext context,
    required bool searching,
    required List<CharacterContentFolder> folders,
    required List<ItemDefinition> itemFolders,
    required bool showObjectsFolder,
    required List<CharacterAbility> abilities,
    required List<CharacterPassive> passives,
  }) {
    final theme = Theme.of(context);
    final folderCards = <Widget>[
      ...folders.map(
        (folder) => _ContentFolderGridCard(
          icon: Icons.folder_rounded,
          name: folder.name,
          onTap: () => _openFolder(folder.id),
        ),
      ),
      if (showObjectsFolder)
        _ContentFolderGridCard(
          icon: Icons.inventory_2_rounded,
          name: 'Objetos',
          automatic: true,
          onTap: _openItemsRoot,
        ),
      ...itemFolders.map(
        (item) => _ContentFolderGridCard(
          icon: Icons.inventory_2_rounded,
          name: item.name,
          automatic: true,
          onTap: () => _openItemFolder(item),
        ),
      ),
    ];

    final contentCards = <Widget>[
      ...abilities.map(
        (ability) => _AbilityGridCard(
          ability: ability,
          onTap: () => _showAbilityGridDetails(ability),
        ),
      ),
      ...passives.map(
        (passive) => _PassiveGridCard(
          passive: passive,
          onTap: () => _showPassiveGridDetails(passive),
        ),
      ),
    ];

    Widget grid(List<Widget> children) => LayoutBuilder(
      builder: (context, constraints) {
        var columns = 3;
        if (constraints.maxWidth < 360) {
          columns = 2;
        } else if (constraints.maxWidth >= 700) {
          columns = 4;
        }
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1,
          children: children,
        );
      },
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
      children: [
        if (searching)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              '${abilities.length + passives.length} ${(abilities.length + passives.length) == 1 ? 'resultado' : 'resultados'} · Incluye subcarpetas',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (folderCards.isNotEmpty) ...[
          grid(folderCards),
          if (contentCards.isNotEmpty) const SizedBox(height: 18),
        ],
        if (contentCards.isNotEmpty) grid(contentCards),
      ],
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final currentItem = _currentItem;
    final query = _normalizeSearchText(_searchQuery.trim());
    final searching = query.isNotEmpty;

    final folders =
        !searching &&
            !_showingItemsRoot &&
            !_showingSpellsRoot &&
            currentItem == null
        ? character.contentFoldersInside(_currentFolderId)
        : <CharacterContentFolder>[];

    late final List<CharacterAbility> abilities;
    late final List<CharacterPassive> passives;

    if (currentItem != null) {
      abilities = currentItem.abilities
          .where(
            (ability) => !searching || _matchesAbilitySearch(ability, query),
          )
          .toList(growable: false);
      passives = currentItem.passives
          .where(
            (passive) => !searching || _matchesPassiveSearch(passive, query),
          )
          .toList(growable: false);
    } else if (_showingItemsRoot) {
      if (searching) {
        abilities = character.equippedContentItems
            .expand((item) => item.abilities)
            .where((ability) => _matchesAbilitySearch(ability, query))
            .toList(growable: false);
        passives = character.equippedContentItems
            .expand((item) => item.passives)
            .where((passive) => _matchesPassiveSearch(passive, query))
            .toList(growable: false);
      } else {
        abilities = const <CharacterAbility>[];
        passives = const <CharacterPassive>[];
      }
    } else if (_showingSpellsRoot) {
      abilities = const <CharacterAbility>[];
      passives = const <CharacterPassive>[];
    } else if (searching) {
      final scope = _abilityFolderSearchScope();

      // Resultados de las carpetas normales de Habilidades/Pasivas.
      final matchedAbilities = character.characterAbilities
          .where((ability) {
            final folderId = ability.folderId;
            final inScope =
                folderId == _currentFolderId ||
                (folderId != null && scope.contains(folderId));
            return inScope && _matchesAbilitySearch(ability, query);
          })
          .toList();

      final matchedPassives = character.passives
          .where((passive) {
            final folderId = passive.folderId;
            final inScope =
                folderId == _currentFolderId ||
                (folderId != null && scope.contains(folderId));
            return inScope && _matchesPassiveSearch(passive, query);
          })
          .toList();

      // "Objetos" es una carpeta virtual que cuelga de la raíz de esta
      // pantalla. Por tanto, una búsqueda iniciada desde la raíz también debe
      // entrar en ella y recorrer el contenido de TODOS los objetos equipados.
      // Antes solo se buscaba aquí al abrir explícitamente "Objetos", por lo
      // que una pasiva como "Adamantina Pura" dentro de
      // Objetos/Radiant Choir quedaba fuera de la búsqueda global.
      if (_currentFolderId == null) {
        for (final item in character.equippedContentItems) {
          matchedAbilities.addAll(
            item.abilities.where(
              (ability) => _matchesAbilitySearch(ability, query),
            ),
          );
          matchedPassives.addAll(
            item.passives.where(
              (passive) => _matchesPassiveSearch(passive, query),
            ),
          );
        }
      }

      abilities = matchedAbilities;
      passives = matchedPassives;
    } else {
      abilities = character.abilitiesInFolder(_currentFolderId);
      passives = character.passivesInFolder(_currentFolderId);
    }

    final itemFolders = !searching && _showingItemsRoot
        ? character.equippedContentItems
        : const <ItemDefinition>[];

    final showObjectsFolder =
        !searching &&
        _currentFolderId == null &&
        !_showingItemsRoot &&
        !_showingSpellsRoot &&
        currentItem == null &&
        character.equippedContentItems.isNotEmpty;

    final hasContent = searching
        ? abilities.isNotEmpty || passives.isNotEmpty
        : folders.isNotEmpty ||
              abilities.isNotEmpty ||
              passives.isNotEmpty ||
              itemFolders.isNotEmpty ||
              showObjectsFolder ||
              _showingSpellsRoot;

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
            if (abilities.any((ability) => ability.hasLimitedUses))
              IconButton(
                tooltip: 'Restaurar usos',
                onPressed: restoreAllAbilities,
                icon: const Icon(Icons.restart_alt_rounded),
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
              tooltip: 'Importar resultado externo',
              onPressed: _importExternalAction,
              icon: const Icon(Icons.move_to_inbox_rounded),
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
                                : Icons.auto_awesome_rounded,
                            title: searching
                                ? 'Sin resultados'
                                : 'Carpeta vacía',
                            message: searching
                                ? 'No hay habilidades o pasivas que coincidan en esta carpeta ni en sus subcarpetas.'
                                : 'Añade habilidades, pasivas o subcarpetas.',
                            actionLabel: searching ? null : 'Añadir',
                            onAction: searching ? null : _showCreateMenu,
                          )
                        : gridView
                        ? _buildGridContent(
                            context: context,
                            searching: searching,
                            folders: folders,
                            itemFolders: itemFolders,
                            showObjectsFolder: showObjectsFolder,
                            abilities: abilities,
                            passives: passives,
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
                            children: [
                              if (searching)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Text(
                                    '${abilities.length + passives.length} ${(abilities.length + passives.length) == 1 ? 'resultado' : 'resultados'} · Incluye subcarpetas',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              // =============================================================
                              // SUBCARPETAS REGULARES
                              // =============================================================
                              ...folders.map(
                                (folder) => _ContentFolderTile(
                                  icon: Icons.folder_rounded,
                                  name: folder.name,
                                  count: character.directContentCountInFolder(
                                    folder.id,
                                  ),
                                  onTap: () => _openFolder(folder.id),
                                ),
                              ),

                              // =============================================================
                              // OBJETOS ROOT
                              // =============================================================
                              if (showObjectsFolder)
                                _ContentFolderTile(
                                  icon: Icons.inventory_2_rounded,
                                  name: 'Objetos',
                                  count: character.equippedContentItems
                                      .fold<int>(
                                        0,
                                        (sum, item) =>
                                            sum +
                                            character.itemContentCount(item),
                                      ),
                                  automatic: true,
                                  onTap: _openItemsRoot,
                                ),

                              // =============================================================
                              // CARPETAS DE OBJETO
                              // =============================================================
                              ...itemFolders.map(
                                (item) => _ContentFolderTile(
                                  icon: Icons.inventory_2_rounded,
                                  name: item.name,
                                  count: character.itemContentCount(item),
                                  automatic: true,
                                  onTap: () => _openItemFolder(item),
                                ),
                              ),

                              // =============================================================
                              // CONTENIDO (HABILIDADES Y PASIVAS)
                              // =============================================================
                              if (abilities.isNotEmpty ||
                                  passives.isNotEmpty) ...[
                                if (folders.isNotEmpty ||
                                    itemFolders.isNotEmpty ||
                                    showObjectsFolder)
                                  const SizedBox(height: 14),

                                ...abilities.map((ability) {
                                  final sourceItem = character.itemForAbility(
                                    ability,
                                  );
                                  return AbilityCard(
                                    ability: ability,
                                    character: character,
                                    sourceItem: sourceItem,
                                    onMove: sourceItem == null
                                        ? () => moveAbility(ability)
                                        : null,
                                    onEdit: sourceItem == null
                                        ? () => editAbility(ability)
                                        : null,
                                    onDelete: sourceItem == null
                                        ? () => deleteAbility(ability)
                                        : null,
                                    onRestore: ability.hasLimitedUses
                                        ? () => restoreAbility(ability)
                                        : null,
                                    onCombatActions: () =>
                                        showAbilityCombatActions(ability),
                                  );
                                }),

                                ...passives.map((passive) {
                                  final sourceItem = character.itemForPassive(
                                    passive,
                                  );
                                  final fromItem = sourceItem != null;

                                  return PassiveCard(
                                    passive: passive,
                                    character: character,
                                    sourceItem: sourceItem,
                                    showPassiveBadge: true,
                                    onMove: fromItem
                                        ? null
                                        : () => movePassive(passive),
                                    onRoll: passive.hasRoll
                                        ? () => rollPassive(passive)
                                        : null,
                                    onApplyLinkedEffects:
                                        passive.linkedEffects.isNotEmpty &&
                                            !passive
                                                .hasAutomaticLinkedEffectTriggers
                                        ? () =>
                                              applyPassiveLinkedEffects(passive)
                                        : null,
                                    onRestoreCharges: passive.usesCharges
                                        ? () => restorePassiveCharge(passive)
                                        : null,
                                    onToggle: fromItem
                                        ? null
                                        : (value) =>
                                              togglePassive(passive, value),
                                    onEdit: fromItem
                                        ? null
                                        : () => editPassive(passive),
                                    onDelete: fromItem
                                        ? null
                                        : () => deletePassive(passive),
                                  );
                                }),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
        floatingActionButton:
            _showingItemsRoot || _showingSpellsRoot || currentItem != null
            ? null
            : FloatingActionButton.extended(
                onPressed: _showCreateMenu,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Añadir'),
              ),
      ),
    );
  }
}

class _FolderOption {
  final CharacterContentFolder folder;
  final int depth;

  const _FolderOption({required this.folder, required this.depth});
}

class _ContentFolderTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final int count;
  final bool automatic;
  final VoidCallback onTap;

  const _ContentFolderTile({
    required this.icon,
    required this.name,
    required this.count,
    required this.onTap,
    this.automatic = false,
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (automatic)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
              ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _ContentFolderGridCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final bool automatic;
  final VoidCallback onTap;

  const _ContentFolderGridCard({
    required this.icon,
    required this.name,
    required this.onTap,
    this.automatic = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: colors.primary),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (automatic) ...[
                    const SizedBox(width: 3),
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AbilityGridCard extends StatelessWidget {
  final CharacterAbility ability;
  final VoidCallback onTap;

  const _AbilityGridCard({required this.ability, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _CompactContentGridCard(
      name: ability.name,
      imagePath: ability.imagePath,
      imageAlignmentX: ability.imageAlignmentX,
      imageAlignmentY: ability.imageAlignmentY,
      fallbackIcon: Icons.bolt_rounded,
      onTap: onTap,
    );
  }
}

class _PassiveGridCard extends StatelessWidget {
  final CharacterPassive passive;
  final VoidCallback onTap;

  const _PassiveGridCard({required this.passive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: passive.enabled ? 1 : 0.62,
      child: _CompactContentGridCard(
        name: passive.name,
        imagePath: passive.imagePath,
        imageAlignmentX: passive.imageAlignmentX,
        imageAlignmentY: passive.imageAlignmentY,
        fallbackIcon: Icons.auto_awesome_rounded,
        onTap: onTap,
      ),
    );
  }
}

class _CompactContentGridCard extends StatelessWidget {
  final String name;
  final String? imagePath;
  final double imageAlignmentX;
  final double imageAlignmentY;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  const _CompactContentGridCard({
    required this.name,
    required this.imagePath,
    this.imageAlignmentX = 0,
    this.imageAlignmentY = 0,
    required this.fallbackIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final path = imagePath?.trim();
    final file = path == null || path.isEmpty ? null : File(path);
    final hasImage = file?.existsSync() ?? false;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.file(
                file!,
                fit: BoxFit.cover,
                alignment: Alignment(imageAlignmentX, imageAlignmentY),
              )
            else
              ColoredBox(
                color: colors.primary,
                child: Center(
                  child: Icon(fallbackIcon, size: 34, color: Theme.of(context).colorScheme.onInverseSurface),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.42, 1],
                  colors: [Theme.of(context).colorScheme.surface.withValues(alpha: 0), Theme.of(context).colorScheme.scrim.withValues(alpha: 0.80)],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 9),
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    shadows:  [
                      Shadow(blurRadius: 3, color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.54)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
