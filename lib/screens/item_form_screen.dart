import 'package:flutter/material.dart';

import '../models/character_knowledge.dart';
import '../models/knowledge_definition.dart';
import '../models/ability.dart';
import '../models/character.dart';
import '../models/consumable.dart';
import '../models/critical_damage_bonus.dart';
import '../models/dice_pool.dart';
import '../models/equipment_slot.dart';
import '../models/item_definition.dart';
import '../models/passive.dart';
import '../models/skill.dart';
import '../models/weapon.dart';
import '../models/weapon_damage.dart';

import '../widgets/common/app_card.dart';
import '../widgets/common/section_header.dart';
import '../widgets/items/knowledge_insert_bar.dart';
import '../widgets/items/item_form/item_abilities_section.dart';
import '../widgets/items/item_form/item_armor_section.dart';
import '../widgets/items/item_form/item_calculation_section.dart';
import '../widgets/items/item_form/item_consumable_section.dart';
import '../widgets/items/item_form/item_general_section.dart';
import '../widgets/items/item_form/item_image_section.dart';
import '../widgets/items/item_form/item_notes_section.dart';
import '../widgets/items/item_form/item_passives_section.dart';
import '../widgets/items/item_form/item_weapon_section.dart';

import 'knowledge_form_screen.dart';
import 'ability_form_screen.dart';
import 'passive_form_screen.dart';

class ItemFormScreen extends StatefulWidget {
  final ItemDefinition? definition;
  final Character? character;
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
  late final TextEditingController knowledgeIdController;
  late final TextEditingController customArmorFormulaController;

  // ===========================================================================
  // ESTADO GENERAL
  // ===========================================================================

  late ItemType itemType;
  late String imagePath;
  late bool calculable;
  late List<ItemCalculationCost> calculationCosts;
  late List<String> equipmentSlotIds;
  late Set<String> recommendedClasses;

  static const List<String> _classOptions = [
    'Bárbaro', 'Bardo', 'Brujo', 'Clérigo', 'Druida', 'Explorador',
    'Guerrero', 'Hechicero', 'Mago', 'Monje', 'Paladín', 'Pícaro',
  ];

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
  late int weaponEmpoweredCriticalMultiplier;
  late final TextEditingController weaponEmpoweredCriticalFormulaController;
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

  bool get editing => widget.definition != null;

  List<EquipmentSlotDefinition> get availableSlotDefinitions {
    final allSlots =
        (widget.character != null &&
            widget.character!.equipmentSlots.isNotEmpty)
        ? widget.character!.equipmentSlots
        : defaultEquipmentSlots;

    final allowedCategories = itemType.compatibleSlotCategories;
    if (allowedCategories.isEmpty) return const [];

    return allSlots
        .where((slot) => allowedCategories.contains(slot.category))
        .toList();
  }

  List<ItemDefinition> get availableCalculationItems {
    final resultById = <String, ItemDefinition>{};
    final currentDefinitionId = widget.definition?.id.trim();

    void register(ItemDefinition def) {
      final id = def.id.trim();
      if (id.isEmpty) return;
      if (currentDefinitionId != null &&
          currentDefinitionId.isNotEmpty &&
          id == currentDefinitionId) {
        return;
      }
      resultById.putIfAbsent(id, () => def);
    }

    for (final definition in widget.availableDefinitions) {
      register(ItemDefinition.fromMap(definition.toMap()));
    }

    final character = widget.character;
    if (character != null) {
      for (final inventory in character.inventoryItems) {
        final def = character.definitionForInventoryItem(inventory);
        if (def != null) {
          register(def);
        }
      }
      for (final def in character.itemDefinitions) {
        register(def);
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
    knowledgeIdController = TextEditingController(
      text: item?.relatedKnowledgeId ?? '',
    );
    customArmorFormulaController = TextEditingController(
      text: item?.armor?.customFormula ?? '',
    );

    itemType = item?.type ?? ItemType.misc;
    imagePath = item?.imagePath ?? '';
    recommendedClasses = Set<String>.from(item?.recommendedClasses ?? const []);

    equipmentSlotIds = item?.equipmentSlotIds.isNotEmpty == true
        ? List<String>.from(item!.equipmentSlotIds)
        : (itemType.isEquipable
              ? List<String>.from(itemType.defaultEquipmentSlotIds)
              : <String>[]);

    calculable = item?.calculable ?? false;
    calculationCosts =
        item?.calculationCosts
            .map((cost) => ItemCalculationCost.fromMap(cost.toMap()))
            .toList() ??
        <ItemCalculationCost>[];

    armorCategory = item?.armor?.category ?? ArmorCategory.light;

    final weapon = item?.weapon;
    magicBonusController = TextEditingController(
      text: '${weapon?.magicBonus ?? 0}',
    );
    weaponAttackAbility = weapon?.attackAbility ?? AbilityType.strength;
    weaponCriticalMinimumNaturalRoll = weapon?.criticalMinimumNaturalRoll ?? 20;
    weaponEmpoweredCritical = weapon?.empoweredCritical ?? false;
    weaponEmpoweredCriticalMultiplier = weapon?.empoweredCriticalMultiplier ?? 2;
    weaponEmpoweredCriticalFormulaController = TextEditingController(
      text: weapon?.empoweredCriticalFormula ??
          '(MAX + MOD) * ${weapon?.empoweredCriticalMultiplier ?? 2}',
    );
    weaponProficient = weapon?.proficient ?? true;
    weaponDamages =
        weapon?.damages
            .map((damage) => WeaponDamage.fromMap(damage.toMap()))
            .toList() ??
        <WeaponDamage>[];

    final consumable = item?.consumable;
    consumableUseText = consumable?.useText.trim().isNotEmpty == true
        ? consumable!.useText
        : 'Usar';
    consumableEffects =
        consumable?.effects.map(_cloneConsumableEffect).toList() ??
        <AbilityEffect>[];

    passives =
        item?.passives
            .map((passive) => CharacterPassive.fromMap(passive.toMap()))
            .toList() ??
        <CharacterPassive>[];

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
    if (index < 0 || index >= consumableEffects.length) return;
    setState(() {
      consumableEffects[index] = effect;
    });
  }

  void removeConsumableEffect(int index) {
    if (index < 0 || index >= consumableEffects.length) return;
    setState(() {
      consumableEffects.removeAt(index);
    });
  }

  void moveConsumableEffectUp(int index) {
    if (index <= 0 || index >= consumableEffects.length) return;
    setState(() {
      final effect = consumableEffects.removeAt(index);
      consumableEffects.insert(index - 1, effect);
    });
  }

  void moveConsumableEffectDown(int index) {
    if (index < 0 || index >= consumableEffects.length - 1) return;
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
    if (passive == null || !mounted) return;

    passive.sourceType = PassiveSourceType.item;
    setState(() {
      passives.add(passive);
    });
  }

  Future<void> editPassive(int index) async {
    if (index < 0 || index >= passives.length) return;
    final current = passives[index];

    final result = await Navigator.push<CharacterPassive>(
      context,
      MaterialPageRoute(builder: (_) => PassiveFormScreen(passive: current)),
    );
    if (result == null || !mounted) return;

    result.sourceType = PassiveSourceType.item;
    setState(() {
      passives[index] = result;
    });
  }

  Future<void> deletePassive(int index) async {
    if (index < 0 || index >= passives.length) return;
    final passive = passives[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar pasiva'),
          content: Text('¿Quieres eliminar "${passive.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
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
    if (ability == null || !mounted) return;

    setState(() {
      abilities.add(ability);
    });
  }

  Future<void> editAbility(int index) async {
    if (index < 0 || index >= abilities.length) return;
    final current = abilities[index];

    final result = await Navigator.push<CharacterAbility>(
      context,
      MaterialPageRoute(builder: (_) => AbilityFormScreen(ability: current)),
    );
    if (result == null || !mounted) return;

    setState(() {
      abilities[index] = result;
    });
  }

  Future<void> deleteAbility(int index) async {
    if (index < 0 || index >= abilities.length) return;
    final ability = abilities[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar habilidad'),
          content: Text('¿Quieres eliminar "${ability.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    setState(() {
      abilities.removeAt(index);
    });
  }

  // ===========================================================================
  // GUARDAR
  // ===========================================================================

  void saveItem() {
    if (!_formKey.currentState!.validate()) return;

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
        empoweredCriticalMultiplier: weaponEmpoweredCriticalMultiplier,
        empoweredCriticalFormula: weaponEmpoweredCriticalFormulaController.text.trim().isEmpty
            ? '(MAX + MOD) * 2'
            : weaponEmpoweredCriticalFormulaController.text.trim(),
        damageDice: primaryDamage?.diceNotation ?? '1d6',
        damageType: primaryDamage?.damageType ?? 'Cortante',
        damages: weaponDamages
            .map((d) => WeaponDamage.fromMap(d.toMap()))
            .toList(),
        criticalDamageBonuses:
            existingWeapon?.criticalDamageBonuses
                .map((b) => CriticalDamageBonus.fromMap(b.toMap()))
                .toList() ??
            <CriticalDamageBonus>[],
      );
    }

    Consumable? consumable;
    if (itemType == ItemType.consumable || itemType == ItemType.potion) {
      consumable = Consumable(
        useText: consumableUseText.trim().isEmpty
            ? 'Usar'
            : consumableUseText.trim(),
        effects: consumableEffects.map(_cloneConsumableEffect).toList(),
      );
    }

    final rawKnowledgeId = knowledgeIdController.text.trim();
    final armorBaseClass = int.tryParse(armorBaseClassController.text) ?? 10;

    final definition = ItemDefinition(
      id:
          widget.definition?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      type: itemType,
      imagePath: imagePath,
      recommendedClasses: recommendedClasses.toList()..sort(),
      notes: notesController.text.trim(),
      stackable: widget.definition?.stackable ?? itemType.stackableByDefault,
      calculable: calculable,
      calculationCosts: calculationCosts
          .map((cost) => ItemCalculationCost.fromMap(cost.toMap()))
          .toList(),
      equipmentSlotIds: itemType.isEquipable
          ? List<String>.from(equipmentSlotIds)
          : const [],
      relatedKnowledgeId: rawKnowledgeId.isNotEmpty ? rawKnowledgeId : null,
      armor: itemType == ItemType.armor
          ? ItemArmorDefinition(
              category: armorCategory,
              baseArmorClass: armorBaseClass,
              customFormula: armorCategory == ArmorCategory.custom
                  ? customArmorFormulaController.text.trim()
                  : null,
            )
          : null,
      weapon: weapon,
      consumable: consumable,
      passives: passives
          .map((p) => CharacterPassive.fromMap(p.toMap()))
          .toList(),
      abilities: abilities
          .map((a) => CharacterAbility.fromMap(a.toMap()))
          .toList(),
    );

    Navigator.pop<ItemDefinition>(context, definition);
  }

  // ===========================================================================
  // DAÑOS DEL ARMA
  // ===========================================================================

  Future<void> addWeaponDamage() async {
    final result = await openWeaponDamageForm();
    if (result == null || !mounted) return;
    setState(() => weaponDamages.add(result));
  }

  Future<void> editWeaponDamage(int index) async {
    if (index < 0 || index >= weaponDamages.length) return;
    final result = await openWeaponDamageForm(damage: weaponDamages[index]);
    if (result == null || !mounted) return;
    setState(() => weaponDamages[index] = result);
  }

  Future<void> deleteWeaponDamage(int index) async {
    if (index < 0 || index >= weaponDamages.length) return;
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
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    setState(() => weaponDamages.removeAt(index));
  }

  Future<void> editWeaponCriticalDamage(int index) async {
    if (index < 0 || index >= weaponDamages.length) return;
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
            onChanged: (value) => diceText = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final text = diceText.trim();
                if (text.isEmpty) {
                  Navigator.pop(dialogContext, <DicePool>[]);
                  return;
                }
                final pools = _parseWeaponDice(text);
                if (pools == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Usa un formato válido, por ejemplo 2d6 o 1d6 + 1d4.',
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

    if (result == null || !mounted) return;
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
                        setDialogState(() => addAbilityModifier = value);
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
                          if (value == null) return;
                          setDialogState(() => abilityType = value);
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final pools = _parseWeaponDice(diceController.text);
                    if (pools == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
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
                        name: damageNameController.text.trim(),
                        dicePools: pools,
                        addAbilityModifier: addAbilityModifier,
                        abilityType: abilityType,
                        bonus: int.tryParse(bonusController.text) ?? 0,
                        damageType: damageTypeController.text.trim(),
                        criticalDicePools:
                            damage?.criticalDicePools
                                .map(
                                  (p) =>
                                      DicePool(count: p.count, sides: p.sides),
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
    customArmorFormulaController.dispose();
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
      if (!calculationCosts.any((cost) => cost.itemId == item.id)) {
        candidate = item;
        break;
      }
    }
    if (candidate == null) return;

    setState(() {
      calculationCosts.add(
        ItemCalculationCost(itemId: candidate!.id, quantityPerUnit: 1),
      );
    });
  }

  void updateCalculationCostItem(int index, String itemId) {
    if (index < 0 || index >= calculationCosts.length) return;
    setState(() => calculationCosts[index].itemId = itemId);
  }

  void updateCalculationCostQuantity(int index, int quantity) {
    if (index < 0 || index >= calculationCosts.length || quantity < 1) return;
    setState(() => calculationCosts[index].quantityPerUnit = quantity);
  }

  void removeCalculationCost(int index) {
    if (index < 0 || index >= calculationCosts.length) return;
    setState(() => calculationCosts.removeAt(index));
  }

  bool get isBookOrScroll {
    final nameLower = nameController.text.trim().toLowerCase();
    final isTextNamed =
        nameLower.contains('libro') ||
        nameLower.contains('tomo') ||
        nameLower.contains('grimorio') ||
        nameLower.contains('pergamino') ||
        nameLower.contains('manual');

    return itemType == ItemType.misc ||
        isTextNamed ||
        itemType == ItemType.book ||
        itemType == ItemType.scroll;
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    notesController.dispose();
    armorBaseClassController.dispose();
    magicBonusController.dispose();
    knowledgeIdController.dispose();
    customArmorFormulaController.dispose();
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
              ItemImageSection(
                imagePath: imagePath,
                onImageChanged: (value) => setState(() => imagePath = value),
              ),
              const SizedBox(height: 28),

              ItemGeneralSection(
                nameController: nameController,
                descriptionController: descriptionController,
                itemType: itemType,
                onTypeChanged: (value) {
                  setState(() {
                    itemType = value;

                    final allowedCategories = itemType.compatibleSlotCategories;
                    final validSlotIds = availableSlotDefinitions
                        .where((s) => allowedCategories.contains(s.category))
                        .map((s) => s.id)
                        .toSet();

                    equipmentSlotIds.removeWhere(
                      (id) => !validSlotIds.contains(id),
                    );

                    if (equipmentSlotIds.isEmpty && itemType.isEquipable) {
                      equipmentSlotIds = itemType.defaultEquipmentSlotIds
                          .where(validSlotIds.contains)
                          .toList();
                    }
                  });
                },
              ),

              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      icon: Icons.groups_2_rounded,
                      title: 'Clases recomendadas',
                      subtitle: 'El objeto puede recomendarse para una o varias clases',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _classOptions.map((className) => FilterChip(
                        label: Text(className),
                        selected: recommendedClasses.contains(className),
                        onSelected: (selected) => setState(() {
                          if (selected) { recommendedClasses.add(className); }
                          else { recommendedClasses.remove(className); }
                        }),
                      )).toList(),
                    ),
                  ],
                ),
              ),

              // ===============================================================
              // KNOWLEDGE INSERT BAR (Conocimiento vinculado para libros/pergaminos)
              // ===============================================================
              if (isBookOrScroll) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        icon: Icons.auto_stories_rounded,
                        title: 'Conocimiento vinculado',
                        subtitle:
                            'Asocia este tomo o pergamino a un saber de estudio',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: knowledgeIdController,
                        decoration: InputDecoration(
                          labelText: 'ID del Conocimiento',
                          hintText: 'ej. historia_arcana_vol_1',
                          prefixIcon: const Icon(Icons.menu_book_rounded),
                          helperText:
                              'Habilita la acción de leer y estudiar en el inventario.',
                          suffixIcon: knowledgeIdController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    setState(() {
                                      knowledgeIdController.clear();
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),

                      // Barra de inserción rápida basada en el patrón de fórmulas
                      KnowledgeInsertBar(
                        character: widget.character,
                        onInsert: (value) {
                          setState(() {
                            knowledgeIdController.text = value;
                            knowledgeIdController.selection =
                                TextSelection.collapsed(
                                  offset: knowledgeIdController.text.length,
                                );
                          });
                        },
                        onCreateKnowledge: () async {
                          if (widget.character == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Se necesita un personaje para crear un saber.',
                                ),
                              ),
                            );
                            return;
                          }

                          // Navegamos al formulario para crear el conocimiento
                          final result =
                              await Navigator.push<Map<String, dynamic>>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const KnowledgeFormScreen(),
                                ),
                              );

                          if (result == null || !mounted) return;

                          final def =
                              result['definition'] as KnowledgeDefinition;
                          final notes = result['notes'] as String;
                          final spellIds =
                              result['unlockedSpellIds'] as List<String>? ?? [];

                          setState(() {
                            final entry = CharacterKnowledge(
                              knowledgeId: def.id,
                              status: KnowledgeStatus.discovered,
                              currentProgress: 0,
                              notes: notes,
                              unlockedSpellIds: spellIds,
                            );
                            widget.character!.knowledges.add(entry);

                            // Autoseleccionamos el ID del saber recién creado en el campo del objeto
                            knowledgeIdController.text = def.id;
                            knowledgeIdController.selection =
                                TextSelection.collapsed(
                                  offset: knowledgeIdController.text.length,
                                );
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // ===============================================================
              // RANURAS DE EQUIPAMIENTO
              // ===============================================================
              if (itemType.isEquipable) ...[
                const SizedBox(height: 28),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        icon: Icons.checkroom_rounded,
                        title: 'Ranuras compatibles',
                        subtitle:
                            'Elige en qué ranuras se puede equipar este objeto',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableSlotDefinitions.map((slot) {
                          final isSelected = equipmentSlotIds.contains(slot.id);
                          return FilterChip(
                            label: Text(slot.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  equipmentSlotIds.add(slot.id);
                                } else {
                                  equipmentSlotIds.remove(slot.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              ItemCalculationSection(
                calculable: calculable,
                availableItems: availableCalculationItems,
                costs: calculationCosts,
                onCalculableChanged: (val) => setState(() => calculable = val),
                onAddCost: addCalculationCost,
                onCostItemChanged: updateCalculationCostItem,
                onCostQuantityChanged: updateCalculationCostQuantity,
                onRemoveCost: removeCalculationCost,
              ),

              if (itemType == ItemType.armor) ...[
                const SizedBox(height: 28),
                ItemArmorSection(
                  armorCategory: armorCategory,
                  armorBaseClassController: armorBaseClassController,
                  customFormulaController: customArmorFormulaController,
                  character: widget.character,
                  onCategoryChanged: (val) =>
                      setState(() => armorCategory = val),
                ),
              ],

              if (itemType == ItemType.weapon) ...[
                const SizedBox(height: 28),
                ItemWeaponSection(
                  attackAbility: weaponAttackAbility,
                  proficient: weaponProficient,
                  magicBonusController: magicBonusController,
                  criticalMinimumNaturalRoll: weaponCriticalMinimumNaturalRoll,
                  empoweredCritical: weaponEmpoweredCritical,
                  empoweredCriticalMultiplier: weaponEmpoweredCriticalMultiplier,
                  empoweredCriticalFormulaController:
                      weaponEmpoweredCriticalFormulaController,
                  damages: weaponDamages,
                  onAttackAbilityChanged: (val) =>
                      setState(() => weaponAttackAbility = val),
                  onProficientChanged: (val) =>
                      setState(() => weaponProficient = val),
                  onCriticalMinimumNaturalRollChanged: (val) =>
                      setState(() => weaponCriticalMinimumNaturalRoll = val),
                  onEmpoweredCriticalChanged: (val) =>
                      setState(() => weaponEmpoweredCritical = val),
                  onEmpoweredCriticalMultiplierChanged: (val) =>
                      setState(() => weaponEmpoweredCriticalMultiplier = val),
                  onAddDamage: addWeaponDamage,
                  onEditDamage: editWeaponDamage,
                  onDeleteDamage: deleteWeaponDamage,
                  onEditCriticalDamage: editWeaponCriticalDamage,
                  onDamageChanged: (_) => setState(() {}),
                ),
              ],

              if (itemType == ItemType.consumable ||
                  itemType == ItemType.potion) ...[
                const SizedBox(height: 28),
                ItemConsumableSection(
                  useText: consumableUseText,
                  onUseTextChanged: (val) => consumableUseText = val,
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
              ItemPassivesSection(
                passives: passives,
                onAdd: addPassive,
                onEdit: editPassive,
                onDelete: deletePassive,
              ),

              const SizedBox(height: 28),
              ItemAbilitiesSection(
                abilities: abilities,
                onAdd: addAbility,
                onEdit: editAbility,
                onDelete: deleteAbility,
              ),

              const SizedBox(height: 28),
              ItemNotesSection(notesController: notesController),

              const SizedBox(height: 30),
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
