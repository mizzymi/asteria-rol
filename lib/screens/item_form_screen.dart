import 'package:flutter/material.dart';

import '../models/ability.dart';
import '../models/item.dart';
import '../models/passive.dart';

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

  const ItemFormScreen({super.key, this.item});

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

    armorCategory = item?.armorCategory ?? ArmorCategory.light;

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

    final quantity = int.tryParse(quantityController.text) ?? 1;

    final armorBaseClass = int.tryParse(armorBaseClassController.text) ?? 10;

    final item = CharacterItem(
      id: widget.item?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),

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
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    nameController.dispose();

    descriptionController.dispose();

    quantityController.dispose();

    notesController.dispose();

    armorBaseClassController.dispose();

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
