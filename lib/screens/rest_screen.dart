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
                        color: isSelected
                            ? colors.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const Divider(height: 24),
                    Text(
                      _shortRestRule == 'single'
                          ? 'Regla: Gastar 1 dado (d8) + Constitución.'
                          : _shortRestRule == 'all_available'
                          ? 'Regla: Gastar todos los dados ($maxHitDice × d8) + Constitución por cada dado.'
                          : 'Regla: Tirar nivel de dados ($maxHitDice × d8) + Constitución única al total.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Modo de tirada: ${selectedDiceMode == ActionDiceMode.digital ? 'Digital' : 'Físico'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
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

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '¡Has recuperado un total de $totalHealing PV en el descanso corto!',
                        ),
                      ),
                    );

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
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
          'Restaurará tus Puntos de Golpe al máximo. Los recursos solo se recuperarán si tienen activada esa opción; las cargas no se modifican.',
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

      for (final resource in character.resources) {
        if (resource.hasMaximum && resource.restoreOnLongRest) {
          character.restoreResourceFull(resource.id, dispatchTriggers: false);
        }
      }
    });

    await _save();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '¡Descanso largo completado! Salud restaurada y recursos configurados recuperados.',
        ),
      ),
    );
  }

  String get _shortRestRuleLabel {
    switch (_shortRestRule) {
      case 'all_available':
        return 'Todos los dados + CON por dado';
      case 'level_dice_single_con':
        return 'Nivel de dados + CON una vez';
      case 'single':
      default:
        return '1 dado + CON';
    }
  }

  double get _healthProgress {
    if (character.maxHealth <= 0) return 0;
    return (character.currentHealth / character.maxHealth).clamp(0.0, 1.0);
  }

  Widget _buildBenefitChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool emphasized = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: emphasized
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: emphasized
              ? colors.primary.withValues(alpha: 0.18)
              : colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: emphasized
                ? colors.onPrimaryContainer
                : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: emphasized
                  ? colors.onPrimaryContainer
                  : colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestCard(
    BuildContext context, {
    required String eyebrow,
    required String title,
    required String description,
    required IconData icon,
    required Color accent,
    required Color accentContainer,
    required Color onAccentContainer,
    required List<Widget> benefits,
    required Widget footer,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 7, color: accent),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: accentContainer,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(icon, color: onAccentContainer, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eyebrow.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.05,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: benefits),
                const SizedBox(height: 18),
                footer,
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hpMissing = (character.maxHealth - character.currentHealth).clamp(
      0,
      character.maxHealth,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Descanso'),
        actions: [
          IconButton.filledTonal(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Configurar descanso corto',
            onPressed: _configureShortRestRules,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primaryContainer,
                  colors.tertiaryContainer.withValues(alpha: 0.82),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.surface.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.nights_stay_rounded,
                        color: colors.onPrimaryContainer,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            character.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            'Recupera fuerzas antes de volver a la aventura',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onPrimaryContainer.withValues(
                                alpha: 0.78,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Puntos de golpe',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Text(
                      '${character.currentHealth} / ${character.maxHealth} PV',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: _healthProgress,
                    minHeight: 10,
                    backgroundColor: colors.surface.withValues(alpha: 0.5),
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    _buildBenefitChip(
                      context,
                      icon: Icons.favorite_rounded,
                      label: hpMissing == 0
                          ? 'Salud completa'
                          : 'Faltan $hpMissing PV',
                      emphasized: hpMissing > 0,
                    ),
                    const SizedBox(width: 8),
                    _buildBenefitChip(
                      context,
                      icon: Icons.shield_outlined,
                      label: 'Nv. ${character.level}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildRestCard(
            context,
            eyebrow: 'Recuperación rápida',
            title: 'Descanso corto',
            description:
                'Gasta dados de golpe para recuperar PV y recarga las pasivas que vuelven tras un descanso corto.',
            icon: Icons.hourglass_bottom_rounded,
            accent: colors.tertiary,
            accentContainer: colors.tertiaryContainer,
            onAccentContainer: colors.onTertiaryContainer,
            benefits: [
              _buildBenefitChip(
                context,
                icon: Icons.casino_rounded,
                label: _shortRestRuleLabel,
              ),
              _buildBenefitChip(
                context,
                icon: Icons.favorite_outline_rounded,
                label: 'Recupera PV',
              ),
              _buildBenefitChip(
                context,
                icon: Icons.bolt_rounded,
                label: 'Recarga pasivas',
              ),
            ],
            footer: FilledButton.tonalIcon(
              onPressed: _performShortRest,
              icon: const Icon(Icons.local_cafe_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: Text('Tomar descanso corto'),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _buildRestCard(
            context,
            eyebrow: 'Recuperación completa',
            title: 'Descanso largo',
            description:
                'Una noche de descanso restaura tus PV al máximo. Solo recupera los recursos que tengan activada esa opción y no modifica las cargas.',
            icon: Icons.bedtime_rounded,
            accent: colors.primary,
            accentContainer: colors.primaryContainer,
            onAccentContainer: colors.onPrimaryContainer,
            benefits: [
              _buildBenefitChip(
                context,
                icon: Icons.favorite_rounded,
                label: 'PV al máximo',
                emphasized: true,
              ),
              _buildBenefitChip(
                context,
                icon: Icons.auto_awesome_rounded,
                label: 'Recursos marcados',
              ),
              _buildBenefitChip(
                context,
                icon: Icons.schedule_rounded,
                label: '8 horas',
              ),
            ],
            footer: FilledButton.icon(
              onPressed: _performLongRest,
              icon: const Icon(Icons.hotel_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: Text('Tomar descanso largo'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'La regla del descanso corto se puede cambiar en cualquier momento desde “Reglas”. Antes de tirar podrás elegir dados físicos o digitales.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
