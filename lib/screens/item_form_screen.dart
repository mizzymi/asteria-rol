import 'package:flutter/material.dart';

import '../models/ability.dart';
import '../models/character.dart';
import '../models/consumable.dart';
import '../models/critical_damage_bonus.dart';
import '../models/dice_pool.dart';
import '../models/item_definition.dart';
import '../models/passive.dart';
import '../models/skill.dart';
import '../models/weapon.dart';
import '../models/weapon_damage.dart';

import '../widgets/items/item_form/item_abilities_section.dart';
import '../widgets/items/item_form/item_armor_section.dart';
import '../widgets/items/item_form/item_calculation_section.dart';
import '../widgets/items/item_form/item_consumable_section.dart';
import '../widgets/items/item_form/item_general_section.dart';
import '../widgets/items/item_form/item_image_section.dart';
import '../widgets/items/item_form/item_notes_section.dart';
import '../widgets/items/item_form/item_passives_section.dart';
import '../widgets/items/item_form/item_weapon_section.dart';

import 'ability_form_screen.dart';
import 'passive_form_screen.dart';

class ItemFormScreen extends StatefulWidget {
  final ItemDefinition? definition;

  /// Personaje usado únicamente como contexto.
  ///
  /// Permite:
  /// - mostrar recursos al editar efectos de consumibles;
  /// - utilizar objetos del inventario como candidatos de calculadora.
  ///
  /// La definición NO guarda estado del inventario.
  final Character? character;

  /// Definiciones externas disponibles para la calculadora.
  ///
  /// Esto permite reutilizar el formulario desde biblioteca,
  /// Master, tiendas, etc. sin depender de CharacterItem.
  final List<ItemDefinition> availableDefinitions;

  const ItemFormScreen({
    super.key,
    this.definition,
    this.character,
    this.availableDefinitions = const [],
  });

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

  late final TextEditingController notesController;

  late final TextEditingController armorBaseClassController;

  late final TextEditingController magicBonusController;

  // ===========================================================================
  // ESTADO GENERAL
  // ===========================================================================

  late ItemType itemType;

  late String imagePath;

  late bool calculable;

  late List<ItemCalculationCost> calculationCosts;

  // ===========================================================================
  // ARMADURA
  // ===========================================================================

  late ArmorCategory armorCategory;

  // ===========================================================================
  // ARMA
  // ===========================================================================

  late AbilityType weaponAttackAbility;

  late int weaponCriticalMinimumNaturalRoll;

  late bool weaponEmpoweredCritical;

  late bool weaponProficient;

  late List<WeaponDamage> weaponDamages;

  // ===========================================================================
  // CONSUMIBLE
  // ===========================================================================

  late String consumableUseText;

  late List<AbilityEffect> consumableEffects;

  // ===========================================================================
  // PASIVAS / HABILIDADES
  // ===========================================================================

  late List<CharacterPassive> passives;

  late List<CharacterAbility> abilities;

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  bool get editing {
    return widget.definition != null;
  }

  /// Definiciones utilizables por la calculadora.
  ///
  /// Combina:
  /// - definiciones proporcionadas externamente;
  /// - objetos legacy que todavía viven en Character.items.
  ///
  /// Siempre deduplicamos mediante ItemDefinition.id.
  List<ItemDefinition> get availableCalculationItems {
    final resultById = <String, ItemDefinition>{};

    final currentDefinitionId = widget.definition?.id.trim();

    // =========================================================================
    // DEFINICIONES EXTERNAS
    // =========================================================================

    for (final definition in widget.availableDefinitions) {
      final id = definition.id.trim();

      if (id.isEmpty) {
        continue;
      }

      if (currentDefinitionId != null &&
          currentDefinitionId.isNotEmpty &&
          id == currentDefinitionId) {
        continue;
      }

      resultById.putIfAbsent(
        id,
        () => ItemDefinition.fromMap(definition.toMap()),
      );
    }

    // =========================================================================
    // INVENTARIO LEGACY DEL PERSONAJE
    // =========================================================================

    final characterItems = widget.character?.items;

    if (characterItems != null) {
      for (final item in characterItems) {
        final definition = item.toDefinition();

        final id = definition.id.trim();

        if (id.isEmpty) {
          continue;
        }

        if (currentDefinitionId != null &&
            currentDefinitionId.isNotEmpty &&
            id == currentDefinitionId) {
          continue;
        }

        resultById.putIfAbsent(id, () => definition);
      }
    }

    return List<ItemDefinition>.unmodifiable(resultById.values);
  }

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    final item = widget.definition;

    nameController = TextEditingController(text: item?.name ?? '');

    descriptionController = TextEditingController(
      text: item?.description ?? '',
    );

    notesController = TextEditingController(text: item?.notes ?? '');

    armorBaseClassController = TextEditingController(
      text: '${item?.armor?.baseArmorClass ?? 11}',
    );

    itemType = item?.type ?? ItemType.other;

    imagePath = item?.imagePath ?? '';

    // =========================================================================
    // CALCULADORA
    // =========================================================================

    calculable = item?.calculable ?? false;

    calculationCosts =
        item?.calculationCosts
            .map((cost) => ItemCalculationCost.fromMap(cost.toMap()))
            .toList() ??
        <ItemCalculationCost>[];

    // =========================================================================
    // ARMADURA
    // =========================================================================

    armorCategory = item?.armor?.category ?? ArmorCategory.light;

    // =========================================================================
    // ARMA
    // =========================================================================

    final weapon = item?.weapon;

    magicBonusController = TextEditingController(
      text: '${weapon?.magicBonus ?? 0}',
    );

    weaponAttackAbility = weapon?.attackAbility ?? AbilityType.strength;

    weaponCriticalMinimumNaturalRoll = weapon?.criticalMinimumNaturalRoll ?? 20;

    weaponEmpoweredCritical = weapon?.empoweredCritical ?? false;

    weaponProficient = weapon?.proficient ?? true;

    weaponDamages =
        weapon?.damages
            .map((damage) => WeaponDamage.fromMap(damage.toMap()))
            .toList() ??
        <WeaponDamage>[];

    // =========================================================================
    // CONSUMIBLE
    // =========================================================================

    final consumable = item?.consumable;

    consumableUseText = consumable?.useText.trim().isNotEmpty == true
        ? consumable!.useText
        : 'Usar';

    consumableEffects =
        consumable?.effects.map(_cloneConsumableEffect).toList() ??
        <AbilityEffect>[];

    // =========================================================================
    // PASIVAS
    // =========================================================================

    passives =
        item?.passives
            .map((passive) => CharacterPassive.fromMap(passive.toMap()))
            .toList() ??
        <CharacterPassive>[];

    // =========================================================================
    // HABILIDADES
    // =========================================================================

    abilities =
        item?.abilities
            .map((ability) => CharacterAbility.fromMap(ability.toMap()))
            .toList() ??
        <CharacterAbility>[];
  }

  // ===========================================================================
  // EFECTOS DEL CONSUMIBLE
  // ===========================================================================

  void addConsumableEffect() {
    setState(() {
      consumableEffects.add(
        AbilityEffect(
          id:
              '${DateTime.now().microsecondsSinceEpoch}'
              '_consumable_effect',
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

  AbilityEffect _cloneConsumableEffect(AbilityEffect effect) {
    return AbilityEffect.fromMap(effect.toMap());
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

    passive.sourceType = PassiveSourceType.item;

    setState(() {
      passives.add(passive);
    });
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
  // RESOLUCIÓN DE PROPIEDADES DE DEFINICIÓN
  // ===========================================================================

  bool _resolvedStackable() {
    final original = widget.definition;

    if (original != null && original.type == itemType) {
      return original.stackable;
    }

    return itemType.stackableByDefault;
  }

  List<String> _resolvedEquipmentSlotIds() {
    if (!itemType.isEquipable) {
      return const [];
    }

    final original = widget.definition;

    if (original != null &&
        original.type == itemType &&
        original.equipmentSlotIds.isNotEmpty) {
      return List<String>.from(original.equipmentSlotIds);
    }

    return List<String>.from(itemType.defaultEquipmentSlotIds);
  }

  // ===========================================================================
  // GUARDAR
  // ===========================================================================

  void saveItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // =========================================================================
    // VALIDAR ARMA
    // =========================================================================

    if (itemType == ItemType.weapon && weaponDamages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade al menos un componente de daño al arma.'),
        ),
      );

      return;
    }

    // =========================================================================
    // ARMA
    // =========================================================================

    Weapon? weapon;

    if (itemType == ItemType.weapon) {
      final primaryDamage = weaponDamages.isNotEmpty
          ? weaponDamages.first
          : null;

      final existingWeapon = widget.definition?.weapon;

      weapon = Weapon(
        id:
            existingWeapon?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: nameController.text.trim(),
        attackAbility: weaponAttackAbility,
        proficient: weaponProficient,
        magicBonus: int.tryParse(magicBonusController.text) ?? 0,
        criticalMinimumNaturalRoll: weaponCriticalMinimumNaturalRoll,
        empoweredCritical: weaponEmpoweredCritical,

        // Legacy
        damageDice: primaryDamage?.diceNotation ?? '1d6',
        damageType: primaryDamage?.damageType ?? 'Cortante',

        // Sistema actual
        damages: weaponDamages
            .map((damage) => WeaponDamage.fromMap(damage.toMap()))
            .toList(),

        // Conservamos bonuses intrínsecos
        // que todavía no tienen editor aquí.
        criticalDamageBonuses:
            existingWeapon?.criticalDamageBonuses
                .map((bonus) => CriticalDamageBonus.fromMap(bonus.toMap()))
                .toList() ??
            <CriticalDamageBonus>[],
      );
    }

    // =========================================================================
    // CONSUMIBLE
    // =========================================================================

    Consumable? consumable;

    if (itemType == ItemType.consumable) {
      consumable = Consumable(
        useText: consumableUseText.trim().isEmpty
            ? 'Usar'
            : consumableUseText.trim(),
        effects: consumableEffects.map(_cloneConsumableEffect).toList(),
      );
    }

    // =========================================================================
    // ARMADURA
    // =========================================================================

    final armorBaseClass = int.tryParse(armorBaseClassController.text) ?? 10;

    // =========================================================================
    // DEFINICIÓN
    // =========================================================================

    final definition = ItemDefinition(
      id:
          widget.definition?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),

      name: nameController.text.trim(),

      description: descriptionController.text.trim(),

      type: itemType,

      imagePath: imagePath,

      notes: notesController.text.trim(),

      stackable: _resolvedStackable(),

      calculable: calculable,

      calculationCosts: calculationCosts
          .map((cost) => ItemCalculationCost.fromMap(cost.toMap()))
          .toList(),

      equipmentSlotIds: _resolvedEquipmentSlotIds(),

      armor: itemType == ItemType.armor
          ? ItemArmorDefinition(
              category: armorCategory,
              baseArmorClass: armorBaseClass,
            )
          : null,

      weapon: weapon,

      consumable: consumable,

      passives: passives
          .map((passive) => CharacterPassive.fromMap(passive.toMap()))
          .toList(),

      abilities: abilities
          .map((ability) => CharacterAbility.fromMap(ability.toMap()))
          .toList(),
    );

    Navigator.pop<ItemDefinition>(context, definition);
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

  Future<void> editWeaponCriticalDamage(int index) async {
    if (index < 0 || index >= weaponDamages.length) {
      return;
    }

    final damage = weaponDamages[index];

    var diceText = damage.criticalDiceNotation;

    final result = await showDialog<List<DicePool>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Dados extra de crítico'),
          content: TextFormField(
            initialValue: diceText,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Dados',
              hintText: 'Ej. 2d6',
              prefixIcon: Icon(Icons.flash_on_rounded),
              helperText: 'Solo se tiran en un crítico y no se multiplican.',
            ),
            onChanged: (value) {
              diceText = value;
            },
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
                final text = diceText.trim();

                // Vacío = eliminar dados extra.
                if (text.isEmpty) {
                  Navigator.pop(dialogContext, <DicePool>[]);

                  return;
                }

                final pools = _parseWeaponDice(text);

                if (pools == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Usa un formato válido, por ejemplo '
                        '2d6 o 1d6 + 1d4.',
                      ),
                    ),
                  );

                  return;
                }

                Navigator.pop(dialogContext, pools);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      damage.criticalDicePools = result
          .map((pool) => DicePool(count: pool.count, sides: pool.sides))
          .toList();
    });
  }

  Future<WeaponDamage?> openWeaponDamageForm({WeaponDamage? damage}) async {
    final diceController = TextEditingController(
      text: damage?.diceNotation ?? '1d8',
    );

    final damageNameController = TextEditingController(
      text: damage?.name ?? '',
    );

    final damageTypeController = TextEditingController(
      text: damage?.damageType ?? 'Cortante',
    );

    final bonusController = TextEditingController(
      text: '${damage?.bonus ?? 0}',
    );

    var addAbilityModifier = damage?.addAbilityModifier ?? true;

    var abilityType = damage?.abilityType ?? weaponAttackAbility;

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
                      controller: damageNameController,
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
                          return DropdownMenuItem<AbilityType>(
                            value: ability,
                            child: Text(ability.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setDialogState(() {
                            abilityType = value;
                          });
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
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Usa un formato de dados válido, '
                            'por ejemplo 1d8 o 2d6.',
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
                        name: damageNameController.text.trim(),
                        dicePools: pools,
                        addAbilityModifier: addAbilityModifier,
                        abilityType: abilityType,
                        bonus: int.tryParse(bonusController.text) ?? 0,
                        damageType: damageTypeController.text.trim(),

                        // Conservamos la configuración
                        // de crítico existente.
                        criticalDicePools:
                            damage?.criticalDicePools
                                .map(
                                  (pool) => DicePool(
                                    count: pool.count,
                                    sides: pool.sides,
                                  ),
                                )
                                .toList() ??
                            <DicePool>[],

                        participatesInCritical:
                            damage?.participatesInCritical ?? true,
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
    damageNameController.dispose();
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

  // ===========================================================================
  // CALCULADORA
  // ===========================================================================

  void addCalculationCost() {
    ItemDefinition? candidate;

    for (final item in availableCalculationItems) {
      final alreadyUsed = calculationCosts.any(
        (cost) => cost.itemId == item.id,
      );

      if (alreadyUsed) {
        continue;
      }

      candidate = item;
      break;
    }

    if (candidate == null) {
      return;
    }

    setState(() {
      calculationCosts.add(
        ItemCalculationCost(itemId: candidate!.id, quantityPerUnit: 1),
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

                itemType: itemType,

                onTypeChanged: (value) {
                  setState(() {
                    itemType = value;
                  });
                },
              ),

              const SizedBox(height: 28),

              // ===============================================================
              // CALCULADORA
              // ===============================================================
              ItemCalculationSection(
                calculable: calculable,

                availableItems: availableCalculationItems,

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

              // ===============================================================
              // ARMA
              // ===============================================================
              if (itemType == ItemType.weapon) ...[
                const SizedBox(height: 28),

                ItemWeaponSection(
                  attackAbility: weaponAttackAbility,

                  proficient: weaponProficient,

                  magicBonusController: magicBonusController,

                  criticalMinimumNaturalRoll: weaponCriticalMinimumNaturalRoll,

                  empoweredCritical: weaponEmpoweredCritical,

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

                  onCriticalMinimumNaturalRollChanged: (value) {
                    setState(() {
                      weaponCriticalMinimumNaturalRoll = value;
                    });
                  },

                  onEmpoweredCriticalChanged: (value) {
                    setState(() {
                      weaponEmpoweredCritical = value;
                    });
                  },

                  onAddDamage: addWeaponDamage,

                  onEditDamage: editWeaponDamage,

                  onDeleteDamage: deleteWeaponDamage,

                  onEditCriticalDamage: editWeaponCriticalDamage,

                  onDamageChanged: (_) {
                    setState(() {});
                  },
                ),
              ],

              // ===============================================================
              // CONSUMIBLE
              // ===============================================================
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
