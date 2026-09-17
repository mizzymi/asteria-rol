import 'dart:math';
import 'dart:math' as math;

import '../services/resource_modifier_resolver.dart';
import '../services/formula_evaluator.dart';
import '../services/passive_trigger_engine.dart';
import '../services/character_effect_trigger_engine.dart';

import 'formulas/character_formula.dart';
import 'character_knowledge.dart';
import 'equipment_slot.dart';
import 'formulas/formula_bonus.dart';
import 'character_content_folder.dart';
import 'formulas/character_formula_context.dart';
import 'character_counter.dart';
import 'formulas/formula_context.dart';
import 'character_resource.dart';
import 'active_damage_bonus.dart';
import 'ability.dart';
import 'ability_scores.dart';
import 'character_class_level.dart';
import 'dice_history_entry.dart';
import 'ability_effect_part.dart';
import 'dnd_class.dart';
import 'journal_entry.dart';
import 'passive.dart';
import 'proficiency.dart';
import 'skill.dart';
import 'weapon.dart';
import 'item.dart';
import 'character_effect.dart';
import 'weapon_damage.dart';
import 'damage_bonus.dart';
import 'critical_damage_bonus.dart';
import 'healing_bonus.dart';
import 'action_trigger_context.dart';
import 'pet.dart'; // <--- Importante: Importar el modelo de mascota

class Character {
  final String id;

  String name;
  String? avatarPath;

  /// Campaña a la que pertenece el personaje.
  String? campaignId;

  /// Quién controla esta ficha: player, npc o creatureHost.
  /// creatureHost es una ficha técnica oculta que permite reutilizar toda la
  /// mecánica de Pet para las criaturas del Master.
  String ownerType;

  String race;

  /// Una o varias clases.
  ///
  /// La primera clase se considera la clase principal / inicial.
  List<CharacterClassLevel> classes;
  List<CharacterContentFolder> contentFolders;
  AbilityScores abilities;

  int currentHealth;
  int? customMaxHealth;

  int armorClass;
  int speed;

  String backstory;
  String personality;

  String appearance;
  String ideals;
  String bonds;
  String flaws;
  String goals;
  String storyNotes;

  Map<DndSkill, ProficiencyLevel> skillProficiencies;

  Map<AbilityType, bool> savingThrowProficiencies;

  List<Weapon> weapons;

  List<CharacterAbility> characterAbilities;

  List<CharacterPassive> passives;

  List<JournalEntry> journalEntries;

  List<DiceHistoryEntry> diceHistory;

  List<CharacterItem> items;

  List<ItemDefinition> itemDefinitions;

  List<InventoryItem> inventoryItems;

  List<CharacterResource> resources;

  List<CharacterEffect> effects;

  bool combatActive;

  int combatRound;

  bool turnActive;

  int combatTurnSequence;

  /// Progreso de conocimientos descubiertos o aprendidos por el personaje
  List<CharacterKnowledge> knowledges;

  /// Slots o recursos de magia preparados (ej: {'slot_1': 4, 'slot_2': 3})
  Map<String, int> spellSlots;

  /// Mascotas y compañeros del personaje
  List<Pet> pets; // <--- Lista de mascotas añadida

  List<ActiveDamageBonus> get activeDamageBonuses {
    final result = <ActiveDamageBonus>[];

    for (final passive in enabledPassives) {
      for (final bonus in passive.damageBonuses) {
        result.add(ActiveDamageBonus(bonus: bonus, passive: passive));
      }
    }

    for (final effect in enabledEffects) {
      for (final bonus in effect.damageBonuses) {
        result.add(ActiveDamageBonus(bonus: bonus));
      }
    }

    return result;
  }

  /// Bonos críticos globales activos del personaje.
  ///
  /// Incluye únicamente modificadores procedentes del personaje:
  /// - pasivas
  /// - efectos activos
  ///
  /// Los CriticalDamageBonus propios de un arma NO se incluyen aquí.
  /// Esos forman parte de ActionContent.
  List<CriticalDamageBonus> get activeGlobalCriticalDamageBonuses {
    final bonuses = <CriticalDamageBonus>[];

    for (final passive in enabledPassives) {
      bonuses.addAll(passive.criticalDamageBonuses);
    }

    for (final effect in enabledEffects) {
      bonuses.addAll(effect.criticalDamageBonuses);
    }

    return List<CriticalDamageBonus>.unmodifiable(bonuses);
  }

  List<int> get criticalMinimumRollSources {
    final sources = <int>[criticalMinimumNaturalRoll];

    for (final passive in enabledPassives) {
      sources.add(passive.criticalMinimumNaturalRoll);
    }

    for (final effect in enabledEffects) {
      sources.add(effect.criticalMinimumNaturalRoll);
    }

    return sources;
  }

  List<ActiveHealingBonus> get activeHealingBonuses {
    final result = <ActiveHealingBonus>[];

    for (final passive in enabledPassives) {
      for (final bonus in passive.healingBonuses) {
        result.add(ActiveHealingBonus(bonus: bonus, passive: passive));
      }
    }

    for (final effect in enabledEffects) {
      for (final bonus in effect.healingBonuses) {
        result.add(ActiveHealingBonus(bonus: bonus));
      }
    }

    return List<ActiveHealingBonus>.unmodifiable(result);
  }

  List<CharacterCounter> counters;

  /// Rango crítico base/personal del personaje.
  ///
  /// 20 = crítico únicamente con 20 natural.
  int criticalMinimumNaturalRoll;

  String shortRestRule;

  Character({
    required this.id,
    required this.name,
    this.avatarPath,
    this.campaignId,
    this.ownerType = 'player',
    this.race = '',

    /// Nuevo sistema.
    List<CharacterClassLevel>? classes,

    /// Compatibilidad temporal con código antiguo.
    DndClass? dndClass,
    int? level,

    AbilityScores? abilities,
    List<CharacterContentFolder>? contentFolders,
    int? currentHealth,
    this.customMaxHealth,
    this.armorClass = 10,
    this.speed = 30,
    this.backstory = '',
    this.personality = '',
    this.appearance = '',
    this.ideals = '',
    this.bonds = '',
    this.flaws = '',
    this.goals = '',
    this.storyNotes = '',
    Map<DndSkill, ProficiencyLevel>? skillProficiencies,
    Map<AbilityType, bool>? savingThrowProficiencies,
    List<Weapon>? weapons,
    List<CharacterAbility>? characterAbilities,
    List<CharacterPassive>? passives,
    List<JournalEntry>? journalEntries,
    List<DiceHistoryEntry>? diceHistory,
    List<CharacterItem>? items,
    List<ItemDefinition>? itemDefinitions,
    List<InventoryItem>? inventoryItems,
    List<CharacterResource>? resources,
    List<CharacterEffect>? effects,
    List<CharacterKnowledge>? knowledges,
    Map<String, int>? spellSlots,
    List<Pet>? pets, // <--- Parámetro en constructor
    this.combatActive = false,
    this.combatRound = 1,
    this.turnActive = false,
    this.combatTurnSequence = 0,
    List<CharacterCounter>? counters,
    this.criticalMinimumNaturalRoll = 20,
    this.shortRestRule = 'single',
  }) : classes = _resolveClasses(
         classes: classes,
         dndClass: dndClass,
         level: level,
       ),
       abilities = abilities ?? AbilityScores(),
       contentFolders = contentFolders ?? <CharacterContentFolder>[],
       skillProficiencies =
           skillProficiencies ??
           {for (final skill in DndSkill.values) skill: ProficiencyLevel.none},
       savingThrowProficiencies = savingThrowProficiencies ?? {},
       weapons = weapons ?? [],
       characterAbilities = characterAbilities ?? [],
       passives = passives ?? [],
       journalEntries = journalEntries ?? [],
       diceHistory = diceHistory ?? [],
       items = items ?? [],
       itemDefinitions = itemDefinitions ?? [],
       inventoryItems = inventoryItems ?? [],
       resources = resources ?? [],
       effects = effects ?? [],
       knowledges = List<CharacterKnowledge>.from(knowledges ?? []),
       spellSlots = Map<String, int>.from(spellSlots ?? {}),
       pets = List<Pet>.from(
         pets ?? const [],
       ), // <--- Inicialización de mascotas
       counters = List<CharacterCounter>.from(counters ?? []),
       currentHealth = currentHealth ?? -1 {
    /*
     * D&D:
     * Las competencias en salvaciones vienen de la clase
     * con la que empieza el personaje, no de cada clase
     * añadida después.
     */
    if (savingThrowProficiencies == null) {
      this.savingThrowProficiencies = {
        for (final ability in AbilityType.values)
          ability: primaryClass.savingThrowProficiencies.contains(ability),
      };
    }

    /*
     * -1 significa que el personaje todavía no tenía
     * vida actual guardada.
     *
     * 0 sí es un valor válido: personaje a 0 PG.
     */
    if (this.currentHealth == -1) {
      this.currentHealth = maxHealth;
    }

    normalizeHealth();
  }

  // ===========================================================================
  // GESTIÓN DE CONOCIMIENTOS Y LIBROS
  // ===========================================================================

  /// Comprueba si el personaje ya tiene registrado este conocimiento
  CharacterKnowledge? getKnowledge(String knowledgeId) {
    try {
      return knowledges.firstWhere((k) => k.knowledgeId == knowledgeId);
    } catch (_) {
      return null;
    }
  }

  /// Descubre o inicia el estudio de un conocimiento
  void discoverKnowledge(String knowledgeId) {
    if (getKnowledge(knowledgeId) != null) return;
    knowledges.add(
      CharacterKnowledge(
        knowledgeId: knowledgeId,
        status: KnowledgeStatus.discovered,
      ),
    );
  }

  /// Registra puntos de progreso sobre un conocimiento mediante tiradas de estudio.
  void studyKnowledge(String knowledgeId, int progress, int requiredProgress) {
    final entry = getKnowledge(knowledgeId);
    if (entry == null) {
      knowledges.add(
        CharacterKnowledge(
          knowledgeId: knowledgeId,
          status: progress >= requiredProgress
              ? KnowledgeStatus.mastered
              : KnowledgeStatus.studying,
          currentProgress: progress,
        ),
      );
      return;
    }

    entry.currentProgress += progress;
    if (entry.currentProgress >= requiredProgress) {
      entry.status = KnowledgeStatus.mastered;
    } else {
      entry.status = KnowledgeStatus.studying;
    }
  }

  // Carpetas exclusivas de Habilidades/Pasivas
  List<CharacterContentFolder> abilityFoldersInside(String? parentId) {
    return contentFolders
        .where((f) => !f.isItemFolder && f.parentId == parentId)
        .toList();
  }

  // Carpetas exclusivas de Objetos
  List<CharacterContentFolder> itemFoldersInside(String? parentId) {
    return contentFolders
        .where((f) => f.isItemFolder && f.parentId == parentId)
        .toList();
  }

  // Creación específica
  CharacterContentFolder createContentFolder({
    required String name,
    String? parentId,
    bool isItemFolder = false,
  }) {
    final folder = CharacterContentFolder(
      id: 'folder_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      parentId: parentId,
      isItemFolder: isItemFolder,
    );
    contentFolders.add(folder);
    return folder;
  }

  CharacterContentFolder? contentFolderById(String? folderId) {
    if (folderId == null || folderId.trim().isEmpty) {
      return null;
    }

    for (final folder in contentFolders) {
      if (folder.id == folderId) {
        return folder;
      }
    }

    return null;
  }

  void renameContentFolder(String folderId, String newName) {
    final folder = contentFolderById(folderId);

    if (folder == null) {
      return;
    }

    final normalizedName = newName.trim();

    if (normalizedName.isEmpty) {
      return;
    }

    folder.name = normalizedName;
  }

  void moveAbilityToFolder(CharacterAbility ability, String? folderId) {
    if (folderId != null && contentFolderById(folderId) == null) {
      throw StateError('La carpeta no existe.');
    }

    ability.folderId = folderId;
  }

  void movePassiveToFolder(CharacterPassive passive, String? folderId) {
    if (folderId != null && contentFolderById(folderId) == null) {
      throw StateError('La carpeta no existe.');
    }

    passive.folderId = folderId;
  }

  // ===========================================================================
  // CONTENIDO ORGANIZADO
  // ===========================================================================

  List<CharacterContentFolder> contentFoldersInside(String? parentId) {
    final result = contentFolders
        .where((folder) => folder.parentId == parentId)
        .toList(growable: false);

    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return result;
  }

  List<CharacterAbility> abilitiesInFolder(String? folderId) {
    return characterAbilities
        .where((ability) => ability.folderId == folderId)
        .toList(growable: false);
  }

  List<CharacterPassive> passivesInFolder(String? folderId) {
    return passives
        .where((passive) => passive.folderId == folderId)
        .toList(growable: false);
  }

  int directContentCountInFolder(String? folderId) {
    return abilitiesInFolder(folderId).length +
        passivesInFolder(folderId).length;
  }

  List<InventoryItem> itemsInFolder(String? folderId) {
    return inventoryItems
        .where((item) => item.folderId == folderId)
        .toList(growable: false);
  }

  int itemCountInFolder(String? folderId) {
    return itemsInFolder(folderId).length;
  }

  List<ItemDefinition> get equippedContentItems {
    final result = <ItemDefinition>[];

    for (final inventoryItem in equippedInventoryItems) {
      final definition = definitionForInventoryItem(inventoryItem);

      if (definition == null) {
        continue;
      }

      if (definition.abilities.isEmpty && definition.passives.isEmpty) {
        continue;
      }

      result.add(definition);
    }

    return List<ItemDefinition>.unmodifiable(result);
  }

  int itemContentCount(ItemDefinition item) {
    return item.abilities.length + item.passives.length;
  }

  bool contentFolderContains(String ancestorId, String descendantId) {
    String? currentId = descendantId;

    final visited = <String>{};

    while (currentId != null) {
      if (!visited.add(currentId)) {
        return false;
      }

      if (currentId == ancestorId) {
        return true;
      }

      currentId = contentFolderById(currentId)?.parentId;
    }

    return false;
  }

  void moveContentFolder(String folderId, String? newParentId) {
    final folder = contentFolderById(folderId);

    if (folder == null) {
      return;
    }

    if (folderId == newParentId) {
      throw StateError('Una carpeta no puede estar dentro de sí misma.');
    }

    if (newParentId != null) {
      final parent = contentFolderById(newParentId);

      if (parent == null) {
        throw StateError('La carpeta destino no existe.');
      }

      if (contentFolderContains(folderId, newParentId)) {
        throw StateError(
          'No puedes mover una carpeta dentro de una subcarpeta suya.',
        );
      }
    }

    folder.parentId = newParentId;
  }

  void removeContentFolder(String folderId) {
    final folder = contentFolderById(folderId);

    if (folder == null) {
      return;
    }

    final parentId = folder.parentId;

    for (final ability in characterAbilities) {
      if (ability.folderId == folderId) {
        ability.folderId = parentId;
      }
    }

    for (final passive in passives) {
      if (passive.folderId == folderId) {
        passive.folderId = parentId;
      }
    }

    for (final child in contentFolders) {
      if (child.parentId == folderId) {
        child.parentId = parentId;
      }
    }

    contentFolders.removeWhere((candidate) => candidate.id == folderId);
  }

  Map<String, double> _passiveTriggerContext(
    Map<String, double> eventVariables,
  ) {
    return <String, double>{
      'round': combatRound.toDouble(),
      'turn_active': turnActive ? 1 : 0,
      'turn_sequence': combatTurnSequence.toDouble(),
      ...eventVariables,
    };
  }

  void dispatchPassiveTrigger(
    PassiveTriggerEvent event, {
    Map<String, double> eventVariables = const {},
    ActionTriggerContext? actionContext,
  }) {
    final variables = _passiveTriggerContext(eventVariables);

    final passiveEngine = PassiveTriggerEngine(character: this);

    final effectEngine = CharacterEffectTriggerEngine(character: this);

    passiveEngine.dispatch(
      event,
      eventVariables: variables,
      actionContext: actionContext,
    );

    effectEngine.dispatch(
      event,
      eventVariables: variables,
      actionContext: actionContext,
    );
  }

  void refreshPassiveTriggers() {
    PassiveTriggerEngine(character: this).refreshPersistentTriggers();

    CharacterEffectTriggerEngine(character: this).refreshPersistentTriggers();
  }

  int evaluateFormulaBonus(FormulaBonus bonus, {CharacterPassive? passive}) {
    var result = bonus.flatValue;

    final formula = bonus.formula;

    if (formula == null ||
        formula.expression.trim().isEmpty ||
        formula.expression.trim() == '0') {
      return result;
    }

    final resolver = ResourceModifierResolver(character: this);

    final formulaResult = const FormulaEvaluator().evaluate(
      formula,
      context: CharacterFormulaContext.fromCharacter(
        this,
        passive: passive,

        resourceResolver: (resourceId) {
          final resource = resourceById(resourceId);

          if (resource == null) {
            return null;
          }

          final snapshot = resolver.resolveSnapshot(resource);

          return FormulaResourceValue(
            baseCurrentValue: snapshot.baseCurrentValue,
            baseMaxValue: snapshot.baseMaxValue,
            currentValue: snapshot.currentValue,
            maxValue: snapshot.maxValue,
          );
        },

        baseResourceResolver: (resourceId) {
          final resource = resourceById(resourceId);

          if (resource == null) {
            return null;
          }

          final baseMax = resource.hasMaximum
              ? resource.maxValue.toDouble()
              : null;

          return FormulaResourceValue(
            baseCurrentValue: resource.currentValue.toDouble(),
            baseMaxValue: baseMax,
            currentValue: resource.currentValue.toDouble(),
            maxValue: baseMax,
          );
        },
      ),
    );

    if (!formulaResult.valid) {
      return result;
    }

    result += formulaResult.value.round();

    return result;
  }

  // ===========================================================================
  // COMBATE · RONDAS / TURNOS
  // ===========================================================================

  void startCombat() {
    if (combatActive) return;

    combatActive = true;
    combatRound = 1;
    turnActive = false;

    dispatchPassiveTrigger(
      PassiveTriggerEvent.roundStarted,
      eventVariables: {'round': combatRound.toDouble(), 'turn_active': 0},
    );

    refreshPassiveTriggers();
  }

  void endCombat() {
    if (!combatActive) return;

    resetCombat();
    combatActive = false;
  }

  void startTurn() {
    if (!combatActive || turnActive) {
      return;
    }

    combatTurnSequence++;

    turnActive = true;

    dispatchPassiveTrigger(
      PassiveTriggerEvent.turnStarted,
      eventVariables: {
        'round': combatRound.toDouble(),
        'turn_active': 1,
        'turn_sequence': combatTurnSequence.toDouble(),
      },
    );
  }

  void endTurn() {
    if (!turnActive) {
      return;
    }

    dispatchPassiveTrigger(
      PassiveTriggerEvent.turnEnded,
      eventVariables: {'round': combatRound.toDouble(), 'turn_active': 1},
    );

    turnActive = false;

    advanceTurnEffects();
  }

  void startNextRound() {
    if (!combatActive) {
      return;
    }

    if (turnActive) {
      dispatchPassiveTrigger(
        PassiveTriggerEvent.turnEnded,
        eventVariables: {'round': combatRound.toDouble(), 'turn_active': 1},
      );

      turnActive = false;

      advanceTurnEffects();
    }

    dispatchPassiveTrigger(
      PassiveTriggerEvent.roundEnded,
      eventVariables: {'round': combatRound.toDouble(), 'turn_active': 0},
    );

    advanceRoundEffects();

    combatRound++;

    dispatchPassiveTrigger(
      PassiveTriggerEvent.roundStarted,
      eventVariables: {'round': combatRound.toDouble(), 'turn_active': 0},
    );
  }

  void resetCombat() {
    if (turnActive) {
      dispatchPassiveTrigger(
        PassiveTriggerEvent.turnEnded,
        eventVariables: {'round': combatRound.toDouble(), 'turn_active': 1},
      );

      turnActive = false;
    }

    dispatchPassiveTrigger(
      PassiveTriggerEvent.roundEnded,
      eventVariables: {'round': combatRound.toDouble(), 'turn_active': 0},
    );

    combatRound = 1;

    refreshPassiveTriggers();
  }

  String get combatStatusText {
    return 'Ronda $combatRound · '
        '${turnActive ? 'Turno activo' : 'Esperando turno'}';
  }

  void setHealth(int value, {bool dispatchTriggers = true}) {
    final before = currentHealth;

    currentHealth = value;

    normalizeHealth();

    final after = currentHealth;

    if (!dispatchTriggers || before == after) {
      return;
    }

    _dispatchHealthChange(before, after);
  }

  void setPassiveEnabled(CharacterPassive passive, bool enabled) {
    if (passive.enabled == enabled) {
      return;
    }

    passive.enabled = enabled;

    final engine = PassiveTriggerEngine(character: this);

    if (!enabled) {
      engine.removeRuntimeEffectsForPassive(passive.id, refreshTriggers: false);
    }

    normalizeHealth();

    refreshPassiveTriggers();
  }

  // ===========================================================================
  // RECURSOS · MODIFICACIÓN CENTRALIZADA
  // ===========================================================================

  void addResourceValue(
    String resourceId,
    int amount, {
    bool dispatchTriggers = true,
  }) {
    if (amount == 0) {
      return;
    }

    final resource = resourceById(resourceId);

    if (resource == null) {
      return;
    }

    setResourceValue(
      resourceId,
      resource.currentValue + amount,
      dispatchTriggers: dispatchTriggers,
    );
  }

  void subtractResourceValue(
    String resourceId,
    int amount, {
    bool dispatchTriggers = true,
  }) {
    if (amount <= 0) {
      return;
    }

    final resource = resourceById(resourceId);

    if (resource == null) {
      return;
    }

    setResourceValue(
      resourceId,
      resource.currentValue - amount,
      dispatchTriggers: dispatchTriggers,
    );
  }

  void setResourceValue(
    String resourceId,
    int value, {
    bool dispatchTriggers = true,
  }) {
    final resource = resourceById(resourceId);

    if (resource == null) {
      return;
    }

    final previousValue = resource.currentValue;

    resource.currentValue = value;

    normalizeResource(resource);

    final currentValue = resource.currentValue;

    if (!dispatchTriggers || previousValue == currentValue) {
      return;
    }

    dispatchPassiveTrigger(
      PassiveTriggerEvent.resourceChanged,
      eventVariables: {
        'previous_resource': previousValue.toDouble(),

        'current_resource': currentValue.toDouble(),

        'resource_change': (currentValue - previousValue).toDouble(),

        'resource_${resource.id}': 1,

        'resource_spent': currentValue < previousValue ? 1 : 0,

        'resource_gained': currentValue > previousValue ? 1 : 0,
      },
    );

    refreshPassiveTriggers();
  }

  void restoreResourceFull(String resourceId, {bool dispatchTriggers = true}) {
    final resource = resourceById(resourceId);

    if (resource == null || !resource.hasMaximum) {
      return;
    }

    final effectiveMax = resourceEffectiveMax(resource);

    if (effectiveMax == null) {
      return;
    }

    setResourceValue(
      resourceId,
      effectiveMax,
      dispatchTriggers: dispatchTriggers,
    );
  }

  List<int> criticalMinimumRollSourcesForAbility(CharacterAbility ability) {
    return [...criticalMinimumRollSources, ability.criticalMinimumNaturalRoll];
  }

  List<int> criticalMinimumRollSourcesForWeapon(Weapon weapon) {
    return [...criticalMinimumRollSources, weapon.criticalMinimumNaturalRoll];
  }

  bool empoweredCriticalForWeapon(Weapon weapon) {
    if (weapon.empoweredCritical) {
      return true;
    }

    for (final passive in enabledPassives) {
      if (passive.empoweredCritical) {
        return true;
      }
    }

    for (final effect in enabledEffects) {
      if (effect.empoweredCritical) {
        return true;
      }
    }

    return false;
  }

  // ===========================================================================
  // COMPATIBILIDAD / CLASES
  // ===========================================================================

  static List<CharacterClassLevel> _resolveClasses({
    List<CharacterClassLevel>? classes,
    DndClass? dndClass,
    int? level,
  }) {
    if (classes != null && classes.isNotEmpty) {
      return classes;
    }

    return [
      CharacterClassLevel(
        dndClass: dndClass ?? DndClass.fighter,
        level: (level ?? 1) < 1 ? 1 : level ?? 1,
      ),
    ];
  }

  int get level {
    if (classes.isEmpty) {
      return 1;
    }

    return classes.fold<int>(0, (sum, item) => sum + item.level);
  }

  set level(int value) {
    final safeValue = value < 1 ? 1 : value;

    if (classes.isEmpty) {
      classes.add(
        CharacterClassLevel(dndClass: DndClass.fighter, level: safeValue),
      );

      _refreshAfterCharacterStructureChange();

      return;
    }

    if (classes.length == 1) {
      if (classes.first.level == safeValue) {
        return;
      }

      classes.first.level = safeValue;

      _refreshAfterCharacterStructureChange();

      return;
    }

    final secondaryLevels = classes
        .skip(1)
        .fold<int>(0, (sum, item) => sum + item.level);

    final primaryLevel = safeValue - secondaryLevels;

    final finalLevel = primaryLevel < 1 ? 1 : primaryLevel;

    if (classes.first.level == finalLevel) {
      return;
    }

    classes.first.level = finalLevel;

    _refreshAfterCharacterStructureChange();
  }

  DndClass get primaryClass {
    if (classes.isEmpty) {
      return DndClass.fighter;
    }

    return classes.first.dndClass;
  }

  DndClass get dndClass => primaryClass;

  set dndClass(DndClass value) {
    if (classes.isEmpty) {
      classes.add(CharacterClassLevel(dndClass: value, level: 1));

      return;
    }

    classes.first.dndClass = value;
  }

  bool get isMulticlass => classes.length > 1;

  String get classSummary {
    if (classes.isEmpty) {
      return 'Sin clase';
    }

    return classes
        .map((item) => '${item.dndClass.label} ${item.level}')
        .join(' / ');
  }

  void _refreshAfterCharacterStructureChange() {
    normalizeHealthWithTriggers();

    for (final resource in resources) {
      normalizeResourceWithTriggers(resource, dispatchTriggers: true);
    }

    refreshPassiveTriggers();
  }

  void addClass(DndClass dndClass, {int level = 1}) {
    final safeLevel = level < 1 ? 1 : level;

    final existing = classes.indexWhere((item) => item.dndClass == dndClass);

    if (existing >= 0) {
      classes[existing].level += safeLevel;

      _refreshAfterCharacterStructureChange();

      return;
    }

    classes.add(CharacterClassLevel(dndClass: dndClass, level: safeLevel));

    _refreshAfterCharacterStructureChange();
  }

  void removeClass(DndClass dndClass) {
    if (classes.length <= 1) {
      return;
    }

    final previousLength = classes.length;

    classes.removeWhere((item) => item.dndClass == dndClass);

    if (classes.length == previousLength) {
      return;
    }

    _refreshAfterCharacterStructureChange();
  }

  void setClassLevel(DndClass dndClass, int newLevel) {
    final index = classes.indexWhere((item) => item.dndClass == dndClass);

    if (index < 0) {
      return;
    }

    final safeLevel = newLevel < 1 ? 1 : newLevel;

    if (classes[index].level == safeLevel) {
      return;
    }

    classes[index].level = safeLevel;

    _refreshAfterCharacterStructureChange();
  }

  // ===========================================================================
  // RECURSOS PERSONALIZADOS
  // ===========================================================================

  void normalizeResourceWithTriggers(
    CharacterResource resource, {
    bool dispatchTriggers = true,
  }) {
    final before = resource.currentValue;

    normalizeResource(resource);

    final after = resource.currentValue;

    if (!dispatchTriggers || before == after) {
      return;
    }

    dispatchPassiveTrigger(
      PassiveTriggerEvent.resourceChanged,
      eventVariables: {
        'previous_resource': before.toDouble(),
        'current_resource': after.toDouble(),
        'resource_change': (after - before).toDouble(),

        'resource_${resource.id}': 1,

        'resource_spent': after < before ? 1 : 0,
        'resource_gained': after > before ? 1 : 0,
      },
    );

    refreshPassiveTriggers();
  }

  void addResource(CharacterResource resource, {bool refreshTriggers = true}) {
    resource.normalize();

    resources.add(resource);

    normalizeResource(resource);

    if (refreshTriggers) {
      refreshPassiveTriggers();
    }
  }

  void removeResource(String resourceId, {bool refreshTriggers = true}) {
    final previousLength = resources.length;

    resources.removeWhere((resource) => resource.id == resourceId);

    if (resources.length == previousLength) {
      return;
    }

    if (refreshTriggers) {
      refreshPassiveTriggers();
    }
  }

  CharacterResource? resourceById(String id) {
    for (final resource in resources) {
      if (resource.id == id) {
        return resource;
      }
    }

    return null;
  }

  int? effectiveResourceCurrentById(String resourceId) {
    final resource = resourceById(resourceId);

    if (resource == null) {
      return null;
    }

    return resourceEffectiveCurrent(resource);
  }

  int? effectiveResourceMaxById(String resourceId) {
    final resource = resourceById(resourceId);

    if (resource == null || !resource.hasMaximum) {
      return null;
    }

    return resourceEffectiveMax(resource);
  }

  CharacterResource? resourceForAbility(CharacterAbility ability) {
    final resourceId = ability.resourceId;

    if (resourceId == null || resourceId.isEmpty) {
      return null;
    }

    return resourceById(resourceId);
  }

  bool canSpendResource(String resourceId, int amount) {
    if (amount <= 0) {
      return true;
    }

    final resource = resourceById(resourceId);

    if (resource == null) {
      return false;
    }

    if (!resource.spendable) {
      return false;
    }

    return resource.currentValue >= amount;
  }

  bool spendResource(
    String resourceId,
    int amount, {
    bool dispatchTriggers = true,
  }) {
    if (!canSpendResource(resourceId, amount)) {
      return false;
    }

    if (amount <= 0) {
      return true;
    }

    subtractResourceValue(
      resourceId,
      amount,
      dispatchTriggers: dispatchTriggers,
    );

    return true;
  }

  bool canPayAbilityResource(CharacterAbility ability) {
    if (!ability.usesResource) {
      return true;
    }

    final resourceId = ability.resourceId;

    if (resourceId == null || resourceId.isEmpty) {
      return false;
    }

    return canSpendResource(resourceId, ability.resourceCost);
  }

  bool payAbilityResource(
    CharacterAbility ability, {
    bool dispatchTriggers = true,
  }) {
    if (!ability.usesResource) {
      return true;
    }

    final resourceId = ability.resourceId;

    if (resourceId == null || resourceId.isEmpty) {
      return false;
    }

    return spendResource(
      resourceId,
      ability.resourceCost,
      dispatchTriggers: dispatchTriggers,
    );
  }

  void updateResource(
    CharacterResource resource, {
    bool refreshTriggers = true,
  }) {
    final index = resources.indexWhere((item) => item.id == resource.id);

    if (index < 0) {
      return;
    }

    resource.normalize();

    resources[index] = resource;

    normalizeResource(resource);

    if (refreshTriggers) {
      refreshPassiveTriggers();
    }
  }

  void consumeResource(
    CharacterResource resource,
    int amount, {
    bool dispatchTriggers = true,
  }) {
    spendResource(resource.id, amount, dispatchTriggers: dispatchTriggers);
  }

  void restoreResource(
    CharacterResource resource,
    int amount, {
    bool dispatchTriggers = true,
  }) {
    if (amount <= 0) {
      return;
    }

    addResourceValue(resource.id, amount, dispatchTriggers: dispatchTriggers);
  }

  void normalizeResource(CharacterResource resource) {
    if (resource.currentValue < 0) {
      resource.currentValue = 0;
    }

    if (!resource.hasMaximum) {
      return;
    }

    final effectiveMax = resourceEffectiveMax(resource);

    if (effectiveMax == null) {
      return;
    }

    if (resource.currentValue > effectiveMax) {
      resource.currentValue = effectiveMax;
    }
  }

  // ===========================================================================
  // CARGAS DE PASIVAS
  // ===========================================================================

  void addPassiveCharges(
    String passiveId,
    int amount, {
    bool dispatchTriggers = true,
  }) {
    if (amount == 0) {
      return;
    }

    final passive = passiveById(passiveId);

    if (passive == null || !passive.hasCharges) {
      return;
    }

    setPassiveCharges(
      passiveId,
      passive.currentCharges + amount,
      dispatchTriggers: dispatchTriggers,
    );
  }

  void subtractPassiveCharges(
    String passiveId,
    int amount, {
    bool dispatchTriggers = true,
  }) {
    if (amount <= 0) {
      return;
    }

    final passive = passiveById(passiveId);

    if (passive == null || !passive.hasCharges) {
      return;
    }

    setPassiveCharges(
      passiveId,
      passive.currentCharges - amount,
      dispatchTriggers: dispatchTriggers,
    );
  }

  bool canSpendPassiveCharges(String passiveId, int amount) {
    if (amount <= 0) {
      return true;
    }

    final passive = passiveById(passiveId);

    if (passive == null || !passive.hasCharges) {
      return false;
    }

    return passive.currentCharges >= amount;
  }

  bool spendPassiveCharges(
    String passiveId,
    int amount, {
    bool dispatchTriggers = true,
  }) {
    if (!canSpendPassiveCharges(passiveId, amount)) {
      return false;
    }

    if (amount <= 0) {
      return true;
    }

    subtractPassiveCharges(
      passiveId,
      amount,
      dispatchTriggers: dispatchTriggers,
    );

    return true;
  }

  void setPassiveCharges(
    String passiveId,
    int value, {
    bool dispatchTriggers = true,
  }) {
    final passive = passiveById(passiveId);

    if (passive == null || !passive.hasCharges) {
      return;
    }

    final previousValue = passive.currentCharges;

    passive.currentCharges = value;

    passive.normalizeCharges();

    final currentValue = passive.currentCharges;

    if (!dispatchTriggers || previousValue == currentValue) {
      return;
    }

    dispatchPassiveTrigger(
      PassiveTriggerEvent.chargeChanged,
      eventVariables: {
        'previous_charges': previousValue.toDouble(),
        'current_charges': currentValue.toDouble(),
        'charges_change': (currentValue - previousValue).toDouble(),

        'passive_${passive.id}': 1,

        'charge_spent': currentValue < previousValue ? 1 : 0,

        'charge_gained': currentValue > previousValue ? 1 : 0,
      },
    );

    refreshPassiveTriggers();
  }

  CharacterPassive? passiveById(String passiveId) {
    for (final passive in passives) {
      if (passive.id == passiveId) {
        return passive;
      }
    }

    for (final inventoryItem in equippedInventoryItems) {
      final definition = definitionForInventoryItem(inventoryItem);

      if (definition == null) {
        continue;
      }

      for (final passive in definition.passives) {
        if (passive.id == passiveId) {
          return passive;
        }
      }
    }

    return null;
  }

  // ===========================================================================
  // EFECTOS ACTIVOS
  // ===========================================================================

  Iterable<CharacterEffect> get enabledEffects {
    return effects.where((effect) => effect.enabled && !effect.expired);
  }

  void addEffect(
    CharacterEffect effect, {
    bool refreshTriggers = true,
    bool dispatchHealthTriggers = true,
  }) {
    effect.normalizeDuration();

    effects.add(effect);

    if (dispatchHealthTriggers) {
      normalizeHealthWithTriggers();
    } else {
      normalizeHealth();
    }

    if (refreshTriggers) {
      refreshPassiveTriggers();
    }
  }

  void applyReceivedEffect(
    CharacterEffect effect, {
    String? templateId,
    bool refreshTriggers = true,
    bool dispatchHealthTriggers = true,
    Map<String, double> eventVariables = const {},
  }) {
    final effectiveTemplateId = templateId?.trim() ?? '';

    addEffect(
      effect,
      refreshTriggers: false,
      dispatchHealthTriggers: dispatchHealthTriggers,
    );

    dispatchPassiveTrigger(
      PassiveTriggerEvent.effectReceived,
      eventVariables: {
        ...eventVariables,

        'effect_received': 1,
        'effect_applied': 1,

        if (effectiveTemplateId.isNotEmpty) 'effect_$effectiveTemplateId': 1,
      },
    );

    if (refreshTriggers) {
      refreshPassiveTriggers();
    }
  }

  void removeEffect(
    String effectId, {
    bool refreshTriggers = true,
    bool dispatchHealthTriggers = true,
  }) {
    final previousLength = effects.length;

    effects.removeWhere((effect) => effect.id == effectId);

    if (effects.length == previousLength) {
      return;
    }

    if (dispatchHealthTriggers) {
      normalizeHealthWithTriggers();
    } else {
      normalizeHealth();
    }

    if (refreshTriggers) {
      refreshPassiveTriggers();
    }
  }

  void updateEffect(
    CharacterEffect effect, {
    bool refreshTriggers = true,
    bool dispatchHealthTriggers = true,
  }) {
    final index = effects.indexWhere((item) => item.id == effect.id);

    if (index < 0) {
      return;
    }

    effect.normalizeDuration();

    effects[index] = effect;

    if (dispatchHealthTriggers) {
      normalizeHealthWithTriggers();
    } else {
      normalizeHealth();
    }

    if (refreshTriggers) {
      refreshPassiveTriggers();
    }
  }

  CharacterEffect? effectById(String id) {
    for (final effect in effects) {
      if (effect.id == id) {
        return effect;
      }
    }

    return null;
  }

  void advanceTurnEffects() {
    for (final effect in effects) {
      effect.advanceTurn();
    }

    _cleanupExpiredEffects();

    normalizeHealth();

    refreshPassiveTriggers();
  }

  void advanceRoundEffects() {
    for (final effect in effects) {
      effect.advanceRound();
    }

    _cleanupExpiredEffects();

    normalizeHealth();

    refreshPassiveTriggers();
  }

  void _cleanupExpiredEffects() {
    effects.removeWhere((effect) => effect.hasDuration && effect.isExpired);
  }

  // ===========================================================================
  // ATRIBUTOS / STATS / MODIFICADORES
  // ===========================================================================

  void setAbilityScore(AbilityType ability, int value) {
    final safeValue = value < 1 ? 1 : value;

    final previous = abilities.valueByType(ability);

    if (previous == safeValue) {
      return;
    }

    abilities.setValueByType(ability, safeValue);

    _refreshAfterCharacterStructureChange();
  }

  int baseAbilityScore(AbilityType ability) {
    return abilities.valueByType(ability);
  }

  int passiveAbilityScoreBonus(AbilityType ability) {
    var total = 0;

    for (final passive in enabledPassives) {
      final bonus = passive.abilityScoreBonuses[ability];

      if (bonus == null || !bonus.hasValue) {
        continue;
      }

      total += evaluateFormulaBonus(bonus, passive: passive);
    }

    return total;
  }

  int abilityScore(AbilityType ability) {
    return baseAbilityScore(ability) + passiveAbilityScoreBonus(ability);
  }

  int baseAbilityModifier(AbilityType ability) {
    return AbilityScores.modifierFor(baseAbilityScore(ability));
  }

  int passiveAbilityModifierBonus(AbilityType ability) {
    var total = 0;

    for (final passive in enabledPassives) {
      final bonus = passive.abilityModifierBonuses[ability];

      if (bonus == null || !bonus.hasValue) {
        continue;
      }

      total += evaluateFormulaBonus(bonus, passive: passive);
    }

    return total;
  }

  int effectAbilityModifierBonus(AbilityType ability) {
    return enabledEffects.fold<int>(
      0,
      (sum, effect) => sum + (effect.abilityModifierBonuses[ability] ?? 0),
    );
  }

  int abilityModifier(AbilityType ability) {
    final effectiveScore = abilityScore(ability);

    final naturalModifier = AbilityScores.modifierFor(effectiveScore);

    return naturalModifier +
        passiveAbilityModifierBonus(ability) +
        effectAbilityModifierBonus(ability);
  }

  int get strengthScore => abilityScore(AbilityType.strength);

  int get dexterityScore => abilityScore(AbilityType.dexterity);

  int get constitutionScore => abilityScore(AbilityType.constitution);

  int get intelligenceScore => abilityScore(AbilityType.intelligence);

  int get wisdomScore => abilityScore(AbilityType.wisdom);

  int get charismaScore => abilityScore(AbilityType.charisma);

  int get strengthModifier => abilityModifier(AbilityType.strength);

  int get dexterityModifier => abilityModifier(AbilityType.dexterity);

  int get constitutionModifier => abilityModifier(AbilityType.constitution);

  int get intelligenceModifier => abilityModifier(AbilityType.intelligence);

  int get wisdomModifier => abilityModifier(AbilityType.wisdom);

  int get charismaModifier => abilityModifier(AbilityType.charisma);

  // ===========================================================================
  // COMPETENCIA
  // ===========================================================================

  int get proficiencyBonus {
    final safeLevel = level < 1 ? 1 : level;

    return 2 + ((safeLevel - 1) ~/ 4);
  }

  // ===========================================================================
  // COMBATE
  // ===========================================================================

  int get initiative =>
      dexterityModifier + passiveInitiativeBonus + effectInitiativeBonus;

  int get effectInitiativeBonus {
    return enabledEffects.fold<int>(
      0,
      (sum, effect) => sum + effect.initiativeBonus,
    );
  }

  int get calculatedArmorClass {
    final armorItem = equippedArmor;

    if (armorItem == null || armorItem.armor == null) {
      return 10 + dexterityModifier + totalArmorClassBonus;
    }

    final armor = armorItem.armor!;

    switch (armor.category) {
      case ArmorCategory.light:
        return armor.baseArmorClass + dexterityModifier + totalArmorClassBonus;

      case ArmorCategory.medium:
        final dexBonus = dexterityModifier > 2 ? 2 : dexterityModifier;
        return armor.baseArmorClass + dexBonus + totalArmorClassBonus;

      case ArmorCategory.heavy:
        return armor.baseArmorClass + totalArmorClassBonus;

      case ArmorCategory.shield:
        return armor.baseArmorClass + totalArmorClassBonus;

      case ArmorCategory.custom:
        final formulaStr = armor.customFormula?.trim();
        if (formulaStr != null && formulaStr.isNotEmpty) {
          try {
            final resolver = ResourceModifierResolver(character: this);
            final formulaResult = const FormulaEvaluator().evaluate(
              CharacterFormula(expression: formulaStr),
              context: CharacterFormulaContext.fromCharacter(
                this,
                resourceResolver: (resourceId) {
                  final resource = resourceById(resourceId);
                  if (resource == null) return null;
                  final snapshot = resolver.resolveSnapshot(resource);
                  return FormulaResourceValue(
                    baseCurrentValue: snapshot.baseCurrentValue,
                    baseMaxValue: snapshot.baseMaxValue,
                    currentValue: snapshot.currentValue,
                    maxValue: snapshot.maxValue,
                  );
                },
                baseResourceResolver: (resourceId) {
                  final resource = resourceById(resourceId);
                  if (resource == null) return null;
                  final baseMax = resource.hasMaximum
                      ? resource.maxValue.toDouble()
                      : null;
                  return FormulaResourceValue(
                    baseCurrentValue: resource.currentValue.toDouble(),
                    baseMaxValue: baseMax,
                    currentValue: resource.currentValue.toDouble(),
                    maxValue: baseMax,
                  );
                },
              ),
            );

            if (formulaResult.valid) {
              return formulaResult.value.round() + totalArmorClassBonus;
            }
          } catch (_) {
            return armor.baseArmorClass + totalArmorClassBonus;
          }
        }
        return armor.baseArmorClass + totalArmorClassBonus;
    }
  }

  int get effectArmorClassBonus {
    return enabledEffects.fold<int>(
      0,
      (sum, effect) => sum + effect.armorClassBonus,
    );
  }

  int get totalArmorClassBonus {
    return passiveArmorClassBonus + effectArmorClassBonus;
  }

  int get totalSpeed => speed + passiveSpeedBonus + effectSpeedBonus;

  int get effectSpeedBonus {
    return enabledEffects.fold<int>(
      0,
      (sum, effect) => sum + effect.speedBonus,
    );
  }

  int get hitDie => primaryClass.hitDie;

  String get hitDiceText {
    if (classes.isEmpty) {
      return '';
    }

    return classes
        .map((item) => '${item.level}d${item.dndClass.hitDie}')
        .join(' + ');
  }

  int calculateAbilityMultipliers(Map<AbilityType, int> multipliers) {
    int result = 0;

    for (final entry in multipliers.entries) {
      result += abilityModifier(entry.key) * entry.value;
    }

    return result;
  }

  int damageBonusModifier(
    DamageBonus bonus, {
    CharacterPassive? passive,
    FormulaContext? formulaContext,
  }) {
    var result =
        bonus.flatBonus +
        calculateAbilityMultipliers(bonus.abilityModifierMultipliers);

    final formula = bonus.formula;

    if (formula != null) {
      final context =
          formulaContext ??
          CharacterFormulaContext.fromCharacter(
            this,
            passive: passive,
            resourceResolver: (resourceId) {
              final resource = resourceById(resourceId);

              if (resource == null) {
                return null;
              }

              final resolver = ResourceModifierResolver(character: this);

              final snapshot = resolver.resolveSnapshot(resource);

              return FormulaResourceValue(
                baseCurrentValue: snapshot.baseCurrentValue,
                baseMaxValue: snapshot.baseMaxValue,
                currentValue: snapshot.currentValue,
                maxValue: snapshot.maxValue,
              );
            },
            baseResourceResolver: (resourceId) {
              final resource = resourceById(resourceId);

              if (resource == null) {
                return null;
              }

              final baseMax = resource.hasMaximum
                  ? resource.maxValue.toDouble()
                  : null;

              return FormulaResourceValue(
                baseCurrentValue: resource.currentValue.toDouble(),
                baseMaxValue: baseMax,
                currentValue: resource.currentValue.toDouble(),
                maxValue: baseMax,
              );
            },
          );

      final formulaResult = const FormulaEvaluator().evaluate(
        formula,
        context: context,
      );

      if (formulaResult.valid) {
        result += formulaResult.value.round();
      }
    }

    return result;
  }

  bool empoweredCriticalForAbility(CharacterAbility ability) {
    if (ability.empoweredCritical) {
      return true;
    }

    for (final passive in enabledPassives) {
      if (passive.empoweredCritical) {
        return true;
      }
    }

    for (final effect in enabledEffects) {
      if (effect.empoweredCritical) {
        return true;
      }
    }

    return false;
  }

  // ===========================================================================
  // PUNTOS DE VIDA
  // ===========================================================================

  int get baseMaxHealth {
    if (classes.isEmpty) {
      return 1;
    }

    final conMod = baseAbilityModifier(AbilityType.constitution);

    int total = 0;

    for (final classLevel in classes) {
      final levels = classLevel.level < 1 ? 1 : classLevel.level;

      final hitDie = classLevel.dndClass.hitDie;

      final healthPerLevel = hitDie + conMod;

      final safeHealthPerLevel = healthPerLevel < 1 ? 1 : healthPerLevel;

      total += safeHealthPerLevel * levels;
    }

    return total < 1 ? 1 : total;
  }

  int get maxHealth {
    if (customMaxHealth != null) {
      return customMaxHealth! < 1 ? 1 : customMaxHealth!;
    }
    final total = baseMaxHealth + passiveMaxHealthBonus + effectMaxHealthBonus;

    return total < 1 ? 1 : total;
  }

  double get healthPercentage {
    if (maxHealth <= 0) {
      return 0;
    }

    return (currentHealth / maxHealth).clamp(0.0, 1.0);
  }

  double get healthPercentage100 {
    return healthPercentage * 100;
  }

  int get effectMaxHealthBonus {
    return enabledEffects.fold<int>(
      0,
      (sum, effect) => sum + effect.maxHealthBonus,
    );
  }

  void normalizeHealth() {
    if (currentHealth > maxHealth) {
      currentHealth = maxHealth;
    }

    if (currentHealth < 0) {
      currentHealth = 0;
    }
  }

  void normalizeHealthWithTriggers({bool dispatchTriggers = true}) {
    final before = currentHealth;

    normalizeHealth();

    final after = currentHealth;

    if (!dispatchTriggers || before == after) {
      return;
    }

    _dispatchHealthChange(before, after);
  }

  void _dispatchHealthChange(int before, int after) {
    if (before == after) {
      return;
    }

    final change = after - before;

    final variables = <String, double>{
      'health_before': before.toDouble(),
      'health_after': after.toDouble(),
      'health_change': change.toDouble(),
    };

    if (change < 0) {
      dispatchPassiveTrigger(
        PassiveTriggerEvent.damageReceived,
        eventVariables: {...variables, 'damage': (-change).toDouble()},
      );
    } else {
      dispatchPassiveTrigger(
        PassiveTriggerEvent.healingReceived,
        eventVariables: {...variables, 'healing': change.toDouble()},
      );
    }

    dispatchPassiveTrigger(
      PassiveTriggerEvent.healthChanged,
      eventVariables: variables,
    );

    if (before > 0 && after <= 0) {
      dispatchPassiveTrigger(
        PassiveTriggerEvent.characterDied,
        eventVariables: {
          ...variables,
          'damage': change < 0 ? (-change).toDouble() : 0,
          'death': 1,
        },
      );
    }

    refreshPassiveTriggers();
  }

  void heal(int amount, {bool dispatchTriggers = true}) {
    if (amount <= 0) {
      return;
    }

    setHealth(currentHealth + amount, dispatchTriggers: dispatchTriggers);
  }

  void takeDamage(int amount, {bool dispatchTriggers = true}) {
    if (amount <= 0) {
      return;
    }

    int totalMitigation = 0;
    for (final passive in enabledPassives) {
      if (!passive.enabled) continue;
      for (final trigger in passive.triggers) {
        for (final action in trigger.actions) {
          if (action.type == PassiveTriggerActionType.mitigateDamage) {
            final value = action.valueFormula != null ? 0 : 0;
            totalMitigation += value;
          }
        }
      }
    }

    final int netDamage = math.max(0, amount - totalMitigation);

    if (netDamage <= 0) {
      return;
    }

    setHealth(currentHealth - netDamage, dispatchTriggers: dispatchTriggers);
  }

  void fullHeal({bool dispatchTriggers = true}) {
    final missingHealth = maxHealth - currentHealth;

    if (missingHealth <= 0) {
      return;
    }

    heal(missingHealth, dispatchTriggers: dispatchTriggers);
  }

  List<EquipmentSlotDefinition> equipmentSlots = [];

  void updateSlotCapacity(String slotId, int newMax) {
    final index = equipmentSlots.indexWhere((s) => s.id == slotId);
    if (index >= 0 && newMax >= 0) {
      equipmentSlots[index] = equipmentSlots[index].copyWith(
        maxEquipped: newMax,
      );

      final equippedInSlot = inventoryItems
          .where((item) => item.equipped && item.equippedSlotId == slotId)
          .toList();

      while (equippedInSlot.length > newMax) {
        final excess = equippedInSlot.removeLast();
        unequipInventoryItem(excess);
      }
    }
  }

  // ===========================================================================
  // CALCULADORA DE OBJETOS
  // ===========================================================================

  int maxCalculableQuantity(ItemDefinition target) {
    if (!target.calculable || target.calculationCosts.isEmpty) {
      return 0;
    }

    int? maximum;

    for (final cost in target.calculationCosts) {
      if (cost.itemId.trim().isEmpty || cost.quantityPerUnit <= 0) {
        return 0;
      }

      final available = inventoryQuantityById(cost.itemId);
      final possible = available ~/ cost.quantityPerUnit;

      if (maximum == null || possible < maximum) {
        maximum = possible;
      }
    }

    return maximum ?? 0;
  }

  int inventoryQuantityById(String itemId) {
    var total = 0;
    for (final item in inventoryItems) {
      if (item.itemId == itemId) {
        total += item.quantity;
      }
    }
    return total;
  }

  bool canCalculateItem(ItemDefinition target, int amount) {
    if (amount <= 0) return false;
    if (!target.calculable || target.calculationCosts.isEmpty) return false;

    for (final cost in target.calculationCosts) {
      if (cost.quantityPerUnit <= 0) return false;
      final required = cost.quantityPerUnit * amount;
      if (inventoryQuantityById(cost.itemId) < required) {
        return false;
      }
    }

    return true;
  }

  bool payCalculatedItem(ItemDefinition target, int amount) {
    if (!canCalculateItem(target, amount)) return false;

    for (final cost in target.calculationCosts) {
      var remaining = cost.quantityPerUnit * amount;

      for (var i = inventoryItems.length - 1; i >= 0 && remaining > 0; i--) {
        final item = inventoryItems[i];
        if (item.itemId != cost.itemId) continue;

        final consumed = min(item.quantity, remaining);
        item.quantity -= consumed;
        remaining -= consumed;

        if (item.quantity <= 0) {
          inventoryItems.removeAt(i);
        }
      }
    }

    return true;
  }

  ItemDefinition? itemForPassive(CharacterPassive passive) {
    for (final inventoryItem in inventoryItems) {
      final definition = definitionForInventoryItem(inventoryItem);

      if (definition == null) {
        continue;
      }

      final containsPassive = definition.passives.any(
        (itemPassive) => itemPassive.id == passive.id,
      );

      if (containsPassive) {
        return definition;
      }
    }

    return null;
  }

  ItemDefinition? itemForAbility(CharacterAbility ability) {
    for (final inventoryItem in inventoryItems) {
      final definition = definitionForInventoryItem(inventoryItem);

      if (definition == null) {
        continue;
      }

      final containsAbility = definition.abilities.any(
        (itemAbility) => itemAbility.id == ability.id,
      );

      if (containsAbility) {
        return definition;
      }
    }

    return null;
  }

  ItemDefinition? itemDefinitionById(String itemId) {
    final normalized = itemId.trim();

    if (normalized.isEmpty) {
      return null;
    }

    for (final definition in itemDefinitions) {
      if (definition.id == normalized) {
        return definition;
      }
    }

    return null;
  }

  InventoryItem? inventoryItemById(String inventoryId) {
    final normalized = inventoryId.trim();

    if (normalized.isEmpty) {
      return null;
    }

    for (final item in inventoryItems) {
      if (item.id == normalized) {
        return item;
      }
    }

    return null;
  }

  ItemDefinition? definitionForInventoryItem(InventoryItem item) {
    return itemDefinitionById(item.itemId);
  }

  List<InventoryItem> get equippedInventoryItems {
    return inventoryItems
        .where((item) => item.equipped)
        .toList(growable: false);
  }

  void registerItemDefinition(ItemDefinition definition) {
    final index = itemDefinitions.indexWhere(
      (current) => current.id == definition.id,
    );

    final copy = ItemDefinition.fromMap(definition.toMap());

    if (index < 0) {
      itemDefinitions.add(copy);
      return;
    }

    itemDefinitions[index] = copy;
  }

  void addInventoryItem({
    required ItemDefinition definition,
    int quantity = 1,
  }) {
    registerItemDefinition(definition);

    final safeQuantity = quantity < 1 ? 1 : quantity;

    if (definition.stackable) {
      for (final item in inventoryItems) {
        if (item.itemId != definition.id) {
          continue;
        }

        if (item.equipped) {
          continue;
        }

        item.quantity += safeQuantity;

        return;
      }
    }

    inventoryItems.add(
      InventoryItem(
        id:
            'inventory_item_'
            '${DateTime.now().microsecondsSinceEpoch}_'
            '${inventoryItems.length}',
        itemId: definition.id,
        quantity: safeQuantity,
        equipped: false,
        equippedSlotId: null,
      ),
    );
  }

  void equipInventoryItem(InventoryItem item, {String? slotId}) {
    final definition = definitionForInventoryItem(item);

    if (definition == null) {
      return;
    }

    if (!definition.type.isEquipable) {
      return;
    }

    final effectiveSlotId =
        slotId ??
        (definition.equipmentSlotIds.isNotEmpty
            ? definition.equipmentSlotIds.first
            : null);

    if (definition.type.exclusiveSlot) {
      for (final other in inventoryItems) {
        if (other.id == item.id) {
          continue;
        }

        if (!other.equipped) {
          continue;
        }

        final otherDefinition = definitionForInventoryItem(other);

        if (otherDefinition == null) {
          continue;
        }

        if (otherDefinition.type == definition.type) {
          other.equipped = false;
          other.equippedSlotId = null;
        }
      }
    }

    if (effectiveSlotId != null) {
      for (final other in inventoryItems) {
        if (other.id == item.id) {
          continue;
        }

        if (!other.equipped) {
          continue;
        }

        if (other.equippedSlotId == effectiveSlotId) {
          other.equipped = false;
          other.equippedSlotId = null;
        }
      }
    }

    item.equipped = true;
    item.equippedSlotId = effectiveSlotId;

    _refreshAfterEquipmentChange();
  }

  void unequipInventoryItem(InventoryItem item) {
    if (!item.equipped) {
      return;
    }

    item.equipped = false;
    item.equippedSlotId = null;

    _refreshAfterEquipmentChange();
  }

  ItemDefinition? definitionForPassive(CharacterPassive passive) {
    return itemForPassive(passive);
  }

  ItemDefinition? definitionForAbility(CharacterAbility ability) {
    return itemForAbility(ability);
  }

  void _refreshAfterEquipmentChange() {
    final activePassiveIds = enabledPassives
        .map((passive) => passive.id)
        .toSet();

    effects.removeWhere((effect) {
      if (!effect.id.startsWith('trigger:')) {
        return false;
      }

      final parts = effect.id.split(':');

      if (parts.length < 2) {
        return false;
      }

      final passiveId = parts[1];

      return !activePassiveIds.contains(passiveId);
    });

    normalizeHealthWithTriggers();

    for (final resource in resources) {
      normalizeResourceWithTriggers(resource, dispatchTriggers: true);
    }

    refreshPassiveTriggers();
  }

  bool addCharacterAbilityIfAbsent(CharacterAbility ability) {
    if (characterAbilities.any((a) => a.id == ability.id)) {
      return false;
    }
    characterAbilities.add(ability);
    return true;
  }

  bool addPassiveIfAbsent(CharacterPassive passive) {
    if (passives.any((p) => p.id == passive.id)) {
      return false;
    }
    addPassive(passive);
    return true;
  }

  int abilityEffectModifier(CharacterAbility ability, AbilityEffect effect) {
    int result = effect.effectBonus;

    if (effect.abilityModifierMultipliers.isNotEmpty) {
      result += calculateAbilityMultipliers(effect.abilityModifierMultipliers);
    } else if (effect.legacyAddAbilityModifier) {
      result += abilityModifier(ability.abilityType);
    }

    return result;
  }

  int abilityEffectSaveDc(CharacterAbility ability, AbilityEffect effect) {
    final modifier = abilityModifier(ability.abilityType);

    return 8 + proficiencyBonus + modifier + effect.saveDcBonus;
  }

  int skillBonus(DndSkill skill) {
    final modifier = abilityModifier(skill.ability);

    final proficiency = skillProficiencies[skill] ?? ProficiencyLevel.none;

    return modifier +
        proficiency.bonus(proficiencyBonus) +
        passiveSkillBonus(skill) +
        effectSkillBonus(skill);
  }

  ProficiencyLevel skillProficiency(DndSkill skill) {
    return skillProficiencies[skill] ?? ProficiencyLevel.none;
  }

  void setSkillProficiency(DndSkill skill, ProficiencyLevel level) {
    skillProficiencies[skill] = level;
  }

  bool isSkillProficient(DndSkill skill) {
    return skillProficiency(skill) != ProficiencyLevel.none;
  }

  bool hasExpertise(DndSkill skill) {
    return skillProficiency(skill) == ProficiencyLevel.expertise;
  }

  int savingThrowBonus(AbilityType ability) {
    final modifier = abilityModifier(ability);

    final proficient = savingThrowProficiencies[ability] ?? false;

    return modifier +
        (proficient ? proficiencyBonus : 0) +
        passiveSavingThrowBonus(ability) +
        effectSavingThrowBonus(ability);
  }

  int effectSavingThrowBonus(AbilityType ability) {
    return enabledEffects.fold<int>(
      0,
      (sum, effect) => sum + (effect.savingThrowBonuses[ability] ?? 0),
    );
  }

  bool isSavingThrowProficient(AbilityType ability) {
    return savingThrowProficiencies[ability] ?? false;
  }

  void setSavingThrowProficiency(AbilityType ability, bool proficient) {
    savingThrowProficiencies[ability] = proficient;
  }

  void resetSavingThrowProficienciesFromClass() {
    savingThrowProficiencies = {
      for (final ability in AbilityType.values)
        ability: primaryClass.savingThrowProficiencies.contains(ability),
    };
  }

  int attackBonus(Weapon weapon) {
    final modifier = abilityModifier(weapon.attackAbility);

    final proficiency = weapon.proficient ? proficiencyBonus : 0;

    return modifier +
        proficiency +
        weapon.magicBonus +
        passiveAttackBonus +
        effectAttackBonus;
  }

  int get effectAttackBonus {
    return enabledEffects.fold<int>(
      0,
      (sum, effect) => sum + effect.attackBonus,
    );
  }

  int calculateResourceValueMultipliers(Map<String, int> multipliers) {
    int result = 0;

    for (final entry in multipliers.entries) {
      final resource = resources
          .where((resource) => resource.id == entry.key)
          .firstOrNull;

      if (resource == null) {
        continue;
      }

      result += resource.currentValue * entry.value;
    }

    return result;
  }

  int damageModifier(Weapon weapon) {
    final modifier = abilityModifier(weapon.attackAbility);

    return modifier + weapon.magicBonus;
  }

  int weaponDamageModifier(Weapon weapon, WeaponDamage damage) {
    int result = damage.bonus;

    if (damage.addAbilityModifier) {
      result += abilityModifier(damage.abilityType);
    }

    if (weapon.damages.isNotEmpty && identical(weapon.damages.first, damage)) {
      result += weapon.magicBonus;
    }

    return result;
  }

  String weaponDamagePartText(Weapon weapon, WeaponDamage damage) {
    final modifier = weaponDamageModifier(weapon, damage);

    String result = damage.diceNotation;

    if (modifier > 0) {
      if (result.isNotEmpty) {
        result += ' + $modifier';
      } else {
        result = '$modifier';
      }
    }

    if (modifier < 0) {
      if (result.isNotEmpty) {
        result += ' - ${modifier.abs()}';
      } else {
        result = '$modifier';
      }
    }

    if (damage.damageType.trim().isNotEmpty) {
      result += ' ${damage.damageType.trim()}';
    }

    return result.trim();
  }

  String damageText(Weapon weapon) {
    if (weapon.damages.isNotEmpty) {
      return weapon.damages
          .map((damage) => weaponDamagePartText(weapon, damage))
          .join(' + ');
    }

    final modifier = damageModifier(weapon);

    if (modifier == 0) {
      return '${weapon.damageDice} ${weapon.damageType}'.trim();
    }

    final modifierText = modifier > 0 ? '+ $modifier' : '- ${modifier.abs()}';

    return '${weapon.damageDice} $modifierText ${weapon.damageType}'.trim();
  }

  int healingBonusModifier(
    HealingBonus bonus, {
    CharacterPassive? passive,
    FormulaContext? formulaContext,
  }) {
    var result =
        bonus.flatBonus +
        calculateAbilityMultipliers(bonus.abilityModifierMultipliers);

    final formula = bonus.formula;

    if (formula == null) {
      return result;
    }

    final context =
        formulaContext ??
        CharacterFormulaContext.fromCharacter(
          this,
          passive: passive,
          resourceResolver: (resourceId) {
            final resource = resourceById(resourceId);

            if (resource == null) {
              return null;
            }

            final resolver = ResourceModifierResolver(character: this);

            final snapshot = resolver.resolveSnapshot(resource);

            return FormulaResourceValue(
              baseCurrentValue: snapshot.baseCurrentValue,
              baseMaxValue: snapshot.baseMaxValue,
              currentValue: snapshot.currentValue,
              maxValue: snapshot.maxValue,
            );
          },
          baseResourceResolver: (resourceId) {
            final resource = resourceById(resourceId);

            if (resource == null) {
              return null;
            }

            final baseMax = resource.hasMaximum
                ? resource.maxValue.toDouble()
                : null;

            return FormulaResourceValue(
              baseCurrentValue: resource.currentValue.toDouble(),
              baseMaxValue: baseMax,
              currentValue: resource.currentValue.toDouble(),
              maxValue: baseMax,
            );
          },
        );

    final formulaResult = const FormulaEvaluator().evaluate(
      formula,
      context: context,
    );

    if (formulaResult.valid) {
      result += formulaResult.value.round();
    }

    return result;
  }

  int criticalDamageBonusModifier(
    CriticalDamageBonus bonus, {
    CharacterPassive? passive,
    FormulaContext? formulaContext,
  }) {
    var result =
        bonus.flatBonus +
        calculateAbilityMultipliers(bonus.abilityModifierMultipliers);

    final formula = bonus.formula;

    if (formula == null) {
      return result;
    }

    final formulaResult = const FormulaEvaluator().evaluate(
      formula,
      context:
          formulaContext ??
          CharacterFormulaContext.fromCharacter(this, passive: passive),
    );

    if (formulaResult.valid) {
      result += formulaResult.value.round();
    }

    return result;
  }

  int abilityEffectPartModifier(AbilityEffectPart part) {
    final abilityModifier = calculateAbilityMultipliers(
      part.abilityModifierMultipliers,
    );

    final resourceModifier = calculateResourceValueMultipliers(
      part.resourceValueMultipliers,
    );

    return part.flatBonus + abilityModifier + resourceModifier;
  }

  String attackBonusText(Weapon weapon) {
    final bonus = attackBonus(weapon);

    return bonus >= 0 ? '+$bonus' : '$bonus';
  }

  void addWeapon(Weapon weapon) {
    weapons.add(weapon);
  }

  void removeWeapon(String weaponId) {
    weapons.removeWhere((weapon) => weapon.id == weaponId);
  }

  Weapon? weaponById(String id) {
    for (final weapon in weapons) {
      if (weapon.id == id) {
        return weapon;
      }
    }

    return null;
  }

  int characterAbilityAttackBonus(CharacterAbility ability) {
    final modifier = abilityModifier(ability.abilityType);

    final proficiency = ability.proficient ? proficiencyBonus : 0;

    return modifier +
        proficiency +
        ability.attackBonus +
        passiveAttackBonus +
        effectAttackBonus;
  }

  int effectSkillBonus(DndSkill skill) {
    return enabledEffects.fold<int>(
      0,
      (sum, effect) => sum + (effect.skillBonuses[skill] ?? 0),
    );
  }

  int characterAbilityEffectModifier(CharacterAbility ability) {
    int result = ability.effectBonus;

    if (ability.addAbilityModifierToEffect) {
      result += abilityModifier(ability.abilityType);
    }

    return result;
  }

  String characterAbilityEffectText(CharacterAbility ability) {
    if (!ability.hasEffect) {
      return '';
    }

    final modifier = characterAbilityEffectModifier(ability);

    String result = ability.diceNotation;

    if (modifier > 0) {
      result += ' + $modifier';
    }

    if (modifier < 0) {
      result += ' - ${modifier.abs()}';
    }

    if (ability.effectTypeName.isNotEmpty) {
      result += ' ${ability.effectTypeName}';
    }

    return result;
  }

  int characterAbilitySaveDc(CharacterAbility ability) {
    final modifier = abilityModifier(ability.abilityType);

    return 8 + proficiencyBonus + modifier + ability.saveDcBonus;
  }

  void addCharacterAbility(CharacterAbility ability) {
    characterAbilities.add(ability);
  }

  void removeCharacterAbility(String id) {
    characterAbilities.removeWhere((ability) => ability.id == id);
  }

  ItemDefinition? get equippedArmor {
    for (final inventoryItem in equippedInventoryItems) {
      final definition = definitionForInventoryItem(inventoryItem);

      if (definition == null) {
        continue;
      }

      if (definition.type == ItemType.armor && definition.armor != null) {
        return definition;
      }
    }

    return null;
  }

  CharacterAbility? characterAbilityById(String id) {
    for (final ability in characterAbilities) {
      if (ability.id == id) {
        return ability;
      }
    }

    return null;
  }

  void restoreCharacterAbility(CharacterAbility ability) {
    if (!ability.hasLimitedUses) {
      return;
    }

    setAbilityUses(ability, ability.maxUses);
  }

  void restoreAllAbilities() {
    for (final ability in availableAbilities) {
      restoreCharacterAbility(ability);
    }
  }

  void setAbilityUses(CharacterAbility ability, int value) {
    if (!ability.hasLimitedUses) {
      return;
    }

    ability.currentUses = value.clamp(0, ability.maxUses);
  }

  bool canSpendAbilityUses(CharacterAbility ability, int amount) {
    if (amount <= 0) {
      return true;
    }

    if (!ability.hasLimitedUses) {
      return true;
    }

    return ability.currentUses >= amount;
  }

  bool spendAbilityUses(CharacterAbility ability, int amount) {
    if (!canSpendAbilityUses(ability, amount)) {
      return false;
    }

    if (amount <= 0 || !ability.hasLimitedUses) {
      return true;
    }

    setAbilityUses(ability, ability.currentUses - amount);

    return true;
  }

  bool canCommitAbilityCosts({required CharacterAbility ability}) {
    if (ability.hasLimitedUses && ability.currentUses <= 0) {
      return false;
    }

    if (ability.usesResource && !canPayAbilityResource(ability)) {
      return false;
    }

    return true;
  }

  void updateCharacterAbility(CharacterAbility ability) {
    final index = characterAbilities.indexWhere(
      (item) => item.id == ability.id,
    );

    if (index < 0) {
      return;
    }

    characterAbilities[index] = ability;
  }

  int passiveRollModifier(CharacterPassive passive) {
    return passive.rollFlatBonus +
        calculateAbilityMultipliers(passive.rollAbilityModifierMultipliers);
  }

  Iterable<CharacterPassive> get enabledPassives {
    final normalPassives = passives.where((passive) => passive.enabled);

    final itemPassives = <CharacterPassive>[];

    for (final inventoryItem in equippedInventoryItems) {
      final definition = definitionForInventoryItem(inventoryItem);

      if (definition == null) {
        continue;
      }

      itemPassives.addAll(
        definition.passives.where((passive) => passive.enabled),
      );
    }

    return [...normalPassives, ...itemPassives];
  }

  List<CharacterAbility> get availableAbilities {
    final result = <CharacterAbility>[...characterAbilities];

    for (final inventoryItem in equippedInventoryItems) {
      final definition = definitionForInventoryItem(inventoryItem);

      if (definition == null) {
        continue;
      }

      result.addAll(definition.abilities);
    }

    return result;
  }

  int get passiveArmorClassBonus {
    var total = 0;

    for (final passive in enabledPassives) {
      total += evaluateFormulaBonus(passive.armorClassBonus, passive: passive);
    }

    return total;
  }

  int get passiveInitiativeBonus {
    var total = 0;

    for (final passive in enabledPassives) {
      total += evaluateFormulaBonus(passive.initiativeBonus, passive: passive);
    }

    return total;
  }

  int get passiveSpeedBonus {
    var total = 0;

    for (final passive in enabledPassives) {
      total += evaluateFormulaBonus(passive.speedBonus, passive: passive);
    }

    return total;
  }

  int get passiveMaxHealthBonus {
    var total = 0;

    for (final passive in enabledPassives) {
      total += evaluateFormulaBonus(passive.maxHealthBonus, passive: passive);
    }

    return total;
  }

  int get passiveAttackBonus {
    var total = 0;

    for (final passive in enabledPassives) {
      total += evaluateFormulaBonus(passive.attackBonus, passive: passive);
    }

    return total;
  }

  int passiveSkillBonus(DndSkill skill) {
    var total = 0;

    for (final passive in enabledPassives) {
      final bonus = passive.skillBonuses[skill];

      if (bonus == null || !bonus.hasValue) {
        continue;
      }

      total += evaluateFormulaBonus(bonus, passive: passive);
    }

    return total;
  }

  int passiveSavingThrowBonus(AbilityType ability) {
    var total = 0;

    for (final passive in enabledPassives) {
      final bonus = passive.savingThrowBonuses[ability];

      if (bonus == null || !bonus.hasValue) {
        continue;
      }

      total += evaluateFormulaBonus(bonus, passive: passive);
    }

    return total;
  }

  void addPassive(CharacterPassive passive, {bool refreshTriggers = true}) {
    passive.normalizeCharges();

    passives.add(passive);

    normalizeHealth();

    if (refreshTriggers) {
      refreshPassiveTriggers();
    }
  }

  void removePassive(String passiveId, {bool refreshTriggers = true}) {
    final exists = passives.any((passive) => passive.id == passiveId);

    if (!exists) {
      return;
    }

    PassiveTriggerEngine(
      character: this,
    ).removeRuntimeEffectsForPassive(passiveId, refreshTriggers: false);

    passives.removeWhere((passive) => passive.id == passiveId);

    normalizeHealth();

    if (refreshTriggers) {
      refreshPassiveTriggers();
    }
  }

  void updatePassive(CharacterPassive passive, {bool refreshTriggers = true}) {
    final index = passives.indexWhere((item) => item.id == passive.id);

    if (index < 0) {
      return;
    }

    final engine = PassiveTriggerEngine(character: this);

    engine.removeRuntimeEffectsForPassive(passive.id, refreshTriggers: false);

    passive.normalizeCharges();

    passives[index] = passive;

    normalizeHealth();

    if (refreshTriggers) {
      refreshPassiveTriggers();
    }
  }

  ResourceModifierResolver get resourceResolver {
    return ResourceModifierResolver(character: this);
  }

  int resourceBaseMax(CharacterResource resource) {
    return resource.maxValue;
  }

  int resourceBaseCurrent(CharacterResource resource) {
    return resource.currentValue;
  }

  int resourceEffectiveCurrent(CharacterResource resource) {
    final resolver = ResourceModifierResolver(character: this);

    return resolver.resolveCurrent(resource);
  }

  int? resourceEffectiveMax(CharacterResource resource) {
    if (!resource.hasMaximum) {
      return null;
    }

    final resolver = ResourceModifierResolver(character: this);

    return resolver.resolveMax(resource);
  }

  void addJournalEntry(JournalEntry entry) {
    journalEntries.add(entry);
  }

  void removeJournalEntry(String id) {
    journalEntries.removeWhere((entry) => entry.id == id);
  }

  JournalEntry? journalEntryById(String id) {
    for (final entry in journalEntries) {
      if (entry.id == id) {
        return entry;
      }
    }

    return null;
  }

  CharacterCounter? counterById(String counterId) {
    for (final counter in counters) {
      if (counter.id == counterId) {
        return counter;
      }
    }

    return null;
  }

  int counterValue(String counterId) {
    return counterById(counterId)?.value ?? 0;
  }

  void incrementCounter(
    String counterId,
    int amount, {
    bool dispatchTriggers = true,
  }) {
    if (amount == 0) {
      return;
    }

    final counter = counterById(counterId);

    if (counter == null) {
      return;
    }

    setCounter(
      counterId,
      counter.value + amount,
      dispatchTriggers: dispatchTriggers,
    );
  }

  void increaseCounter(
    String counterId, {
    int amount = 1,
    bool dispatchTriggers = true,
  }) {
    incrementCounter(counterId, amount, dispatchTriggers: dispatchTriggers);
  }

  void setCounter(String counterId, int value, {bool dispatchTriggers = true}) {
    final counter = counterById(counterId);

    if (counter == null) {
      return;
    }

    final previousValue = counter.value;

    counter.value = value;

    final currentValue = counter.value;

    if (!dispatchTriggers || previousValue == currentValue) {
      return;
    }

    dispatchPassiveTrigger(
      PassiveTriggerEvent.counterChanged,
      eventVariables: {
        'previous_counter': previousValue.toDouble(),

        'current_counter': currentValue.toDouble(),

        'counter_change': (currentValue - previousValue).toDouble(),

        'counter_${counter.id}': 1,

        'counter_increased': currentValue > previousValue ? 1 : 0,

        'counter_decreased': currentValue < previousValue ? 1 : 0,
      },
    );

    refreshPassiveTriggers();
  }

  void resetCounter(String counterId, {bool dispatchTriggers = true}) {
    setCounter(counterId, 0, dispatchTriggers: dispatchTriggers);
  }

  void addDiceHistory(DiceHistoryEntry entry) {
    diceHistory.insert(0, entry);

    if (diceHistory.length > 50) {
      diceHistory = diceHistory.take(50).toList();
    }
  }

  void clearDiceHistory() {
    diceHistory.clear();
  }

  // ===========================================================================
  // SERIALIZACIÓN
  // ===========================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarPath': avatarPath,
      'campaignId': campaignId,
      'ownerType': ownerType,
      'race': race,
      'classes': classes.map((item) => item.toMap()).toList(),
      'dndClass': primaryClass.name,
      'level': level,
      'abilities': abilities.toMap(),
      'contentFolders': contentFolders.map((folder) => folder.toMap()).toList(),
      'currentHealth': currentHealth,
      'customMaxHealth': customMaxHealth,
      'armorClass': armorClass,
      'speed': speed,
      'backstory': backstory,
      'personality': personality,
      'appearance': appearance,
      'ideals': ideals,
      'bonds': bonds,
      'flaws': flaws,
      'goals': goals,
      'storyNotes': storyNotes,
      'skillProficiencies': {
        for (final entry in skillProficiencies.entries)
          entry.key.name: entry.value.name,
      },
      'savingThrowProficiencies': {
        for (final entry in savingThrowProficiencies.entries)
          entry.key.name: entry.value,
      },
      'weapons': weapons.map((weapon) => weapon.toMap()).toList(),
      'characterAbilities': characterAbilities
          .map((ability) => ability.toMap())
          .toList(),
      'passives': passives.map((passive) => passive.toMap()).toList(),
      'journalEntries': journalEntries.map((entry) => entry.toMap()).toList(),
      'diceHistory': diceHistory.map((entry) => entry.toMap()).toList(),
      'items': items.map((item) => item.toMap()).toList(),
      'itemDefinitions': itemDefinitions
          .map((definition) => definition.toMap())
          .toList(),
      'inventoryItems': inventoryItems.map((item) => item.toMap()).toList(),
      'equipmentSlots': equipmentSlots.map((slot) => slot.toJson()).toList(),
      'resources': resources.map((resource) => resource.toMap()).toList(),
      'effects': effects.map((effect) => effect.toMap()).toList(),
      'combatActive': combatActive,
      'combatRound': combatRound,
      'turnActive': turnActive,
      'combatTurnSequence': combatTurnSequence,
      'counters': counters.map((counter) => counter.toMap()).toList(),
      'criticalMinimumNaturalRoll': criticalMinimumNaturalRoll,
      'knowledges': knowledges.map((k) => k.toMap()).toList(),
      'spellSlots': spellSlots,
      'pets': pets
          .map((p) => p.toMap())
          .toList(), // <--- Serialización de mascotas añadida
      'shortRestRule': shortRestRule,
    };
  }

  factory Character.fromMap(Map<dynamic, dynamic> map) {
    final itemDefinitions = <ItemDefinition>[];
    final inventoryItems = <InventoryItem>[];

    final rawSlots = map['equipmentSlots'];
    final slots = <EquipmentSlotDefinition>[];

    if (rawSlots is List && rawSlots.isNotEmpty) {
      for (final raw in rawSlots) {
        if (raw is Map) {
          try {
            slots.add(
              EquipmentSlotDefinition.fromJson(Map<String, dynamic>.from(raw)),
            );
          } catch (_) {}
        }
      }
    }

    if (slots.isEmpty) {
      slots.addAll(defaultEquipmentSlots);
    }

    final rawKnowledges = map['knowledges'];
    final parsedKnowledges = <CharacterKnowledge>[];
    if (rawKnowledges is List) {
      for (final item in rawKnowledges) {
        if (item is Map) {
          try {
            parsedKnowledges.add(
              CharacterKnowledge.fromMap(Map<dynamic, dynamic>.from(item)),
            );
          } catch (_) {}
        }
      }
    }

    // Deserialización de mascotas
    final rawPets = map['pets'];
    final parsedPets = <Pet>[];
    if (rawPets is List) {
      for (final item in rawPets) {
        if (item is Map) {
          try {
            parsedPets.add(Pet.fromMap(Map<dynamic, dynamic>.from(item)));
          } catch (_) {}
        }
      }
    }

    final rawSpellSlots = map['spellSlots'];
    final parsedSpellSlots = <String, int>{};
    if (rawSpellSlots is Map) {
      for (final entry in rawSpellSlots.entries) {
        parsedSpellSlots[entry.key.toString()] =
            (entry.value as num?)?.toInt() ?? 0;
      }
    }

    final rawItemDefinitions = map['itemDefinitions'];

    if (rawItemDefinitions is List) {
      for (final rawDefinition in rawItemDefinitions) {
        if (rawDefinition is! Map) {
          continue;
        }

        try {
          final definition = ItemDefinition.fromMap(
            Map<dynamic, dynamic>.from(rawDefinition),
          );

          if (definition.id.trim().isEmpty) {
            continue;
          }

          if (itemDefinitions.any((current) => current.id == definition.id)) {
            continue;
          }

          itemDefinitions.add(definition);
        } catch (_) {
          continue;
        }
      }
    }

    final rawInventoryItems = map['inventoryItems'];

    if (rawInventoryItems is List) {
      for (final rawInventoryItem in rawInventoryItems) {
        if (rawInventoryItem is! Map) {
          continue;
        }

        try {
          final inventoryItem = InventoryItem.fromMap(
            Map<String, dynamic>.from(rawInventoryItem),
          );

          if (inventoryItem.id.trim().isEmpty ||
              inventoryItem.itemId.trim().isEmpty) {
            continue;
          }

          inventoryItems.add(inventoryItem);
        } catch (_) {
          continue;
        }
      }
    }

    final items = <CharacterItem>[];
    final rawItems = map['items'];

    if (rawItems is List) {
      for (final rawItem in rawItems) {
        if (rawItem is! Map) {
          continue;
        }

        try {
          final legacyItem = CharacterItem.fromMap(
            Map<dynamic, dynamic>.from(rawItem),
          );

          items.add(legacyItem);

          final definition = legacyItem.toDefinition();

          if (definition.id.trim().isNotEmpty &&
              !itemDefinitions.any((current) => current.id == definition.id)) {
            itemDefinitions.add(definition);
          }

          if (definition.id.trim().isNotEmpty) {
            final alreadyMigrated = inventoryItems.any(
              (current) =>
                  current.id == legacyItem.id ||
                  (current.itemId == definition.id &&
                      current.quantity == legacyItem.quantity &&
                      current.equipped == legacyItem.equipped),
            );

            if (!alreadyMigrated) {
              final inventoryId = legacyItem.id.trim().isNotEmpty
                  ? legacyItem.id
                  : 'inventory_item_'
                        '${DateTime.now().microsecondsSinceEpoch}_'
                        '${inventoryItems.length}';

              inventoryItems.add(
                InventoryItem(
                  id: inventoryId,
                  itemId: definition.id,
                  quantity: legacyItem.quantity < 1 ? 1 : legacyItem.quantity,
                  equipped: legacyItem.equipped,
                  equippedSlotId: null,
                ),
              );
            }
          }
        } catch (_) {
          continue;
        }
      }
    }

    inventoryItems.removeWhere(
      (inventoryItem) => !itemDefinitions.any(
        (definition) => definition.id == inventoryItem.itemId,
      ),
    );

    final counters = <CharacterCounter>[];
    final rawCounters = map['counters'];

    if (rawCounters is List) {
      for (final rawCounter in rawCounters) {
        if (rawCounter is! Map) {
          continue;
        }

        try {
          counters.add(
            CharacterCounter.fromMap(Map<dynamic, dynamic>.from(rawCounter)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    final resources = <CharacterResource>[];
    final rawResources = map['resources'];

    final effects = <CharacterEffect>[];
    final rawEffects = map['effects'];

    if (rawEffects is List) {
      for (final rawEffect in rawEffects) {
        if (rawEffect == null) {
          continue;
        }

        try {
          effects.add(
            CharacterEffect.fromMap(Map<dynamic, dynamic>.from(rawEffect)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    if (rawResources is List) {
      for (final rawResource in rawResources) {
        if (rawResource == null) {
          continue;
        }

        try {
          resources.add(
            CharacterResource.fromMap(Map<dynamic, dynamic>.from(rawResource)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    final classes = <CharacterClassLevel>[];
    final rawClasses = map['classes'];

    if (rawClasses is List) {
      for (final rawClass in rawClasses) {
        if (rawClass == null) {
          continue;
        }

        try {
          classes.add(
            CharacterClassLevel.fromMap(Map<dynamic, dynamic>.from(rawClass)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    if (classes.isEmpty) {
      final rawLegacyClass = map['dndClass'] ?? map['characterClass'];

      classes.add(
        CharacterClassLevel(
          dndClass: DndClassData.fromString(rawLegacyClass?.toString()),
          level: (map['level'] as num?)?.toInt() ?? 1,
        ),
      );
    }

    final rawAbilities = map['abilities'];
    final abilities = rawAbilities is Map
        ? AbilityScores.fromMap(Map<dynamic, dynamic>.from(rawAbilities))
        : AbilityScores();

    final skillProficiencies = <DndSkill, ProficiencyLevel>{};
    final rawSkillProficiencies = map['skillProficiencies'];

    if (rawSkillProficiencies is Map) {
      final skillMap = Map<dynamic, dynamic>.from(rawSkillProficiencies);

      for (final skill in DndSkill.values) {
        final storedValue = skillMap[skill.name]?.toString();

        skillProficiencies[skill] = ProficiencyLevel.values.firstWhere(
          (value) => value.name == storedValue,
          orElse: () => ProficiencyLevel.none,
        );
      }
    } else {
      for (final skill in DndSkill.values) {
        skillProficiencies[skill] = ProficiencyLevel.none;
      }
    }

    final savingThrowProficiencies = <AbilityType, bool>{};
    final rawSavingThrows = map['savingThrowProficiencies'];

    if (rawSavingThrows is Map) {
      final savingMap = Map<dynamic, dynamic>.from(rawSavingThrows);

      for (final ability in AbilityType.values) {
        savingThrowProficiencies[ability] = savingMap[ability.name] == true;
      }
    } else {
      final initialClass = classes.first.dndClass;

      for (final ability in AbilityType.values) {
        savingThrowProficiencies[ability] = initialClass
            .savingThrowProficiencies
            .contains(ability);
      }
    }

    final weapons = <Weapon>[];
    final rawWeapons = map['weapons'];

    if (rawWeapons is List) {
      for (final rawWeapon in rawWeapons) {
        if (rawWeapon == null) {
          continue;
        }

        try {
          weapons.add(Weapon.fromMap(Map<dynamic, dynamic>.from(rawWeapon)));
        } catch (_) {
          continue;
        }
      }
    }

    final contentFolders = <CharacterContentFolder>[];
    final rawContentFolders = map['contentFolders'];

    if (rawContentFolders is List) {
      for (final rawFolder in rawContentFolders) {
        if (rawFolder is! Map) {
          continue;
        }

        final folder = CharacterContentFolder.fromMap(rawFolder);

        if (folder.id.trim().isEmpty || folder.name.trim().isEmpty) {
          continue;
        }

        contentFolders.add(folder);
      }
    }

    final characterAbilities = <CharacterAbility>[];
    final rawCharacterAbilities = map['characterAbilities'];

    if (rawCharacterAbilities is List) {
      for (final rawAbility in rawCharacterAbilities) {
        if (rawAbility == null) {
          continue;
        }

        try {
          characterAbilities.add(
            CharacterAbility.fromMap(Map<dynamic, dynamic>.from(rawAbility)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    final passives = <CharacterPassive>[];
    final rawPassives = map['passives'];

    if (rawPassives is List) {
      for (final rawPassive in rawPassives) {
        if (rawPassive == null) {
          continue;
        }

        try {
          passives.add(
            CharacterPassive.fromMap(Map<dynamic, dynamic>.from(rawPassive)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    final journalEntries = <JournalEntry>[];
    final rawJournalEntries = map['journalEntries'];

    if (rawJournalEntries is List) {
      for (final rawEntry in rawJournalEntries) {
        if (rawEntry == null) {
          continue;
        }

        try {
          journalEntries.add(
            JournalEntry.fromMap(Map<dynamic, dynamic>.from(rawEntry)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    final diceHistory = <DiceHistoryEntry>[];
    final rawDiceHistory = map['diceHistory'];

    if (rawDiceHistory is List) {
      for (final rawEntry in rawDiceHistory) {
        if (rawEntry == null) {
          continue;
        }

        try {
          diceHistory.add(
            DiceHistoryEntry.fromMap(Map<dynamic, dynamic>.from(rawEntry)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    final combatActive = map['combatActive'] == true;
    final combatRound = (map['combatRound'] as num?)?.toInt() ?? 1;
    final turnActive = map['turnActive'] == true;
    final combatTurnSequence =
        (map['combatTurnSequence'] as num?)?.toInt() ?? 0;

    final character = Character(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      avatarPath: map['avatarPath']?.toString(),
      campaignId: map['campaignId']?.toString(),
      ownerType: map['ownerType']?.toString() ?? 'player',
      race: map['race']?.toString() ?? '',
      classes: classes,
      abilities: abilities,
      contentFolders: contentFolders,
      currentHealth: (map['currentHealth'] as num?)?.toInt(),
      customMaxHealth: (map['customMaxHealth'] as num?)?.toInt(),
      armorClass: (map['armorClass'] as num?)?.toInt() ?? 10,
      speed: (map['speed'] as num?)?.toInt() ?? 30,
      backstory: map['backstory']?.toString() ?? '',
      personality: map['personality']?.toString() ?? '',
      appearance: map['appearance']?.toString() ?? '',
      ideals: map['ideals']?.toString() ?? '',
      bonds: map['bonds']?.toString() ?? '',
      flaws: map['flaws']?.toString() ?? '',
      goals: map['goals']?.toString() ?? '',
      storyNotes: map['storyNotes']?.toString() ?? '',
      skillProficiencies: skillProficiencies,
      savingThrowProficiencies: savingThrowProficiencies,
      weapons: weapons,
      characterAbilities: characterAbilities,
      passives: passives,
      journalEntries: journalEntries,
      diceHistory: diceHistory,
      items: items,
      itemDefinitions: itemDefinitions,
      inventoryItems: inventoryItems,
      resources: resources,
      effects: effects,
      combatActive: combatActive,
      combatRound: combatRound,
      turnActive: turnActive,
      combatTurnSequence: combatTurnSequence,
      counters: counters,
      criticalMinimumNaturalRoll:
          (map['criticalMinimumNaturalRoll'] as num?)?.toInt() ?? 20,
      knowledges: parsedKnowledges,
      spellSlots: parsedSpellSlots,
      pets: parsedPets,
      shortRestRule: map['shortRestRule']?.toString() ?? 'single',
    );

    character.normalizeHealth();

    return character;
  }
}
