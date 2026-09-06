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
  String _shortRestRule = 'single';

  Future<void> _save() async {
    await CharacterStorageService.saveCharacter(character);
    if (mounted) setState(() {});
  }

  // ===========================================================================
  // CONFIGURACIÓN DE REGLAS DE DESCANSO CORTO
  // ===========================================================================
  Future<void> _configureShortRestRules() async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Configurar Regla de Descanso Corto'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Estándar (1 Dado por uso)'),
                    subtitle: const Text(
                      'Gastas 1 dado de golpe + Constitución por cada uso.',
                    ),
                    value: 'single',
                    groupValue: _shortRestRule,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => _shortRestRule = val);
                        setState(() {});
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Todos los dados (Con. por cada dado)'),
                    subtitle: const Text(
                      'Tiras todos tus dados de golpe y sumas Constitución a cada uno.',
                    ),
                    value: 'all_available',
                    groupValue: _shortRestRule,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => _shortRestRule = val);
                        setState(() {});
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Nivel de dados + Con. al total'),
                    subtitle: const Text(
                      'Tiras todos los dados de golpe equivalentes a tu nivel y añades la Constitución una sola vez al total.',
                    ),
                    value: 'level_dice_single_con',
                    groupValue: _shortRestRule,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => _shortRestRule = val);
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
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

    // 1. Preguntar si se desea tirar en Digital o Físico usando el selector oficial de la app
    final selectedDiceMode = await showActionDiceModeSheet(context);
    if (selectedDiceMode == null || !mounted) return;

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

                    // Si es la regla de un único modificador al total, el modificador de la request es 0 en los dados
                    // y lo sumamos manualmente después, o viceversa. Gestionarlo mediante modifier único:
                    int appliedModifier =
                        (_shortRestRule == 'level_dice_single_con')
                        ? conMod
                        : (conMod * diceCountToRoll);

                    // Construimos la petición de dados usando la estructura interna del ActionDiceResolver
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
                      // Resolución digital automática
                      final diceResult = const ActionDiceResolver().rollDigital(
                        request,
                      );
                      totalHealing = diceResult.parts.fold<int>(
                        0,
                        (sum, part) => sum + part.total,
                      );
                    } else {
                      // Resolución física (pide introducir el valor manual en un diálogo)
                      final inputsBySection = await showPhysicalDiceDialog(
                        context,
                        sections: [
                          PhysicalDiceSection(
                            id: 'hit-dice-physical',
                            title: 'Dados de Golpe (Descanso Corto)',
                            request: request,
                          ),
                        ],
                      );

                      if (inputsBySection == null || !context.mounted) {
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

                    // Aseguramos un mínimo de recuperación de 1 PV por tirada si sale muy bajo
                    if (totalHealing < 1) totalHealing = 1;

                    setState(() {
                      character.currentHealth =
                          (character.currentHealth + totalHealing).clamp(
                            0,
                            character.maxHealth,
                          );
                    });
                    _save();

                    if (!context.mounted) return;
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

    // Aplicar recarga de pasivas de descanso corto
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
      // 1. Restaurar vida al máximo
      character.currentHealth = character.maxHealth;

      // 2. Restaurar cargas de todas las pasivas
      for (final passive in character.passives) {
        if (passive.hasCharges) {
          passive.currentCharges = passive.maxCharges;
        }
      }

      // 3. Restaurar recursos del personaje
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
          // ===================================================================
          // TARJETA DE DESCANSO CORTO
          // ===================================================================
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

          // ===================================================================
          // TARJETA DE DESCANSO LARGO
          // ===================================================================
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
