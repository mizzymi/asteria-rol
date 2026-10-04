import 'package:flutter/material.dart';

import '../../../models/character_resource.dart';
import '../../../models/formulas/character_formula.dart';
import '../../../models/action_cost.dart';
import '../../../models/action_external_requirement.dart';
import '../../../models/ability_effect_part.dart';
import '../../../models/ability.dart';
import '../../../models/dice_pool.dart';
import '../../../models/skill.dart';

class AbilityEffectsSection extends StatelessWidget {
  final List<AbilityEffect> effects;

  final List<CharacterResource> resources;

  final VoidCallback onAddEffect;

  final void Function(int index, AbilityEffect effect) onEffectChanged;

  final ValueChanged<int> onRemoveEffect;

  final ValueChanged<int> onMoveUp;
  final ValueChanged<int> onMoveDown;

  const AbilityEffectsSection({
    super.key,
    required this.effects,
    required this.resources,
    required this.onAddEffect,
    required this.onEffectChanged,
    required this.onRemoveEffect,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome_motion_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                'Efectos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            Text(
              '${effects.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),

        const SizedBox(height: 6),

        Text(
          'Una habilidad puede tener varios daños, curaciones o salvaciones diferentes.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        const SizedBox(height: 14),

        if (effects.isEmpty)
          _EmptyEffects(onAdd: onAddEffect)
        else
          ...List.generate(effects.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AbilityEffectEditor(
                key: ValueKey(effects[index].id),
                effect: effects[index],
                resources: resources,
                abilityMitigatesDamage: effects.any(
                  (effect) => effect.mitigatesDamage,
                ),
                index: index,
                totalEffects: effects.length,
                onChanged: (effect) {
                  onEffectChanged(index, effect);

                  if (!effects.any((item) => item.mitigatesDamage)) {
                    for (var i = 0; i < effects.length; i++) {
                      final item = effects[i];
                      if (item.heals && item.onlyWhenDamageFullyMitigated) {
                        item.activationCondition =
                            AbilityEffectActivationCondition.always;
                        onEffectChanged(i, item);
                      }
                    }
                  }
                },
                onDelete: () {
                  final hasOtherMitigation = effects.asMap().entries.any(
                    (entry) =>
                        entry.key != index && entry.value.mitigatesDamage,
                  );

                  if (!hasOtherMitigation && effects[index].mitigatesDamage) {
                    for (var i = 0; i < effects.length; i++) {
                      if (i == index) {
                        continue;
                      }
                      final item = effects[i];
                      if (item.heals && item.onlyWhenDamageFullyMitigated) {
                        item.activationCondition =
                            AbilityEffectActivationCondition.always;
                        onEffectChanged(i, item);
                      }
                    }
                  }

                  onRemoveEffect(index);
                },
                onMoveUp: () {
                  onMoveUp(index);
                },
                onMoveDown: () {
                  onMoveDown(index);
                },
              ),
            );
          }),

        if (effects.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddEffect,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Añadir efecto'),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// EDITOR DE EFECTO
// =============================================================================

class AbilityEffectEditor extends StatefulWidget {
  final AbilityEffect effect;

  final List<CharacterResource> resources;

  final bool abilityMitigatesDamage;

  final int index;
  final int totalEffects;

  final ValueChanged<AbilityEffect> onChanged;

  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const AbilityEffectEditor({
    super.key,
    required this.effect,
    required this.resources,
    required this.abilityMitigatesDamage,
    required this.index,
    required this.totalEffects,
    required this.onChanged,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  State<AbilityEffectEditor> createState() => _AbilityEffectEditorState();
}

class _AbilityEffectEditorState extends State<AbilityEffectEditor> {
  late final TextEditingController nameController;

  late final TextEditingController saveDcBonusController;

  // ===========================================================================
  // BONUS EXTRA DEL EFECTO
  // ===========================================================================

  late final TextEditingController extraDiceController;

  late final TextEditingController extraBonusController;

  late final TextEditingController extraTypeController;

  late AbilityEffect effect;

  bool expanded = true;

  @override
  void initState() {
    super.initState();

    effect = _clone(widget.effect);

    nameController = TextEditingController(text: effect.name);

    saveDcBonusController = TextEditingController(
      text: '${effect.saveDcBonus}',
    );

    extraDiceController = TextEditingController(text: _legacyDiceNotation);

    extraBonusController = TextEditingController(text: '${effect.effectBonus}');

    extraTypeController = TextEditingController(text: effect.effectTypeName);
  }

  AbilityEffect _clone(AbilityEffect source) {
    return AbilityEffect(
      id: source.id,

      name: source.name,

      effectType: source.effectType,

      parts: source.parts
          .map((part) => AbilityEffectPart.fromMap(part.toMap()))
          .toList(),

      // Legacy / bonus extra del efecto.
      dicePools: source.dicePools
          .map((pool) => DicePool(count: pool.count, sides: pool.sides))
          .toList(),

      abilityModifierMultipliers: Map<AbilityType, int>.from(
        source.abilityModifierMultipliers,
      ),

      legacyAddAbilityModifier: source.legacyAddAbilityModifier,

      effectBonus: source.effectBonus,

      effectTypeName: source.effectTypeName,

      extraParticipatesInCritical: source.extraParticipatesInCritical,

      usesSavingThrow: source.usesSavingThrow,

      savingThrowAbility: source.savingThrowAbility,

      saveDcBonus: source.saveDcBonus,

      saveSuccessEffect: source.saveSuccessEffect,

      activationCondition: source.activationCondition,
    );
  }

  // ===========================================================================
  // NOTIFICAR CAMBIOS
  // ===========================================================================

  void notifyParent() {
    effect.name = nameController.text.trim();

    effect.saveDcBonus = int.tryParse(saveDcBonusController.text.trim()) ?? 0;

    effect.effectBonus = int.tryParse(extraBonusController.text.trim()) ?? 0;

    effect.effectTypeName = extraTypeController.text.trim();

    widget.onChanged(_clone(effect));
  }

  // ===========================================================================
  // COMPONENTES
  // ===========================================================================

  void addPart() {
    setState(() {
      effect.parts.add(
        AbilityEffectPart(
          id: '${DateTime.now().microsecondsSinceEpoch}_part',

          dicePools: [DicePool(count: 1, sides: 6)],

          abilityModifierMultipliers: {},

          resourceValueMultipliers: {},

          flatBonus: 0,

          typeName: effect.mitigatesDamage
              ? 'Mitigación'
              : (effect.heals ? 'Curación' : ''),
        ),
      );
    });

    notifyParent();
  }

  void updatePart(int index, AbilityEffectPart part) {
    if (index < 0 || index >= effect.parts.length) {
      return;
    }

    setState(() {
      effect.parts[index] = part;
    });

    notifyParent();
  }

  void removePart(int index) {
    if (index < 0 || index >= effect.parts.length) {
      return;
    }

    setState(() {
      effect.parts.removeAt(index);
    });

    notifyParent();
  }

  // ===========================================================================
  // EXTRA DEL EFECTO
  // ===========================================================================

  String get _legacyDiceNotation {
    if (effect.dicePools.isEmpty) {
      return '';
    }

    return effect.dicePools.map((pool) => pool.notation).join(' + ');
  }

  bool get _hasExtraEffectBonus {
    return effect.dicePools.isNotEmpty ||
        effect.abilityModifierMultipliers.values.any((value) => value != 0) ||
        effect.effectBonus != 0 ||
        effect.effectTypeName.trim().isNotEmpty;
  }

  void _updateExtraDice(String value) {
    final parsed = _parseDicePools(value);

    if (parsed == null) {
      return;
    }

    setState(() {
      effect.dicePools = parsed;
    });

    notifyParent();
  }

  void _clearExtraBonus() {
    setState(() {
      effect.dicePools.clear();

      effect.abilityModifierMultipliers.clear();

      effect.effectBonus = 0;

      effect.effectTypeName = '';

      effect.legacyAddAbilityModifier = false;

      extraDiceController.clear();

      extraBonusController.text = '0';

      extraTypeController.clear();
    });

    notifyParent();
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    nameController.dispose();

    saveDcBonusController.dispose();

    extraDiceController.dispose();

    extraBonusController.dispose();

    extraTypeController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final title = nameController.text.trim().isNotEmpty
        ? nameController.text.trim()
        : 'Efecto ${widget.index + 1}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                expanded = !expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_effectIcon),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          _summary,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                ],
              ),
            ),
          ),

          if (expanded) ...[
            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainFields(),

                  if (effect.effectType != AbilityEffectType.none) ...[
                    const SizedBox(height: 18),

                    _buildPartsSection(),

                    const SizedBox(height: 18),

                    _buildExtraEffectSection(),
                  ],

                  // Una habilidad puede limitarse a aplicar un estado/efecto.
                  // En ese caso sigue siendo válido exigir una salvación aunque
                  // no exista daño, curación ni mitigación.
                  if (!effect.mitigatesDamage) ...[
                    const SizedBox(height: 18),
                    _buildSavingThrowSection(),
                  ],

                  const SizedBox(height: 18),

                  _buildActions(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // CAMPOS PRINCIPALES
  // ===========================================================================

  Widget _buildMainFields() {
    return Column(
      children: [
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre del efecto',
            hintText: 'Ej: Hielo, Veneno...',
          ),
          onChanged: (_) {
            setState(() {});

            notifyParent();
          },
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<AbilityEffectType>(
          initialValue: effect.effectType,
          decoration: const InputDecoration(labelText: 'Tipo de efecto'),
          items: AbilityEffectType.values.map((type) {
            return DropdownMenuItem(value: type, child: Text(type.label));
          }).toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              effect.effectType = value;

              if (value != AbilityEffectType.healing) {
                effect.activationCondition =
                    AbilityEffectActivationCondition.always;
              }

              if (value == AbilityEffectType.mitigation) {
                // La mitigación es una respuesta defensiva propia; no utiliza
                // salvación ni transformación crítica.
                effect.usesSavingThrow = false;
                effect.extraParticipatesInCritical = false;
              }

              if (value == AbilityEffectType.none) {
                // Sistema moderno.
                effect.parts.clear();

                // Bonus extra / legacy.
                effect.dicePools.clear();

                effect.abilityModifierMultipliers.clear();

                effect.effectBonus = 0;

                effect.effectTypeName = '';

                effect.legacyAddAbilityModifier = false;

                // UI.
                extraDiceController.clear();

                extraBonusController.text = '0';

                extraTypeController.clear();

                // Conservamos la salvación: un efecto sin daño/curación
                // puede controlar un estado o efecto vinculado.
              }
            });

            notifyParent();
          },
        ),

        if (effect.heals && widget.abilityMitigatesDamage) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<AbilityEffectActivationCondition>(
            initialValue: effect.activationCondition,
            decoration: const InputDecoration(
              labelText: 'Cuándo cura',
              prefixIcon: Icon(Icons.rule_rounded),
            ),
            items: AbilityEffectActivationCondition.values.map((condition) {
              return DropdownMenuItem(
                value: condition,
                child: Text(condition.label),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                effect.activationCondition = value;
              });

              notifyParent();
            },
          ),
          if (effect.onlyWhenDamageFullyMitigated) ...[
            const SizedBox(height: 6),
            Text(
              'Cura solo si la habilidad mitiga todo el daño.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ],
    );
  }

  // ===========================================================================
  // COMPONENTES PRINCIPALES
  // ===========================================================================

  Widget _buildPartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              effect.mitigatesDamage
                  ? Icons.shield_rounded
                  : (effect.heals ? Icons.favorite_rounded : Icons.flash_on_rounded),
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                effect.mitigatesDamage
                    ? 'Componentes de mitigación'
                    : (effect.heals
                          ? 'Componentes de curación'
                          : 'Componentes de daño'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            if (effect.parts.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${effect.parts.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),

        const SizedBox(height: 6),

        Text(
          effect.mitigatesDamage
              ? 'Cada componente indica cuánto daño puede absorber esta habilidad.'
              : (effect.heals
                    ? 'Cada componente puede tener sus propios dados, atributos, recursos y bonus fijo.'
                    : 'Cada tipo de daño puede tener sus propios dados, atributos, recursos y bonus fijo.'),
          style: Theme.of(context).textTheme.bodySmall,
        ),

        const SizedBox(height: 12),

        if (effect.parts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              effect.mitigatesDamage
                  ? 'Todavía no hay componentes de mitigación.'
                  : (effect.heals
                        ? 'Todavía no hay componentes de curación.'
                        : 'Todavía no hay componentes de daño.'),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...List.generate(effect.parts.length, (partIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AbilityEffectPartCard(
                key: ValueKey(effect.parts[partIndex].id),

                part: effect.parts[partIndex],

                effectType: effect.effectType,

                usesSavingThrow: effect.usesSavingThrow,

                resources: widget.resources,

                onChanged: (part) {
                  updatePart(partIndex, part);
                },

                onDelete: () {
                  removePart(partIndex);
                },
              ),
            );
          }),

        const SizedBox(height: 4),

        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: addPart,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              effect.mitigatesDamage
                  ? 'Añadir mitigación'
                  : (effect.heals ? 'Añadir curación' : 'Añadir tipo de daño'),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // DAÑO / CURACIÓN EXTRA DEL EFECTO
  // ===========================================================================

  Widget _buildExtraEffectSection() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                color: theme.colorScheme.tertiary,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  effect.mitigatesDamage
                      ? 'Mitigación extra'
                      : (effect.heals ? 'Curación extra' : 'Daño extra'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),

              if (_hasExtraEffectBonus)
                IconButton(
                  tooltip: 'Limpiar extra',
                  onPressed: _clearExtraBonus,
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            effect.mitigatesDamage
                ? 'Esta mitigación se suma una sola vez al total que absorberá la reacción.'
                : (effect.heals
                      ? 'Este bonus se suma una sola vez al resultado total de este efecto.'
                      : 'Este daño se suma una sola vez al resultado total de este efecto.'),
            style: theme.textTheme.bodySmall,
          ),

          const SizedBox(height: 14),

          // ===================================================================
          // DADOS EXTRA
          // ===================================================================
          TextFormField(
            controller: extraDiceController,
            decoration: InputDecoration(
              labelText: effect.mitigatesDamage
                  ? 'Dados de mitigación extra'
                  : (effect.heals
                        ? 'Dados de curación extra'
                        : 'Dados de daño extra'),
              hintText: 'Ej: 1d6 + 1d4',
              prefixIcon: const Icon(Icons.casino_rounded),
              helperText: 'Déjalo vacío si el extra no usa dados.',
            ),
            onChanged: _updateExtraDice,
          ),

          const SizedBox(height: 12),

          // ===================================================================
          // TIPO EXTRA
          // ===================================================================
          TextFormField(
            controller: extraTypeController,
            decoration: InputDecoration(
              labelText: effect.mitigatesDamage
                  ? 'Descripción de la mitigación'
                  : (effect.heals
                        ? 'Tipo de curación extra'
                        : 'Tipo de daño extra'),
              hintText: effect.mitigatesDamage
                  ? 'Escudo, bloqueo, reducción...'
                  : (effect.heals ? 'Curación mágica' : 'Fuego, radiante, veneno...'),
            ),
            onChanged: (_) {
              notifyParent();
            },
          ),

          const SizedBox(height: 12),

          // ===================================================================
          // BONUS FIJO EXTRA
          // ===================================================================
          TextFormField(
            controller: extraBonusController,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            decoration: InputDecoration(
              labelText: effect.mitigatesDamage
                  ? 'Mitigación fija extra'
                  : (effect.heals
                        ? 'Bonus fijo de curación extra'
                        : 'Bonus fijo de daño extra'),
              hintText: '0',
              prefixIcon: const Icon(Icons.exposure_plus_1_rounded),
            ),
            onChanged: (_) {
              notifyParent();
            },
          ),

          const SizedBox(height: 16),

          // ===================================================================
          // ATRIBUTOS DEL EXTRA
          // ===================================================================
          _PartAbilityModifiersEditor(
            title: effect.mitigatesDamage
                ? 'Modificadores de la mitigación extra'
                : (effect.heals
                      ? 'Modificadores de la curación extra'
                      : 'Modificadores del daño extra'),

            multipliers: effect.abilityModifierMultipliers,

            onChanged: (multipliers) {
              setState(() {
                effect.abilityModifierMultipliers = multipliers;

                // Ya no necesitamos este
                // booleano para cálculos.
                effect.legacyAddAbilityModifier = false;
              });

              notifyParent();
            },
          ),

          if (effect.dealsDamage && !effect.usesSavingThrow) ...[
            const SizedBox(height: 14),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,

              value: effect.extraParticipatesInCritical,

              title: const Text(
                'Participa en crítico',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),

              subtitle: const Text(
                'Este daño extra recibe la transformación '
                'crítica cuando el ataque es crítico.',
              ),

              secondary: const Icon(Icons.whatshot_rounded),

              onChanged: (value) {
                setState(() {
                  effect.extraParticipatesInCritical = value;
                });

                notifyParent();
              },
            ),
          ],

          if (_hasExtraEffectBonus) ...[
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome_rounded),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Extra actual',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 3),

                        Text(_extraSummary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // SALVACIÓN
  // ===========================================================================

  Widget _buildSavingThrowSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,

          value: effect.usesSavingThrow,

          title: const Text('Requiere salvación'),

          subtitle: const Text(
            'Este efecto tiene su propia tirada de salvación',
          ),

          onChanged: (value) {
            setState(() {
              effect.usesSavingThrow = value;
            });

            notifyParent();
          },
        ),

        if (effect.usesSavingThrow) ...[
          const SizedBox(height: 10),

          DropdownButtonFormField<AbilityType>(
            initialValue: effect.savingThrowAbility,

            decoration: const InputDecoration(
              labelText: 'Salvación',
              prefixIcon: Icon(Icons.shield_rounded),
            ),

            items: AbilityType.values.map((ability) {
              return DropdownMenuItem(
                value: ability,
                child: Text(ability.label),
              );
            }).toList(),

            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                effect.savingThrowAbility = value;
              });

              notifyParent();
            },
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: saveDcBonusController,

            keyboardType: const TextInputType.numberWithOptions(signed: true),

            decoration: const InputDecoration(
              labelText: 'Bonus adicional a la CD',

              helperText: 'CD = 8 + competencia + atributo + bonus',
            ),

            onChanged: (_) {
              notifyParent();
            },
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<SaveSuccessEffect>(
            initialValue: effect.saveSuccessEffect,

            decoration: const InputDecoration(
              labelText: 'Si supera la salvación',

              prefixIcon: Icon(Icons.verified_user_rounded),
            ),

            items: SaveSuccessEffect.values.map((result) {
              return DropdownMenuItem(value: result, child: Text(result.label));
            }).toList(),

            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                effect.saveSuccessEffect = value;
              });

              notifyParent();
            },
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // ACCIONES
  // ===========================================================================

  Widget _buildActions() {
    return Row(
      children: [
        IconButton(
          tooltip: 'Mover arriba',

          onPressed: widget.index > 0 ? widget.onMoveUp : null,

          icon: const Icon(Icons.arrow_upward_rounded),
        ),

        IconButton(
          tooltip: 'Mover abajo',

          onPressed: widget.index < widget.totalEffects - 1
              ? widget.onMoveDown
              : null,

          icon: const Icon(Icons.arrow_downward_rounded),
        ),

        const Spacer(),

        TextButton.icon(
          onPressed: widget.onDelete,

          icon: const Icon(Icons.delete_outline_rounded),

          label: const Text('Eliminar'),
        ),
      ],
    );
  }

  // ===========================================================================
  // ICONO
  // ===========================================================================

  IconData get _effectIcon {
    switch (effect.effectType) {
      case AbilityEffectType.damage:
        return effect.usesSavingThrow
            ? Icons.shield_rounded
            : Icons.flash_on_rounded;

      case AbilityEffectType.healing:
        return Icons.favorite_rounded;

      case AbilityEffectType.mitigation:
        return Icons.shield_rounded;

      case AbilityEffectType.none:
        return Icons.auto_awesome_rounded;
    }
  }

  // ===========================================================================
  // RESUMEN GENERAL
  // ===========================================================================

  String get _summary {
    if (effect.effectType == AbilityEffectType.none) {
      return 'Sin daño, curación ni mitigación';
    }

    final pieces = <String>[];

    // Componentes.
    for (final part in effect.parts) {
      final value = _partSummary(part);

      if (value.isNotEmpty) {
        pieces.add(value);
      }
    }

    // Bonus extra.
    if (_hasExtraEffectBonus) {
      pieces.add('Extra: $_extraSummary');
    }

    if (effect.onlyWhenDamageFullyMitigated) {
      pieces.add('Solo si mitiga todo el daño');
    }

    // Salvación.
    if (effect.usesSavingThrow) {
      pieces.add(
        '${effect.savingThrowAbility.shortLabel} · '
        '${effect.saveSuccessEffect.label}',
      );
    }

    if (pieces.isEmpty) {
      return effect.effectType.label;
    }

    return pieces.join(' · ');
  }

  // ===========================================================================
  // RESUMEN DE UN COMPONENTE
  // ===========================================================================

  String _partSummary(AbilityEffectPart part) {
    final formula = <String>[];

    if (part.diceNotation.isNotEmpty) {
      formula.add(part.diceNotation);
    }

    for (final entry in part.abilityModifierMultipliers.entries) {
      if (entry.value == 0) {
        continue;
      }

      if (entry.value == 1) {
        formula.add(entry.key.shortLabel);
      } else {
        formula.add('${entry.value}×${entry.key.shortLabel}');
      }
    }

    for (final entry in part.resourceValueMultipliers.entries) {
      if (entry.value == 0) {
        continue;
      }

      final resourceName = _resourceName(entry.key);

      if (entry.value == 1) {
        formula.add(resourceName);
      } else {
        formula.add('${entry.value}×$resourceName');
      }
    }

    if (part.flatBonus != 0) {
      formula.add(
        part.flatBonus > 0 ? '+${part.flatBonus}' : '${part.flatBonus}',
      );
    }

    var result = formula.join(' + ').replaceAll('+ -', '- ');

    final type = part.typeName.trim();

    if (type.isNotEmpty) {
      if (result.isEmpty) {
        result = type;
      } else {
        result += ' $type';
      }
    }

    return result;
  }

  // ===========================================================================
  // RESUMEN DEL EXTRA
  // ===========================================================================

  String get _extraSummary {
    final formula = <String>[];

    if (effect.dicePools.isNotEmpty) {
      formula.add(effect.dicePools.map((pool) => pool.notation).join(' + '));
    }

    for (final entry in effect.abilityModifierMultipliers.entries) {
      if (entry.value == 0) {
        continue;
      }

      if (entry.value == 1) {
        formula.add(entry.key.shortLabel);
      } else {
        formula.add('${entry.value}×${entry.key.shortLabel}');
      }
    }

    if (effect.effectBonus != 0) {
      formula.add(
        effect.effectBonus > 0
            ? '+${effect.effectBonus}'
            : '${effect.effectBonus}',
      );
    }

    var result = formula.join(' + ').replaceAll('+ -', '- ');

    final type = effect.effectTypeName.trim();

    if (type.isNotEmpty) {
      if (result.isEmpty) {
        result = type;
      } else {
        result += ' $type';
      }
    }

    if (result.isEmpty) {
      return effect.mitigatesDamage
          ? 'Sin mitigación extra'
          : (effect.heals ? 'Sin curación extra' : 'Sin daño extra');
    }

    return result;
  }

  String _resourceName(String resourceId) {
    for (final resource in widget.resources) {
      if (resource.id == resourceId) {
        return resource.name;
      }
    }

    return resourceId;
  }
}

// =============================================================================
// EMPTY
// =============================================================================

class _EmptyEffects extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyEffects({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome_motion_rounded,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),

          const SizedBox(height: 10),

          const Text(
            'Sin efectos',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          const Text(
            'Puedes añadir daño, curación o varios efectos con salvaciones independientes.',
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 14),

          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Añadir efecto'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// COMPONENTE DE EFECTO
// =============================================================================
enum _PartConditionPreset {
  always,

  wounded,
  fullHealth,

  belowHalf,
  atOrBelowHalf,
  aboveHalf,
  atOrAboveHalf,

  belowPercent,
  atOrBelowPercent,
  abovePercent,
  atOrAbovePercent,

  self,
  external,

  custom,
}

class _AbilityEffectPartCard extends StatefulWidget {
  final AbilityEffectPart part;

  final AbilityEffectType effectType;

  final List<CharacterResource> resources;

  final ValueChanged<AbilityEffectPart> onChanged;

  final VoidCallback onDelete;

  final bool usesSavingThrow;

  const _AbilityEffectPartCard({
    super.key,
    required this.part,
    required this.effectType,
    required this.resources,
    required this.onChanged,
    required this.onDelete,
    required this.usesSavingThrow,
  });

  @override
  State<_AbilityEffectPartCard> createState() => _AbilityEffectPartCardState();
}

class _AbilityEffectPartCardState extends State<_AbilityEffectPartCard> {
  late AbilityEffectPart part;

  late final TextEditingController diceController;

  late final TextEditingController typeController;

  late final TextEditingController bonusController;

  late _PartConditionPreset conditionPreset;

  late final TextEditingController conditionPercentController;

  late final TextEditingController customConditionController;

  @override
  void initState() {
    super.initState();

    part = AbilityEffectPart.fromMap(widget.part.toMap());

    diceController = TextEditingController(text: part.diceNotation);

    typeController = TextEditingController(text: part.typeName);

    bonusController = TextEditingController(text: '${part.flatBonus}');

    conditionPreset = _detectConditionPreset(part);

    conditionPercentController = TextEditingController(
      text: _conditionThresholdText(part),
    );

    customConditionController = TextEditingController(
      text: part.condition?.expression ?? '',
    );
  }

  void notify() {
    widget.onChanged(
      AbilityEffectPart(
        id: part.id,

        dicePools: part.dicePools
            .map((pool) => DicePool(count: pool.count, sides: pool.sides))
            .toList(),

        abilityModifierMultipliers: Map<AbilityType, int>.from(
          part.abilityModifierMultipliers,
        ),

        resourceValueMultipliers: Map<String, int>.from(
          part.resourceValueMultipliers,
        ),

        flatBonus: int.tryParse(bonusController.text.trim()) ?? 0,

        typeName: typeController.text.trim(),

        costs: part.costs
            .map((cost) => ActionCost.fromMap(cost.toMap()))
            .toList(),

        condition: part.condition?.copy(),

        externalRequirements: part.externalRequirements
            .map(
              (requirement) =>
                  ActionExternalRequirement.fromMap(requirement.toMap()),
            )
            .toList(),

        optional: part.optional,

        optionalGroupId: part.optionalGroupId,

        optionalLabel: part.optionalLabel,

        hitBehavior: part.hitBehavior,

        participatesInCritical: part.participatesInCritical,
      ),
    );
  }

  _PartConditionPreset _detectConditionPreset(AbilityEffectPart part) {
    if (!part.hasCondition && part.externalRequirements.isEmpty) {
      return _PartConditionPreset.always;
    }

    if (part.externalRequirements.length == 1) {
      final requirement = part.externalRequirements.first;

      if (requirement.type == ActionExternalRequirementType.boolean) {
        switch (requirement.variableName) {
          case 'target_wounded':
            return _PartConditionPreset.wounded;

          case 'target_full_health':
            return _PartConditionPreset.fullHealth;

          case 'target_below_half':
            return _PartConditionPreset.belowHalf;

          case 'target_at_or_below_half':
            return _PartConditionPreset.atOrBelowHalf;

          case 'target_above_half':
            return _PartConditionPreset.aboveHalf;

          case 'target_at_or_above_half':
            return _PartConditionPreset.atOrAboveHalf;

          case 'target_is_self':
            return _PartConditionPreset.self;

          case 'target_is_external':
            return _PartConditionPreset.external;
        }
      }

      switch (requirement.type) {
        case ActionExternalRequirementType.percentageBelow:
          return _PartConditionPreset.belowPercent;

        case ActionExternalRequirementType.percentageAtOrBelow:
          return _PartConditionPreset.atOrBelowPercent;

        case ActionExternalRequirementType.percentageAbove:
          return _PartConditionPreset.abovePercent;

        case ActionExternalRequirementType.percentageAtOrAbove:
          return _PartConditionPreset.atOrAbovePercent;

        case ActionExternalRequirementType.boolean:
          break;
      }
    }

    return _PartConditionPreset.custom;
  }

  String _conditionThresholdText(AbilityEffectPart part) {
    if (part.externalRequirements.length != 1) {
      return '50';
    }

    final threshold = part.externalRequirements.first.threshold;

    if (threshold == null) {
      return '50';
    }

    if (threshold == threshold.roundToDouble()) {
      return threshold.toInt().toString();
    }

    return threshold.toString();
  }

  String _conditionPresetLabel(_PartConditionPreset preset) {
    switch (preset) {
      case _PartConditionPreset.always:
        return 'Siempre';

      case _PartConditionPreset.wounded:
        return 'Objetivo herido';

      case _PartConditionPreset.fullHealth:
        return 'Objetivo a vida completa';

      case _PartConditionPreset.belowHalf:
        return 'Vida por debajo del 50%';

      case _PartConditionPreset.atOrBelowHalf:
        return 'Vida al 50% o por debajo';

      case _PartConditionPreset.aboveHalf:
        return 'Vida por encima del 50%';

      case _PartConditionPreset.atOrAboveHalf:
        return 'Vida al 50% o por encima';

      case _PartConditionPreset.belowPercent:
        return 'Vida por debajo de X%';

      case _PartConditionPreset.atOrBelowPercent:
        return 'Vida a X% o por debajo';

      case _PartConditionPreset.abovePercent:
        return 'Vida por encima de X%';

      case _PartConditionPreset.atOrAbovePercent:
        return 'Vida a X% o por encima';

      case _PartConditionPreset.self:
        return 'Objetivo propio';

      case _PartConditionPreset.external:
        return 'Objetivo externo';

      case _PartConditionPreset.custom:
        return 'Fórmula personalizada';
    }
  }

  bool get _conditionUsesPercentage {
    switch (conditionPreset) {
      case _PartConditionPreset.belowPercent:
      case _PartConditionPreset.atOrBelowPercent:
      case _PartConditionPreset.abovePercent:
      case _PartConditionPreset.atOrAbovePercent:
        return true;

      default:
        return false;
    }
  }

  void _setBooleanCondition({
    required String variableName,
    required String label,
  }) {
    part.condition = CharacterFormula(expression: '$variableName == 1');

    part.externalRequirements = [
      ActionExternalRequirement.boolean(
        variableName: variableName,
        label: label,
      ),
    ];

    customConditionController.text = part.condition!.expression;
  }

  void _setPercentageCondition({required ActionExternalRequirementType type}) {
    final raw = double.tryParse(conditionPercentController.text.trim());

    final threshold = (raw ?? 50.0).clamp(0.0, 100.0).toDouble();

    final thresholdText = threshold == threshold.roundToDouble()
        ? threshold.toInt().toString()
        : threshold.toString();

    late final ActionExternalRequirement requirement;

    switch (type) {
      case ActionExternalRequirementType.percentageBelow:
        requirement = ActionExternalRequirement.percentageBelow(
          variableName: 'target_health_percent',
          threshold: threshold,
          label:
              '¿El objetivo está por debajo del '
              '$thresholdText% de vida?',
        );

        break;

      case ActionExternalRequirementType.percentageAtOrBelow:
        requirement = ActionExternalRequirement.percentageAtOrBelow(
          variableName: 'target_health_percent',
          threshold: threshold,
          label:
              '¿El objetivo está al $thresholdText% '
              'de vida o por debajo?',
        );

        break;

      case ActionExternalRequirementType.percentageAbove:
        requirement = ActionExternalRequirement.percentageAbove(
          variableName: 'target_health_percent',
          threshold: threshold,
          label:
              '¿El objetivo está por encima del '
              '$thresholdText% de vida?',
        );

        break;

      case ActionExternalRequirementType.percentageAtOrAbove:
        requirement = ActionExternalRequirement.percentageAtOrAbove(
          variableName: 'target_health_percent',
          threshold: threshold,
          label:
              '¿El objetivo está al $thresholdText% '
              'de vida o por encima?',
        );

        break;

      case ActionExternalRequirementType.boolean:
        return;
    }

    // IMPORTANTE:
    // usamos la respuesta normalizada del requirement.
    //
    // target_health_percent_lt_50
    // target_health_percent_gte_75
    // etc.
    part.condition = CharacterFormula(
      expression: '${requirement.normalizedVariableName} == 1',
    );

    part.externalRequirements = [requirement];

    customConditionController.text = part.condition!.expression;
  }

  void _applyConditionPreset() {
    switch (conditionPreset) {
      case _PartConditionPreset.always:
        part.condition = null;
        part.externalRequirements = [];
        customConditionController.clear();
        break;

      case _PartConditionPreset.wounded:
        _setBooleanCondition(
          variableName: 'target_wounded',
          label: '¿El objetivo está herido?',
        );
        break;

      case _PartConditionPreset.fullHealth:
        _setBooleanCondition(
          variableName: 'target_full_health',
          label: '¿El objetivo está a vida completa?',
        );
        break;

      case _PartConditionPreset.belowHalf:
        _setBooleanCondition(
          variableName: 'target_below_half',
          label: '¿El objetivo está por debajo del 50% de vida?',
        );
        break;

      case _PartConditionPreset.atOrBelowHalf:
        _setBooleanCondition(
          variableName: 'target_at_or_below_half',
          label: '¿El objetivo está al 50% de vida o por debajo?',
        );
        break;

      case _PartConditionPreset.aboveHalf:
        _setBooleanCondition(
          variableName: 'target_above_half',
          label: '¿El objetivo está por encima del 50% de vida?',
        );
        break;

      case _PartConditionPreset.atOrAboveHalf:
        _setBooleanCondition(
          variableName: 'target_at_or_above_half',
          label: '¿El objetivo está al 50% de vida o por encima?',
        );
        break;

      case _PartConditionPreset.self:
        // Self/external los conoce el contexto,
        // por lo que no necesitan preguntar.
        part.condition = CharacterFormula(expression: 'target_is_self == 1');

        part.externalRequirements = [];

        customConditionController.text = part.condition!.expression;
        break;

      case _PartConditionPreset.external:
        part.condition = CharacterFormula(
          expression: 'target_is_external == 1',
        );

        part.externalRequirements = [];

        customConditionController.text = part.condition!.expression;
        break;

      case _PartConditionPreset.belowPercent:
        _setPercentageCondition(
          type: ActionExternalRequirementType.percentageBelow,
        );
        break;

      case _PartConditionPreset.atOrBelowPercent:
        _setPercentageCondition(
          type: ActionExternalRequirementType.percentageAtOrBelow,
        );
        break;

      case _PartConditionPreset.abovePercent:
        _setPercentageCondition(
          type: ActionExternalRequirementType.percentageAbove,
        );
        break;

      case _PartConditionPreset.atOrAbovePercent:
        _setPercentageCondition(
          type: ActionExternalRequirementType.percentageAtOrAbove,
        );
        break;

      case _PartConditionPreset.custom:
        _applyCustomCondition();
        break;
    }

    setState(() {});

    notify();
  }

  void _applyCustomCondition() {
    final expression = customConditionController.text.trim();

    if (expression.isEmpty) {
      part.condition = null;
      part.externalRequirements = [];

      return;
    }

    part.condition = CharacterFormula(expression: expression);

    // En personalizado no destruimos automáticamente
    // requirements existentes.
    //
    // Los presets sí los sincronizan automáticamente.
  }

  @override
  void dispose() {
    diceController.dispose();

    typeController.dispose();

    bonusController.dispose();

    conditionPercentController.dispose();

    customConditionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                widget.effectType == AbilityEffectType.mitigation
                    ? Icons.shield_rounded
                    : (widget.effectType == AbilityEffectType.healing
                          ? Icons.favorite_rounded
                          : Icons.flash_on_rounded),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  widget.effectType == AbilityEffectType.mitigation
                      ? 'Componente de mitigación'
                      : (widget.effectType == AbilityEffectType.healing
                            ? 'Componente de curación'
                            : 'Componente de daño'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),

              IconButton(
                tooltip: 'Eliminar componente',
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ===================================================================
          // DADOS
          // ===================================================================
          TextFormField(
            controller: diceController,
            decoration: const InputDecoration(
              labelText: 'Dados',
              hintText: '2d4 + 1d6',
              prefixIcon: Icon(Icons.casino_rounded),
              helperText: 'Puedes usar varios grupos, por ejemplo 2d6 + 1d8.',
            ),
            onChanged: (value) {
              final parsed = _parseDicePools(value);

              if (parsed != null) {
                setState(() {
                  part.dicePools = parsed;
                });

                notify();
              }
            },
          ),

          const SizedBox(height: 12),

          // ===================================================================
          // TIPO
          // ===================================================================
          TextFormField(
            controller: typeController,
            decoration: InputDecoration(
              labelText: widget.effectType == AbilityEffectType.healing
                  ? 'Tipo de curación'
                  : 'Tipo de daño',
              hintText: widget.effectType == AbilityEffectType.healing
                  ? 'Curación'
                  : 'Fuego, perforante...',
            ),
            onChanged: (_) {
              notify();
            },
          ),

          const SizedBox(height: 12),

          // ===================================================================
          // BONUS FIJO
          // ===================================================================
          TextFormField(
            controller: bonusController,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            decoration: const InputDecoration(
              labelText: 'Bonus fijo',
              hintText: '0',
              prefixIcon: Icon(Icons.exposure_plus_1_rounded),
            ),
            onChanged: (_) {
              notify();
            },
          ),

          const SizedBox(height: 16),

          // ===================================================================
          // ATRIBUTOS
          // ===================================================================
          _PartAbilityModifiersEditor(
            multipliers: part.abilityModifierMultipliers,

            onChanged: (multipliers) {
              setState(() {
                part.abilityModifierMultipliers = multipliers;
              });

              notify();
            },
          ),

          const SizedBox(height: 16),

          // ===================================================================
          // RECURSOS
          // ===================================================================
          _PartResourceModifiersEditor(
            resources: widget.resources,

            multipliers: part.resourceValueMultipliers,

            onChanged: (multipliers) {
              setState(() {
                part.resourceValueMultipliers = multipliers;
              });

              notify();
            },
          ),

          if (widget.effectType == AbilityEffectType.damage &&
              !widget.usesSavingThrow) ...[
            const SizedBox(height: 16),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,

              value: part.participatesInCritical,

              title: const Text(
                'Participa en crítico',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),

              subtitle: const Text(
                'Si esta habilidad hace un ataque crítico, '
                'este componente también recibe la transformación crítica.',
              ),

              secondary: const Icon(Icons.whatshot_rounded),

              onChanged: (value) {
                setState(() {
                  part.participatesInCritical = value;
                });

                notify();
              },
            ),
          ],

          const SizedBox(height: 16),

          _buildConditionEditor(),
        ],
      ),
    );
  }

  Widget _buildConditionEditor() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.rule_rounded, color: theme.colorScheme.primary),

              const SizedBox(width: 8),

              const Expanded(
                child: Text(
                  'Condición de aplicación',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            'Decide cuándo participa este componente.',
            style: theme.textTheme.bodySmall,
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<_PartConditionPreset>(
            initialValue: conditionPreset,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Condición',
              prefixIcon: Icon(Icons.filter_alt_rounded),
            ),
            items: _PartConditionPreset.values.map((preset) {
              return DropdownMenuItem(
                value: preset,
                child: Text(
                  _conditionPresetLabel(preset),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              conditionPreset = value;

              _applyConditionPreset();
            },
          ),

          if (_conditionUsesPercentage) ...[
            const SizedBox(height: 12),

            TextFormField(
              controller: conditionPercentController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Porcentaje de vida',
                suffixText: '%',
                prefixIcon: Icon(Icons.percent_rounded),
              ),
              onChanged: (_) {
                _applyConditionPreset();
              },
            ),
          ],

          if (conditionPreset == _PartConditionPreset.custom) ...[
            const SizedBox(height: 12),

            TextFormField(
              controller: customConditionController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Fórmula de condición',
                hintText: 'Ej: target_wounded == 1',
                prefixIcon: Icon(Icons.functions_rounded),
              ),
              onChanged: (_) {
                _applyCustomCondition();
                notify();
              },
            ),
          ],

          if (part.hasCondition) ...[
            const SizedBox(height: 10),

            Text(
              'Condición: '
              '${part.condition!.expression}',
              style: theme.textTheme.bodySmall,
            ),
          ],

          if (part.externalRequirements.isNotEmpty) ...[
            const SizedBox(height: 4),

            Text(
              part.externalRequirements.length == 1
                  ? 'Puede requerir una pregunta al resolver la habilidad.'
                  : 'Puede requerir varias preguntas al resolver la habilidad.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// PARSER DE DADOS
// =============================================================================

List<DicePool>? _parseDicePools(String value) {
  final clean = value.trim();

  if (clean.isEmpty) {
    return [];
  }

  final pieces = clean
      .split('+')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  if (pieces.isEmpty) {
    return [];
  }

  final pools = <DicePool>[];

  for (final piece in pieces) {
    final match = RegExp(
      r'^(\d+)d(\d+)$',
      caseSensitive: false,
    ).firstMatch(piece);

    if (match == null) {
      return null;
    }

    final count = int.tryParse(match.group(1) ?? '');

    final sides = int.tryParse(match.group(2) ?? '');

    if (count == null || sides == null || count <= 0 || sides <= 0) {
      return null;
    }

    pools.add(DicePool(count: count, sides: sides));
  }

  return pools;
}

// =============================================================================
// MODIFICADORES DE ATRIBUTO
// =============================================================================

class _PartAbilityModifiersEditor extends StatelessWidget {
  final String title;

  final Map<AbilityType, int> multipliers;

  final ValueChanged<Map<AbilityType, int>> onChanged;

  const _PartAbilityModifiersEditor({
    this.title = 'Modificadores',
    required this.multipliers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final entries = multipliers.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),

            IconButton.filledTonal(
              tooltip: 'Añadir atributo',
              onPressed: () {
                final available = AbilityType.values
                    .where((ability) => !multipliers.containsKey(ability))
                    .toList();

                if (available.isEmpty) {
                  return;
                }

                final updated = Map<AbilityType, int>.from(multipliers);

                updated[available.first] = 1;

                onChanged(updated);
              },
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),

        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Sin modificadores de atributo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

        ...entries.map((entry) {
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<AbilityType>(
                        initialValue: entry.key,

                        decoration: const InputDecoration(
                          labelText: 'Atributo',
                          isDense: true,
                        ),

                        items: AbilityType.values.map((ability) {
                          return DropdownMenuItem(
                            value: ability,
                            child: Text(ability.label),
                          );
                        }).toList(),

                        onChanged: (value) {
                          if (value == null || value == entry.key) {
                            return;
                          }

                          final updated = Map<AbilityType, int>.from(
                            multipliers,
                          );

                          final count = updated.remove(entry.key) ?? 1;

                          updated[value] = (updated[value] ?? 0) + count;

                          onChanged(updated);
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    IconButton(
                      tooltip: 'Eliminar atributo',
                      onPressed: () {
                        final updated = Map<AbilityType, int>.from(multipliers);

                        updated.remove(entry.key);

                        onChanged(updated);
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Veces que se suma',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),

                    IconButton.filledTonal(
                      tooltip: 'Restar',
                      onPressed: entry.value > 1
                          ? () {
                              final updated = Map<AbilityType, int>.from(
                                multipliers,
                              );

                              updated[entry.key] = entry.value - 1;

                              onChanged(updated);
                            }
                          : null,
                      icon: const Icon(Icons.remove_rounded),
                    ),

                    Container(
                      constraints: const BoxConstraints(minWidth: 48),
                      alignment: Alignment.center,
                      child: Text(
                        '×${entry.value}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),

                    IconButton.filledTonal(
                      tooltip: 'Sumar',
                      onPressed: () {
                        final updated = Map<AbilityType, int>.from(multipliers);

                        updated[entry.key] = entry.value + 1;

                        onChanged(updated);
                      },
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// =============================================================================
// MODIFICADORES DE RECURSOS
// =============================================================================

class _PartResourceModifiersEditor extends StatelessWidget {
  final List<CharacterResource> resources;

  final Map<String, int> multipliers;

  final ValueChanged<Map<String, int>> onChanged;

  const _PartResourceModifiersEditor({
    required this.resources,
    required this.multipliers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final entries = multipliers.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.battery_charging_full_rounded,
              color: theme.colorScheme.primary,
            ),

            const SizedBox(width: 8),

            const Expanded(
              child: Text(
                'Recursos al resultado',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),

            IconButton.filledTonal(
              tooltip: 'Añadir recurso',

              onPressed: _findAvailableResource() != null ? _addResource : null,

              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Text(
          'Suma el valor actual del recurso sin consumirlo.',
          style: theme.textTheme.bodySmall,
        ),

        if (resources.isEmpty) ...[
          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'El personaje no tiene recursos disponibles.',
              textAlign: TextAlign.center,
            ),
          ),
        ],

        if (entries.isNotEmpty) ...[
          const SizedBox(height: 10),

          ...entries.map((entry) => _buildResourceRow(context, entry)),
        ],
      ],
    );
  }

  Widget _buildResourceRow(BuildContext context, MapEntry<String, int> entry) {
    final theme = Theme.of(context);

    final resource = _findResource(entry.key);

    if (resource == null) {
      return const SizedBox.shrink();
    }

    final usedIds = multipliers.keys.where((id) => id != entry.key).toSet();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.55,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: resource.id,

                  decoration: const InputDecoration(
                    labelText: 'Recurso',
                    isDense: true,
                  ),

                  items: resources
                      .where((candidate) => !usedIds.contains(candidate.id))
                      .map(
                        (candidate) => DropdownMenuItem<String>(
                          value: candidate.id,
                          child: Text(candidate.name),
                        ),
                      )
                      .toList(),

                  onChanged: (value) {
                    if (value == null || value == entry.key) {
                      return;
                    }

                    final updated = Map<String, int>.from(multipliers);

                    final multiplier = updated.remove(entry.key) ?? 1;

                    if (updated.containsKey(value)) {
                      updated[value] = updated[value]! + multiplier;
                    } else {
                      updated[value] = multiplier;
                    }

                    onChanged(updated);
                  },
                ),
              ),

              const SizedBox(width: 8),

              IconButton(
                tooltip: 'Eliminar recurso',

                onPressed: () {
                  final updated = Map<String, int>.from(multipliers);

                  updated.remove(entry.key);

                  onChanged(updated);
                },

                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Veces que se suma',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

              IconButton.filledTonal(
                tooltip: 'Restar',

                onPressed: entry.value > 1
                    ? () {
                        final updated = Map<String, int>.from(multipliers);

                        updated[entry.key] = entry.value - 1;

                        onChanged(updated);
                      }
                    : null,

                icon: const Icon(Icons.remove_rounded),
              ),

              Container(
                constraints: const BoxConstraints(minWidth: 54),
                alignment: Alignment.center,
                child: Text(
                  '×${entry.value}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              IconButton.filledTonal(
                tooltip: 'Sumar',

                onPressed: () {
                  final updated = Map<String, int>.from(multipliers);

                  updated[entry.key] = entry.value + 1;

                  onChanged(updated);
                },

                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  CharacterResource? _findResource(String id) {
    for (final resource in resources) {
      if (resource.id == id) {
        return resource;
      }
    }

    return null;
  }

  CharacterResource? _findAvailableResource() {
    for (final resource in resources) {
      if (!multipliers.containsKey(resource.id)) {
        return resource;
      }
    }

    return null;
  }

  void _addResource() {
    final resource = _findAvailableResource();

    if (resource == null) {
      return;
    }

    final updated = Map<String, int>.from(multipliers);

    updated[resource.id] = 1;

    onChanged(updated);
  }
}
