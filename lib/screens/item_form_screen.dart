import 'package:flutter/material.dart';
import 'package:rol/widgets/items/item_form/item_calculation_section.dart';

import '../models/ability.dart';
import '../models/item.dart';
import '../models/passive.dart';
import '../models/skill.dart';
import '../models/weapon.dart';
import '../models/weapon_damage.dart';
import '../models/dice_pool.dart';
import '../models/consumable.dart';
import '../models/character.dart';

import '../widgets/items/item_form/item_consumable_section.dart';
import '../widgets/items/item_form/item_weapon_section.dart';
import '../widgets/items/item_form/item_image_section.dart';
import '../widgets/items/item_form/item_general_section.dart';
import '../widgets/items/item_form/item_armor_section.dart';
import '../widgets/items/item_form/item_passives_section.dart';
import '../widgets/items/item_form/item_abilities_section.dart';
import '../widgets/items/item_form/item_notes_section.dart';

import 'ability_form_screen.dart';
import 'passive_form_screen.dart';

class ItemFormScreen extends StatefulWidget {
  final CharacterItem? item;

  /// Personaje al que pertenece el objeto.
  ///
  /// Puede ser null cuando editamos un objeto
  /// directamente desde la biblioteca.
  final Character? character;

  const ItemFormScreen({super.key, this.item, this.character});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ===========================================================================
  // CONTROLADORES
  // ===========================================================================

  late final TextEditingController nameController;

  late final TextEditingController descriptionController;

  late final TextEditingController quantityController;

  late final TextEditingController notesController;

  late final TextEditingController armorBaseClassController;

  // ===========================================================================
  // ESTADO
  // ===========================================================================

  late ItemType itemType;

  late ArmorCategory armorCategory;

  bool equipped = false;

  late String imagePath;

  late List<CharacterPassive> passives;

  late List<CharacterAbility> abilities;

  bool get editing {
    return widget.item != null;
  }

  late final TextEditingController magicBonusController;

  late AbilityType weaponAttackAbility;

  bool weaponProficient = true;

  late List<WeaponDamage> weaponDamages;

  late bool calculable;

  late List<ItemCalculationCost> calculationCosts;

  // ===========================================================================
  // CONSUMIBLE
  // ===========================================================================

  late String consumableUseText;

  late List<AbilityEffect> consumableEffects;

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    nameController = TextEditingController(text: item?.name ?? '');

    descriptionController = TextEditingController(
      text: item?.description ?? '',
    );

    quantityController = TextEditingController(text: '${item?.quantity ?? 1}');

    notesController = TextEditingController(text: item?.notes ?? '');

    armorBaseClassController = TextEditingController(
      text: '${item?.armorBaseClass ?? 11}',
    );

    itemType = item?.type ?? ItemType.other;

    calculable = item?.calculable ?? false;

    calculationCosts =
        item?.calculationCosts
            .map((cost) => ItemCalculationCost.fromMap(cost.toMap()))
            .toList() ??
        [];

    armorCategory = item?.armorCategory ?? ArmorCategory.light;

    final weapon = item?.weapon;

    magicBonusController = TextEditingController(
      text: '${weapon?.magicBonus ?? 0}',
    );

    weaponAttackAbility = weapon?.attackAbility ?? AbilityType.strength;

    weaponProficient = weapon?.proficient ?? true;

    weaponDamages =
        weapon?.damages
            .map((damage) => WeaponDamage.fromMap(damage.toMap()))
            .toList() ??
        [];

    final consumable = item?.consumable;

    consumableUseText = consumable?.useText.trim().isNotEmpty == true
        ? consumable!.useText
        : 'Usar';

    consumableEffects =
        consumable?.effects
            .map<AbilityEffect>((effect) => _cloneConsumableEffect(effect))
            .toList() ??
        <AbilityEffect>[];

    equipped = item?.equipped ?? false;

    imagePath = item?.imagePath ?? '';

    // =========================================================================
    // COPIA PROFUNDA DE PASIVAS
    // =========================================================================

    passives =
        item?.passives
            .map((passive) => CharacterPassive.fromMap(passive.toMap()))
            .toList() ??
        [];

    // =========================================================================
    // COPIA PROFUNDA DE HABILIDADES
    // =========================================================================

    abilities =
        item?.abilities
            .map((ability) => CharacterAbility.fromMap(ability.toMap()))
            .toList() ??
        [];
  }

  // ===========================================================================
  // EFECTOS DEL CONSUMIBLE
  // ===========================================================================

  void addConsumableEffect() {
    setState(() {
      consumableEffects.add(
        AbilityEffect(
          id: '${DateTime.now().microsecondsSinceEpoch}_consumable_effect',

          name: '',

          effectType: AbilityEffectType.healing,

          dicePools: [DicePool(count: 1, sides: 4)],

          abilityModifierMultipliers: {},

          legacyAddAbilityModifier: false,

          effectBonus: 0,

          saveSuccessEffect: SaveSuccessEffect.half,
        ),
      );
    });
  }

  void updateConsumableEffect(int index, AbilityEffect effect) {
    if (index < 0 || index >= consumableEffects.length) {
      return;
    }

    setState(() {
      consumableEffects[index] = effect;
    });
  }

  void removeConsumableEffect(int index) {
    if (index < 0 || index >= consumableEffects.length) {
      return;
    }

    setState(() {
      consumableEffects.removeAt(index);
    });
  }

  void moveConsumableEffectUp(int index) {
    if (index <= 0 || index >= consumableEffects.length) {
      return;
    }

    setState(() {
      final effect = consumableEffects.removeAt(index);

      consumableEffects.insert(index - 1, effect);
    });
  }

  void moveConsumableEffectDown(int index) {
    if (index < 0 || index >= consumableEffects.length - 1) {
      return;
    }

    setState(() {
      final effect = consumableEffects.removeAt(index);

      consumableEffects.insert(index + 1, effect);
    });
  }

  // ===========================================================================
  // PASIVAS
  // ===========================================================================

  Future<void> addPassive() async {
    final passive = await Navigator.push<CharacterPassive>(
      context,
      MaterialPageRoute(builder: (_) => const PassiveFormScreen()),
    );

    if (passive == null || !mounted) {
      return;
    }

    /*
     * Las pasivas creadas desde un objeto
     * siempre se marcan como procedentes
     * de un objeto.
     */
    passive.sourceType = PassiveSourceType.item;

    setState(() {
      passives.add(passive);
    });
  }

  AbilityEffect _cloneConsumableEffect(AbilityEffect effect) {
    return AbilityEffect(
      id: effect.id,

      name: effect.name,

      effectType: effect.effectType,

      dicePools: effect.dicePools
          .map((pool) => DicePool(count: pool.count, sides: pool.sides))
          .toList(),

      abilityModifierMultipliers: Map<AbilityType, int>.from(
        effect.abilityModifierMultipliers,
      ),

      legacyAddAbilityModifier: effect.legacyAddAbilityModifier,

      effectBonus: effect.effectBonus,

      effectTypeName: effect.effectTypeName,

      usesSavingThrow: effect.usesSavingThrow,

      savingThrowAbility: effect.savingThrowAbility,

      saveDcBonus: effect.saveDcBonus,

      saveSuccessEffect: effect.saveSuccessEffect,
    );
  }

  Future<void> editPassive(int index) async {
    if (index < 0 || index >= passives.length) {
      return;
    }

    final current = passives[index];

    final result = await Navigator.push<CharacterPassive>(
      context,
      MaterialPageRoute(builder: (_) => PassiveFormScreen(passive: current)),
    );

    if (result == null || !mounted) {
      return;
    }

    result.sourceType = PassiveSourceType.item;

    setState(() {
      passives[index] = result;
    });
  }

  Future<void> deletePassive(int index) async {
    if (index < 0 || index >= passives.length) {
      return;
    }

    final passive = passives[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar pasiva'),
          content: Text('¿Quieres eliminar "${passive.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      passives.removeAt(index);
    });
  }

  // ===========================================================================
  // HABILIDADES
  // ===========================================================================

  Future<void> addAbility() async {
    final ability = await Navigator.push<CharacterAbility>(
      context,
      MaterialPageRoute(builder: (_) => const AbilityFormScreen()),
    );

    if (ability == null || !mounted) {
      return;
    }

    setState(() {
      abilities.add(ability);
    });
  }

  Future<void> editAbility(int index) async {
    if (index < 0 || index >= abilities.length) {
      return;
    }

    final current = abilities[index];

    final result = await Navigator.push<CharacterAbility>(
      context,
      MaterialPageRoute(builder: (_) => AbilityFormScreen(ability: current)),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      abilities[index] = result;
    });
  }

  Future<void> deleteAbility(int index) async {
    if (index < 0 || index >= abilities.length) {
      return;
    }

    final ability = abilities[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar habilidad'),
          content: Text('¿Quieres eliminar "${ability.name}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      abilities.removeAt(index);
    });
  }

  // ===========================================================================
  // GUARDAR
  // ===========================================================================

  void saveItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (itemType == ItemType.weapon && weaponDamages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade al menos un componente de daño al arma.'),
        ),
      );

      return;
    }

    Weapon? weapon;

    if (itemType == ItemType.weapon) {
      final primaryDamage = weaponDamages.isNotEmpty
          ? weaponDamages.first
          : null;

      weapon = Weapon(
        id:
            widget.item?.weapon?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),

        name: nameController.text.trim(),

        attackAbility: weaponAttackAbility,

        proficient: weaponProficient,

        magicBonus: int.tryParse(magicBonusController.text) ?? 0,

        // =========================================================
        // LEGACY
        // =========================================================
        damageDice: primaryDamage?.diceNotation ?? '1d6',

        damageType: primaryDamage?.damageType ?? 'Cortante',

        // =========================================================
        // NUEVO SISTEMA
        // =========================================================
        damages: weaponDamages
            .map((damage) => WeaponDamage.fromMap(damage.toMap()))
            .toList(),
      );
    }

    Consumable? consumable;

    if (itemType == ItemType.consumable) {
      consumable = Consumable(
        useText: consumableUseText.trim().isEmpty
            ? 'Usar'
            : consumableUseText.trim(),

        effects: consumableEffects.map(_cloneConsumableEffect).toList(),
      );
    }

    final quantity = int.tryParse(quantityController.text) ?? 1;

    final armorBaseClass = int.tryParse(armorBaseClassController.text) ?? 10;

    final item = CharacterItem(
      id: widget.item?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),

      calculable: calculable,

      calculationCosts: calculationCosts
          .map((cost) => ItemCalculationCost.fromMap(cost.toMap()))
          .toList(),
      // Imagen
      imagePath: imagePath,

      // Datos generales
      name: nameController.text.trim(),

      description: descriptionController.text.trim(),

      type: itemType,

      quantity: quantity,

      notes: notesController.text.trim(),

      // Equipamiento
      equipped: itemType.isEquipable ? equipped : false,

      // Armadura
      armorCategory: itemType == ItemType.armor ? armorCategory : null,

      armorBaseClass: itemType == ItemType.armor ? armorBaseClass : 10,

      //Arma
      weapon: weapon,

      // Consumible
      consumable: consumable,

      // Pasivas
      passives: passives
          .map((passive) => CharacterPassive.fromMap(passive.toMap()))
          .toList(),

      // Habilidades
      abilities: abilities
          .map((ability) => CharacterAbility.fromMap(ability.toMap()))
          .toList(),
    );

    Navigator.pop(context, item);
  }

  // ===========================================================================
  // DAÑOS DEL ARMA
  // ===========================================================================

  Future<void> addWeaponDamage() async {
    final result = await openWeaponDamageForm();

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      weaponDamages.add(result);
    });
  }

  Future<void> editWeaponDamage(int index) async {
    if (index < 0 || index >= weaponDamages.length) {
      return;
    }

    final current = weaponDamages[index];

    final result = await openWeaponDamageForm(damage: current);

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      weaponDamages[index] = result;
    });
  }

  Future<void> deleteWeaponDamage(int index) async {
    if (index < 0 || index >= weaponDamages.length) {
      return;
    }

    final damage = weaponDamages[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar daño'),
          content: Text(
            damage.name.trim().isNotEmpty
                ? '¿Quieres eliminar "${damage.name}"?'
                : '¿Quieres eliminar este componente de daño?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      weaponDamages.removeAt(index);
    });
  }

  Future<WeaponDamage?> openWeaponDamageForm({WeaponDamage? damage}) async {
    final diceController = TextEditingController(
      text: damage?.diceNotation ?? '1d8',
    );

    final nameController = TextEditingController(text: damage?.name ?? '');

    final damageTypeController = TextEditingController(
      text: damage?.damageType ?? 'Cortante',
    );

    final bonusController = TextEditingController(
      text: '${damage?.bonus ?? 0}',
    );

    bool addAbilityModifier = damage?.addAbilityModifier ?? true;

    AbilityType abilityType = damage?.abilityType ?? weaponAttackAbility;

    final result = await showDialog<WeaponDamage>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(damage == null ? 'Añadir daño' : 'Editar daño'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Daño principal',
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: diceController,
                      decoration: const InputDecoration(
                        labelText: 'Dados',
                        hintText: '1d8',
                        prefixIcon: Icon(Icons.casino_rounded),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: damageTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de daño',
                        hintText: 'Cortante',
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: bonusController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Bonificador',
                        hintText: '0',
                      ),
                    ),

                    const SizedBox(height: 10),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Añadir modificador de atributo'),
                      value: addAbilityModifier,
                      onChanged: (value) {
                        setDialogState(() {
                          addAbilityModifier = value;
                        });
                      },
                    ),

                    if (addAbilityModifier)
                      DropdownButtonFormField<AbilityType>(
                        initialValue: abilityType,
                        decoration: const InputDecoration(
                          labelText: 'Atributo',
                        ),
                        items: AbilityType.values.map((ability) {
                          return DropdownMenuItem(
                            value: ability,
                            child: Text(ability.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              abilityType = value;
                            });
                          }
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),

                FilledButton(
                  onPressed: () {
                    final pools = _parseWeaponDice(diceController.text);

                    if (pools == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Usa un formato de dados válido, por ejemplo 1d8 o 2d6.',
                          ),
                        ),
                      );

                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      WeaponDamage(
                        id:
                            damage?.id ??
                            DateTime.now().microsecondsSinceEpoch.toString(),
                        name: nameController.text.trim(),
                        dicePools: pools,
                        addAbilityModifier: addAbilityModifier,
                        abilityType: abilityType,
                        bonus: int.tryParse(bonusController.text) ?? 0,
                        damageType: damageTypeController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    diceController.dispose();
    nameController.dispose();
    damageTypeController.dispose();
    bonusController.dispose();

    return result;
  }

  List<DicePool>? _parseWeaponDice(String value) {
    final pieces = value
        .split('+')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (pieces.isEmpty) {
      return null;
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

  void addCalculationCost() {
    final candidates = widget.character?.items ?? [];

    CharacterItem? candidate;

    for (final item in candidates) {
      final key = item.templateId.isNotEmpty ? item.templateId : item.id;

      final alreadyUsed = calculationCosts.any((cost) => cost.itemId == key);

      if (!alreadyUsed) {
        candidate = item;
        break;
      }
    }

    if (candidate == null) {
      return;
    }

    final key = candidate.templateId.isNotEmpty
        ? candidate.templateId
        : candidate.id;

    setState(() {
      calculationCosts.add(
        ItemCalculationCost(itemId: key, quantityPerUnit: 1),
      );
    });
  }

  void updateCalculationCostItem(int index, String itemId) {
    if (index < 0 || index >= calculationCosts.length) {
      return;
    }

    setState(() {
      calculationCosts[index].itemId = itemId;
    });
  }

  void updateCalculationCostQuantity(int index, int quantity) {
    if (index < 0 || index >= calculationCosts.length) {
      return;
    }

    if (quantity < 1) {
      return;
    }

    setState(() {
      calculationCosts[index].quantityPerUnit = quantity;
    });
  }

  void removeCalculationCost(int index) {
    if (index < 0 || index >= calculationCosts.length) {
      return;
    }

    setState(() {
      calculationCosts.removeAt(index);
    });
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    nameController.dispose();

    descriptionController.dispose();

    quantityController.dispose();

    notesController.dispose();

    armorBaseClassController.dispose();

    magicBonusController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar objeto' : 'Nuevo objeto'),
        actions: [
          IconButton(
            tooltip: 'Guardar',
            onPressed: saveItem,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // ===============================================================
              // IMAGEN
              // ===============================================================
              ItemImageSection(
                imagePath: imagePath,
                onImageChanged: (value) {
                  setState(() {
                    imagePath = value;
                  });
                },
              ),

              const SizedBox(height: 28),

              // ===============================================================
              // GENERAL
              // ===============================================================
              ItemGeneralSection(
                nameController: nameController,

                descriptionController: descriptionController,

                quantityController: quantityController,

                itemType: itemType,

                equipped: equipped,

                onTypeChanged: (value) {
                  setState(() {
                    itemType = value;

                    /*
                     * Consumibles no pueden
                     * estar equipados.
                     */
                    if (!itemType.isEquipable) {
                      equipped = false;
                    }
                  });
                },

                onEquippedChanged: (value) {
                  setState(() {
                    equipped = value;
                  });
                },
              ),

              const SizedBox(height: 28),

              ItemCalculationSection(
                calculable: calculable,

                availableItems:
                    widget.character?.items ?? const <CharacterItem>[],

                costs: calculationCosts,

                onCalculableChanged: (value) {
                  setState(() {
                    calculable = value;
                  });
                },

                onAddCost: addCalculationCost,

                onCostItemChanged: updateCalculationCostItem,

                onCostQuantityChanged: updateCalculationCostQuantity,

                onRemoveCost: removeCalculationCost,
              ),

              // ===============================================================
              // ARMADURA
              // ===============================================================
              if (itemType == ItemType.armor) ...[
                const SizedBox(height: 28),

                ItemArmorSection(
                  armorCategory: armorCategory,

                  armorBaseClassController: armorBaseClassController,

                  onCategoryChanged: (value) {
                    setState(() {
                      armorCategory = value;
                    });
                  },
                ),
              ],

              if (itemType == ItemType.weapon) ...[
                const SizedBox(height: 28),

                ItemWeaponSection(
                  attackAbility: weaponAttackAbility,

                  proficient: weaponProficient,

                  magicBonusController: magicBonusController,

                  damages: weaponDamages,

                  onAttackAbilityChanged: (value) {
                    setState(() {
                      weaponAttackAbility = value;
                    });
                  },

                  onProficientChanged: (value) {
                    setState(() {
                      weaponProficient = value;
                    });
                  },

                  onAddDamage: addWeaponDamage,

                  onEditDamage: editWeaponDamage,

                  onDeleteDamage: deleteWeaponDamage,
                ),
              ],

              if (itemType == ItemType.consumable) ...[
                const SizedBox(height: 28),

                ItemConsumableSection(
                  useText: consumableUseText,

                  onUseTextChanged: (value) {
                    consumableUseText = value;
                  },

                  effects: consumableEffects,

                  resources: widget.character?.resources ?? const [],

                  onAddEffect: addConsumableEffect,

                  onEffectChanged: updateConsumableEffect,

                  onRemoveEffect: removeConsumableEffect,

                  onMoveUp: moveConsumableEffectUp,

                  onMoveDown: moveConsumableEffectDown,
                ),
              ],

              const SizedBox(height: 28),

              // ===============================================================
              // PASIVAS
              // ===============================================================
              ItemPassivesSection(
                passives: passives,

                onAdd: addPassive,

                onEdit: editPassive,

                onDelete: deletePassive,
              ),

              const SizedBox(height: 28),

              // ===============================================================
              // HABILIDADES
              // ===============================================================
              ItemAbilitiesSection(
                abilities: abilities,

                onAdd: addAbility,

                onEdit: editAbility,

                onDelete: deleteAbility,
              ),

              const SizedBox(height: 28),

              // ===============================================================
              // NOTAS
              // ===============================================================
              ItemNotesSection(notesController: notesController),

              const SizedBox(height: 30),

              // ===============================================================
              // GUARDAR
              // ===============================================================
              FilledButton.icon(
                onPressed: saveItem,
                icon: const Icon(Icons.save_rounded),
                label: Text(editing ? 'Guardar cambios' : 'Crear objeto'),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
