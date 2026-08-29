import 'package:flutter/material.dart';

import '../../../models/action_external_requirement.dart';
import '../../../models/character.dart';
import '../../../models/character_effect.dart';
import '../../../models/passive.dart';
import '../../../models/formulas/character_formula.dart';

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
    barrierDismissible: false,
    builder: (_) {
      return PassiveTriggerEditorDialog(
        trigger: trigger,
        character: character,
        passive: passive,
        linkedEffects: linkedEffects,
      );
    },
  );
}

class PassiveTriggerEditorDialog extends StatefulWidget {
  final PassiveTrigger trigger;

  final Character? character;

  final CharacterPassive? passive;

  final List<CharacterEffect> linkedEffects;

  const PassiveTriggerEditorDialog({
    super.key,
    required this.trigger,
    this.character,
    this.passive,
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

  late final TextEditingController valueController;

  late final TextEditingController targetController;

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

    valueController = TextEditingController(
      text: trigger.valueFormula?.expression ?? '1',
    );

    targetController = TextEditingController(text: trigger.targetId ?? '');

    customEventController = TextEditingController(
      text: trigger.customEvent ?? '',
    );

    percentController = TextEditingController(text: '50');
  }

  @override
  void dispose() {
    conditionController.dispose();
    valueController.dispose();
    targetController.dispose();
    customEventController.dispose();
    percentController.dispose();

    super.dispose();
  }

  bool get _usesResource {
    switch (trigger.actionType) {
      case PassiveTriggerActionType.addResource:
      case PassiveTriggerActionType.subtractResource:
      case PassiveTriggerActionType.setResource:
        return true;

      default:
        return false;
    }
  }

  bool get _usesCounter {
    switch (trigger.actionType) {
      case PassiveTriggerActionType.incrementCounter:
      case PassiveTriggerActionType.setCounter:
        return true;

      default:
        return false;
    }
  }

  bool get _usesEffect {
    switch (trigger.actionType) {
      case PassiveTriggerActionType.applyEffect:
      case PassiveTriggerActionType.removeEffect:
        return true;

      default:
        return false;
    }
  }

  bool get _usesValue {
    switch (trigger.actionType) {
      case PassiveTriggerActionType.addResource:
      case PassiveTriggerActionType.subtractResource:
      case PassiveTriggerActionType.setResource:
      case PassiveTriggerActionType.addCharge:
      case PassiveTriggerActionType.subtractCharge:
      case PassiveTriggerActionType.dealDamage:
      case PassiveTriggerActionType.heal:
      case PassiveTriggerActionType.incrementCounter:
      case PassiveTriggerActionType.setCounter:
        return true;

      case PassiveTriggerActionType.applyEffect:
      case PassiveTriggerActionType.removeEffect:
        return false;
    }
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
        return trigger.actionType == PassiveTriggerActionType.applyEffect;

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

  List<CharacterEffect> get _effectsForApply {
    return List<CharacterEffect>.from(widget.linkedEffects);
  }

  List<CharacterEffect> get _effectsForRemoval {
    final character = widget.character;

    if (character == null) {
      return const [];
    }

    return List<CharacterEffect>.from(character.effects);
  }

  List<CharacterEffect> get _selectedEffectOptions {
    switch (trigger.actionType) {
      case PassiveTriggerActionType.applyEffect:
        return _effectsForApply;

      case PassiveTriggerActionType.removeEffect:
        return _effectsForRemoval;

      default:
        return const [];
    }
  }

  void _save() {
    final condition = conditionController.text.trim();

    final value = valueController.text.trim();

    final target = targetController.text.trim();

    final customEvent = customEventController.text.trim();

    if (trigger.event == PassiveTriggerEvent.custom && customEvent.isEmpty) {
      _showError('Escribe el nombre del evento personalizado.');
      return;
    }

    if ((_usesResource || _usesCounter || _usesEffect) && target.isEmpty) {
      _showError('Selecciona el objetivo de la acción.');
      return;
    }

    if (_usesValue && value.isEmpty) {
      _showError('Introduce el valor de la acción.');
      return;
    }

    trigger.condition = condition.isEmpty
        ? null
        : CharacterFormula(expression: condition);

    trigger.valueFormula = _usesValue
        ? CharacterFormula(expression: value)
        : null;

    trigger.targetId = target.isEmpty ? null : target;

    trigger.customEvent = trigger.event == PassiveTriggerEvent.custom
        ? customEvent
        : null;

    Navigator.pop(context, trigger);
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
                  '${trigger.actionType.name}_'
                  '${trigger.mode.name}',
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

              DropdownButtonFormField<PassiveTriggerActionType>(
                initialValue: trigger.actionType,

                isExpanded: true,

                decoration: const InputDecoration(
                  labelText: 'Acción',
                  prefixIcon: Icon(Icons.play_arrow_rounded),
                ),

                items: PassiveTriggerActionType.values.map((action) {
                  return DropdownMenuItem(
                    value: action,
                    child: Text(action.label),
                  );
                }).toList(),

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    trigger.actionType = value;

                    targetController.clear();

                    if (!_usesValue) {
                      valueController.clear();
                    }

                    _normalizeTriggerMode();
                  });
                },
              ),

              if (_usesResource) ...[
                const SizedBox(height: 12),

                _ResourceTargetField(
                  character: widget.character,

                  controller: targetController,
                ),
              ],

              if (_usesCounter) ...[
                const SizedBox(height: 12),

                _CounterTargetField(
                  character: widget.character,

                  controller: targetController,
                ),
              ],

              if (_usesEffect) ...[
                const SizedBox(height: 12),

                _EffectTargetField(
                  effects: _selectedEffectOptions,
                  controller: targetController,
                  actionType: trigger.actionType,
                ),
              ],

              if (_usesValue) ...[
                const SizedBox(height: 18),

                FormulaInputSection(
                  controller: valueController,

                  character: widget.character,

                  title: 'Valor',

                  label: 'Fórmula de valor',

                  hint: '1',
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
