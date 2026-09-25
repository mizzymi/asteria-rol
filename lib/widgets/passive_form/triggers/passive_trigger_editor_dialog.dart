import 'package:flutter/material.dart';

import '../../../models/skill.dart';
import '../../../models/action_external_requirement.dart';
import '../../../models/character.dart';
import '../../../models/character_effect.dart';
import '../../../models/passive.dart';
import '../../../models/formulas/character_formula.dart';
import '../../../models/dice_pool.dart';

import '../../forms/common/formula_input_section.dart';

import 'passive_trigger_labels.dart';

enum TriggerTargetConditionPreset {
  none,

  wounded,
  fullHealth,

  belowPercent,
  atOrBelowPercent,
  abovePercent,
  atOrAbovePercent,

  self,
  external,
}

Future<PassiveTrigger?> showPassiveTriggerEditorDialog(
  BuildContext context, {
  required PassiveTrigger trigger,
  Character? character,
  CharacterPassive? passive,
  List<CharacterEffect> linkedEffects = const [],
}) {
  return showDialog<PassiveTrigger>(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return PassiveTriggerEditorDialog(
        trigger: trigger,
        character: character,
        linkedEffects: linkedEffects,
      );
    },
  );
}

class PassiveTriggerEditorDialog extends StatefulWidget {
  final PassiveTrigger trigger;

  final Character? character;

  final List<CharacterEffect> linkedEffects;

  const PassiveTriggerEditorDialog({
    super.key,
    required this.trigger,
    this.character,
    this.linkedEffects = const [],
  });

  @override
  State<PassiveTriggerEditorDialog> createState() =>
      _PassiveTriggerEditorDialogState();
}

class _PassiveTriggerEditorDialogState
    extends State<PassiveTriggerEditorDialog> {
  late PassiveTrigger trigger;

  late final TextEditingController conditionController;

  late final TextEditingController customEventController;

  late final TextEditingController percentController;

  TriggerTargetConditionPreset preset = TriggerTargetConditionPreset.none;

  @override
  void initState() {
    super.initState();

    trigger = PassiveTrigger.fromMap(widget.trigger.toMap());

    _normalizeTriggerMode();

    conditionController = TextEditingController(
      text: trigger.condition?.expression ?? '',
    );

    customEventController = TextEditingController(
      text: trigger.customEvent ?? '',
    );

    percentController = TextEditingController(text: '50');
  }

  @override
  void dispose() {
    conditionController.dispose();
    customEventController.dispose();
    percentController.dispose();

    super.dispose();
  }

  bool get _eventSupportsTargetConditions {
    switch (trigger.event) {
      case PassiveTriggerEvent.attackHit:
      case PassiveTriggerEvent.attackMiss:
      case PassiveTriggerEvent.damageDealt:
      case PassiveTriggerEvent.healingDealt:
      case PassiveTriggerEvent.effectApplied:
      case PassiveTriggerEvent.effectReceived:
      case PassiveTriggerEvent.criticalHit:
      case PassiveTriggerEvent.enemyKilled:
        return true;

      default:
        return false;
    }
  }

  bool get _supportsWhileCondition {
    switch (trigger.event) {
      case PassiveTriggerEvent.healthChanged:
      case PassiveTriggerEvent.resourceChanged:
      case PassiveTriggerEvent.chargeChanged:
      case PassiveTriggerEvent.counterChanged:
        return trigger.targetsSelf &&
            trigger.actions.length == 1 &&
            trigger.actions.first.type == PassiveTriggerActionType.applyEffect;

      default:
        return false;
    }
  }

  List<PassiveTriggerMode> get _availableModes {
    return <PassiveTriggerMode>[
      PassiveTriggerMode.once,

      if (_supportsWhileCondition) PassiveTriggerMode.whileCondition,
    ];
  }

  void _normalizeTriggerMode() {
    if (!_supportsWhileCondition &&
        trigger.mode == PassiveTriggerMode.whileCondition) {
      trigger.mode = PassiveTriggerMode.once;
    }
  }

  bool get _presetNeedsPercent {
    switch (preset) {
      case TriggerTargetConditionPreset.belowPercent:
      case TriggerTargetConditionPreset.atOrBelowPercent:
      case TriggerTargetConditionPreset.abovePercent:
      case TriggerTargetConditionPreset.atOrAbovePercent:
        return true;

      default:
        return false;
    }
  }

  String _presetLabel(TriggerTargetConditionPreset value) {
    switch (value) {
      case TriggerTargetConditionPreset.none:
        return 'Sin condición rápida';

      case TriggerTargetConditionPreset.wounded:
        return 'Objetivo herido';

      case TriggerTargetConditionPreset.fullHealth:
        return 'Objetivo a vida completa';

      case TriggerTargetConditionPreset.belowPercent:
        return 'Vida por debajo de X%';

      case TriggerTargetConditionPreset.atOrBelowPercent:
        return 'Vida a X% o por debajo';

      case TriggerTargetConditionPreset.abovePercent:
        return 'Vida por encima de X%';

      case TriggerTargetConditionPreset.atOrAbovePercent:
        return 'Vida a X% o por encima';

      case TriggerTargetConditionPreset.self:
        return 'El objetivo soy yo';

      case TriggerTargetConditionPreset.external:
        return 'El objetivo es externo';
    }
  }

  String? _presetExpression() {
    switch (preset) {
      case TriggerTargetConditionPreset.none:
        return null;

      case TriggerTargetConditionPreset.wounded:
        return 'target_wounded == 1';

      case TriggerTargetConditionPreset.fullHealth:
        return 'target_full_health == 1';

      case TriggerTargetConditionPreset.self:
        return 'target_is_self == 1';

      case TriggerTargetConditionPreset.external:
        return 'target_is_external == 1';

      case TriggerTargetConditionPreset.belowPercent:
      case TriggerTargetConditionPreset.atOrBelowPercent:
      case TriggerTargetConditionPreset.abovePercent:
      case TriggerTargetConditionPreset.atOrAbovePercent:
        final raw = double.tryParse(percentController.text.trim());

        if (raw == null) {
          return null;
        }

        final percent = raw.clamp(0.0, 100.0).toDouble();

        late final ActionExternalRequirement requirement;

        switch (preset) {
          case TriggerTargetConditionPreset.belowPercent:
            requirement = ActionExternalRequirement.percentageBelow(
              variableName: 'target_health_percent',
              label: '',
              threshold: percent,
            );
            break;

          case TriggerTargetConditionPreset.atOrBelowPercent:
            requirement = ActionExternalRequirement.percentageAtOrBelow(
              variableName: 'target_health_percent',
              label: '',
              threshold: percent,
            );
            break;

          case TriggerTargetConditionPreset.abovePercent:
            requirement = ActionExternalRequirement.percentageAbove(
              variableName: 'target_health_percent',
              label: '',
              threshold: percent,
            );
            break;

          case TriggerTargetConditionPreset.atOrAbovePercent:
            requirement = ActionExternalRequirement.percentageAtOrAbove(
              variableName: 'target_health_percent',
              label: '',
              threshold: percent,
            );
            break;

          default:
            return null;
        }

        return '${requirement.normalizedVariableName} == 1';
    }
  }

  void _applyPreset() {
    final expression = _presetExpression();

    if (expression == null) {
      return;
    }

    final current = conditionController.text.trim();

    conditionController.text = current.isEmpty
        ? expression
        : '($current) && ($expression)';

    conditionController.selection = TextSelection.collapsed(
      offset: conditionController.text.length,
    );

    setState(() {});
  }

  Future<void> _addAction() async {
    final action = PassiveTriggerAction(
      type: PassiveTriggerActionType.dealDamage,
    );

    final result = await showDialog<PassiveTriggerAction>(
      context: context,
      builder: (_) {
        return _PassiveTriggerActionEditorDialog(
          action: action,
          character: widget.character,
          linkedEffects: widget.linkedEffects,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      trigger.actions.add(result);

      _normalizeTriggerMode();
    });
  }

  Future<void> _editAction(PassiveTriggerAction action) async {
    final copy = PassiveTriggerAction.fromMap(action.toMap());

    final result = await showDialog<PassiveTriggerAction>(
      context: context,
      builder: (_) {
        return _PassiveTriggerActionEditorDialog(
          action: copy,
          character: widget.character,
          linkedEffects: widget.linkedEffects,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    final index = trigger.actions.indexOf(action);

    if (index < 0) {
      return;
    }

    setState(() {
      trigger.actions[index] = result;

      _normalizeTriggerMode();
    });
  }

  void _deleteAction(PassiveTriggerAction action) {
    setState(() {
      trigger.actions.remove(action);

      _normalizeTriggerMode();
    });
  }

  String _actionSubtitle(PassiveTriggerAction action) {
    final pieces = <String>[];

    if (action.hasDice) {
      pieces.add(action.diceNotation);
    }

    if (action.hasFormula) {
      pieces.add(action.valueFormula!.expression.trim());
    }

    if (action.hasDamageType) {
      pieces.add(action.damageType.trim());
    }

    if (action.targetId?.trim().isNotEmpty == true) {
      pieces.add(action.targetId!.trim());
    }

    return pieces.isEmpty ? 'Sin configuración adicional' : pieces.join(' · ');
  }

  void _save() {
    final condition = conditionController.text.trim();

    final customEvent = customEventController.text.trim();

    if (trigger.event == PassiveTriggerEvent.custom && customEvent.isEmpty) {
      _showError(
        'Escribe el nombre del '
        'evento personalizado.',
      );

      return;
    }

    if (trigger.actions.isEmpty) {
      _showError('Añade al menos una acción.');

      return;
    }

    for (final action in trigger.actions) {
      if (!action.hasValidTargetId) {
        _showError(
          'Hay una acción sin '
          'objetivo configurado.',
        );

        return;
      }

      if (action.requiresNumericValue &&
          !action.hasFormula &&
          !action.hasDice) {
        _showError(
          'Hay una acción sin '
          'valor configurado.',
        );

        return;
      }
    }

    if (trigger.savingThrow != null && trigger.savingThrow!.dc <= 0) {
      _showError(
        'La CD de salvación '
        'debe ser mayor que 0.',
      );

      return;
    }

    trigger.condition = condition.isEmpty
        ? null
        : CharacterFormula(expression: condition);

    trigger.customEvent = trigger.event == PassiveTriggerEvent.custom
        ? customEvent
        : null;

    Navigator.pop(context, trigger);
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  bool get _hasSavingThrow {
    return trigger.savingThrow != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Trigger'),

      content: SizedBox(
        width: 650,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<PassiveTriggerEvent>(
                initialValue: trigger.event,

                isExpanded: true,

                decoration: const InputDecoration(
                  labelText: 'Evento',
                  prefixIcon: Icon(Icons.bolt_rounded),
                ),

                items: PassiveTriggerEvent.values.map((event) {
                  return DropdownMenuItem(
                    value: event,
                    child: Text(event.label, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    trigger.event = value;

                    if (!_eventSupportsTargetConditions) {
                      preset = TriggerTargetConditionPreset.none;
                    }

                    _normalizeTriggerMode();
                  });
                },
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<PassiveTriggerTarget>(
                initialValue: trigger.target,

                decoration: const InputDecoration(
                  labelText: 'Objetivo del trigger',
                  prefixIcon: Icon(Icons.gps_fixed_rounded),
                ),

                items: PassiveTriggerTarget.values.map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(
                      value == PassiveTriggerTarget.self
                          ? 'Mi personaje'
                          : 'Objetivo de la acción',
                    ),
                  );
                }).toList(),

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    trigger.target = value;

                    if (value == PassiveTriggerTarget.actionTarget) {
                      // Los persistentes no pueden
                      // apuntar a otro personaje.
                      trigger.mode = PassiveTriggerMode.once;
                    }

                    _normalizeTriggerMode();
                  });
                },
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<TriggerUsageLimit>(
                initialValue: trigger.usageLimit,

                decoration: const InputDecoration(
                  labelText: 'Límite de activación',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),

                items: TriggerUsageLimit.values.map((value) {
                  final label = switch (value) {
                    TriggerUsageLimit.unlimited => 'Sin límite',
                    TriggerUsageLimit.oncePerTurn => 'Una vez por turno',
                    TriggerUsageLimit.oncePerRound => 'Una vez por ronda',
                  };

                  return DropdownMenuItem(value: value, child: Text(label));
                }).toList(),

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    trigger.usageLimit = value;
                  });
                },
              ),

              const SizedBox(height: 18),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,

                title: const Text(
                  'Salvación',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),

                subtitle: const Text(
                  'Las acciones del trigger dependen '
                  'de una tirada de salvación.',
                ),

                value: _hasSavingThrow,

                onChanged: (value) {
                  setState(() {
                    if (value) {
                      trigger.savingThrow = const TriggerSavingThrow(
                        ability: AbilityType.constitution,
                        dc: 10,
                        behavior: TriggerSaveBehavior.negate,
                      );
                    } else {
                      trigger.savingThrow = null;
                    }
                  });
                },
              ),

              if (trigger.savingThrow != null) ...[
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<AbilityType>(
                        initialValue: trigger.savingThrow!.ability,

                        decoration: const InputDecoration(
                          labelText: 'Atributo de salvación',
                        ),

                        items: AbilityType.values.map((ability) {
                          return DropdownMenuItem(
                            value: ability,
                            child: Text(ability.shortLabel),
                          );
                        }).toList(),

                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            trigger.savingThrow = TriggerSavingThrow(
                              ability: value,
                              dc: trigger.savingThrow!.dc,
                              behavior: trigger.savingThrow!.behavior,
                            );
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 10),

                    SizedBox(
                      width: 110,
                      child: TextFormField(
                        initialValue: '${trigger.savingThrow!.dc}',

                        keyboardType: TextInputType.number,

                        decoration: const InputDecoration(labelText: 'CD'),

                        onChanged: (value) {
                          final dc = int.tryParse(value);

                          if (dc == null) {
                            return;
                          }

                          trigger.savingThrow = TriggerSavingThrow(
                            ability: trigger.savingThrow!.ability,

                            dc: dc,

                            behavior: trigger.savingThrow!.behavior,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],

              if (trigger.event == PassiveTriggerEvent.custom) ...[
                const SizedBox(height: 12),

                TextFormField(
                  controller: customEventController,

                  decoration: const InputDecoration(
                    labelText: 'Nombre del evento',
                  ),
                ),
              ],

              const SizedBox(height: 12),

              DropdownButtonFormField<PassiveTriggerMode>(
                key: ValueKey(
                  'trigger_mode_'
                  '${trigger.event.name}_'
                  '${trigger.target.name}_'
                  '${trigger.mode.name}_'
                  '${trigger.actions.length}',
                ),

                initialValue: trigger.mode,

                decoration: const InputDecoration(
                  labelText: 'Modo del trigger',
                  prefixIcon: Icon(Icons.autorenew_rounded),
                ),

                items: _availableModes.map((mode) {
                  return DropdownMenuItem(value: mode, child: Text(mode.label));
                }).toList(),

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    trigger.mode = value;
                  });
                },
              ),

              const SizedBox(height: 5),

              Text(
                trigger.mode.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 20),

              if (_eventSupportsTargetConditions) ...[
                _TargetPresetCard(
                  value: preset,

                  percentController: percentController,

                  needsPercent: _presetNeedsPercent,

                  labelBuilder: _presetLabel,

                  onChanged: (value) {
                    setState(() {
                      preset = value;
                    });
                  },

                  onApply: _applyPreset,
                ),

                const SizedBox(height: 14),
              ],

              FormulaInputSection(
                controller: conditionController,

                character: widget.character,

                title: 'Condición',

                label: 'Condición',

                hint: 'counter(kills) % 75 == 0',

                description:
                    'Opcional. El trigger solo se ejecuta cuando el resultado es distinto de 0.',
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Acciones',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  FilledButton.tonalIcon(
                    onPressed: _addAction,

                    icon: const Icon(Icons.add_rounded),

                    label: const Text('Añadir'),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                'Todas estas acciones pertenecen '
                'al mismo trigger y comparten '
                'condición, límite y salvación.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 12),

              if (trigger.actions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),

                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,

                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: const Text('Este trigger no tiene acciones.'),
                )
              else
                for (final action in trigger.actions)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.play_arrow_rounded),

                      title: Text(
                        action.type.label,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),

                      subtitle: Text(_actionSubtitle(action)),

                      onTap: () {
                        _editAction(action);
                      },

                      trailing: IconButton(
                        tooltip: 'Eliminar acción',

                        onPressed: () {
                          _deleteAction(action);
                        },

                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),

        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}

class _TargetPresetCard extends StatelessWidget {
  final TriggerTargetConditionPreset value;

  final TextEditingController percentController;

  final bool needsPercent;

  final String Function(TriggerTargetConditionPreset) labelBuilder;

  final ValueChanged<TriggerTargetConditionPreset> onChanged;

  final VoidCallback onApply;

  const _TargetPresetCard({
    required this.value,
    required this.percentController,
    required this.needsPercent,
    required this.labelBuilder,
    required this.onChanged,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<TriggerTargetConditionPreset>(
            initialValue: value,

            isExpanded: true,

            decoration: const InputDecoration(
              labelText: 'Condición del objetivo',
              prefixIcon: Icon(Icons.track_changes_rounded),
            ),

            items: TriggerTargetConditionPreset.values.map((preset) {
              return DropdownMenuItem(
                value: preset,
                child: Text(labelBuilder(preset)),
              );
            }).toList(),

            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
          ),

          if (needsPercent) ...[
            const SizedBox(height: 12),

            TextFormField(
              controller: percentController,

              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),

              decoration: const InputDecoration(
                labelText: 'Porcentaje de vida',
                suffixText: '%',
              ),
            ),
          ],

          if (value != TriggerTargetConditionPreset.none) ...[
            const SizedBox(height: 12),

            FilledButton.tonalIcon(
              onPressed: onApply,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Añadir a la condición'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResourceTargetField extends StatelessWidget {
  final Character? character;

  final TextEditingController controller;

  const _ResourceTargetField({
    required this.character,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final values = character?.resources ?? const [];

    if (values.isEmpty) {
      return const Text('El personaje no tiene recursos disponibles.');
    }

    return DropdownButtonFormField<String>(
      initialValue: values.any((resource) => resource.id == controller.text)
          ? controller.text
          : null,

      decoration: const InputDecoration(labelText: 'Recurso'),

      items: values.map((resource) {
        return DropdownMenuItem(value: resource.id, child: Text(resource.name));
      }).toList(),

      onChanged: (value) {
        controller.text = value ?? '';
      },
    );
  }
}

class _CounterTargetField extends StatelessWidget {
  final Character? character;

  final TextEditingController controller;

  const _CounterTargetField({
    required this.character,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final values = character?.counters ?? const [];

    if (values.isEmpty) {
      return const Text('El personaje no tiene contadores disponibles.');
    }

    return DropdownButtonFormField<String>(
      initialValue: values.any((counter) => counter.id == controller.text)
          ? controller.text
          : null,

      decoration: const InputDecoration(labelText: 'Contador'),

      items: values.map((counter) {
        return DropdownMenuItem(
          value: counter.id,
          child: Text(counter.name.trim().isEmpty ? counter.id : counter.name),
        );
      }).toList(),

      onChanged: (value) {
        controller.text = value ?? '';
      },
    );
  }
}

class _EffectTargetField extends StatelessWidget {
  final List<CharacterEffect> effects;

  final TextEditingController controller;

  final PassiveTriggerActionType actionType;

  const _EffectTargetField({
    required this.effects,
    required this.controller,
    required this.actionType,
  });

  String get _label {
    switch (actionType) {
      case PassiveTriggerActionType.applyEffect:
        return 'Efecto a aplicar';

      case PassiveTriggerActionType.removeEffect:
        return 'Efecto a eliminar';

      default:
        return 'Efecto';
    }
  }

  String get _emptyText {
    switch (actionType) {
      case PassiveTriggerActionType.applyEffect:
        return 'No hay efectos disponibles para aplicar.';

      case PassiveTriggerActionType.removeEffect:
        return 'El personaje no tiene efectos activos para eliminar.';

      default:
        return 'No hay efectos disponibles.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) {
      controller.clear();

      return Text(_emptyText);
    }

    final selectedValue = effects.any((effect) => effect.id == controller.text)
        ? controller.text
        : null;

    return DropdownButtonFormField<String>(
      key: ValueKey(
        'effect_target_${actionType.name}_'
        '${selectedValue ?? 'none'}',
      ),

      initialValue: selectedValue,

      isExpanded: true,

      decoration: InputDecoration(labelText: _label),

      items: effects.map((effect) {
        final name = effect.name.trim();

        return DropdownMenuItem(
          value: effect.id,
          child: Text(
            name.isEmpty ? 'Efecto sin nombre' : name,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),

      onChanged: (value) {
        controller.text = value ?? '';
      },
    );
  }
}

class _PassiveTriggerActionEditorDialog extends StatefulWidget {
  final PassiveTriggerAction action;

  final Character? character;

  final List<CharacterEffect> linkedEffects;

  const _PassiveTriggerActionEditorDialog({
    required this.action,
    required this.character,
    required this.linkedEffects,
  });

  @override
  State<_PassiveTriggerActionEditorDialog> createState() =>
      _PassiveTriggerActionEditorDialogState();
}

class _PassiveTriggerActionEditorDialogState
    extends State<_PassiveTriggerActionEditorDialog> {
  late PassiveTriggerAction action;

  late final TextEditingController targetController;

  late final TextEditingController valueController;

  late final TextEditingController damageTypeController;

  @override
  void initState() {
    super.initState();

    action = PassiveTriggerAction.fromMap(widget.action.toMap());

    targetController = TextEditingController(text: action.targetId ?? '');

    valueController = TextEditingController(
      text: action.valueFormula?.expression ?? '',
    );

    damageTypeController = TextEditingController(text: action.damageType);
  }

  @override
  void dispose() {
    targetController.dispose();
    valueController.dispose();
    damageTypeController.dispose();

    super.dispose();
  }

  bool get _usesResource {
    switch (action.type) {
      case PassiveTriggerActionType.addResource:
      case PassiveTriggerActionType.subtractResource:
      case PassiveTriggerActionType.setResource:
        return true;

      default:
        return false;
    }
  }

  bool get _usesCounter {
    switch (action.type) {
      case PassiveTriggerActionType.incrementCounter:
      case PassiveTriggerActionType.setCounter:
        return true;

      default:
        return false;
    }
  }

  bool get _usesEffect {
    return action.type == PassiveTriggerActionType.applyEffect ||
        action.type == PassiveTriggerActionType.removeEffect;
  }

  bool get _usesDamage {
    return action.type == PassiveTriggerActionType.dealDamage;
  }

  bool get _usesHealing {
    return action.type == PassiveTriggerActionType.heal;
  }

  bool get _usesMitigation {
    return action.type == PassiveTriggerActionType.mitigateDamage;
  }

  List<CharacterEffect> get _effectOptions {
    if (action.type == PassiveTriggerActionType.applyEffect) {
      return widget.linkedEffects;
    }

    if (action.type == PassiveTriggerActionType.removeEffect) {
      return widget.character?.effects ?? const [];
    }

    return const [];
  }

  bool get _usesValue {
    switch (action.type) {
      case PassiveTriggerActionType.addResource:
      case PassiveTriggerActionType.subtractResource:
      case PassiveTriggerActionType.setResource:
      case PassiveTriggerActionType.addCharge:
      case PassiveTriggerActionType.subtractCharge:
      case PassiveTriggerActionType.incrementCounter:
      case PassiveTriggerActionType.setCounter:
        return true;

      case PassiveTriggerActionType.dealDamage:
      case PassiveTriggerActionType.heal:
      case PassiveTriggerActionType.mitigateDamage:
        return true;

      case PassiveTriggerActionType.applyEffect:
      case PassiveTriggerActionType.removeEffect:
        return false;
    }
  }

  void _save() {
    final target = targetController.text.trim();

    final valueText = valueController.text.trim();

    final damageType = damageTypeController.text.trim();

    if (action.requiresTargetId && target.isEmpty) {
      _showError('Selecciona el objetivo de la acción.');
      return;
    }

    if (action.requiresNumericValue && !action.hasDice && valueText.isEmpty) {
      _showError('Introduce un valor o configura dados.');
      return;
    }

    action.targetId = target.isEmpty ? null : target;

    action.valueFormula = valueText.isEmpty
        ? null
        : CharacterFormula(expression: valueText);

    action.damageType = _usesDamage ? damageType : '';

    Navigator.pop(context, action);
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _addDicePool() async {
    final result = await showDialog<DicePool>(
      context: context,
      builder: (_) {
        return const _DicePoolEditorDialog();
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      action.dicePools.add(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Acción del trigger'),

      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===============================================================
              // TIPO
              // ===============================================================
              DropdownButtonFormField<PassiveTriggerActionType>(
                initialValue: action.type,

                isExpanded: true,

                decoration: const InputDecoration(
                  labelText: 'Tipo de acción',
                  prefixIcon: Icon(Icons.play_arrow_rounded),
                ),

                items: PassiveTriggerActionType.values
                    .where(
                      (type) =>
                          type != PassiveTriggerActionType.mitigateDamage ||
                          action.type == PassiveTriggerActionType.mitigateDamage,
                    )
                    .map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.label));
                }).toList(),

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    action.type = value;

                    targetController.clear();

                    valueController.clear();

                    damageTypeController.clear();

                    action.dicePools = [];
                  });
                },
              ),

              // ===============================================================
              // RECURSO
              // ===============================================================
              if (_usesResource) ...[
                const SizedBox(height: 14),

                _ResourceTargetField(
                  character: widget.character,
                  controller: targetController,
                ),
              ],

              // ===============================================================
              // CONTADOR
              // ===============================================================
              if (_usesCounter) ...[
                const SizedBox(height: 14),

                _CounterTargetField(
                  character: widget.character,
                  controller: targetController,
                ),
              ],

              // ===============================================================
              // EFECTO
              // ===============================================================
              if (_usesEffect) ...[
                const SizedBox(height: 14),

                _EffectTargetField(
                  effects: _effectOptions,
                  controller: targetController,
                  actionType: action.type,
                ),
              ],

              // ===============================================================
              // DADOS
              // ===============================================================
              if (_usesDamage || _usesHealing || _usesMitigation) ...[
                const SizedBox(height: 20),

                Text(
                  'Dados',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                if (action.dicePools.isEmpty)
                  Text(
                    'Sin dados configurados.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  for (final pool in action.dicePools)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.casino_rounded),
                      title: Text(pool.notation),
                      trailing: IconButton(
                        tooltip: 'Eliminar dado',
                        onPressed: () {
                          setState(() {
                            action.dicePools.remove(pool);
                          });
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ),

                const SizedBox(height: 8),

                FilledButton.tonalIcon(
                  onPressed: _addDicePool,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Añadir dado'),
                ),
              ],

              // ===============================================================
              // VALOR / FÓRMULA
              // ===============================================================
              if (_usesValue) ...[
                const SizedBox(height: 20),

                FormulaInputSection(
                  controller: valueController,
                  character: widget.character,
                  title: _usesDamage
                      ? 'Modificador de daño'
                      : _usesHealing
                      ? 'Modificador de curación'
                      : _usesMitigation
                      ? 'Modificador de mitigación' // <--- Etiqueta específica
                      : 'Valor',
                  label: 'Fórmula',
                  hint: _usesDamage || _usesHealing || _usesMitigation
                      ? 'Opcional'
                      : '1',
                  description: _usesDamage || _usesHealing
                      ? 'Se suma al resultado de los dados.'
                      : _usesMitigation
                      ? 'Se suma al resultado de los dados de mitigación.'
                      : 'Valor que aplicará esta acción.',
                ),
              ],

              // ===============================================================
              // TIPO DE DAÑO
              // ===============================================================
              if (_usesDamage) ...[
                const SizedBox(height: 16),

                TextFormField(
                  controller: damageTypeController,

                  decoration: const InputDecoration(
                    labelText: 'Tipo de daño',
                    hintText: 'Veneno',
                    prefixIcon: Icon(Icons.flash_on_rounded),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),

        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}

class _DicePoolEditorDialog extends StatefulWidget {
  const _DicePoolEditorDialog();

  @override
  State<_DicePoolEditorDialog> createState() => _DicePoolEditorDialogState();
}

class _DicePoolEditorDialogState extends State<_DicePoolEditorDialog> {
  final countController = TextEditingController(text: '1');

  int sides = 6;

  @override
  void dispose() {
    countController.dispose();
    super.dispose();
  }

  void _save() {
    final count = int.tryParse(countController.text.trim()) ?? 0;

    if (count <= 0) {
      return;
    }

    Navigator.pop(context, DicePool(count: count, sides: sides));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir dados'),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: countController,

            keyboardType: TextInputType.number,

            decoration: const InputDecoration(
              labelText: 'Cantidad',
              prefixText: '',
            ),
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<int>(
            initialValue: sides,

            decoration: const InputDecoration(labelText: 'Dado'),

            items: const [4, 6, 8, 10, 12, 20, 100].map((value) {
              return DropdownMenuItem(value: value, child: Text('d$value'));
            }).toList(),

            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                sides = value;
              });
            },
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

        FilledButton(onPressed: _save, child: const Text('Añadir')),
      ],
    );
  }
}
