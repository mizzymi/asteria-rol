import 'dart:io';

import 'package:flutter/material.dart';

import '../models/dice_pool.dart';
import '../models/skill.dart';
import '../models/character.dart';
import '../models/pet.dart';
import '../models/ability.dart';
import '../models/passive.dart';
import '../models/weapon.dart';
import '../models/weapon_damage.dart';
import '../models/character_effect.dart';
import '../services/character_storage_service.dart';
import '../services/action_resolution_flow.dart';
import '../services/ability_library_service.dart';
import '../services/passive_library_service.dart';
import '../widgets/action_resolution/result/action_resolution_result_dialog.dart';
import 'ability_form_screen.dart';
import 'passive_form_screen.dart';
import 'pet_form_screen.dart';
import 'effect_form_screen.dart';

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

  Future<void> _addEffect() async {
    final effect = await Navigator.push<CharacterEffect>(
      context,
      MaterialPageRoute(
        builder: (_) => EffectFormScreen(character: _toTemporaryCharacter()),
      ),
    );
    if (effect == null) return;

    setState(() {
      pet.effects.add(effect);
    });
    await _save();
  }

  Future<void> _editEffect(CharacterEffect effect) async {
    final result = await Navigator.push<CharacterEffect>(
      context,
      MaterialPageRoute(
        builder: (_) => EffectFormScreen(
          effect: effect,
          character: _toTemporaryCharacter(),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        final index = pet.effects.indexWhere((e) => e.id == effect.id);
        if (index != -1) {
          pet.effects[index] = result;
        }
      });
      await _save();
    }
  }

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
      pet.avatarPath = result.avatarPath;
      pet.avatarAlignmentX = result.avatarAlignmentX;
      pet.avatarAlignmentY = result.avatarAlignmentY;
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
  List<DicePool> _parseDiceNotation(String notation) {
    final cleaned = notation.trim().toLowerCase();
    final regex = RegExp(r'(\d+)\s*d\s*(\d+)');
    final match = regex.firstMatch(cleaned);

    if (match != null) {
      final count = int.tryParse(match.group(1)!) ?? 1;
      final sides = int.tryParse(match.group(2)!) ?? 6;
      return [DicePool(count: count, sides: sides)];
    }

    return [DicePool(count: 1, sides: 6)];
  }

  Future<void> _addOrEditWeapon({Weapon? weapon}) async {
    final nameController = TextEditingController(text: weapon?.name ?? '');
    bool proficient = weapon?.proficient ?? true;
    AbilityType attackAbility = weapon?.attackAbility ?? AbilityType.strength;

    // Clonamos o inicializamos la lista de daños para editarla de forma segura en el diálogo
    List<WeaponDamage> dialogDamages = weapon != null
        ? weapon.damages
              .map(
                (d) => WeaponDamage(
                  id: d.id,
                  name: d.name,
                  dicePools: List.from(d.dicePools),
                  damageType: d.damageType,
                  bonus: d.bonus,
                  addAbilityModifier: d.addAbilityModifier,
                  abilityType: d.abilityType,
                ),
              )
              .toList()
        : [
            WeaponDamage(
              id: 'dmg_${DateTime.now().microsecondsSinceEpoch}',
              name: 'Daño principal',
              dicePools: [DicePool(count: 1, sides: 6)],
              damageType: 'cortante',
              addAbilityModifier: true,
              abilityType: attackAbility,
            ),
          ];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                weapon == null ? 'Nuevo ataque básico' : 'Editar ataque',
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText:
                              'Nombre del ataque (ej. Mordisco de Fuego)',
                          prefixIcon: Icon(Icons.gavel_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<AbilityType>(
                        initialValue: attackAbility,
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
                            setDialogState(() {
                              attackAbility = val;
                              for (var d in dialogDamages) {
                                d.abilityType = val;
                              }
                            });
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
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Componentes de Daño',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            color: Theme.of(context).colorScheme.primary,
                            tooltip: 'Añadir otro tipo de daño',
                            onPressed: () {
                              setDialogState(() {
                                dialogDamages.add(
                                  WeaponDamage(
                                    id: 'dmg_${DateTime.now().microsecondsSinceEpoch}',
                                    name: 'Daño adicional',
                                    dicePools: [DicePool(count: 1, sides: 6)],
                                    damageType: 'fuego',
                                    addAbilityModifier:
                                        false, // Por lo general el secundario no lleva mod extra
                                    abilityType: attackAbility,
                                  ),
                                );
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...dialogDamages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final dmg = entry.value;
                        final diceStr = dmg.dicePools
                            .map((p) => '${p.count}d${p.sides}')
                            .join(' + ');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    initialValue: diceStr,
                                    decoration: const InputDecoration(
                                      labelText: 'Dados (ej. 1d6)',
                                    ),
                                    onChanged: (val) {
                                      final pools = _parseDiceNotation(val);
                                      dmg.dicePools = pools;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    initialValue: dmg.damageType,
                                    decoration: const InputDecoration(
                                      labelText: 'Tipo (ej. fuego)',
                                    ),
                                    onChanged: (val) {
                                      dmg.damageType = val.trim();
                                    },
                                  ),
                                ),
                                if (dialogDamages.length > 1)
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                    onPressed: () {
                                      setDialogState(() {
                                        dialogDamages.removeAt(index);
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
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
    if (name.isEmpty || dialogDamages.isEmpty) return;

    // Actualizamos el resumen de texto legacy (damageDice / damageType) tomando el principal para compatibilidad visual
    final primaryDmg = dialogDamages.first;
    final primaryDiceStr = primaryDmg.dicePools
        .map((p) => '${p.count}d${p.sides}')
        .join(' + ');

    setState(() {
      if (weapon == null) {
        pet.weapons.add(
          Weapon(
            id: 'pet_weapon_${DateTime.now().microsecondsSinceEpoch}',
            name: name,
            damageDice: primaryDiceStr,
            damageType: primaryDmg.damageType,
            attackAbility: attackAbility,
            proficient: proficient,
            damages: dialogDamages,
          ),
        );
      } else {
        weapon.name = name;
        weapon.damageDice = primaryDiceStr;
        weapon.damageType = primaryDmg.damageType;
        weapon.attackAbility = attackAbility;
        weapon.proficient = proficient;
        weapon.damages = dialogDamages;
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
      effects: pet.effects,
      itemDefinitions: character.itemDefinitions,
      inventoryItems: character.inventoryItems,
    );
  }

  Future<void> _resolvePetWeapon(Weapon weapon) async {
    final tempChar = _toTemporaryCharacter();
    final flow = ActionResolutionFlow(character: tempChar);

    try {
      final execution = await flow.resolveWeapon(context, weapon: weapon);

      if (execution == null || !mounted) return;

      pet.currentHealth = tempChar.currentHealth;
      pet.effects = List.from(tempChar.effects);

      await _save();
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

  Future<void> _resolvePetAbility(CharacterAbility ability) async {
    final tempChar = _toTemporaryCharacter();
    final flow = ActionResolutionFlow(character: tempChar);

    try {
      final execution = await flow.resolveAbility(context, ability: ability);

      if (execution == null || !mounted) return;

      pet.currentHealth = tempChar.currentHealth;
      pet.effects = List.from(tempChar.effects);

      await _save();
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


  Future<void> _showAvatarFullscreen() async {
    if (pet.avatarPath.isEmpty || !File(pet.avatarPath).existsSync()) return;

    await showDialog<void>(
      context: context,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .94),
      builder: (dialogContext) {
        return Dialog.fullscreen(
          backgroundColor: Theme.of(context).colorScheme.scrim,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Image.file(
                    File(pet.avatarPath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(dialogContext).top + 8,
                right: 12,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .55),
                    foregroundColor: Theme.of(context).colorScheme.onInverseSurface,
                  ),
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              Positioned(
                left: 18,
                right: 70,
                bottom: MediaQuery.paddingOf(dialogContext).bottom + 18,
                child: Text(
                  'Pellizca para ampliar · arrastra para moverte',
                  style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onInverseSurface.withValues(alpha: 0.70),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHero(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildOverviewCard(context),
                const SizedBox(height: 20),
                _buildSectionHeader(
                  context,
                  title: 'Efectos activos',
                  icon: Icons.auto_awesome_rounded,
                  action: FilledButton.tonalIcon(
                    onPressed: _addEffect,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Añadir'),
                  ),
                ),
                const SizedBox(height: 8),
                if (pet.effects.isEmpty)
                  _buildEmptyState(context, 'No hay efectos activos asignados.')
                else
                  ...pet.effects.map((effect) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(effect.enabled ? Icons.bolt_rounded : Icons.bolt_outlined),
                      ),
                      title: Text(effect.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(effect.durationText.isNotEmpty ? effect.durationText : (effect.enabled ? 'Activo' : 'Inactivo')),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch.adaptive(
                            value: effect.enabled,
                            onChanged: (value) async {
                              setState(() => effect.enabled = value);
                              await _save();
                            },
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await _editEffect(effect);
                              } else if (value == 'turn') {
                                setState(() {
                                  effect.advanceTurn();
                                  pet.effects.removeWhere((e) => e.hasDuration && e.isExpired);
                                });
                                await _save();
                              } else if (value == 'delete') {
                                setState(() => pet.effects.removeWhere((e) => e.id == effect.id));
                                await _save();
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'turn', child: Text('Reducir 1 turno')),
                              PopupMenuItem(value: 'edit', child: Text('Editar')),
                              PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => _editEffect(effect),
                    ),
                  )),
                const SizedBox(height: 20),
                _buildSectionHeader(
                  context,
                  title: 'Ataques básicos',
                  icon: Icons.gavel_rounded,
                  action: FilledButton.tonalIcon(
                    onPressed: () => _addOrEditWeapon(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Añadir'),
                  ),
                ),
                const SizedBox(height: 8),
                if (pet.weapons.isEmpty)
                  _buildEmptyState(context, 'No hay ataques básicos configurados.')
                else
                  ...pet.weapons.map((weapon) {
                    final atkBonus = pet.weaponAttackBonus(weapon);
                    final atkText = atkBonus >= 0 ? '+$atkBonus' : '$atkBonus';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () => _resolvePetWeapon(weapon),
                        leading: const CircleAvatar(child: Icon(Icons.gavel_rounded)),
                        title: Text(weapon.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text('Ataque $atkText  •  ${weapon.damageDice} ${weapon.damageType}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'use') await _resolvePetWeapon(weapon);
                            if (value == 'edit') await _addOrEditWeapon(weapon: weapon);
                            if (value == 'delete') {
                              setState(() => pet.weapons.removeWhere((w) => w.id == weapon.id));
                              await _save();
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'use', child: Text('Atacar')),
                            PopupMenuItem(value: 'edit', child: Text('Editar')),
                            PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 20),
                _buildSectionHeader(
                  context,
                  title: 'Habilidades activas',
                  icon: Icons.flash_on_rounded,
                  action: FilledButton.tonalIcon(
                    onPressed: _addAbility,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Añadir'),
                  ),
                ),
                const SizedBox(height: 8),
                if (pet.characterAbilities.isEmpty)
                  _buildEmptyState(context, 'No hay habilidades activas asignadas.')
                else
                  ...pet.characterAbilities.map((ability) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.flash_on_rounded)),
                      title: Text(ability.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(ability.description.isNotEmpty ? ability.description : 'Sin descripción', maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () => _resolvePetAbility(ability),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'use') await _resolvePetAbility(ability);
                          if (value == 'edit') await _editAbility(ability);
                          if (value == 'delete') {
                            setState(() => pet.characterAbilities.removeWhere((a) => a.id == ability.id));
                            await _save();
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'use', child: Text('Usar')),
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                        ],
                      ),
                    ),
                  )),
                const SizedBox(height: 20),
                _buildSectionHeader(
                  context,
                  title: 'Pasivas',
                  icon: Icons.auto_awesome_rounded,
                  action: FilledButton.tonalIcon(
                    onPressed: _addPassive,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Añadir'),
                  ),
                ),
                const SizedBox(height: 8),
                if (pet.passives.isEmpty)
                  _buildEmptyState(context, 'No hay pasivas asignadas.')
                else
                  ...pet.passives.map((passive) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.auto_awesome_rounded)),
                      title: Text(passive.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(passive.hasCharges
                          ? '${passive.triggers.length} triggers  •  Cargas ${passive.chargesText}'
                          : '${passive.triggers.length} triggers configurados'),
                      onTap: () => _editPassive(passive),
                      trailing: passive.hasCharges
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Gastar carga',
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.remove_rounded, size: 18),
                                        onPressed: passive.currentCharges <= 0
                                            ? null
                                            : () async {
                                                setState(() {
                                                  passive.currentCharges--;
                                                  passive.normalizeCharges();
                                                });
                                                await _save();
                                              },
                                      ),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(minWidth: 42),
                                        child: Text(
                                          passive.chargesText,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Recuperar carga',
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.add_rounded, size: 18),
                                        onPressed: passive.chargesFull
                                            ? null
                                            : () async {
                                                setState(() {
                                                  passive.currentCharges++;
                                                  passive.normalizeCharges();
                                                });
                                                await _save();
                                              },
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') await _editPassive(passive);
                                    if (value == 'delete') {
                                      setState(() => pet.passives.removeWhere((p) => p.id == passive.id));
                                      await _save();
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                                  ],
                                ),
                              ],
                            )
                          : PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') await _editPassive(passive);
                                if (value == 'delete') {
                                  setState(() => pet.passives.removeWhere((p) => p.id == passive.id));
                                  await _save();
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'edit', child: Text('Editar')),
                                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                              ],
                            ),
                    ),
                  )),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasImage = pet.avatarPath.isNotEmpty && File(pet.avatarPath).existsSync();

    return GestureDetector(
      onTap: hasImage ? _showAvatarFullscreen : null,
      child: SizedBox(
        height: 290,
        child: Stack(
          fit: StackFit.expand,
          children: [
          if (hasImage)
            Image.file(
              File(pet.avatarPath),
              fit: BoxFit.cover,
              alignment: Alignment(pet.avatarAlignmentX, pet.avatarAlignmentY),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.primaryContainer, colors.tertiaryContainer],
                ),
              ),
              child: Icon(Icons.pets_rounded, size: 100, color: colors.onPrimaryContainer.withValues(alpha: .55)),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Theme.of(context).colorScheme.surface.withValues(alpha: 0), Theme.of(context).colorScheme.scrim.withValues(alpha: .72)],
                  stops: const [.35, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pet.species.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.scrim.withValues(alpha: .28), borderRadius: BorderRadius.circular(999)),
                    child: Text(pet.species, style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface, fontWeight: FontWeight.w700)),
                  ),
                const SizedBox(height: 8),
                Text(
                  pet.name,
                  style: theme.textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.onInverseSurface, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          if (hasImage)
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.scrim.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_out_map_rounded, color: Theme.of(context).colorScheme.onInverseSurface, size: 17),
                    SizedBox(width: 6),
                    Text(
                      'Ampliar',
                      style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final healthRatio = pet.maxHealth <= 0 ? 0.0 : (pet.currentHealth / pet.maxHealth).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _editPetHealth,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite_rounded, color: colors.error),
                        const SizedBox(width: 8),
                        Text('Puntos de vida', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text('${pet.currentHealth} / ${pet.maxHealth}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: healthRatio, minHeight: 9, borderRadius: BorderRadius.circular(99)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _buildMetricTile(context, 'CA', '${pet.armorClass}', Icons.shield_rounded)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricTile(context, 'Velocidad', '${pet.speed}', Icons.directions_run_rounded)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricTile(context, 'Competencia', '+${pet.proficiencyBonus}', Icons.military_tech_rounded)),
              ],
            ),
            const SizedBox(height: 18),
            Text('Atributos', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            _buildAttributesRow(),
            if (pet.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                child: Text(pet.notes),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(icon, color: colors.primary, size: 21),
          const SizedBox(height: 5),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, required IconData icon, required Widget action}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 21, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
        action,
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${attr.$2}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            Text(
              modText,
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
