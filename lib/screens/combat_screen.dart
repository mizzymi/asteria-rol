import 'package:flutter/material.dart';

import '../models/formulas/formula_bonus.dart';
import '../models/character.dart';
import '../models/character_resource.dart';
import '../models/item.dart';
import '../models/ability.dart';
import '../models/passive.dart';
import '../models/character_content_folder.dart';

import '../services/character_effect_application_service.dart';
import '../services/action_resolution_flow.dart';
import '../services/character_storage_service.dart';

import '../widgets/combat/combat_content_folder_card.dart';
import '../widgets/passives/passive_roll_dialog.dart';
import '../widgets/combat/combat_passive_card.dart';
import '../widgets/combat/combat_weapon_card.dart';
import '../widgets/combat/combat_health_card.dart';
import '../widgets/combat/combat_empty_section.dart';
import '../widgets/combat/combat_state_card.dart';
import '../widgets/character_home/combat_stat_card.dart';
import '../widgets/character_home/character_home_colors.dart';
import '../widgets/combat/combat_resource_card.dart';
import '../widgets/action_resolution/result/action_resolution_result_dialog.dart';
import '../widgets/combat/combat_ability_card.dart';
import '../widgets/abilities/ability_card.dart';
import '../widgets/passives/passive_card.dart';

import 'journal_screen.dart';

class CombatScreen extends StatefulWidget {
  final Character character;

  const CombatScreen({super.key, required this.character});

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> {
  Character get character => widget.character;

  String? _currentContentFolderId;

  bool _showingContentItemsRoot = false;

  String? _currentContentItemId;

  CharacterContentFolder? get _currentContentFolder {
    return character.contentFolderById(_currentContentFolderId);
  }

  ItemDefinition? get _currentContentItem {
    final itemId = _currentContentItemId;

    if (itemId == null) {
      return null;
    }

    return character.itemDefinitionById(itemId);
  }

  bool get _contentCanGoBack {
    return _currentContentFolderId != null ||
        _showingContentItemsRoot ||
        _currentContentItemId != null;
  }

  String get _contentTitle {
    final item = _currentContentItem;

    if (item != null) {
      return item.name;
    }

    if (_showingContentItemsRoot) {
      return 'Objetos';
    }

    final folder = _currentContentFolder;

    if (folder != null) {
      return folder.name;
    }

    return 'Habilidades y pasivas';
  }

  void _openContentFolder(String folderId) {
    setState(() {
      _currentContentFolderId = folderId;

      _showingContentItemsRoot = false;

      _currentContentItemId = null;
    });
  }

  void _openContentItems() {
    setState(() {
      _currentContentFolderId = null;

      _showingContentItemsRoot = true;

      _currentContentItemId = null;
    });
  }

  void _openContentItem(ItemDefinition item) {
    setState(() {
      _currentContentFolderId = null;

      _showingContentItemsRoot = false;

      _currentContentItemId = item.id;
    });
  }

  void _goBackContent() {
    if (_currentContentItemId != null) {
      setState(() {
        _currentContentItemId = null;

        _showingContentItemsRoot = true;
      });

      return;
    }

    if (_showingContentItemsRoot) {
      setState(() {
        _showingContentItemsRoot = false;
      });

      return;
    }

    final folder = _currentContentFolder;

    if (folder != null) {
      setState(() {
        _currentContentFolderId = folder.parentId;
      });
    }
  }

  // ===========================================================================
  // GUARDAR
  // ===========================================================================

  Future<void> _save() async {
    await CharacterStorageService.saveCharacter(character);
  }

  Future<void> _showAbilityDetails(
    CharacterAbility ability,
    ItemDefinition? sourceItem,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.94,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            child: AbilityCard(
              ability: ability,
              character: character,
              sourceItem: sourceItem,
              onEdit: null,
              onDelete: null,
              onRestore: null,
              onMove: null,
              initialExpanded: true,
              onCombatActions: () {
                _resolveAbility(ability);
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPassiveDetails(
    CharacterPassive passive,
    ItemDefinition? sourceItem,
  ) async {
    final canApplyLinkedEffects =
        passive.linkedEffects.isNotEmpty &&
        !passive.hasAutomaticLinkedEffectTriggers;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.94,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            child: PassiveCard(
              passive: passive,
              character: character,
              sourceItem: sourceItem,
              showPassiveBadge: true,
              initialExpanded: true,
              onRoll: passive.hasRoll
                  ? () {
                      _rollPassive(passive);
                    }
                  : null,
              onApplyLinkedEffects: canApplyLinkedEffects
                  ? () {
                      _applyPassiveLinkedEffects(passive);
                    }
                  : null,
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // COMBATE
  // ===========================================================================

  Future<void> _toggleCombat() async {
    setState(() {
      if (character.combatActive) {
        character.endCombat();
      } else {
        character.startCombat();
      }
    });

    await _save();
  }

  Future<void> _toggleTurn() async {
    setState(() {
      if (character.turnActive) {
        character.endTurn();
      } else {
        character.startTurn();
      }
    });

    await _save();
  }

  Future<void> _nextRound() async {
    setState(() {
      character.startNextRound();
    });

    await _save();
  }

  Future<void> _editHealth() async {
    final input =
        await showDialog<({String operation, int amount, String damageType})>(
          context: context,
          builder: (dialogContext) {
            return const _SimpleHealthDialog();
          },
        );

    if (input == null || input.amount <= 0 || !mounted) {
      return;
    }

    final flow = ActionResolutionFlow(character: character);
    final isDamage = input.operation == '-';

    await flow.resolveHealthChange(
      context,
      baseAmount: input.amount,
      isDamage: isDamage,
      damageType: isDamage ? input.damageType : '',
    );

    if (!mounted) {
      return;
    }

    setState(() {});
    await _save();
  }

  Future<void> _editResource(CharacterResource resource) async {
    final effectiveCurrent = character.resourceEffectiveCurrent(resource);

    final effectiveMax = character.resourceEffectiveMax(resource);

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return _CombatResourceDialog(
          resource: resource,
          currentValue: effectiveCurrent,
          maxValue: effectiveMax,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    character.setResourceValue(resource.id, result);

    if (!mounted) {
      return;
    }

    setState(() {});

    await _save();
  }

  Future<void> _resolveWeapon(ItemDefinition item) async {
    final weapon = item.weapon;

    if (weapon == null) {
      return;
    }

    final flow = ActionResolutionFlow(character: character);

    try {
      final execution = await flow.resolveWeapon(context, weapon: weapon);

      if (execution == null) {
        return;
      }

      await _save();

      if (!mounted) {
        return;
      }

      setState(() {});

      await showActionResolutionResultDialog(
        context,
        character: character,
        execution: execution,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se ha podido resolver el ataque: $error')),
      );
    }
  }

  Future<void> _resolveAbility(CharacterAbility ability) async {
    final flow = ActionResolutionFlow(character: character);

    try {
      final execution = await flow.resolveAbility(context, ability: ability);

      if (execution == null) {
        return;
      }

      await _save();

      if (!mounted) {
        return;
      }

      setState(() {});

      await showActionResolutionResultDialog(
        context,
        character: character,
        execution: execution,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se ha podido resolver la acción: $error')),
      );
    }
  }

  Future<void> _rollPassive(CharacterPassive passive) async {
    if (!passive.enabled || !passive.hasRoll) {
      return;
    }

    await showPassiveRollDialog(
      context,
      character: character,
      passive: passive,
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _applyPassiveLinkedEffects(CharacterPassive passive) async {
    if (!passive.enabled || passive.linkedEffects.isEmpty) {
      return;
    }

    final service = CharacterEffectApplicationService(character: character);

    final applied = service.applyTemplates(passive.linkedEffects);

    if (applied.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {});
    }

    await _save();

    if (!mounted) {
      return;
    }

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
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final equippedWeapons =
        <({InventoryItem inventory, ItemDefinition definition})>[];

    for (final inventoryItem in character.equippedInventoryItems) {
      final definition = character.definitionForInventoryItem(inventoryItem);

      if (definition == null) {
        continue;
      }

      if (definition.type != ItemType.weapon) {
        continue;
      }

      if (definition.weapon == null) {
        continue;
      }

      equippedWeapons.add((inventory: inventoryItem, definition: definition));
    }

    final currentContentItem = _currentContentItem;

    final contentFolders =
        !_showingContentItemsRoot && currentContentItem == null
        ? character.contentFoldersInside(_currentContentFolderId)
        : <CharacterContentFolder>[];

    final contentAbilities = currentContentItem != null
        ? currentContentItem.abilities
        : _showingContentItemsRoot
        ? const <CharacterAbility>[]
        : character.abilitiesInFolder(_currentContentFolderId);

    final contentPassives = currentContentItem != null
        ? currentContentItem.passives
              .where((passive) => passive.enabled)
              .toList(growable: false)
        : _showingContentItemsRoot
        ? const <CharacterPassive>[]
        : character
              .passivesInFolder(_currentContentFolderId)
              .where((passive) => passive.enabled)
              .toList(growable: false);

    final itemFolders = _showingContentItemsRoot
        ? character.equippedContentItems
        : const <ItemDefinition>[];

    final showObjectsFolder =
        _currentContentFolderId == null &&
        !_showingContentItemsRoot &&
        currentContentItem == null &&
        character.equippedContentItems.isNotEmpty;

    return PopScope(
      canPop: !_contentCanGoBack,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _contentCanGoBack) {
          _goBackContent();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _contentCanGoBack
              ? IconButton(
                  tooltip: 'Volver a combate',
                  onPressed: _goBackContent,
                  icon: const Icon(Icons.arrow_back_rounded),
                )
              : null,
          title: const Text('Combate'),
          actions: [
            IconButton(
              tooltip: 'Diario',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JournalScreen(character: character),
                  ),
                );

                if (!mounted) {
                  return;
                }

                setState(() {});
              },
              icon: const Icon(Icons.menu_book_rounded),
            ),
          ],
        ),

        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
            children: [
              // =================================================================
              // ESTADO DEL COMBATE
              // =================================================================
              CombatStateCard(
                character: character,
                onToggleCombat: _toggleCombat,
                onToggleTurn: _toggleTurn,
                onNextRound: _nextRound,
              ),

              const SizedBox(height: 20),

              // =================================================================
              // VIDA
              // =================================================================
              Text(
                'Estado',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              CombatHealthCard(character: character, onTap: _editHealth),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: CombatStatCard(
                      icon: Icons.shield_rounded,
                      title: 'CA',
                      value: '${character.calculatedArmorClass}',
                      color: CharacterHomeColors.armor(context),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: CombatStatCard(
                      icon: Icons.bolt_rounded,
                      title: 'INI',
                      value:
                          '${character.initiative >= 0 ? '+' : ''}${character.initiative}',
                      color: CharacterHomeColors.initiative(context),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: CombatStatCard(
                      icon: Icons.directions_run_rounded,
                      title: 'VEL',
                      value: '${character.totalSpeed}',
                      color: CharacterHomeColors.speed(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 24),

              // =================================================================
              // RECURSOS
              // =================================================================
              Text(
                'Recursos',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              if (character.resources.isEmpty)
                CombatEmptySection(
                  icon: Icons.battery_0_bar_rounded,
                  text: 'Sin recursos configurados',
                )
              else
                ...character.resources
                    .where((resource) => resource.visible)
                    .map(
                      (resource) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: CombatResourceCard(
                          resource: resource,

                          effectiveCurrent: character.resourceEffectiveCurrent(
                            resource,
                          ),

                          effectiveMax: character.resourceEffectiveMax(
                            resource,
                          ),

                          onTap: () {
                            _editResource(resource);
                          },
                        ),
                      ),
                    ),

              const SizedBox(height: 24),

              // =================================================================
              // ARMAS
              // =================================================================
              Text(
                'Armas',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              if (equippedWeapons.isEmpty)
                const CombatEmptySection(
                  icon: Icons.gavel_rounded,
                  text: 'No hay armas equipadas',
                )
              else
                ...equippedWeapons.map(
                  (entry) => CombatWeaponCard(
                    character: character,
                    item: entry.definition,
                    inventoryItem: entry.inventory,
                    onAttack: () {
                      _resolveWeapon(entry.definition);
                    },
                  ),
                ),

              const SizedBox(height: 24),

              const SizedBox(height: 24),

              // =================================================================
              // HABILIDADES Y PASIVAS
              // =================================================================
              Row(
                children: [
                  if (_contentCanGoBack) ...[
                    IconButton(
                      tooltip: 'Volver',
                      onPressed: _goBackContent,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),

                    const SizedBox(width: 4),
                  ],

                  Expanded(
                    child: Text(
                      _contentTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // =================================================================
              // SUBCARPETAS PERSONALIZADAS
              // =================================================================
              ...contentFolders.map(
                (folder) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CombatContentFolderCard(
                    name: folder.name,

                    count: character.directContentCountInFolder(folder.id),

                    onTap: () {
                      _openContentFolder(folder.id);
                    },
                  ),
                ),
              ),

              // =================================================================
              // OBJETOS
              // =================================================================
              if (showObjectsFolder)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CombatContentFolderCard(
                    name: 'Objetos',

                    count: character.equippedContentItems.fold<int>(
                      0,
                      (sum, item) => sum + character.itemContentCount(item),
                    ),

                    automatic: true,

                    onTap: _openContentItems,
                  ),
                ),

              // =================================================================
              // OBJETOS INDIVIDUALES
              // =================================================================
              ...itemFolders.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CombatContentFolderCard(
                    name: item.name,

                    count: character.itemContentCount(item),

                    automatic: true,

                    onTap: () {
                      _openContentItem(item);
                    },
                  ),
                ),
              ),

              // =================================================================
              // HABILIDADES
              // =================================================================
              ...contentAbilities.map((ability) {
                final sourceItem = character.itemForAbility(ability);

                return CombatAbilityCard(
                  character: character,

                  ability: ability,

                  sourceItem: sourceItem,

                  onUse: () {
                    _resolveAbility(ability);
                  },

                  onExpand: () {
                    _showAbilityDetails(ability, sourceItem);
                  },
                );
              }),

              // =================================================================
              // PASIVAS
              // =================================================================
              ...contentPassives.map((passive) {
                final sourceItem = character.itemForPassive(passive);

                final canApplyLinkedEffects =
                    passive.linkedEffects.isNotEmpty &&
                    !passive.hasAutomaticLinkedEffectTriggers;

                return CombatPassiveCard(
                  character: character,

                  passive: passive,

                  sourceItem: sourceItem,

                  onRoll: passive.hasRoll
                      ? () {
                          _rollPassive(passive);
                        }
                      : null,

                  onApplyLinkedEffects: canApplyLinkedEffects
                      ? () {
                          _applyPassiveLinkedEffects(passive);
                        }
                      : null,

                  onExpand: () {
                    _showPassiveDetails(passive, sourceItem);
                  },
                );
              }),

              if (contentFolders.isEmpty &&
                  itemFolders.isEmpty &&
                  !showObjectsFolder &&
                  contentAbilities.isEmpty &&
                  contentPassives.isEmpty)
                const CombatEmptySection(
                  icon: Icons.auto_awesome_outlined,
                  text: 'No hay habilidades ni pasivas en esta carpeta',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CombatHealthDialog extends StatefulWidget {
  final Character character;
  final int currentHealth;
  final int maxHealth;

  const _CombatHealthDialog({
    required this.character,
    required this.currentHealth,
    required this.maxHealth,
  });

  @override
  State<_CombatHealthDialog> createState() => _CombatHealthDialogState();
}

class _CombatHealthDialogState extends State<_CombatHealthDialog> {
  late final TextEditingController amountController;
  String operation = '-';

  // Control de modo de tirada por cada pasiva activada ('digital' o 'physical')
  final Map<String, String> _passiveRollModes = {};

  // Controladores de texto por cada dado individual de cada pasiva: passiveId -> Map<diceIndex, TextEditingController>
  final Map<String, Map<int, TextEditingController>> _diceControllers = {};

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
  }

  @override
  void dispose() {
    amountController.dispose();
    for (var map in _diceControllers.values) {
      for (var controller in map.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  int get baseAmount {
    return int.tryParse(amountController.text.trim()) ?? 0;
  }

  // Filtra las pasivas habilitadas que reaccionan al evento de daño o curación recibido
  List<CharacterPassive> get triggeredPassives {
    final event = operation == '-'
        ? PassiveTriggerEvent.damageReceived
        : PassiveTriggerEvent.healingReceived;

    return widget.character.enabledPassives.where((passive) {
      return passive.triggers.any((t) => t.event == event);
    }).toList();
  }

  // Extrae de forma plana todos los dados individuales que la pasiva requiere tirar (ej. 2d8 -> [8, 8])
  List<int> _getDiceSidesForPassive(CharacterPassive passive) {
    final sidesList = <int>[];

    // Dados de la tirada propia de la pasiva
    for (final pool in passive.rollDicePools) {
      for (int i = 0; i < pool.count; i++) {
        sidesList.add(pool.sides);
      }
    }

    // Dados procedentes de las acciones del trigger
    for (final t in passive.triggers) {
      for (final a in t.actions) {
        for (final pool in a.dicePools) {
          for (int i = 0; i < pool.count; i++) {
            sidesList.add(pool.sides);
          }
        }
      }
    }

    return sidesList;
  }

  TextEditingController _getDiceController(String passiveId, int index) {
    final passiveMap = _diceControllers.putIfAbsent(passiveId, () => {});
    return passiveMap.putIfAbsent(index, () => TextEditingController());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final passives = triggeredPassives;

    int modifierTotal = 0;

    for (final passive in passives) {
      final diceSides = _getDiceSidesForPassive(passive);
      final bool hasAnyDice = diceSides.isNotEmpty || passive.hasRoll;

      if (hasAnyDice) {
        final mode = _passiveRollModes[passive.id] ?? 'digital';
        if (mode == 'physical') {
          // Sumamos los valores introducidos en cada input individual de los dados
          int manualSum = 0;
          for (int i = 0; i < diceSides.length; i++) {
            final textVal = _getDiceController(passive.id, i).text.trim();
            manualSum += int.tryParse(textVal) ?? 0;
          }
          final mod = widget.character.passiveRollModifier(passive);
          modifierTotal += (manualSum + mod);
        } else {
          // Modo digital por defecto (estimación o valor medio de los dados)
          final mod = widget.character.passiveRollModifier(passive);
          int digitalSum = diceSides.fold(
            0,
            (sum, sides) => sum + (sides ~/ 2 + 1),
          ); // Media aprox del dado
          if (diceSides.isEmpty) {
            digitalSum = 4;
            modifierTotal += (digitalSum + mod);
          }
        }
      } else {
        // Modificador estático sin dados
        modifierTotal += widget.character.evaluateFormulaBonus(
          FormulaBonus(flatValue: 1),
          passive: passive,
        );
      }
    }

    final rawAmount = baseAmount;
    final finalAmount = operation == '-'
        ? (rawAmount - modifierTotal).clamp(0, 9999)
        : (rawAmount + modifierTotal);

    final calculated = operation == '-'
        ? (widget.currentHealth - finalAmount).clamp(0, widget.maxHealth)
        : (widget.currentHealth + finalAmount).clamp(0, widget.maxHealth);

    final difference = calculated - widget.currentHealth;
    final resultColor = difference < 0
        ? colors.error
        : difference > 0
        ? CharacterHomeColors.notes(context)
        : colors.onSurfaceVariant;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.favorite_rounded),
          SizedBox(width: 10),
          Text('Puntos de golpe y Triggers'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Vida actual: ${widget.currentHealth} / ${widget.maxHealth}',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),

            // Selector Daño / Curación
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => setState(() => operation = '-'),
                    icon: const Icon(Icons.remove_rounded),
                    label: const Text('Daño'),
                    style: FilledButton.styleFrom(
                      backgroundColor: operation == '-'
                          ? colors.errorContainer
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => setState(() => operation = '+'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Curación'),
                    style: FilledButton.styleFrom(
                      backgroundColor: operation == '+'
                          ? colors.primaryContainer
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            TextField(
              controller: amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: operation == '-'
                    ? 'Daño base recibido'
                    : 'Curación base recibida',
                prefixIcon: Icon(
                  operation == '-'
                      ? Icons.remove_circle_outline_rounded
                      : Icons.add_circle_outline_rounded,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            // SECCIÓN DE PASIVAS CON TRIGGERS ACTIVAS
            if (passives.isNotEmpty && rawAmount > 0) ...[
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Pasivas activadas por el evento:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...passives.map((passive) {
                final mode = _passiveRollModes[passive.id] ?? 'digital';
                final diceSides = _getDiceSidesForPassive(passive);
                final bool hasAnyDice = diceSides.isNotEmpty || passive.hasRoll;

                return Card(
                  elevation: 0,
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          passive.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (passive.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            passive.description,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 10),

                        if (hasAnyDice) ...[
                          // PREGUNTA ARRIBA
                          const Text(
                            '¿Cómo tirar los dados?',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // BOTONES ABAJO (ORGANIZADOS EN FILA SIN DESBORDE)
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('Digital')),
                                  selected: mode == 'digital',
                                  onSelected: (val) => setState(
                                    () => _passiveRollModes[passive.id] =
                                        'digital',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('Físico')),
                                  selected: mode == 'physical',
                                  onSelected: (val) => setState(
                                    () => _passiveRollModes[passive.id] =
                                        'physical',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // SI ES FÍSICO, UN INPUT POR CADA DADO INDIVIDUAL
                          if (mode == 'physical') ...[
                            const SizedBox(height: 12),
                            Text(
                              'Introduce el resultado de cada dado en mesa:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Generamos un campo de texto por cada dado individual encontrado
                            ...List.generate(
                              diceSides.isEmpty ? 1 : diceSides.length,
                              (index) {
                                final sides = diceSides.isNotEmpty
                                    ? diceSides[index]
                                    : 6;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: TextField(
                                    controller: _getDiceController(
                                      passive.id,
                                      index,
                                    ),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'd$sides (Dado ${index + 1})',
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(
                                        Icons.casino_outlined,
                                        size: 20,
                                      ),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                );
                              },
                            ),
                          ],
                        ] else ...[
                          const Text(
                            'Modificador de pasiva aplicado automáticamente.',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 16),

            // DESGLOSE FINAL
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CharacterHomeColors.tintedSurface(
                  context,
                  resultColor,
                  lightStrength: 0.10,
                  darkStrength: 0.16,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    'Impacto final: $finalAmount (${operation == '-' ? 'Daño' : 'Curación'})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: resultColor,
                    ),
                  ),
                  if (passives.isNotEmpty && rawAmount > 0)
                    Text(
                      'Base ($rawAmount) ${operation == '-' ? '-' : '+'} Mod. Pasivas ($modifierTotal)',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context, calculated);
          },
          icon: const Icon(Icons.check_rounded),
          label: const Text('Aplicar'),
        ),
      ],
    );
  }
}

class _CombatResourceDialog extends StatefulWidget {
  final CharacterResource resource;

  final int currentValue;
  final int? maxValue;

  const _CombatResourceDialog({
    required this.resource,
    required this.currentValue,
    required this.maxValue,
  });

  @override
  State<_CombatResourceDialog> createState() => _CombatResourceDialogState();
}

class _CombatResourceDialogState extends State<_CombatResourceDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(text: '${widget.currentValue}');

    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  int get value {
    final parsed = int.tryParse(controller.text.trim()) ?? widget.currentValue;

    if (widget.maxValue != null) {
      return parsed.clamp(0, widget.maxValue!);
    }

    return parsed < 0 ? 0 : parsed;
  }

  int get difference {
    return value - widget.currentValue;
  }

  void _setValue(int newValue) {
    final max = widget.maxValue;

    final safeValue = max != null
        ? newValue.clamp(0, max)
        : newValue < 0
        ? 0
        : newValue;

    setState(() {
      controller.text = '$safeValue';

      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final color = widget.resource.colorFor(context);

    final diff = difference;

    final diffText = diff == 0
        ? 'Sin cambios'
        : diff > 0
        ? '+$diff'
        : '$diff';

    final currentText = widget.maxValue != null
        ? '${widget.currentValue} / ${widget.maxValue}'
        : '${widget.currentValue}';

    return AlertDialog(
      title: Row(
        children: [
          Icon(widget.resource.icon, color: color),

          const SizedBox(width: 10),

          Expanded(child: Text(widget.resource.name)),
        ],
      ),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Valor actual',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            currentText,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 18),

          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: 'Nuevo valor',
              prefixIcon: Icon(widget.resource.icon),
            ),
            onChanged: (_) {
              setState(() {});
            },
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CharacterHomeColors.tintedSurface(
                context,
                color,
                lightStrength: 0.10,
                darkStrength: 0.16,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              diffText,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _setValue(widget.currentValue - 1);
                  },
                  child: const Text('-1'),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _setValue(widget.currentValue + 1);
                  },
                  child: const Text('+1'),
                ),
              ),

              if (widget.maxValue != null) ...[
                const SizedBox(width: 8),

                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _setValue(widget.maxValue!);
                    },
                    child: const Text('Máx'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),

        FilledButton(
          onPressed: () {
            Navigator.pop(context, value);
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

class _SimpleHealthDialog extends StatefulWidget {
  const _SimpleHealthDialog();

  @override
  State<_SimpleHealthDialog> createState() => _SimpleHealthDialogState();
}

class _SimpleHealthDialogState extends State<_SimpleHealthDialog> {
  final amountController = TextEditingController();
  final damageTypeController = TextEditingController();
  String operation = '-';

  @override
  void dispose() {
    amountController.dispose();
    damageTypeController.dispose();
    super.dispose();
  }

  int get amount => int.tryParse(amountController.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.favorite_rounded),
          SizedBox(width: 10),
          Text('Modificar Puntos de Golpe'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => setState(() => operation = '-'),
                  icon: const Icon(Icons.remove_rounded),
                  label: const Text('Daño'),
                  style: FilledButton.styleFrom(
                    backgroundColor: operation == '-'
                        ? colors.errorContainer
                        : colors.errorContainer.withValues(alpha: 0.35),
                    foregroundColor: operation == '-'
                        ? colors.onErrorContainer
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => setState(() => operation = '+'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Curación'),
                  style: FilledButton.styleFrom(
                    backgroundColor: operation == '+'
                        ? colors.primaryContainer
                        : colors.primaryContainer.withValues(alpha: 0.35),
                    foregroundColor: operation == '+'
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: amountController,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: operation == '-'
                  ? 'Cantidad de daño'
                  : 'Cantidad de curación',
              prefixIcon: Icon(
                operation == '-'
                    ? Icons.remove_circle_outline_rounded
                    : Icons.add_circle_outline_rounded,
              ),
            ),
          ),
          if (operation == '-') ...[
            const SizedBox(height: 12),
            TextField(
              controller: damageTypeController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Tipo de daño',
                hintText: 'Fuego, frío, contundente, radiante...',
                prefixIcon: Icon(Icons.local_fire_department_rounded),
                helperText:
                    'Se usará para aplicar automáticamente las resistencias.',
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (amount <= 0) {
              return;
            }

            final damageType = damageTypeController.text.trim();
            if (operation == '-' && damageType.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Indica el tipo de daño recibido.'),
                ),
              );
              return;
            }

            Navigator.pop(context, (
              operation: operation,
              amount: amount,
              damageType: operation == '-' ? damageType : '',
            ));
          },
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}
