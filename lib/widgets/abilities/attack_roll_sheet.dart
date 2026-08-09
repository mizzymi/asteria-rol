import 'package:flutter/material.dart';

enum AttackRollMode { normal, advantage, disadvantage }

extension AttackRollModeData on AttackRollMode {
  String get label {
    switch (this) {
      case AttackRollMode.normal:
        return 'Normal';

      case AttackRollMode.advantage:
        return 'Ventaja';

      case AttackRollMode.disadvantage:
        return 'Desventaja';
    }
  }

  String get description {
    switch (this) {
      case AttackRollMode.normal:
        return 'Tira 1d20';

      case AttackRollMode.advantage:
        return 'Tira 2d20 y usa el mayor';

      case AttackRollMode.disadvantage:
        return 'Tira 2d20 y usa el menor';
    }
  }

  IconData get icon {
    switch (this) {
      case AttackRollMode.normal:
        return Icons.casino_rounded;

      case AttackRollMode.advantage:
        return Icons.trending_up_rounded;

      case AttackRollMode.disadvantage:
        return Icons.trending_down_rounded;
    }
  }
}

// =============================================================================
// SELECTOR DE MODO
// =============================================================================

Future<AttackRollMode?> showAttackRollModeSheet(BuildContext context) {
  return showModalBottomSheet<AttackRollMode>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.casino_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tirada de ataque',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          'Elige cómo quieres realizar la tirada.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              ...AttackRollMode.values.map(
                (mode) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AttackModeTile(
                    mode: mode,
                    onTap: () {
                      Navigator.pop(sheetContext, mode);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AttackModeTile extends StatelessWidget {
  final AttackRollMode mode;
  final VoidCallback onTap;

  const _AttackModeTile({required this.mode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  mode.icon,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      mode.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// RESULTADO DEL ATAQUE
// =============================================================================

class AttackResultDialog extends StatelessWidget {
  final String abilityName;

  final AttackRollMode mode;

  final int firstRoll;
  final int? secondRoll;
  final int naturalRoll;

  final int bonus;
  final int total;

  final bool critical;
  final bool criticalFailure;

  final VoidCallback? onRollDamage;

  const AttackResultDialog({
    super.key,
    required this.abilityName,
    required this.mode,
    required this.firstRoll,
    required this.secondRoll,
    required this.naturalRoll,
    required this.bonus,
    required this.total,
    required this.critical,
    required this.criticalFailure,
    required this.onRollDamage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ===============================================================
              // HEADER
              // ===============================================================
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: critical
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      critical
                          ? Icons.local_fire_department_rounded
                          : mode.icon,
                      color: critical
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          abilityName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          mode.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ===============================================================
              // DADOS
              // ===============================================================
              if (secondRoll != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AttackDieResult(
                      value: firstRoll,
                      selected: firstRoll == naturalRoll,
                    ),

                    const SizedBox(width: 14),

                    _AttackDieResult(
                      value: secondRoll!,
                      selected: secondRoll == naturalRoll,
                    ),
                  ],
                )
              else
                _SingleAttackResult(value: naturalRoll),

              if (secondRoll != null) ...[
                const SizedBox(height: 10),

                Text(
                  mode == AttackRollMode.advantage
                      ? 'Se usa el resultado más alto'
                      : 'Se usa el resultado más bajo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ===============================================================
              // CÁLCULO
              // ===============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Resultado natural'),

                        const Spacer(),

                        Text(
                          '$naturalRoll',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        const Text('Modificador'),

                        const Spacer(),

                        Text(
                          _bonusText(bonus),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    const Divider(height: 22),

                    Row(
                      children: [
                        Text(
                          'TOTAL',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const Spacer(),

                        Text(
                          '$total',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (critical || criticalFailure) ...[
                const SizedBox(height: 14),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: critical
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        critical
                            ? Icons.local_fire_department_rounded
                            : Icons.warning_amber_rounded,
                        size: 19,
                      ),

                      const SizedBox(width: 7),

                      Text(
                        critical ? '20 NATURAL · CRÍTICO' : '1 NATURAL',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ===============================================================
              // ACCIONES
              // ===============================================================
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cerrar'),
                    ),
                  ),

                  if (onRollDamage != null) ...[
                    const SizedBox(width: 10),

                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onRollDamage,
                        icon: Icon(
                          critical
                              ? Icons.local_fire_department_rounded
                              : Icons.auto_awesome_rounded,
                        ),
                        label: Text(
                          critical ? 'Resolver crítico' : 'Resolver efectos',
                        ),
                      ),
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

  String _bonusText(int value) {
    return value >= 0 ? '+$value' : '$value';
  }
}

// =============================================================================
// DADO SIMPLE
// =============================================================================

class _SingleAttackResult extends StatelessWidget {
  final int value;

  const _SingleAttackResult({required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 94,
      height: 94,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$value',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),

          Text(
            'd20',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DADO DE VENTAJA / DESVENTAJA
// =============================================================================

class _AttackDieResult extends StatelessWidget {
  final int value;
  final bool selected;

  const _AttackDieResult({required this.value, required this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
        border: selected
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$value',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: selected ? theme.colorScheme.primary : null,
            ),
          ),

          if (selected) ...[
            const SizedBox(height: 2),

            Icon(
              Icons.check_circle_rounded,
              size: 17,
              color: theme.colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }
}
