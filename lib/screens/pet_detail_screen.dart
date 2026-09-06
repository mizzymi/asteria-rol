import 'package:flutter/material.dart';

import '../models/dice_pool.dart';
import '../models/skill.dart';
import '../models/character.dart';
import '../models/pet.dart';
import '../models/ability.dart';
import '../models/passive.dart';
import '../models/weapon.dart';
import '../models/weapon_damage.dart';
import '../services/character_storage_service.dart';
import '../services/action_resolution_flow.dart';
import '../services/ability_library_service.dart';
import '../services/passive_library_service.dart';
import '../widgets/action_resolution/result/action_resolution_result_dialog.dart';
import 'ability_form_screen.dart';
import 'passive_form_screen.dart';
import 'pet_form_screen.dart';

class PetDetailScreen extends StatefulWidget {
  final Character character;
  final Pet pet;

  const PetDetailScreen({
    super.key,
    required this.character,
    required this.pet,
  });

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  Character get character => widget.character;
  Pet get pet => widget.pet;

  Future<void> _save() async {
    await CharacterStorageService.saveCharacter(character);
    if (mounted) setState(() {});
  }

  Future<void> _editPet() async {
    final result = await Navigator.push<Pet>(
      context,
      MaterialPageRoute(builder: (_) => PetFormScreen(pet: pet)),
    );

    if (result == null || !mounted) return;

    setState(() {
      pet.name = result.name;
      pet.species = result.species;
      pet.maxHealth = result.maxHealth;
      pet.currentHealth = pet.currentHealth.clamp(0, result.maxHealth);
      pet.armorClass = result.armorClass;
      pet.speed = result.speed;
      pet.proficiencyBonus = result.proficiencyBonus;
      pet.abilities = result.abilities;
      pet.notes = result.notes;
    });

    await _save();
  }

  Future<void> _addAbility() async {
    final ability = await Navigator.push<CharacterAbility>(
      context,
      MaterialPageRoute(
        builder: (_) => AbilityFormScreen(character: character),
      ),
    );
    if (ability == null) return;

    setState(() {
      pet.characterAbilities.add(ability);
    });
    await _save();
  }

  Future<void> _addPassive() async {
    final passive = await Navigator.push<CharacterPassive>(
      context,
      MaterialPageRoute(
        builder: (_) => PassiveFormScreen(character: character),
      ),
    );
    if (passive == null) return;

    setState(() {
      pet.passives.add(passive);
    });
    await _save();
  }

  // ===========================================================================
  // CREAR / EDITAR ATAQUE BÁSICO (Soporta todos los atributos y dados de daño)
  // ===========================================================================
  // Función auxiliar para convertir texto como "1d8" o "2d6" en una lista de DicePool
  List<DicePool> _parseDiceNotation(String notation) {
    final cleaned = notation.trim().toLowerCase();
    final regex = RegExp(r'(\d+)\s*d\s*(\d+)');
    final match = regex.firstMatch(cleaned);

    if (match != null) {
      final count = int.tryParse(match.group(1)!) ?? 1;
      final sides = int.tryParse(match.group(2)!) ?? 6;
      return [DicePool(count: count, sides: sides)];
    }

    // Por defecto si el formato no coincide
    return [DicePool(count: 1, sides: 6)];
  }

  Future<void> _addOrEditWeapon({Weapon? weapon}) async {
    final nameController = TextEditingController(text: weapon?.name ?? '');
    final diceController = TextEditingController(
      text: weapon?.damageDice ?? '1d6',
    );
    final typeController = TextEditingController(
      text: weapon?.damageType ?? 'cortante',
    );
    bool proficient = weapon?.proficient ?? true;
    AbilityType attackAbility = weapon?.attackAbility ?? AbilityType.strength;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                weapon == null ? 'Nuevo ataque básico' : 'Editar ataque',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del ataque (ej. Mordisco, Garra)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: diceController,
                            decoration: const InputDecoration(
                              labelText: 'Dados de daño (ej. 1d8)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: typeController,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de daño',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<AbilityType>(
                      initialValue:
                          attackAbility, // <--- Change 'value' to 'initialValue'
                      decoration: const InputDecoration(
                        labelText: 'Atributo de ataque',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: AbilityType.strength,
                          child: Text('Fuerza'),
                        ),
                        DropdownMenuItem(
                          value: AbilityType.dexterity,
                          child: Text('Destreza'),
                        ),
                        DropdownMenuItem(
                          value: AbilityType.constitution,
                          child: Text('Constitución'),
                        ),
                        DropdownMenuItem(
                          value: AbilityType.intelligence,
                          child: Text('Inteligencia'),
                        ),
                        DropdownMenuItem(
                          value: AbilityType.wisdom,
                          child: Text('Sabiduría'),
                        ),
                        DropdownMenuItem(
                          value: AbilityType.charisma,
                          child: Text('Carisma'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => attackAbility = val);
                        }
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Competente'),
                      value: proficient,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => proficient = val);
                        }
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Competente'),
                      value: proficient,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => proficient = val);
                        }
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Competente'),
                      value: proficient,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        if (val != null) setDialogState(() => proficient = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true || !mounted) return;

    final name = nameController.text.trim();
    if (name.isEmpty) return;

    final diceText = diceController.text.trim();
    final typeText = typeController.text.trim();
    final parsedPools = _parseDiceNotation(diceText);

    setState(() {
      if (weapon == null) {
        pet.weapons.add(
          Weapon(
            id: 'pet_weapon_${DateTime.now().microsecondsSinceEpoch}',
            name: name,
            damageDice: diceText,
            damageType: typeText,
            attackAbility: attackAbility,
            proficient: proficient,
            damages: [
              WeaponDamage(
                id: 'dmg_1',
                dicePools:
                    parsedPools, // <--- Aquí pasamos la lista de DicePool correctamente
                damageType: typeText,
                addAbilityModifier: true,
                abilityType: attackAbility,
              ),
            ],
          ),
        );
      } else {
        weapon.name = name;
        weapon.damageDice = diceText;
        weapon.damageType = typeText;
        weapon.attackAbility = attackAbility;
        weapon.proficient = proficient;
        weapon.damages = [
          WeaponDamage(
            id: weapon.damages.isNotEmpty ? weapon.damages.first.id : 'dmg_1',
            dicePools: parsedPools, // <--- Aquí también
            damageType: typeText,
            addAbilityModifier: true,
            abilityType: attackAbility,
          ),
        ];
      }
    });

    await _save();
  }

  Future<void> _editPetHealth() async {
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return _PetHealthDialog(
          petName: pet.name,
          currentHealth: pet.currentHealth,
          maxHealth: pet.maxHealth,
        );
      },
    );

    if (result == null || !mounted) return;

    setState(() {
      pet.currentHealth = result.clamp(0, pet.maxHealth);
    });

    await _save();
  }

  // ===========================================================================
  // ADAPTADOR TEMPORAL PARA USAR EL RESOLVER OFICIAL CON LOS STATS DE LA MASCOTA
  // ===========================================================================
  Character _toTemporaryCharacter() {
    int targetLevel = 1;
    if (pet.proficiencyBonus >= 6) {
      targetLevel = 17;
    } else if (pet.proficiencyBonus == 5) {
      targetLevel = 13;
    } else if (pet.proficiencyBonus == 4) {
      targetLevel = 9;
    } else if (pet.proficiencyBonus == 3) {
      targetLevel = 5;
    } else {
      targetLevel = 1;
    }

    return Character(
      id: pet.id,
      name: pet.name,
      race: pet.species,
      level: targetLevel,
      abilities: pet.abilities,
      currentHealth: pet.currentHealth,
      customMaxHealth: pet.maxHealth,
      armorClass: pet.armorClass,
      speed: pet.speed,
      weapons: pet.weapons,
      characterAbilities: pet.characterAbilities,
      passives: pet.passives,
      itemDefinitions: character.itemDefinitions,
      inventoryItems: character.inventoryItems,
    );
  }

  // Resolver ataque básico usando el motor de la app
  Future<void> _resolvePetWeapon(Weapon weapon) async {
    final tempChar = _toTemporaryCharacter();
    final flow = ActionResolutionFlow(character: tempChar);

    try {
      final execution = await flow.resolveWeapon(context, weapon: weapon);

      if (execution == null || !mounted) return;

      // Sincronizamos la vida y aseguramos que los cambios en pasivas/cargas se guarden
      pet.currentHealth = tempChar.currentHealth;
      await _save(); // Esto guarda el personaje principal y sus mascotas con las cargas actualizadas
      setState(() {});

      if (!mounted) return;
      await showActionResolutionResultDialog(
        context,
        character: tempChar,
        execution: execution,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se ha podido resolver el ataque: $error')),
      );
    }
  }

  // Resolver habilidad activa usando el motor de la app
  Future<void> _resolvePetAbility(CharacterAbility ability) async {
    final tempChar = _toTemporaryCharacter();
    final flow = ActionResolutionFlow(character: tempChar);

    try {
      final execution = await flow.resolveAbility(context, ability: ability);

      if (execution == null || !mounted) return;

      pet.currentHealth = tempChar.currentHealth;
      await _save(); // Persiste los cambios de la mascota (cargas, vida, etc.)
      setState(() {});

      if (!mounted) return;
      await showActionResolutionResultDialog(
        context,
        character: tempChar,
        execution: execution,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se ha podido resolver la habilidad: $error'),
        ),
      );
    }
  }

  Future<void> _editAbility(CharacterAbility ability) async {
    final result = await Navigator.push<CharacterAbility>(
      context,
      MaterialPageRoute(builder: (_) => AbilityFormScreen(ability: ability)),
    );

    if (result != null) {
      setState(() {
        final index = pet.characterAbilities.indexWhere(
          (a) => a.id == ability.id,
        );
        if (index != -1) {
          pet.characterAbilities[index] = result;
        } else {
          pet.characterAbilities.add(result);
        }
      });

      await AbilityLibraryService.saveAbility(result);
      await _save();
    }
  }

  Future<void> _editPassive(CharacterPassive passive) async {
    final result = await Navigator.push<CharacterPassive>(
      context,
      MaterialPageRoute(
        builder: (_) => PassiveFormScreen(
          passive: passive,
          character: _toTemporaryCharacter(),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        final index = pet.passives.indexWhere((p) => p.id == passive.id);
        if (index != -1) {
          pet.passives[index] = result;
        } else {
          pet.passives.add(result);
        }
      });

      await PassiveLibraryService.savePassive(result);
      await _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(pet.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Editar mascota',
            onPressed: _editPet,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tarjeta de Estado y Atributos
          Card(
            elevation: 0,
            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.species.isNotEmpty ? pet.species : 'Compañero',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pet.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      InkWell(
                        onTap:
                            _editPetHealth, // <--- Al pulsar abre el diálogo de vida de la mascota
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: _buildStatItem(
                            context,
                            'PV (Editar)',
                            '${pet.currentHealth}/${pet.maxHealth}',
                            Icons.favorite_rounded,
                            colors.error,
                          ),
                        ),
                      ),
                      _buildStatItem(
                        context,
                        'CA',
                        '${pet.armorClass}',
                        Icons.shield_rounded,
                        colors.primary,
                      ),
                      _buildStatItem(
                        context,
                        'VEL',
                        '${pet.speed}',
                        Icons.directions_run_rounded,
                        colors.tertiary,
                      ),
                      _buildStatItem(
                        context,
                        'COMP',
                        '+${pet.proficiencyBonus}',
                        Icons.military_tech_rounded,
                        colors.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Atributos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _buildAttributesRow(),
                  if (pet.notes.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text(pet.notes, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Sección de Ataques Básicos / Armas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ataques Básicos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _addOrEditWeapon(),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Añadir'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (pet.weapons.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No hay ataques básicos configurados.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            )
          else
            ...pet.weapons.map((weapon) {
              final atkBonus = pet.weaponAttackBonus(weapon);
              final atkText = atkBonus >= 0 ? '+$atkBonus' : '$atkBonus';
              return Card(
                child: ListTile(
                  onTap: () => _resolvePetWeapon(weapon),
                  leading: const Icon(Icons.gavel_rounded),
                  title: Text(
                    weapon.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Atributo: ${weapon.attackAbility.name.toUpperCase()} • Ataque: $atkText • Daño: ${weapon.damageDice} ${weapon.damageType}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.green,
                        ),
                        tooltip: 'Atacar',
                        onPressed: () => _resolvePetWeapon(weapon),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        onPressed: () => _addOrEditWeapon(weapon: weapon),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                        ),
                        onPressed: () async {
                          setState(
                            () => pet.weapons.removeWhere(
                              (w) => w.id == weapon.id,
                            ),
                          );
                          await _save();
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 20),

          // Sección de Habilidades Activas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Habilidades Activas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _addAbility,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Añadir'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (pet.characterAbilities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No hay habilidades activas asignadas.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            )
          else
            // ===================================================================
            // HABILIDADES ACTIVAS
            // ===================================================================
            ...pet.characterAbilities.map(
              (ability) => Card(
                child: ListTile(
                  onTap: () => _editAbility(ability), // <--- Tocar para editar
                  leading: const Icon(Icons.flash_on_rounded),
                  title: Text(
                    ability.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    ability.description.isNotEmpty
                        ? ability.description
                        : 'Sin descripción',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.green,
                        ),
                        tooltip: 'Usar habilidad',
                        onPressed: () => _resolvePetAbility(ability),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        tooltip: 'Editar',
                        onPressed: () => _editAbility(ability),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () async {
                          setState(
                            () => pet.characterAbilities.removeWhere(
                              (a) => a.id == ability.id,
                            ),
                          );
                          await _save();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Passivas Activas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _addPassive,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Añadir'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ===================================================================
          // PASIVAS
          // ===================================================================
          ...pet.passives.map(
            (passive) => Card(
              child: ListTile(
                onTap: () => _editPassive(passive),
                leading: const Icon(Icons.auto_awesome_rounded),
                title: Text(
                  passive.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${passive.triggers.length} triggers configurados'),
                    // Muestra las cargas si la pasiva las tiene habilitadas
                    if (passive.hasCharges) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Cargas: ${passive.chargesText}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Botón rápido para gastar carga (-)
                          if (passive.currentCharges > 0)
                            InkWell(
                              onTap: () async {
                                setState(() {
                                  passive.currentCharges--;
                                });
                                await _save();
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.remove_circle_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          // Botón rápido para sumar carga (+)
                          if (!passive.chargesFull)
                            InkWell(
                              onTap: () async {
                                setState(() {
                                  passive.currentCharges++;
                                  passive.normalizeCharges();
                                });
                                await _save();
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
                isThreeLine: passive.hasCharges,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      tooltip: 'Editar',
                      onPressed: () => _editPassive(passive),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        setState(
                          () => pet.passives.removeWhere(
                            (p) => p.id == passive.id,
                          ),
                        );
                        await _save();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAttributesRow() {
    final attrs = [
      ('FUE', pet.strengthScore, pet.strengthModifier),
      ('DES', pet.dexterityScore, pet.dexterityModifier),
      ('CON', pet.constitutionScore, pet.constitutionModifier),
      ('INT', pet.intelligenceScore, pet.intelligenceModifier),
      ('SAB', pet.wisdomScore, pet.wisdomModifier),
      ('CAR', pet.charismaScore, pet.charismaModifier),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: attrs.map((attr) {
        final mod = attr.$3;
        final modText = mod >= 0 ? '+$mod' : '$mod';
        return Column(
          children: [
            Text(
              attr.$1,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${attr.$2}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            Text(
              modText,
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _PetHealthDialog extends StatefulWidget {
  final String petName;
  final int currentHealth;
  final int maxHealth;

  const _PetHealthDialog({
    required this.petName,
    required this.currentHealth,
    required this.maxHealth,
  });

  @override
  State<_PetHealthDialog> createState() => _PetHealthDialogState();
}

class _PetHealthDialogState extends State<_PetHealthDialog> {
  late final TextEditingController amountController;
  String operation = '-';

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  int get amount {
    return int.tryParse(amountController.text.trim()) ?? 0;
  }

  int get calculated {
    switch (operation) {
      case '+':
        return (widget.currentHealth + amount).clamp(0, widget.maxHealth);
      case '-':
        return (widget.currentHealth - amount).clamp(0, widget.maxHealth);
      default:
        return widget.currentHealth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.favorite_rounded),
          const SizedBox(width: 10),
          Expanded(child: Text('Vida de ${widget.petName}')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.currentHealth} / ${widget.maxHealth}',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => setState(() => operation = '-'),
                    icon: const Icon(Icons.remove_rounded),
                    label: const Text('Daño'),
                    style: FilledButton.styleFrom(
                      backgroundColor: operation == '-'
                          ? colors.errorContainer
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => setState(() => operation = '+'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Curación'),
                    style: FilledButton.styleFrom(
                      backgroundColor: operation == '+'
                          ? colors.primaryContainer
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: operation == '-'
                    ? 'Daño recibido'
                    : 'Curación recibida',
                prefixIcon: Icon(
                  operation == '-'
                      ? Icons.remove_circle_outline_rounded
                      : Icons.add_circle_outline_rounded,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            Text(
              'Resultado: $calculated / ${widget.maxHealth}',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, calculated),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
