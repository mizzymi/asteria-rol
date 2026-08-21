import 'package:flutter/material.dart';
import 'package:rol/models/character_resource.dart';

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

                index: index,

                totalEffects: effects.length,

                onChanged: (effect) {
                  onEffectChanged(index, effect);
                },

                onDelete: () {
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
  static const availableDice = [4, 6, 8, 10, 12, 20, 100];

  late final TextEditingController nameController;

  late final TextEditingController bonusController;

  late final TextEditingController typeNameController;

  late final TextEditingController saveDcBonusController;

  late AbilityEffect effect;

  bool expanded = true;

  @override
  void initState() {
    super.initState();

    effect = _clone(widget.effect);

    nameController = TextEditingController(text: effect.name);

    bonusController = TextEditingController(text: '${effect.effectBonus}');

    typeNameController = TextEditingController(text: effect.effectTypeName);

    saveDcBonusController = TextEditingController(
      text: '${effect.saveDcBonus}',
    );
  }

  AbilityEffect _clone(AbilityEffect source) {
    return AbilityEffect(
      id: source.id,
      name: source.name,
      effectType: source.effectType,

      parts: source.parts
          .map((part) => AbilityEffectPart.fromMap(part.toMap()))
          .toList(),

      // Legacy
      dicePools: source.dicePools
          .map((pool) => DicePool(count: pool.count, sides: pool.sides))
          .toList(),

      abilityModifierMultipliers: Map<AbilityType, int>.from(
        source.abilityModifierMultipliers,
      ),

      legacyAddAbilityModifier: source.legacyAddAbilityModifier,

      effectBonus: source.effectBonus,
      effectTypeName: source.effectTypeName,

      usesSavingThrow: source.usesSavingThrow,

      savingThrowAbility: source.savingThrowAbility,

      saveDcBonus: source.saveDcBonus,

      saveSuccessEffect: source.saveSuccessEffect,
    );
  }

  void notifyParent() {
    effect.name = nameController.text.trim();

    effect.effectBonus = int.tryParse(bonusController.text) ?? 0;

    effect.effectTypeName = typeNameController.text.trim();

    effect.saveDcBonus = int.tryParse(saveDcBonusController.text) ?? 0;

    widget.onChanged(_clone(effect));
  }

  void addDice() {
    setState(() {
      effect.dicePools.add(DicePool(count: 1, sides: 6));
    });

    notifyParent();
  }

  void removeDice(int index) {
    setState(() {
      effect.dicePools.removeAt(index);
    });

    notifyParent();
  }

  void addPart() {
    setState(() {
      effect.parts.add(
        AbilityEffectPart(
          id: '${DateTime.now().microsecondsSinceEpoch}_part',

          dicePools: [DicePool(count: 1, sides: 6)],

          abilityModifierMultipliers: {},

          flatBonus: 0,

          typeName: effect.dealsDamage ? 'Daño' : 'Curación',
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

  @override
  void dispose() {
    nameController.dispose();
    bonusController.dispose();
    typeNameController.dispose();
    saveDcBonusController.dispose();

    super.dispose();
  }

  void addAbilityModifier() {
    final available = AbilityType.values.where(
      (ability) => !effect.abilityModifierMultipliers.containsKey(ability),
    );

    if (available.isEmpty) {
      return;
    }

    setState(() {
      effect.abilityModifierMultipliers[available.first] = 1;

      // Ya estamos usando el sistema moderno.
      effect.legacyAddAbilityModifier = false;
    });

    notifyParent();
  }

  void removeAbilityModifier(AbilityType ability) {
    setState(() {
      effect.abilityModifierMultipliers.remove(ability);
    });

    notifyParent();
  }

  void changeAbilityModifierType(
    AbilityType oldAbility,
    AbilityType newAbility,
  ) {
    if (oldAbility == newAbility) {
      return;
    }

    final multiplier = effect.abilityModifierMultipliers[oldAbility] ?? 1;

    setState(() {
      effect.abilityModifierMultipliers.remove(oldAbility);

      effect.abilityModifierMultipliers[newAbility] = multiplier;

      effect.legacyAddAbilityModifier = false;
    });

    notifyParent();
  }

  void changeAbilityMultiplier(AbilityType ability, int value) {
    if (value <= 0) {
      removeAbilityModifier(ability);

      return;
    }

    setState(() {
      effect.abilityModifierMultipliers[ability] = value;

      effect.legacyAddAbilityModifier = false;
    });

    notifyParent();
  }

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

                    _buildDiceSection(),

                    const SizedBox(height: 18),

                    _buildModifierSection(),

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

              if (value == AbilityEffectType.none) {
                effect.dicePools.clear();

                effect.abilityModifierMultipliers.clear();

                effect.effectBonus = 0;

                bonusController.text = '0';

                effect.legacyAddAbilityModifier = false;
              }
            });

            notifyParent();
          },
        ),

        if (effect.effectType != AbilityEffectType.none) ...[
          const SizedBox(height: 12),

          TextFormField(
            controller: typeNameController,
            decoration: InputDecoration(
              labelText: effect.effectType == AbilityEffectType.healing
                  ? 'Descripción'
                  : 'Tipo de daño',
              hintText: effect.effectType == AbilityEffectType.healing
                  ? 'Curación mágica'
                  : 'Hielo, veneno, fuego...',
            ),
            onChanged: (_) {
              notifyParent();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDiceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          effect.heals ? 'Componentes de curación' : 'Componentes de daño',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        ...List.generate(effect.parts.length, (partIndex) {
          final part = effect.parts[partIndex];

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================================================================
                // CABECERA DEL COMPONENTE
                // ================================================================
                Row(
                  children: [
                    Icon(
                      effect.heals
                          ? Icons.favorite_rounded
                          : Icons.flash_on_rounded,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        effect.heals
                            ? 'Componente de curación'
                            : 'Componente de daño',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),

                    IconButton(
                      tooltip: 'Eliminar componente',
                      onPressed: () {
                        setState(() {
                          effect.parts.removeAt(partIndex);
                        });

                        notifyParent();
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ================================================================
                // TIPO DE DAÑO / CURACIÓN
                // ================================================================
                TextFormField(
                  initialValue: part.typeName,
                  decoration: InputDecoration(
                    labelText: effect.heals
                        ? 'Tipo de curación'
                        : 'Tipo de daño',
                    hintText: effect.heals
                        ? 'Curación'
                        : 'Veneno, fuego, cortante...',
                  ),
                  onChanged: (value) {
                    part.typeName = value.trim();

                    notifyParent();
                  },
                ),

                const SizedBox(height: 14),

                // ================================================================
                // DADOS DEL COMPONENTE
                // ================================================================
                Text(
                  effect.heals
                      ? 'Dados'
                      : 'Dados de ${part.typeName.trim().isEmpty ? 'daño' : part.typeName}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 10),

                ...List.generate(part.dicePools.length, (diceIndex) {
                  final pool = part.dicePools[diceIndex];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: pool.count,
                            decoration: const InputDecoration(
                              labelText: 'Cantidad',
                            ),
                            items: List.generate(20, (i) => i + 1)
                                .map(
                                  (count) => DropdownMenuItem(
                                    value: count,
                                    child: Text('$count'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                pool.count = value;
                              });

                              notifyParent();
                            },
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: pool.sides,
                            decoration: const InputDecoration(
                              labelText: 'Dado',
                            ),
                            items: availableDice
                                .map(
                                  (sides) => DropdownMenuItem(
                                    value: sides,
                                    child: Text('d$sides'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                pool.sides = value;
                              });

                              notifyParent();
                            },
                          ),
                        ),

                        IconButton(
                          tooltip: 'Eliminar dado',
                          onPressed: () {
                            setState(() {
                              part.dicePools.removeAt(diceIndex);
                            });

                            notifyParent();
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  );
                }),

                // ================================================================
                // AÑADIR DADO AL MISMO COMPONENTE
                // ================================================================
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        part.dicePools.add(DicePool(count: 1, sides: 6));
                      });

                      notifyParent();
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Añadir dado al componente'),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: () {
              setState(() {
                effect.parts.add(
                  AbilityEffectPart(
                    id: '${DateTime.now().microsecondsSinceEpoch}_part',

                    typeName: effect.heals ? 'Curación' : '',

                    dicePools: [DicePool(count: 1, sides: 6)],
                  ),
                );
              });

              notifyParent();
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(
              effect.heals ? 'Añadir curación' : 'Añadir tipo de daño',
            ),
          ),
        ),

        if (effect.dicePools.isNotEmpty) ...[
          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.casino_rounded),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    effect.diceNotation,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                Text(
                  'Máx. ${effect.dicePools.fold<int>(0, (sum, pool) => sum + pool.maximum)}',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModifierSection() {
    final theme = Theme.of(context);

    final entries = effect.abilityModifierMultipliers.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.psychology_rounded, color: theme.colorScheme.primary),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                effect.heals
                    ? 'Modificadores de curación'
                    : 'Modificadores de daño',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Text(
          'Puedes añadir uno o varios atributos y decidir cuántas veces se suma cada modificador.',
          style: theme.textTheme.bodySmall,
        ),

        const SizedBox(height: 12),

        if (entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Sin modificadores de atributo',
              textAlign: TextAlign.center,
            ),
          )
        else
          ...entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildAbilityModifierRow(entry.key, entry.value),
            );
          }),

        const SizedBox(height: 4),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: entries.length < AbilityType.values.length
                ? addAbilityModifier
                : null,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Añadir modificador'),
          ),
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: bonusController,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: InputDecoration(
            labelText: effect.heals
                ? 'Bonus fijo de curación'
                : 'Bonus fijo de daño',
            hintText: 'Ej: 5 o -2',
            prefixIcon: const Icon(Icons.add_circle_outline_rounded),
          ),
          onChanged: (_) {
            notifyParent();
          },
        ),

        if (effect.abilityModifierMultipliers.isNotEmpty) ...[
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.functions_rounded, color: theme.colorScheme.primary),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    _modifierSummary,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAbilityModifierRow(AbilityType ability, int multiplier) {
    final theme = Theme.of(context);

    final usedAbilities = effect.abilityModifierMultipliers.keys
        .where((item) => item != ability)
        .toSet();

    return Container(
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
                child: DropdownButtonFormField<AbilityType>(
                  initialValue: ability,

                  decoration: const InputDecoration(
                    labelText: 'Atributo',
                    isDense: true,
                  ),

                  items: AbilityType.values
                      .where((item) => !usedAbilities.contains(item))
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),

                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    changeAbilityModifierType(ability, value);
                  },
                ),
              ),

              const SizedBox(width: 8),

              IconButton(
                tooltip: 'Eliminar modificador',
                onPressed: () {
                  removeAbilityModifier(ability);
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
                onPressed: multiplier > 1
                    ? () {
                        changeAbilityMultiplier(ability, multiplier - 1);
                      }
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),

              Container(
                constraints: const BoxConstraints(minWidth: 54),
                alignment: Alignment.center,
                child: Text(
                  '×$multiplier',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              IconButton.filledTonal(
                tooltip: 'Sumar',
                onPressed: () {
                  changeAbilityMultiplier(ability, multiplier + 1);
                },
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

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

  IconData get _effectIcon {
    switch (effect.effectType) {
      case AbilityEffectType.damage:
        return effect.usesSavingThrow
            ? Icons.shield_rounded
            : Icons.flash_on_rounded;

      case AbilityEffectType.healing:
        return Icons.favorite_rounded;

      case AbilityEffectType.none:
        return Icons.auto_awesome_rounded;
    }
  }

  String get _summary {
    if (effect.effectType == AbilityEffectType.none) {
      return 'Sin daño ni curación';
    }

    final formula = <String>[];

    // Dados
    if (effect.diceNotation.isNotEmpty) {
      formula.add(effect.diceNotation);
    }

    // Modificadores
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

    // Bonus fijo
    if (effect.effectBonus != 0) {
      formula.add(
        effect.effectBonus > 0
            ? '+${effect.effectBonus}'
            : '${effect.effectBonus}',
      );
    }

    final pieces = <String>[];

    if (formula.isNotEmpty) {
      pieces.add(formula.join(' + '));
    }

    if (effect.effectTypeName.isNotEmpty) {
      pieces.add(effect.effectTypeName);
    }

    if (effect.usesSavingThrow) {
      pieces.add(
        '${effect.savingThrowAbility.shortLabel} · '
        '${effect.saveSuccessEffect.label}',
      );
    }

    return pieces.isEmpty ? effect.effectType.label : pieces.join(' · ');
  }

  String get _modifierSummary {
    final pieces = <String>[];

    for (final entry in effect.abilityModifierMultipliers.entries) {
      final multiplier = entry.value;

      if (multiplier == 0) {
        continue;
      }

      final ability = entry.key.shortLabel;

      if (multiplier == 1) {
        pieces.add(ability);
      } else {
        pieces.add('$multiplier×$ability');
      }
    }

    final bonus = int.tryParse(bonusController.text) ?? effect.effectBonus;

    if (bonus != 0) {
      pieces.add(bonus > 0 ? '+$bonus' : '$bonus');
    }

    if (pieces.isEmpty) {
      return 'Sin modificadores';
    }

    return pieces.join(' + ');
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

class _AbilityEffectPartCard extends StatefulWidget {
  final AbilityEffectPart part;

  final AbilityEffectType effectType;

  final List<CharacterResource> resources;

  final ValueChanged<AbilityEffectPart> onChanged;

  final VoidCallback onDelete;

  const _AbilityEffectPartCard({
    required this.part,
    required this.effectType,
    required this.resources,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_AbilityEffectPartCard> createState() => _AbilityEffectPartCardState();
}

class _AbilityEffectPartCardState extends State<_AbilityEffectPartCard> {
  late AbilityEffectPart part;

  late final TextEditingController diceController;

  late final TextEditingController typeController;

  late final TextEditingController bonusController;

  @override
  void initState() {
    super.initState();

    part = AbilityEffectPart.fromMap(widget.part.toMap());

    diceController = TextEditingController(text: part.diceNotation);

    typeController = TextEditingController(text: part.typeName);

    bonusController = TextEditingController(text: '${part.flatBonus}');
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

        flatBonus: int.tryParse(bonusController.text) ?? 0,

        typeName: typeController.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    diceController.dispose();
    typeController.dispose();
    bonusController.dispose();

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
                widget.effectType == AbilityEffectType.healing
                    ? Icons.favorite_rounded
                    : Icons.flash_on_rounded,
              ),

              const SizedBox(width: 8),

              const Expanded(
                child: Text(
                  'Componente',
                  style: TextStyle(fontWeight: FontWeight.w800),
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

          TextFormField(
            controller: diceController,
            decoration: const InputDecoration(
              labelText: 'Dados',
              hintText: '2d4 + 1d6',
              prefixIcon: Icon(Icons.casino_rounded),
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

          TextFormField(
            controller: bonusController,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            decoration: const InputDecoration(
              labelText: 'Bonus fijo',
              hintText: '0',
            ),
            onChanged: (_) {
              notify();
            },
          ),

          const SizedBox(height: 12),

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
        ],
      ),
    );
  }
}

List<DicePool>? _parseDicePools(String value) {
  final pieces = value
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

class _PartAbilityModifiersEditor extends StatelessWidget {
  final Map<AbilityType, int> multipliers;

  final ValueChanged<Map<AbilityType, int>> onChanged;

  const _PartAbilityModifiersEditor({
    required this.multipliers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final entries = multipliers.entries.toList();

    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Modificadores',
                style: TextStyle(fontWeight: FontWeight.w700),
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

        ...entries.map((entry) {
          return Row(
            children: [
              Expanded(
                child: DropdownButton<AbilityType>(
                  isExpanded: true,
                  value: entry.key,
                  items: AbilityType.values
                      .map(
                        (ability) => DropdownMenuItem(
                          value: ability,
                          child: Text(ability.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    final updated = Map<AbilityType, int>.from(multipliers);

                    final count = updated.remove(entry.key) ?? 1;

                    updated[value] = count;

                    onChanged(updated);
                  },
                ),
              ),

              IconButton(
                onPressed: entry.value > 1
                    ? () {
                        final updated = Map<AbilityType, int>.from(multipliers);

                        updated[entry.key] = entry.value - 1;

                        onChanged(updated);
                      }
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),

              Text(
                '×${entry.value}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),

              IconButton(
                onPressed: () {
                  final updated = Map<AbilityType, int>.from(multipliers);

                  updated[entry.key] = entry.value + 1;

                  onChanged(updated);
                },
                icon: const Icon(Icons.add_rounded),
              ),

              IconButton(
                onPressed: () {
                  final updated = Map<AbilityType, int>.from(multipliers);

                  updated.remove(entry.key);

                  onChanged(updated);
                },
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          );
        }),
      ],
    );
  }
}

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

                    updated[value] = multiplier;

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
