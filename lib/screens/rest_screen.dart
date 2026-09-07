import 'package:flutter/material.dart';
import '../models/ability.dart';
import '../models/character.dart';
import '../models/dice_pool.dart';
import '../models/action_dice_mode.dart';
import '../models/action_dice_request.dart';
import '../models/action_hit_behavior.dart';
import '../services/character_storage_service.dart';
import '../services/action_dice_resolver.dart';
import '../widgets/action_resolution/dice/dice_mode_sheet.dart';
import '../widgets/action_resolution/dice/physical_dice_dialog.dart';

class RestScreen extends StatefulWidget {
  final Character character;

  const RestScreen({super.key, required this.character});

  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen> {
  Character get character => widget.character;

  // Reglas disponibles:
  // 'single': 1 dado + Con
  // 'all_available': Todos los dados + Con (por cada dado)
  // 'level_dice_single_con': Nivel * dados + Constitución única al total
  String get _shortRestRule => character.shortRestRule;
  set _shortRestRule(String value) {
    character.shortRestRule = value;
  }

  Future<void> _save() async {
    await CharacterStorageService.saveCharacter(character);
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
  }

  // ===========================================================================
  // CONFIGURACIÓN DE REGLAS DE DESCANSO CORTO
  // ===========================================================================
  Future<void> _configureShortRestRules() async {
    // Variable temporal dentro del diálogo para manejar la selección antes de aceptar
    String tempSelectedRule = _shortRestRule;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Widget buildDialogRuleOption({
              required String title,
              required String subtitle,
              required String value,
            }) {
              final isSelected = tempSelectedRule == value;
              final colors = Theme.of(dialogContext).colorScheme;

              return InkWell(
                onTap: () {
                  setDialogState(() => tempSelectedRule = value);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected ? colors.primary : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
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

            return AlertDialog(
              title: const Text('Configurar Regla de Descanso Corto'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildDialogRuleOption(
                    title: 'Estándar (1 Dado por uso)',
                    subtitle:
                        'Gastas 1 dado de golpe + Constitución por cada uso.',
                    value: 'single',
                  ),
                  const SizedBox(height: 8),
                  buildDialogRuleOption(
                    title: 'Todos los dados (Con. por cada dado)',
                    subtitle:
                        'Tiras todos tus dados de golpe y sumas Constitución a cada uno.',
                    value: 'all_available',
                  ),
                  const SizedBox(height: 8),
                  buildDialogRuleOption(
                    title: 'Nivel de dados + Con. al total',
                    subtitle:
                        'Tiras todos los dados de golpe equivalentes a tu nivel y añades la Constitución una sola vez al total.',
                    value: 'level_dice_single_con',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    // Guardamos la selección definitiva en el estado y en el personaje
                    setState(() {
                      _shortRestRule = tempSelectedRule;
                      character.shortRestRule = _shortRestRule;
                    });
                    await _save();
                    if (!dialogContext.mounted) return;
                    Navigator.pop(ctx);
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // LÓGICA DE DESCANSO CORTO CON SOPORTE DIGITAL / FÍSICO
  // ===========================================================================
  Future<void> _performShortRest() async {
    int maxHitDice = character.level;
    int conMod = character.constitutionModifier;

    final selectedDiceMode = await showActionDiceModeSheet(context);
    if (selectedDiceMode == null || !mounted) return;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Descanso Corto y Dados de Golpe'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Nivel / Dados disponibles: $maxHitDice',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Salud actual: ${character.currentHealth} / ${character.maxHealth}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Modificador de Constitución: ${conMod >= 0 ? '+$conMod' : conMod}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    const Divider(height: 24),
                    Text(
                      _shortRestRule == 'single'
                          ? 'Regla: Gastar 1 dado (d8) + Constitución.'
                          : _shortRestRule == 'all_available'
                          ? 'Regla: Gastar todos los dados ($maxHitDice × d8) + Constitución por cada dado.'
                          : 'Regla: Tirar nivel de dados ($maxHitDice × d8) + Constitución única al total.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Modo de tirada: ${selectedDiceMode == ActionDiceMode.digital ? 'Digital' : 'Físico'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cerrar'),
                ),
                FilledButton.tonal(
                  onPressed: () async {
                    int diceCountToRoll = (_shortRestRule == 'single')
                        ? 1
                        : maxHitDice;
                    int appliedModifier =
                        (_shortRestRule == 'level_dice_single_con')
                        ? conMod
                        : (conMod * diceCountToRoll);

                    final request = ActionDiceRequest(
                      parts: [
                        ActionDiceRequestPart(
                          id: 'hit-dice-rest',
                          effectId: 'short-rest',
                          effectName: 'Dados de Golpe',
                          effectType: AbilityEffectType.healing,
                          dicePools: [
                            DicePool(count: diceCountToRoll, sides: 8),
                          ],
                          modifier: appliedModifier,
                          hitBehavior: ActionHitBehavior.ignoreHit,
                          sourceType: ActionDiceSourceType.feature,
                          sourceId: 'rest',
                          sourceName: 'Descanso Corto',
                        ),
                      ],
                    );

                    int totalHealing = 0;

                    if (selectedDiceMode == ActionDiceMode.digital) {
                      final diceResult = const ActionDiceResolver().rollDigital(
                        request,
                      );
                      totalHealing = diceResult.parts.fold<int>(
                        0,
                        (sum, part) => sum + part.total,
                      );
                    } else {
                      if (!dialogContext.mounted) return;
                      final inputsBySection = await showPhysicalDiceDialog(
                        dialogContext,
                        sections: [
                          PhysicalDiceSection(
                            id: 'hit-dice-physical',
                            title: 'Dados de Golpe (Descanso Corto)',
                            request: request,
                          ),
                        ],
                      );

                      if (inputsBySection == null || !dialogContext.mounted) {
                        return;
                      }

                      final inputs = inputsBySection['hit-dice-physical'];
                      if (inputs == null) {
                        return;
                      }

                      final diceResult = const ActionDiceResolver()
                          .resolvePhysical(request: request, inputs: inputs);
                      totalHealing = diceResult.parts.fold<int>(
                        0,
                        (sum, part) => sum + part.total,
                      );
                    }

                    if (totalHealing < 1) totalHealing = 1;

                    setState(() {
                      character.currentHealth =
                          (character.currentHealth + totalHealing).clamp(
                            0,
                            character.maxHealth,
                          );
                    });
                    await _save();

                    if (!dialogContext.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '¡Has recuperado un total de $totalHealing PV en el descanso corto!',
                        ),
                      ),
                    );

                    Navigator.pop(ctx);
                  },
                  child: Text(
                    _shortRestRule == 'single'
                        ? 'Tirar 1 Dado (d8)'
                        : 'Tirar Todos los Dados',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    setState(() {
      for (final passive in character.passives) {
        if (passive.hasCharges &&
            passive.rechargeDescription.toLowerCase().contains('corto')) {
          passive.currentCharges = passive.maxCharges;
        }
      }
    });

    await _save();
  }

  // ===========================================================================
  // LÓGICA DE DESCANSO LARGO
  // ===========================================================================
  Future<void> _performLongRest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descanso Largo'),
        content: const Text(
          'Un descanso largo es un período de descanso extendido de al menos 8 horas. '
          'Esto restaurará tus Puntos de Golpe al máximo y recargará todas tus cargas y recursos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Realizar descanso largo'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      character.currentHealth = character.maxHealth;

      for (final passive in character.passives) {
        if (passive.hasCharges) {
          passive.currentCharges = passive.maxCharges;
        }
      }

      for (final resource in character.resources) {
        resource.currentValue = resource.maxValue;
      }
    });

    await _save();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '¡Descanso largo completado! Salud y recursos restaurados.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Zona de Descanso - ${character.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Configurar Reglas de Descanso',
            onPressed: _configureShortRestRules,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.tertiaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.bedtime_outlined,
                          color: colors.onTertiaryContainer,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Descanso Corto',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pausa de 1 hora para gastar dados de golpe y recuperar habilidades específicas.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: _performShortRest,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.hourglass_bottom_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Tomar Descanso Corto'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.hotel_rounded,
                          color: colors.onPrimaryContainer,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Descanso Largo',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '8 horas de descanso profundo. Restaura toda la salud, ranuras y cargas.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _performLongRest,
                      icon: const Icon(Icons.wb_sunny_rounded),
                      label: const Text('Tomar Descanso Largo'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
