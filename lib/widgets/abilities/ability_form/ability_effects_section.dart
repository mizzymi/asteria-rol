import 'package:flutter/material.dart';

import '../../../models/ability.dart';
import '../../../models/dice_pool.dart';
import '../../../models/skill.dart';

class AbilityEffectsSection extends StatelessWidget {
  final List<AbilityEffect> effects;

  final VoidCallback onAddEffect;

  final void Function(int index, AbilityEffect effect) onEffectChanged;

  final ValueChanged<int> onRemoveEffect;

  final ValueChanged<int> onMoveUp;
  final ValueChanged<int> onMoveDown;

  const AbilityEffectsSection({
    super.key,
    required this.effects,
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

  final int index;
  final int totalEffects;

  final ValueChanged<AbilityEffect> onChanged;

  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const AbilityEffectEditor({
    super.key,
    required this.effect,
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
      dicePools: source.dicePools
          .map((pool) => DicePool(count: pool.count, sides: pool.sides))
          .toList(),
      addAbilityModifierToEffect: source.addAbilityModifierToEffect,
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

  @override
  void dispose() {
    nameController.dispose();
    bonusController.dispose();
    typeNameController.dispose();
    saveDcBonusController.dispose();

    super.dispose();
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

              if (value != AbilityEffectType.none && effect.dicePools.isEmpty) {
                effect.dicePools.add(DicePool(count: 1, sides: 6));
              }

              if (value == AbilityEffectType.none) {
                effect.dicePools.clear();
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
          effect.heals ? 'Dados de curación' : 'Dados',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        ...List.generate(effect.dicePools.length, (index) {
          final pool = effect.dicePools[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: pool.count,
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                    items: List.generate(20, (i) => i + 1).map((count) {
                      return DropdownMenuItem(
                        value: count,
                        child: Text('$count'),
                      );
                    }).toList(),
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
                    decoration: const InputDecoration(labelText: 'Dado'),
                    items: availableDice.map((sides) {
                      return DropdownMenuItem(
                        value: sides,
                        child: Text('d$sides'),
                      );
                    }).toList(),
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
                  tooltip: 'Eliminar dados',
                  onPressed: () {
                    removeDice(index);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          );
        }),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: addDice,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Añadir grupo de dados'),
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
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: effect.addAbilityModifierToEffect,
          title: Text(
            effect.heals
                ? 'Sumar atributo a la curación'
                : 'Sumar atributo al daño',
          ),
          subtitle: const Text('Usa el atributo principal de la habilidad'),
          onChanged: (value) {
            setState(() {
              effect.addAbilityModifierToEffect = value;
            });

            notifyParent();
          },
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: bonusController,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: InputDecoration(
            labelText: effect.heals
                ? 'Bonus adicional de curación'
                : 'Bonus adicional de daño',
          ),
          onChanged: (_) {
            notifyParent();
          },
        ),
      ],
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

    final pieces = <String>[];

    if (effect.diceNotation.isNotEmpty) {
      pieces.add(effect.diceNotation);
    }

    if (effect.effectTypeName.isNotEmpty) {
      pieces.add(effect.effectTypeName);
    }

    if (effect.usesSavingThrow) {
      pieces.add(
        '${effect.savingThrowAbility.shortLabel} · ${effect.saveSuccessEffect.label}',
      );
    }

    return pieces.isEmpty ? effect.effectType.label : pieces.join(' · ');
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
