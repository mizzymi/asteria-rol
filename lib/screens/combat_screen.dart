import 'package:flutter/material.dart';

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

  CharacterItem? get _currentContentItem {
    final itemId = _currentContentItemId;

    if (itemId == null) {
      return null;
    }

    return character.itemById(itemId);
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

  void _openContentItem(CharacterItem item) {
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
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return _CombatHealthDialog(
          currentHealth: character.currentHealth,
          maxHealth: character.maxHealth,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    final before = character.currentHealth;

    if (result < before) {
      character.takeDamage(before - result);
    } else if (result > before) {
      character.heal(result - before);
    }

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

  Future<void> _resolveWeapon(CharacterItem item) async {
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
    final equippedWeapons = character.items
        .where((item) => item.equipped && item.isWeapon && item.weapon != null)
        .toList(growable: false);
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
        : const <CharacterItem>[];

    final showObjectsFolder =
        _currentContentFolderId == null &&
        !_showingContentItemsRoot &&
        currentContentItem == null &&
        character.equippedContentItems.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Combate')),

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
                    color: CharacterHomeColors.armor,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: CombatStatCard(
                    icon: Icons.bolt_rounded,
                    title: 'INI',
                    value:
                        '${character.initiative >= 0 ? '+' : ''}${character.initiative}',
                    color: CharacterHomeColors.initiative,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: CombatStatCard(
                    icon: Icons.directions_run_rounded,
                    title: 'VEL',
                    value: '${character.totalSpeed}',
                    color: CharacterHomeColors.speed,
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

                        effectiveMax: character.resourceEffectiveMax(resource),

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
                (item) => CombatWeaponCard(
                  character: character,
                  item: item,

                  onAttack: () {
                    _resolveWeapon(item);
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
    );
  }
}

class _CombatHealthDialog extends StatefulWidget {
  final int currentHealth;
  final int maxHealth;

  const _CombatHealthDialog({
    required this.currentHealth,
    required this.maxHealth,
  });

  @override
  State<_CombatHealthDialog> createState() => _CombatHealthDialogState();
}

class _CombatHealthDialogState extends State<_CombatHealthDialog> {
  late final TextEditingController amountController;

  String operation = '-';

  @override
  void initState() {
    super.initState();

    amountController = TextEditingController();
  }

  @override
  void dispose() {
    amountController.dispose();

    super.dispose();
  }

  int get amount {
    return int.tryParse(amountController.text.trim()) ?? 0;
  }

  int get calculated {
    switch (operation) {
      case '+':
        return (widget.currentHealth + amount).clamp(0, widget.maxHealth);

      case '-':
        return (widget.currentHealth - amount).clamp(0, widget.maxHealth);

      default:
        return widget.currentHealth;
    }
  }

  int get difference {
    return calculated - widget.currentHealth;
  }

  String get resultText {
    final diff = difference;

    if (diff == 0) {
      return 'Sin cambios';
    }

    if (diff < 0) {
      return '${diff.abs()} de daño';
    }

    return '$diff de curación';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final diff = difference;

    final resultColor = diff < 0
        ? colors.error
        : diff > 0
        ? CharacterHomeColors.notes
        : colors.onSurfaceVariant;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.favorite_rounded),
          SizedBox(width: 10),
          Text('Puntos de golpe'),
        ],
      ),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===============================================================
            // VIDA ACTUAL
            // ===============================================================
            Text(
              'Vida actual',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              '${widget.currentHealth} / ${widget.maxHealth}',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 18),

            // ===============================================================
            // OPERACIÓN
            // ===============================================================
            Row(
              children: [
                Expanded(
                  child: operation == '-'
                      ? FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              operation = '-';
                            });
                          },
                          icon: const Icon(Icons.remove_rounded),
                          label: const Text('Daño'),
                        )
                      : OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              operation = '-';
                            });
                          },
                          icon: const Icon(Icons.remove_rounded),
                          label: const Text('Daño'),
                        ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: operation == '+'
                      ? FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              operation = '+';
                            });
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Curación'),
                        )
                      : OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              operation = '+';
                            });
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Curación'),
                        ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ===============================================================
            // CANTIDAD
            // ===============================================================
            TextField(
              controller: amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: operation == '-'
                    ? 'Daño recibido'
                    : 'Curación recibida',
                prefixIcon: Icon(
                  operation == '-'
                      ? Icons.remove_circle_outline_rounded
                      : Icons.add_circle_outline_rounded,
                ),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),

            const SizedBox(height: 16),

            // ===============================================================
            // CÁLCULO
            // ===============================================================
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CharacterHomeColors.tintedSurface(
                  context,
                  resultColor,
                  lightStrength: 0.10,
                  darkStrength: 0.16,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Resultado',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '$calculated / ${widget.maxHealth}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: resultColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '${widget.currentHealth} '
                    '$operation '
                    '${amountController.text.trim().isEmpty ? '0' : amountController.text.trim()}'
                    ' = $calculated',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    resultText,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: resultColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
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

    final color = widget.resource.color;

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
