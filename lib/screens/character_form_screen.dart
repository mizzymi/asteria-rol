import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/ability_scores.dart';
import '../models/character.dart';
import '../models/character_class_level.dart';
import '../models/campaign.dart';
import '../models/dnd_class.dart';
import '../models/custom_class_definition.dart';
import '../services/avatar_storage_service.dart';
import '../services/character_storage_service.dart';
import '../services/campaign_storage_service.dart';
import '../services/class_progression_service.dart';
import '../services/custom_class_storage_service.dart';

class CharacterFormScreen extends StatefulWidget {
  final Character? character;
  final String? initialCampaignId;
  final String ownerType;

  const CharacterFormScreen({
    super.key,
    this.character,
    this.initialCampaignId,
    this.ownerType = 'player',
  });

  @override
  State<CharacterFormScreen> createState() => _CharacterFormScreenState();
}

class _CharacterFormScreenState extends State<CharacterFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;

  late final TextEditingController raceController;

  late final TextEditingController levelController;

  late final TextEditingController strengthController;

  late final TextEditingController dexterityController;

  late final TextEditingController constitutionController;

  late final TextEditingController intelligenceController;

  late final TextEditingController wisdomController;

  late final TextEditingController charismaController;

  late final TextEditingController armorClassController;

  late final TextEditingController speedController;

  late final TextEditingController backstoryController;

  late final TextEditingController personalityController;

  late DndClass selectedClass;
  String? selectedCustomClassId;

  List<CustomClassDefinition> get campaignClasses =>
      CustomClassStorageService.getClasses(selectedCampaignId ?? '');

  CustomClassDefinition? get chosenCustomClass {
    for (final definition in campaignClasses) {
      if (definition.classId == selectedCustomClassId) return definition;
    }
    return null;
  }

  late List<Campaign> campaigns;
  String? selectedCampaignId;

  String? avatarPath;

  String? pendingAvatarPath;
  late final String _newCharacterId = DateTime.now().microsecondsSinceEpoch.toString();

  final ImagePicker picker = ImagePicker();

  bool get editing => widget.character != null;

  @override
  void initState() {
    super.initState();

    final character = widget.character;

    campaigns = CampaignStorageService.getCampaigns();
    selectedCampaignId = character?.campaignId ?? widget.initialCampaignId;
    if (selectedCampaignId == null && campaigns.length == 1) {
      selectedCampaignId = campaigns.first.id;
    }

    nameController = TextEditingController(text: character?.name ?? '');

    raceController = TextEditingController(text: character?.race ?? '');

    levelController = TextEditingController(text: '${character?.level ?? 1}');

    selectedClass = character?.dndClass ?? DndClass.fighter;
    selectedCustomClassId = character?.primaryClassLevel.isCustom == true
        ? character!.primaryClassLevel.classId
        : null;
    if (character == null && campaignClasses.isNotEmpty) {
      selectedCustomClassId = campaignClasses.first.classId;
    }

    final abilities = character?.abilities ?? AbilityScores();

    strengthController = TextEditingController(text: '${abilities.strength}');

    dexterityController = TextEditingController(text: '${abilities.dexterity}');

    constitutionController = TextEditingController(
      text: '${abilities.constitution}',
    );

    intelligenceController = TextEditingController(
      text: '${abilities.intelligence}',
    );

    wisdomController = TextEditingController(text: '${abilities.wisdom}');

    charismaController = TextEditingController(text: '${abilities.charisma}');

    armorClassController = TextEditingController(
      text: '${character?.armorClass ?? 10}',
    );

    speedController = TextEditingController(text: '${character?.speed ?? 30}');

    backstoryController = TextEditingController(
      text: character?.backstory ?? '',
    );

    personalityController = TextEditingController(
      text: character?.personality ?? '',
    );

    avatarPath = character?.avatarPath;
  }

  int parseStat(TextEditingController controller) {
    return int.tryParse(controller.text) ?? 10;
  }

  AbilityScores get currentAbilities {
    return AbilityScores(
      strength: parseStat(strengthController),
      dexterity: parseStat(dexterityController),
      constitution: parseStat(constitutionController),
      intelligence: parseStat(intelligenceController),
      wisdom: parseStat(wisdomController),
      charisma: parseStat(charismaController),
    );
  }

  int get previewHealth {
    final preview = Character(
      id: 'preview',
      name: 'preview',
      classes: chosenCustomClass == null
          ? null
          : [
              CharacterClassLevel(
                dndClass: DndClass.fighter,
                classId: chosenCustomClass!.classId,
                customName: chosenCustomClass!.name,
                customHitDie: chosenCustomClass!.hitDie,
                customSavingThrowProficiencies:
                    chosenCustomClass!.savingThrowProficiencies,
                level: int.tryParse(levelController.text) ?? 1,
              ),
            ],
      dndClass: selectedClass,
      level: int.tryParse(levelController.text) ?? 1,
      abilities: currentAbilities,
    );

    return preview.maxHealth;
  }

  Future<void> _resolveClassProgression(Character character) async {
    final result = ClassProgressionService.reconcile(
      character,
      CustomClassStorageService.getClasses(character.campaignId ?? ''),
    );

    for (final pending in result.pendingChoices) {
      if (!mounted) return;
      final selected = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            pending.reward.name.trim().isEmpty
                ? 'Elección de nivel ${pending.reward.level}'
                : pending.reward.name,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${pending.definition.name} · nivel ${pending.reward.level}',
              ),
              const SizedBox(height: 10),
              for (final option in pending.reward.contents)
                ListTile(
                  leading: Icon(
                    option.type == ClassProgressionContentType.ability
                        ? Icons.auto_awesome_rounded
                        : Icons.shield_outlined,
                  ),
                  title: Text(option.name),
                  onTap: () => Navigator.pop(dialogContext, option.contentId),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Elegir más tarde'),
            ),
          ],
        ),
      );
      if (selected == null) continue;
      ClassProgressionService.applyChoice(
        character,
        definition: pending.definition,
        reward: pending.reward,
        contentId: selected,
      );
    }
  }

  Future<void> pickAvatar() async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    try {
      // Persist the picked image immediately: image_picker's cache is temporary.
      final savedPath = await AvatarStorageService.saveAvatar(
        characterId: widget.character?.id ?? _newCharacterId,
        sourcePath: image.path,
      );
      if (!mounted) return;
      setState(() {
        pendingAvatarPath = savedPath;
        avatarPath = savedPath;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el avatar: $error')),
      );
    }
  }

  Future<void> saveCharacter() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final level = int.tryParse(levelController.text) ?? 1;

    final abilities = currentAbilities;

    final id = widget.character?.id ?? _newCharacterId;

    String? finalAvatarPath = widget.character?.avatarPath;

    if (pendingAvatarPath != null) {
      try {
        finalAvatarPath = await AvatarStorageService.saveAvatar(
          characterId: id,
          sourcePath: pendingAvatarPath!,
        );
      } on FileSystemException {
        // A missing image must not prevent creation of an NPC or character.
        finalAvatarPath = widget.character?.avatarPath;
        if (finalAvatarPath != null && !await File(finalAvatarPath).exists()) {
          finalAvatarPath = null;
        }
      }
    }

    final oldCharacter = widget.character;

    final preservedClasses = oldCharacter?.classes
        .map((item) => CharacterClassLevel.fromMap(item.toMap()))
        .toList();

    if (preservedClasses != null &&
        preservedClasses.isNotEmpty &&
        !preservedClasses.first.isCustom) {
      preservedClasses.first.dndClass = selectedClass;
      preservedClasses.first.classId = 'core:${selectedClass.name}';
      preservedClasses.first.customName = null;
      preservedClasses.first.customHitDie = null;
      preservedClasses.first.customSavingThrowProficiencies = null;
    }

    final customDefinition = chosenCustomClass;
    final startingClasses = oldCharacter == null && customDefinition != null
        ? <CharacterClassLevel>[
            CharacterClassLevel(
              dndClass: DndClass.fighter,
              classId: customDefinition.classId,
              customName: customDefinition.name,
              customHitDie: customDefinition.hitDie,
              customSavingThrowProficiencies:
                  customDefinition.savingThrowProficiencies,
              level: level,
            ),
          ]
        : preservedClasses;

    final character = Character(
      id: id,
      name: nameController.text.trim(),
      avatarPath: finalAvatarPath,
      campaignId: selectedCampaignId,
      ownerType: oldCharacter?.ownerType ?? widget.ownerType,
      race: raceController.text.trim(),
      classes: startingClasses,
      dndClass: oldCharacter == null ? selectedClass : null,
      level: oldCharacter == null ? level : null,
      appliedClassRewardIds: oldCharacter?.appliedClassRewardIds,
      classProgressionChoices: oldCharacter?.classProgressionChoices,
      abilities: abilities,
      currentHealth: oldCharacter?.currentHealth,
      armorClass: int.tryParse(armorClassController.text) ?? 10,
      speed: int.tryParse(speedController.text) ?? 30,
      backstory: backstoryController.text.trim(),
      personality: personalityController.text.trim(),
      skillProficiencies: oldCharacter?.skillProficiencies,
      savingThrowProficiencies: oldCharacter?.savingThrowProficiencies,
      weapons: oldCharacter?.weapons,
      characterAbilities: oldCharacter?.characterAbilities,
      passives: oldCharacter?.passives,
      contentFolders: oldCharacter?.contentFolders,
      journalEntries: oldCharacter?.journalEntries,
      diceHistory: oldCharacter?.diceHistory,
      items: oldCharacter?.items,
      itemDefinitions: oldCharacter?.itemDefinitions,
      inventoryItems: oldCharacter?.inventoryItems,
      resources: oldCharacter?.resources,
      effects: oldCharacter?.effects,
      knowledges: oldCharacter?.knowledges,
      spellSlots: oldCharacter?.spellSlots,
      pets: oldCharacter?.pets,
      counters: oldCharacter?.counters,
      customMaxHealth: oldCharacter?.customMaxHealth,
      combatActive: oldCharacter?.combatActive ?? false,
      combatRound: oldCharacter?.combatRound ?? 1,
      turnActive: oldCharacter?.turnActive ?? false,
      combatTurnSequence: oldCharacter?.combatTurnSequence ?? 0,
      criticalMinimumNaturalRoll:
          oldCharacter?.criticalMinimumNaturalRoll ?? 20,
      shortRestRule: oldCharacter?.shortRestRule ?? 'single',
    );

    if (oldCharacter != null) {
      character.level = level;
    }

    character.normalizeHealth();
    await _resolveClassProgression(character);

    await CharacterStorageService.saveCharacter(character);

    if (!mounted) {
      return;
    }

    Navigator.pop(context, character);
  }

  @override
  void dispose() {
    nameController.dispose();
    raceController.dispose();
    levelController.dispose();

    strengthController.dispose();
    dexterityController.dispose();
    constitutionController.dispose();
    intelligenceController.dispose();
    wisdomController.dispose();
    charismaController.dispose();

    armorClassController.dispose();
    speedController.dispose();

    backstoryController.dispose();
    personalityController.dispose();

    super.dispose();
  }

  Widget statField(String label, TextEditingController controller) {
    final value = int.tryParse(controller.text) ?? 10;

    final modifier = AbilityScores.modifierFor(value);

    final modifierText = modifier >= 0 ? '+$modifier' : '$modifier';

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      onChanged: (_) {
        setState(() {});
      },
      decoration: InputDecoration(labelText: label, helperText: modifierText),
      validator: (value) {
        final number = int.tryParse(value ?? '');

        if (number == null) {
          return 'Inválido';
        }

        if (number < 1 || number > 30) {
          return '1-30';
        }

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarToShow = pendingAvatarPath ?? avatarPath;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar personaje' : 'Nuevo personaje'),
        actions: [
          IconButton(
            onPressed: saveCharacter,
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
              Center(
                child: GestureDetector(
                  onTap: pickAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 58,
                        backgroundImage: avatarToShow != null
                            ? FileImage(File(avatarToShow))
                            : null,
                        child: avatarToShow == null
                            ? const Icon(Icons.person_rounded, size: 54)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 19,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 19,
                            color: Theme.of(
                              context,
                            ).colorScheme.onInverseSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduce un nombre';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: campaigns.any((c) => c.id == selectedCampaignId)
                    ? selectedCampaignId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Campaña',
                  prefixIcon: Icon(Icons.auto_stories_rounded),
                ),
                items: campaigns
                    .map(
                      (campaign) => DropdownMenuItem(
                        value: campaign.id,
                        child: Text(campaign.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCampaignId = value;
                    selectedCustomClassId = campaignClasses.isNotEmpty
                        ? campaignClasses.first.classId
                        : null;
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Selecciona una campaña'
                    : null,
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: raceController,
                decoration: const InputDecoration(
                  labelText: 'Raza',
                  prefixIcon: Icon(Icons.pets_rounded),
                ),
              ),

              const SizedBox(height: 14),

              if (editing && widget.character!.primaryClassLevel.isCustom)
                ListTile(
                  leading: const Icon(Icons.shield_rounded),
                  title: Text(widget.character!.primaryClassLevel.label),
                  subtitle: const Text('Clase personalizada actual'),
                )
              else if (campaignClasses.isNotEmpty)
                DropdownButtonFormField<String>(
                  key: ValueKey('class-$selectedCampaignId'),
                  initialValue: selectedCustomClassId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Clase de la campaña',
                    prefixIcon: Icon(Icons.shield_rounded),
                  ),
                  items: campaignClasses.map((definition) {
                    return DropdownMenuItem(
                      value: definition.classId,
                      child: Text('${definition.name} · d${definition.hitDie}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedCustomClassId = value);
                  },
                  validator: (value) =>
                      value == null ? 'Selecciona una clase' : null,
                )
              else
                DropdownButtonFormField<DndClass>(
                  key: ValueKey('core-$selectedCampaignId'),
                  initialValue: selectedClass,
                  decoration: const InputDecoration(
                    labelText: 'Clase',
                    prefixIcon: Icon(Icons.shield_rounded),
                  ),
                  items: DndClass.values.map((dndClass) {
                    return DropdownMenuItem(
                      value: dndClass,
                      child: Text('${dndClass.label} · d${dndClass.hitDie}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => selectedClass = value);
                  },
                ),

              const SizedBox(height: 14),

              TextFormField(
                controller: levelController,
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  setState(() {});
                },
                decoration: const InputDecoration(
                  labelText: 'Nivel',
                  prefixIcon: Icon(Icons.trending_up_rounded),
                ),
                validator: (value) {
                  final level = int.tryParse(value ?? '');

                  if (level == null || level < 1 || level > 20) {
                    return 'Introduce un nivel entre 1 y 20';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 28),

              Text(
                'Atributos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(child: statField('FUE', strengthController)),
                  const SizedBox(width: 8),
                  Expanded(child: statField('DES', dexterityController)),
                  const SizedBox(width: 8),
                  Expanded(child: statField('CON', constitutionController)),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: statField('INT', intelligenceController)),
                  const SizedBox(width: 8),
                  Expanded(child: statField('SAB', wisdomController)),
                  const SizedBox(width: 8),
                  Expanded(child: statField('CAR', charismaController)),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                'Combate',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PreviewValue(
                          icon: Icons.favorite_rounded,
                          label: 'PG máximos',
                          value: '$previewHealth',
                        ),
                      ),
                      Expanded(
                        child: _PreviewValue(
                          icon: Icons.casino_rounded,
                          label: 'Dado de golpe',
                          value:
                              'd${widget.character?.primaryClassLevel.isCustom == true ? widget.character!.primaryClassLevel.hitDie : (chosenCustomClass?.hitDie ?? selectedClass.hitDie)}',
                        ),
                      ),
                      Expanded(
                        child: _PreviewValue(
                          icon: Icons.military_tech_rounded,
                          label: 'Competencia',
                          value:
                              '+${2 + (((int.tryParse(levelController.text) ?? 1) - 1) ~/ 4)}',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: armorClassController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'CA',
                        prefixIcon: Icon(Icons.shield_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: speedController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Velocidad',
                        suffixText: 'pies',
                        prefixIcon: Icon(Icons.directions_run_rounded),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                'Historia',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: backstoryController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Trasfondo',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: personalityController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Personalidad',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 30),

              FilledButton.icon(
                onPressed: saveCharacter,
                icon: const Icon(Icons.save_rounded),
                label: Text(editing ? 'Guardar cambios' : 'Crear personaje'),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewValue extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PreviewValue({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
