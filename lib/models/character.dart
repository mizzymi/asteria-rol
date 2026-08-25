import 'dart:math';
import 'package:rol/models/ability_effect_part.dart';
import '../services/resource_modifier_resolver.dart';
import '../services/formula_evaluator.dart';
import '../services/passive_trigger_engine.dart';
import 'formulas/formula_bonus.dart';
import 'formulas/character_formula.dart';
import 'formulas/character_formula_context.dart';
import 'formulas/formula_modifier.dart';
import 'character_counter.dart';
import 'passive_resource_modifier.dart';
import 'formulas/formula_context.dart';
import 'character_resource.dart';
import 'active_damage_bonus.dart';
import 'ability.dart';
import 'ability_scores.dart';
import 'character_class_level.dart';
import 'dice_history_entry.dart';
import 'dice_pool.dart';
import 'dnd_class.dart';
import 'journal_entry.dart';
import 'passive.dart';
import 'proficiency.dart';
import 'skill.dart';
import 'weapon.dart';
import 'item.dart';
import 'character_effect.dart';
import 'weapon_damage.dart';
import 'weapon_damage_result.dart';
import 'damage_bonus.dart';
import 'damage_bonus_result.dart';
import 'critical_damage_bonus.dart';
import 'critical_damage_bonus_result.dart';
import 'healing_bonus.dart';
import 'healing_bonus_result.dart';

class Character {
  final String id;

  String name;
  String? avatarPath;

  String race;

  /// Una o varias clases.
  ///
  /// La primera clase se considera la clase principal / inicial.
  List<CharacterClassLevel> classes;

  AbilityScores abilities;

  int currentHealth;

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

  List<CharacterResource> resources;

  List<CharacterEffect> effects;

  int combatRound;

  bool turnActive;

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

  List<CriticalDamageBonus> activeCriticalDamageBonuses([Weapon? weapon]) {
    final result = <CriticalDamageBonus>[];

    // Bonus exclusivos del arma.
    if (weapon != null) {
      result.addAll(weapon.criticalDamageBonuses);
    }

    // Bonus globales de pasivas.
    for (final passive in enabledPassives) {
      result.addAll(passive.criticalDamageBonuses);
    }

    // Bonus globales de estados/efectos.
    for (final effect in enabledEffects) {
      result.addAll(effect.criticalDamageBonuses);
    }

    return result;
  }

  List<HealingBonus> get activeHealingBonuses {
    final result = <HealingBonus>[];

    for (final passive in enabledPassives) {
      result.addAll(passive.healingBonuses);
    }

    for (final effect in enabledEffects) {
      result.addAll(effect.healingBonuses);
    }

    return result;
  }

  List<HealingBonusResult> rollActiveHealingBonuses() {
    final results = <HealingBonusResult>[];

    for (final bonus in activeHealingBonuses) {
      if (!bonus.hasHealing) {
        continue;
      }

      results.add(rollHealingBonus(bonus));
    }

    return results;
  }

  int activeHealingBonusTotal() {
    return rollActiveHealingBonuses().fold<int>(
      0,
      (sum, result) => sum + result.total,
    );
  }

  List<DamageBonusResult> rollActiveDamageBonuses({bool critical = false}) {
    final results = <DamageBonusResult>[];

    for (final active in activeDamageBonuses) {
      final bonus = active.bonus;

      if (!bonus.hasDamage) {
        continue;
      }

      results.add(
        rollDamageBonus(bonus, passive: active.passive, critical: critical),
      );
    }

    return results;
  }

  List<CharacterCounter> counters;

  /// Rango crítico base/personal del personaje.
  ///
  /// 20 = crítico únicamente con 20 natural.
  int criticalMinimumNaturalRoll;

  Character({
    required this.id,
    required this.name,
    this.avatarPath,
    this.race = '',

    /// Nuevo sistema.
    List<CharacterClassLevel>? classes,

    /// Compatibilidad temporal con código antiguo.
    DndClass? dndClass,
    int? level,

    AbilityScores? abilities,
    int? currentHealth,
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
    List<CharacterResource>? resources,
    List<CharacterEffect>? effects,
    this.combatRound = 1,
    this.turnActive = false,
    List<CharacterCounter>? counters,
    this.criticalMinimumNaturalRoll = 20,
  }) : classes = _resolveClasses(
         classes: classes,
         dndClass: dndClass,
         level: level,
       ),
       abilities = abilities ?? AbilityScores(),
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
       resources = resources ?? [],
       effects = effects ?? [],
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

  void dispatchPassiveTrigger(
    PassiveTriggerEvent event, {
    Map<String, double> eventVariables = const {},
  }) {
    final engine = PassiveTriggerEngine(character: this);

    engine.dispatch(event, eventVariables: eventVariables);

    engine.refreshPersistentTriggers(eventVariables: eventVariables);
  }

  void refreshPassiveTriggers({Map<String, double> eventVariables = const {}}) {
    final engine = PassiveTriggerEngine(character: this);

    engine.refreshPersistentTriggers(eventVariables: eventVariables);
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

  void startTurn() {
    if (turnActive) {
      return;
    }

    turnActive = true;

    dispatchPassiveTrigger(
      PassiveTriggerEvent.turnStarted,
      eventVariables: {'round': combatRound.toDouble(), 'turn_active': 1},
    );
  }

  void endTurn() {
    if (!turnActive) {
      return;
    }

    dispatchPassiveTrigger(
      PassiveTriggerEvent.turnEnded,
      eventVariables: {'round': combatRound.toDouble(), 'turn_active': 0},
    );

    turnActive = false;
  }

  void startNextRound() {
    // Si quedaba un turno abierto, lo cerramos.
    if (turnActive) {
      dispatchPassiveTrigger(
        PassiveTriggerEvent.turnEnded,
        eventVariables: {'round': combatRound.toDouble(), 'turn_active': 0},
      );

      turnActive = false;
    }

    combatRound++;

    dispatchPassiveTrigger(
      PassiveTriggerEvent.roundStarted,
      eventVariables: {'round': combatRound.toDouble()},
    );
  }

  void resetCombat() {
    if (turnActive) {
      dispatchPassiveTrigger(
        PassiveTriggerEvent.turnEnded,
        eventVariables: {'round': combatRound.toDouble(), 'turn_active': 0},
      );
    }

    turnActive = false;
    combatRound = 1;

    refreshPassiveTriggers(
      eventVariables: {'round': combatRound.toDouble(), 'turn_active': 0},
    );
  }

  String get combatStatusText {
    return 'Ronda $combatRound · '
        '${turnActive ? 'Turno activo' : 'Esperando turno'}';
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

    final previousValue = resource.currentValue;

    resource.currentValue += amount;
    resource.normalize();

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
      },
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

    addResourceValue(resourceId, -amount, dispatchTriggers: dispatchTriggers);
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
    resource.normalize();

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
      },
    );
  }

  void restoreResourceFull(String resourceId, {bool dispatchTriggers = true}) {
    final resource = resourceById(resourceId);

    if (resource == null || !resource.hasMaximum) {
      return;
    }

    setResourceValue(
      resourceId,
      resource.maxValue,
      dispatchTriggers: dispatchTriggers,
    );
  }

  List<int> criticalMinimumRollSourcesForAbility(CharacterAbility ability) {
    final sources = <int>[
      criticalMinimumNaturalRoll,
      ability.criticalMinimumNaturalRoll,
    ];

    for (final passive in enabledPassives) {
      sources.add(passive.criticalMinimumNaturalRoll);
    }

    for (final effect in enabledEffects) {
      sources.add(effect.criticalMinimumNaturalRoll);
    }

    return sources;
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

  /// Nivel total del personaje.
  ///
  /// Guerrero 3 + Mago 2 = nivel 5.
  int get level {
    if (classes.isEmpty) {
      return 1;
    }

    return classes.fold<int>(0, (sum, item) => sum + item.level);
  }

  /*
   * Setter temporal para que el código antiguo:
   *
   * character.level = 5;
   *
   * siga compilando.
   *
   * Si solo hay una clase cambia su nivel.
   *
   * Si hay multiclase, modifica la clase principal
   * intentando mantener los niveles secundarios.
   */
  set level(int value) {
    final safeValue = value < 1 ? 1 : value;

    if (classes.isEmpty) {
      classes.add(
        CharacterClassLevel(dndClass: DndClass.fighter, level: safeValue),
      );

      return;
    }

    if (classes.length == 1) {
      classes.first.level = safeValue;

      return;
    }

    final secondaryLevels = classes
        .skip(1)
        .fold<int>(0, (sum, item) => sum + item.level);

    final primaryLevel = safeValue - secondaryLevels;

    classes.first.level = primaryLevel < 1 ? 1 : primaryLevel;
  }

  DndClass get primaryClass {
    if (classes.isEmpty) {
      return DndClass.fighter;
    }

    return classes.first.dndClass;
  }

  /// Compatibilidad con pantallas antiguas que todavía usan:
  ///
  /// character.dndClass
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

  void addClass(DndClass dndClass, {int level = 1}) {
    final existing = classes.indexWhere((item) => item.dndClass == dndClass);

    if (existing >= 0) {
      classes[existing].level += level < 1 ? 1 : level;

      normalizeHealth();

      return;
    }

    classes.add(
      CharacterClassLevel(dndClass: dndClass, level: level < 1 ? 1 : level),
    );

    normalizeHealth();
  }

  void removeClass(DndClass dndClass) {
    if (classes.length <= 1) {
      return;
    }

    classes.removeWhere((item) => item.dndClass == dndClass);

    normalizeHealth();
  }

  void setClassLevel(DndClass dndClass, int newLevel) {
    final index = classes.indexWhere((item) => item.dndClass == dndClass);

    if (index < 0) {
      return;
    }

    classes[index].level = newLevel < 1 ? 1 : newLevel;

    normalizeHealth();
  }

  // ===========================================================================
  // RECURSOS PERSONALIZADOS
  // ===========================================================================

  void addResource(CharacterResource resource) {
    resources.add(resource);
  }

  void removeResource(String resourceId) {
    resources.removeWhere((resource) => resource.id == resourceId);
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

  bool canPayAbilityResource(CharacterAbility ability) {
    if (!ability.usesResource) {
      return true;
    }

    final resource = resourceForAbility(ability);

    if (resource == null) {
      return false;
    }

    return resource.currentValue >= ability.resourceCost;
  }

  bool payAbilityResource(CharacterAbility ability) {
    if (!ability.usesResource) {
      return true;
    }

    final resource = resourceForAbility(ability);

    if (resource == null) {
      return false;
    }

    if (resource.currentValue < ability.resourceCost) {
      return false;
    }

    resource.consume(ability.resourceCost);

    return true;
  }

  void updateResource(CharacterResource resource) {
    final index = resources.indexWhere((item) => item.id == resource.id);

    if (index < 0) {
      return;
    }

    resources[index] = resource;
  }

  void consumeResource(CharacterResource resource, int amount) {
    if (!resource.spendable) {
      return;
    }

    if (amount <= 0) {
      return;
    }

    resource.consume(amount);

    normalizeResource(resource);
  }

  void restoreResource(CharacterResource resource, int amount) {
    if (amount <= 0) {
      return;
    }

    if (!resource.hasMaximum) {
      resource.restore(amount);
      return;
    }

    final effectiveMax = resourceEffectiveMax(resource);

    if (effectiveMax == null) {
      return;
    }

    resource.restore(amount, maximum: effectiveMax);
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

    final previousValue = passive.currentCharges;

    passive.currentCharges += amount;
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
      },
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

    addPassiveCharges(passiveId, -amount, dispatchTriggers: dispatchTriggers);
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
      },
    );
  }

  CharacterPassive? passiveById(String passiveId) {
    for (final passive in passives) {
      if (passive.id == passiveId) {
        return passive;
      }
    }

    for (final item in items) {
      if (item.equipped) {
        for (final passive in item.passives) {
          if (passive.id == passiveId) {
            return passive;
          }
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

  void addEffect(CharacterEffect effect) {
    effects.add(effect);
  }

  void removeEffect(String effectId) {
    effects.removeWhere((effect) => effect.id == effectId);
  }

  CharacterEffect? effectById(String id) {
    for (final effect in effects) {
      if (effect.id == id) {
        return effect;
      }
    }

    return null;
  }

  void updateEffect(CharacterEffect effect) {
    final index = effects.indexWhere((item) => item.id == effect.id);

    if (index < 0) {
      return;
    }

    effects[index] = effect;
  }

  // ===========================================================================
  // ATRIBUTOS / STATS / MODIFICADORES
  // ===========================================================================

  /// Valor BASE del atributo.
  ///
  /// Es el valor guardado directamente en [abilities].
  ///
  /// Ejemplo:
  /// FUE base = 16
  int baseAbilityScore(AbilityType ability) {
    return abilities.valueByType(ability);
  }

  /// Bonus al VALOR BASE del atributo procedente de pasivas.
  ///
  /// Ejemplo:
  /// FUE base = 16
  /// Pasiva = +2 FUE
  ///
  /// abilityScore(FUE) = 18
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

  /// Valor EFECTIVO del atributo.
  ///
  /// Incluye:
  /// - valor base
  /// - modificaciones de pasivas
  ///
  /// Ejemplo:
  /// FUE base = 16
  /// Pasiva = +2 FUE
  ///
  /// Resultado = 18
  int abilityScore(AbilityType ability) {
    return baseAbilityScore(ability) + passiveAbilityScoreBonus(ability);
  }

  /// Modificador BASE.
  ///
  /// IMPORTANTE:
  /// Se calcula usando únicamente el atributo BASE.
  ///
  /// Ejemplo:
  /// FUE base = 16
  /// Resultado = +3
  int baseAbilityModifier(AbilityType ability) {
    return AbilityScores.modifierFor(baseAbilityScore(ability));
  }

  /// Modificador procedente específicamente de pasivas.
  ///
  /// Este es el sistema de "Mod" de las pasivas.
  ///
  /// No modifica el valor del atributo.
  /// Modifica directamente su modificador.
  ///
  /// Ejemplo:
  /// FUE 16 = +3
  /// Pasiva Mod FUE = +1
  ///
  /// Resultado final = +4
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

  /// Bonus al modificador procedente de efectos activos.
  int effectAbilityModifierBonus(AbilityType ability) {
    return enabledEffects.fold<int>(
      0,
      (sum, effect) => sum + (effect.abilityModifierBonuses[ability] ?? 0),
    );
  }

  /// Modificador EFECTIVO del atributo.
  ///
  /// Orden:
  ///
  /// 1. Calcula el valor efectivo del stat.
  /// 2. Convierte ese stat en modificador.
  /// 3. Añade modificaciones directas al MOD.
  /// 4. Añade modificaciones de efectos.
  ///
  /// Ejemplo:
  ///
  /// FUE base = 16
  /// Base Stat pasiva = +2
  ///
  /// FUE efectiva = 18
  /// Mod natural = +4
  ///
  /// Mod pasiva = +1
  ///
  /// Resultado final = +5
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
    final armor = equippedArmor;

    if (armor == null || armor.armorCategory == null) {
      return 10 + dexterityModifier + totalArmorClassBonus;
    }

    switch (armor.armorCategory!) {
      case ArmorCategory.light:
        return armor.armorBaseClass + dexterityModifier + totalArmorClassBonus;

      case ArmorCategory.medium:
        final dexBonus = dexterityModifier > 2 ? 2 : dexterityModifier;

        return armor.armorBaseClass + dexBonus + totalArmorClassBonus;

      case ArmorCategory.heavy:
        return armor.armorBaseClass + totalArmorClassBonus;
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

  /// Para compatibilidad visual.
  /// En multiclase hay realmente varios dados de golpe.
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

  DamageBonusResult rollDamageBonus(
    DamageBonus bonus, {
    CharacterPassive? passive,
    bool critical = false,
  }) {
    final baseModifier = damageBonusModifier(bonus, passive: passive);

    final modifier = critical ? baseModifier * 2 : baseModifier;

    final roll = DicePoolRoller.roll(
      pools: bonus.dicePools,
      modifier: modifier,
      critical: critical,
    );

    return DamageBonusResult(bonus: bonus, roll: roll);
  }

  // ===========================================================================
  // PUNTOS DE VIDA
  // ===========================================================================

  /// Vida máxima BASE del personaje.
  ///
  /// No incluye pasivas, efectos ni modificadores temporales.
  /// Es el valor desde el que siempre se recalcula la vida efectiva.
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

  /// Vida máxima EFECTIVA.
  ///
  /// Siempre parte de [baseMaxHealth].
  ///
  /// En el futuro aquí se incorporarán también
  /// los nuevos modificadores mediante fórmulas.
  int get maxHealth {
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

  void heal(int amount, {bool dispatchTriggers = true}) {
    if (amount <= 0) {
      return;
    }

    final healthBefore = currentHealth;

    currentHealth += amount;

    if (currentHealth > maxHealth) {
      currentHealth = maxHealth;
    }

    final actualHealing = currentHealth - healthBefore;

    if (actualHealing <= 0) {
      return;
    }

    if (!dispatchTriggers) {
      return;
    }

    // =========================================================================
    // CURACIÓN RECIBIDA
    // =========================================================================

    dispatchPassiveTrigger(
      PassiveTriggerEvent.healingReceived,
      eventVariables: {
        'healing': actualHealing.toDouble(),
        'health_before': healthBefore.toDouble(),
        'health_after': currentHealth.toDouble(),
      },
    );

    // =========================================================================
    // CAMBIO DE VIDA
    // =========================================================================

    dispatchPassiveTrigger(
      PassiveTriggerEvent.healthChanged,
      eventVariables: {
        'amount': actualHealing.toDouble(),
        'health_before': healthBefore.toDouble(),
        'health_after': currentHealth.toDouble(),
      },
    );
  }

  void takeDamage(int amount, {bool dispatchTriggers = true}) {
    if (amount <= 0) {
      return;
    }

    final healthBefore = currentHealth;

    currentHealth -= amount;

    if (currentHealth < 0) {
      currentHealth = 0;
    }

    final actualDamage = healthBefore - currentHealth;

    if (actualDamage <= 0) {
      return;
    }

    if (!dispatchTriggers) {
      return;
    }

    // =========================================================================
    // DAÑO RECIBIDO
    // =========================================================================

    dispatchPassiveTrigger(
      PassiveTriggerEvent.damageReceived,
      eventVariables: {
        'damage': actualDamage.toDouble(),
        'health_before': healthBefore.toDouble(),
        'health_after': currentHealth.toDouble(),
      },
    );

    // =========================================================================
    // CAMBIO DE VIDA
    // =========================================================================

    dispatchPassiveTrigger(
      PassiveTriggerEvent.healthChanged,
      eventVariables: {
        'amount': (-actualDamage).toDouble(),
        'health_before': healthBefore.toDouble(),
        'health_after': currentHealth.toDouble(),
      },
    );
  }

  void fullHeal() {
    currentHealth = maxHealth;
  }

  void addItem(CharacterItem item) {
    items.add(item);
  }

  void removeItem(String id) {
    items.removeWhere((item) => item.id == id);
  }

  CharacterItem? itemById(String id) {
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  // ===========================================================================
  // CALCULADORA DE OBJETOS
  // ===========================================================================

  /// Devuelve cuántas unidades de [target] puede pagar el personaje
  /// usando los objetos definidos en calculationCosts.
  ///
  /// Ejemplo:
  ///
  /// Poción:
  /// 2 × Moneda de oro
  /// 3 × Moneda de plata
  ///
  /// Inventario:
  /// 15 oro
  /// 32 plata
  ///
  /// Resultado:
  /// min(15 ~/ 2, 32 ~/ 3) = 7
  int maxCalculableQuantity(CharacterItem target) {
    if (!target.calculable || target.calculationCosts.isEmpty) {
      return 0;
    }

    int? maximum;

    for (final cost in target.calculationCosts) {
      if (cost.itemId.trim().isEmpty || cost.quantityPerUnit <= 0) {
        return 0;
      }

      final available = itemQuantityById(cost.itemId);

      final possible = available ~/ cost.quantityPerUnit;

      if (maximum == null || possible < maximum) {
        maximum = possible;
      }
    }

    return maximum ?? 0;
  }

  /// Cantidad total de un objeto concreto.
  ///
  /// Se suma por si en algún momento existen varias pilas
  /// con el mismo ID/referencia.
  int itemQuantityById(String itemId) {
    int total = 0;

    for (final item in items) {
      if (item.id == itemId) {
        total += item.quantity;
      }
    }

    return total;
  }

  /// Comprueba si puede pagar [amount] unidades del objeto.
  bool canCalculateItem(CharacterItem target, int amount) {
    if (amount <= 0) {
      return false;
    }

    if (!target.calculable || target.calculationCosts.isEmpty) {
      return false;
    }

    for (final cost in target.calculationCosts) {
      if (cost.quantityPerUnit <= 0) {
        return false;
      }

      final required = cost.quantityPerUnit * amount;

      if (itemQuantityById(cost.itemId) < required) {
        return false;
      }
    }

    return true;
  }

  /// Consume los objetos necesarios.
  ///
  /// IMPORTANTE:
  /// Esto solamente paga el coste.
  /// No añade automáticamente el objeto comprado.
  bool payCalculatedItem(CharacterItem target, int amount) {
    if (!canCalculateItem(target, amount)) {
      return false;
    }

    for (final cost in target.calculationCosts) {
      var remaining = cost.quantityPerUnit * amount;

      for (var i = items.length - 1; i >= 0 && remaining > 0; i--) {
        final item = items[i];

        if (item.id != cost.itemId) {
          continue;
        }

        final consumed = min(item.quantity, remaining);

        item.quantity -= consumed;
        remaining -= consumed;

        // Igual que con tus consumibles:
        // si llega a 0 desaparece del inventario.
        if (item.quantity <= 0) {
          items.removeAt(i);
        }
      }
    }

    return true;
  }

  void equipItem(CharacterItem item) {
    if (!item.type.isEquipable) {
      return;
    }

    if (item.type.exclusiveSlot) {
      for (final other in items) {
        if (other.id == item.id) {
          continue;
        }

        if (other.type == item.type) {
          other.equipped = false;
        }
      }
    }

    item.equipped = true;
  }

  void unequipItem(CharacterItem item) {
    item.equipped = false;
  }

  CharacterItem? itemForPassive(CharacterPassive passive) {
    for (final item in items) {
      for (final itemPassive in item.passives) {
        if (itemPassive.id == passive.id) {
          return item;
        }
      }
    }

    return null;
  }
  // ===========================================================================
  // HABILIDADES D&D
  // ===========================================================================

  int abilityEffectModifier(CharacterAbility ability, AbilityEffect effect) {
    int result = effect.effectBonus;

    // =========================================================================
    // NUEVO SISTEMA
    // =========================================================================

    if (effect.abilityModifierMultipliers.isNotEmpty) {
      result += calculateAbilityMultipliers(effect.abilityModifierMultipliers);
    }
    // =========================================================================
    // LEGACY
    //
    // Las habilidades antiguas usaban el
    // atributo principal de la habilidad.
    // =========================================================================
    else if (effect.legacyAddAbilityModifier) {
      result += abilityModifier(ability.abilityType);
    }

    return result;
  }

  DiceCalculationResult rollAbilityEffectExtra(
    CharacterAbility ability,
    AbilityEffect effect, {
    bool critical = false,
  }) {
    final baseModifier = abilityEffectModifier(ability, effect);

    /*
   * Crítico Asteria:
   *
   * Dados:
   * máximo + tirada
   *
   * Modificadores:
   * ×2
   */
    final modifier = critical ? baseModifier * 2 : baseModifier;

    return DicePoolRoller.roll(
      pools: effect.dicePools,
      modifier: modifier,
      critical: critical,
    );
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

  // ===========================================================================
  // SALVACIONES
  // ===========================================================================

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

  // ===========================================================================
  // ARMAS
  // ===========================================================================

  static final Random _criticalDamageRandom = Random();

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

  // ===========================================================================
  // DAÑO DE ARMAS
  // ===========================================================================

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

  /// Modificador del sistema antiguo.
  ///
  /// Se mantiene porque todavía puede haber
  /// widgets o código usando:
  ///
  /// weapon.damageDice
  /// weapon.damageType
  int damageModifier(Weapon weapon) {
    final modifier = abilityModifier(weapon.attackAbility);

    return modifier + weapon.magicBonus;
  }

  /// Calcula el modificador de un componente
  /// concreto de daño.
  ///
  /// Ejemplo:
  ///
  /// 1d8 + FUE + 1 mágico
  ///
  /// Si:
  /// FUE = +4
  /// magicBonus = +1
  ///
  /// resultado = +5
  int weaponDamageModifier(Weapon weapon, WeaponDamage damage) {
    int result = damage.bonus;

    // -------------------------------------------------------------------------
    // ATRIBUTO
    // -------------------------------------------------------------------------

    if (damage.addAbilityModifier) {
      result += abilityModifier(damage.abilityType);
    }

    // -------------------------------------------------------------------------
    // BONUS MÁGICO
    //
    // Solo se aplica al PRIMER componente.
    //
    // Ejemplo:
    //
    // Espada +1
    //
    // 1d8 + FUE + 1 cortante
    // 1d6 fuego
    //
    // y NO:
    //
    // 1d8 + FUE + 1
    // 1d6 + 1
    // -------------------------------------------------------------------------

    if (weapon.damages.isNotEmpty && identical(weapon.damages.first, damage)) {
      result += weapon.magicBonus;
    }

    return result;
  }

  /// Texto de un componente de daño.
  ///
  /// Ejemplo:
  ///
  /// 1d8 + 5 Cortante
  ///
  /// 2d6 Fuego
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

  /// Texto completo del daño del arma.
  ///
  /// Nuevo sistema:
  ///
  /// 1d8 + 5 Cortante + 1d6 Fuego
  ///
  /// Si no existen damages, utiliza el
  /// sistema antiguo automáticamente.
  String damageText(Weapon weapon) {
    // -------------------------------------------------------------------------
    // NUEVO SISTEMA
    // -------------------------------------------------------------------------

    if (weapon.damages.isNotEmpty) {
      return weapon.damages
          .map((damage) => weaponDamagePartText(weapon, damage))
          .join(' + ');
    }

    // -------------------------------------------------------------------------
    // LEGACY
    // -------------------------------------------------------------------------

    final modifier = damageModifier(weapon);

    if (modifier == 0) {
      return '${weapon.damageDice} ${weapon.damageType}'.trim();
    }

    final modifierText = modifier > 0 ? '+ $modifier' : '- ${modifier.abs()}';

    return '${weapon.damageDice} $modifierText ${weapon.damageType}'.trim();
  }

  // ===========================================================================
  // TIRADA DE UN COMPONENTE
  // ===========================================================================

  HealingBonusResult rollHealingBonus(
    HealingBonus bonus, {
    CharacterPassive? passive,
  }) {
    final modifier = healingBonusModifier(bonus, passive: passive);

    final roll = DicePoolRoller.roll(
      pools: bonus.dicePools,
      modifier: modifier,
      critical: false,
    );

    return HealingBonusResult(bonus: bonus, roll: roll);
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

  CriticalDamageBonusResult rollCriticalDamageBonus(CriticalDamageBonus bonus) {
    final chance = bonus.chancePercent.clamp(0, 100);

    int chanceRoll;

    bool triggered;

    if (chance >= 100) {
      chanceRoll = 100;

      triggered = true;
    } else if (chance <= 0) {
      chanceRoll = 1;

      triggered = false;
    } else {
      chanceRoll = _criticalDamageRandom.nextInt(100) + 1;

      triggered = chanceRoll <= chance;
    }

    if (!triggered) {
      return CriticalDamageBonusResult(
        bonus: bonus,
        chanceRoll: chanceRoll,
        triggered: false,
      );
    }

    final modifier = criticalDamageBonusModifier(bonus);

    final roll = DicePoolRoller.roll(
      pools: bonus.dicePools,

      modifier: modifier,

      critical: false,
    );

    return CriticalDamageBonusResult(
      bonus: bonus,
      chanceRoll: chanceRoll,
      triggered: true,
      roll: roll,
    );
  }

  List<CriticalDamageBonusResult> rollActiveCriticalDamageBonuses({
    Weapon? weapon,
  }) {
    final results = <CriticalDamageBonusResult>[];

    final bonuses = activeCriticalDamageBonuses(weapon);

    for (final bonus in bonuses) {
      if (!bonus.canTrigger) {
        continue;
      }

      results.add(rollCriticalDamageBonus(bonus));
    }

    return results;
  }

  /*
   * En Asteria un crítico duplica:
   *
   * - todos los dados de daño
   * - todos los modificadores de daño
   *
   * Ejemplo:
   *
   * 1d8 + 4
   *
   * pasa a:
   *
   * 2d8 + 8
   */
  DiceCalculationResult rollWeaponDamagePart(
    Weapon weapon,
    WeaponDamage damage, {
    bool critical = false,
  }) {
    final baseModifier = weaponDamageModifier(weapon, damage);

    final modifier = critical ? baseModifier * 2 : baseModifier;

    return DicePoolRoller.roll(
      pools: damage.dicePools,

      modifier: modifier,

      critical: critical,
    );
  }

  DiceCalculationResult? rollWeaponCriticalDamagePart(WeaponDamage damage) {
    if (damage.criticalDicePools.isEmpty) {
      return null;
    }

    return DicePoolRoller.roll(
      pools: damage.criticalDicePools,
      modifier: 0,
      critical: false,
    );
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

  DiceCalculationResult rollAbilityEffectPart(
    AbilityEffectPart part, {
    bool critical = false,
  }) {
    final baseModifier = abilityEffectPartModifier(part);

    final finalModifier = critical ? baseModifier * 2 : baseModifier;

    return DicePoolRoller.roll(
      pools: part.dicePools,
      modifier: finalModifier,
      critical: critical,
    );
  }

  // ===========================================================================
  // TIRADA COMPLETA DEL ARMA
  // ===========================================================================

  WeaponDamageResult rollWeaponDamage(Weapon weapon, {bool critical = false}) {
    final parts = <WeaponDamagePartResult>[];

    final bonusDamageParts = <DamageBonusResult>[];

    final criticalBonusParts = <CriticalDamageBonusResult>[];

    // =========================================================================
    // DAÑO PROPIO DEL ARMA
    // =========================================================================

    if (weapon.damages.isNotEmpty) {
      for (final damage in weapon.damages) {
        final roll = rollWeaponDamagePart(weapon, damage, critical: critical);

        final criticalExtraRoll = critical
            ? rollWeaponCriticalDamagePart(damage)
            : null;

        parts.add(
          WeaponDamagePartResult(
            damage: damage,
            roll: roll,
            criticalExtraRoll: criticalExtraRoll,
          ),
        );
      }
    } else {
      /*
     * Fallback legacy.
     */
      final legacyDamage = _legacyWeaponDamage(weapon);

      if (legacyDamage != null) {
        final roll = rollWeaponDamagePart(
          weapon,
          legacyDamage,
          critical: critical,
        );

        parts.add(WeaponDamagePartResult(damage: legacyDamage, roll: roll));
      }
    }

    // =========================================================================
    // DAÑOS DE PASIVAS Y ESTADOS
    //
    // SE APLICAN SIEMPRE
    // =========================================================================

    bonusDamageParts.addAll(rollActiveDamageBonuses(critical: critical));

    // =========================================================================
    // DADOS EXTRA GENERADOS POR CRÍTICO
    //
    // SOLO EN CRÍTICO
    // =========================================================================

    if (critical) {
      criticalBonusParts.addAll(
        rollActiveCriticalDamageBonuses(weapon: weapon),
      );
    }

    return WeaponDamageResult(
      parts: parts,

      bonusDamageParts: bonusDamageParts,

      criticalBonusParts: criticalBonusParts,

      critical: critical,
    );
  }

  // ===========================================================================
  // LEGACY → WEAPON DAMAGE
  // ===========================================================================

  WeaponDamage? _legacyWeaponDamage(Weapon weapon) {
    final match = RegExp(
      r'^(\d+)d(\d+)$',
      caseSensitive: false,
    ).firstMatch(weapon.damageDice.trim());

    if (match == null) {
      return null;
    }

    final count = int.tryParse(match.group(1) ?? '');

    final sides = int.tryParse(match.group(2) ?? '');

    if (count == null || sides == null || count <= 0 || sides <= 0) {
      return null;
    }

    return WeaponDamage(
      id: '${weapon.id}_legacy_damage',

      name: 'Daño',

      dicePools: [DicePool(count: count, sides: sides)],

      addAbilityModifier: true,

      abilityType: weapon.attackAbility,

      damageType: weapon.damageType,
    );
  }

  // ===========================================================================
  // TEXTO DE ATAQUE
  // ===========================================================================

  String attackBonusText(Weapon weapon) {
    final bonus = attackBonus(weapon);

    return bonus >= 0 ? '+$bonus' : '$bonus';
  }

  // ===========================================================================
  // CRUD ARMAS
  // ===========================================================================

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

  // ===========================================================================
  // HABILIDADES ACTIVAS
  // ===========================================================================

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

  DiceCalculationResult rollAbilityEffect(
    CharacterAbility ability, {
    bool critical = false,
  }) {
    final isCritical =
        critical && ability.effectType == AbilityEffectType.damage;

    final baseModifier = characterAbilityEffectModifier(ability);

    final modifier = isCritical ? baseModifier * 2 : baseModifier;

    return DicePoolRoller.roll(
      pools: ability.dicePools,
      modifier: modifier,
      critical: isCritical,
    );
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

  CharacterItem? get equippedArmor {
    for (final item in items) {
      if (item.equipped && item.type == ItemType.armor) {
        return item;
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

  void useCharacterAbility(CharacterAbility ability) {
    if (!ability.hasLimitedUses) {
      return;
    }

    if (ability.currentUses > 0) {
      ability.currentUses--;
    }
  }

  void restoreCharacterAbility(CharacterAbility ability) {
    if (!ability.hasLimitedUses) {
      return;
    }

    ability.currentUses = ability.maxUses;
  }

  void restoreAllAbilities() {
    for (final ability in characterAbilities) {
      restoreCharacterAbility(ability);
    }
  }

  // ===========================================================================
  // TIRADAS DE PASIVAS
  // ===========================================================================

  int passiveRollModifier(CharacterPassive passive) {
    return passive.rollFlatBonus +
        calculateAbilityMultipliers(passive.rollAbilityModifierMultipliers);
  }

  DiceCalculationResult rollPassive(CharacterPassive passive) {
    final modifier = passiveRollModifier(passive);

    return DicePoolRoller.roll(
      pools: passive.rollDicePools,
      modifier: modifier,
      critical: false,
    );
  }

  String passiveRollText(CharacterPassive passive) {
    if (!passive.hasRoll) {
      return '';
    }

    final pieces = <String>[];

    if (passive.rollDiceNotation.isNotEmpty) {
      pieces.add(passive.rollDiceNotation);
    }

    for (final entry in passive.rollAbilityModifierMultipliers.entries) {
      if (entry.value == 0) {
        continue;
      }

      if (entry.value == 1) {
        pieces.add(entry.key.shortLabel);
      } else {
        pieces.add('${entry.value}×${entry.key.shortLabel}');
      }
    }

    if (passive.rollFlatBonus != 0) {
      pieces.add(
        passive.rollFlatBonus > 0
            ? '+${passive.rollFlatBonus}'
            : '${passive.rollFlatBonus}',
      );
    }

    return pieces.join(' + ').replaceAll('+ -', '- ');
  }

  // ===========================================================================
  // PASIVAS
  // ===========================================================================

  Iterable<CharacterPassive> get enabledPassives {
    final normalPassives = passives.where((passive) => passive.enabled);

    final itemPassives = items
        .where((item) => item.equipped)
        .expand((item) => item.passives)
        .where((passive) => passive.enabled);

    return [...normalPassives, ...itemPassives];
  }

  List<CharacterAbility> get availableAbilities {
    final result = <CharacterAbility>[...characterAbilities];

    for (final item in items) {
      if (!item.equipped) {
        continue;
      }

      result.addAll(item.abilities);
    }

    return result;
  }

  CharacterItem? itemForAbility(CharacterAbility ability) {
    for (final item in items) {
      for (final itemAbility in item.abilities) {
        if (itemAbility.id == ability.id) {
          return item;
        }
      }
    }

    return null;
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

  void addPassive(CharacterPassive passive) {
    passives.add(passive);
  }

  void removePassive(String id) {
    passives.removeWhere((passive) => passive.id == id);
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

  // ===========================================================================
  // DIARIO
  // ===========================================================================

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

  // ===========================================================================
  // CONTADORES
  // ===========================================================================

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

  // ===========================================================================
  // INCREMENTAR
  // ===========================================================================

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

    final previousValue = counter.value;

    counter.increase(amount);

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
      },
    );
  }

  // ===========================================================================
  // COMPATIBILIDAD CON EL MÉTODO ANTIGUO
  // ===========================================================================

  void increaseCounter(
    String counterId, {
    int amount = 1,
    bool dispatchTriggers = true,
  }) {
    incrementCounter(counterId, amount, dispatchTriggers: dispatchTriggers);
  }

  // ===========================================================================
  // ESTABLECER
  // ===========================================================================

  void setCounter(String counterId, int value, {bool dispatchTriggers = true}) {
    final counter = counterById(counterId);

    if (counter == null) {
      return;
    }

    final previousValue = counter.value;

    // Evitamos valores negativos.
    final safeValue = value < 0 ? 0 : value;

    counter.value = safeValue;

    if (!dispatchTriggers || previousValue == counter.value) {
      return;
    }

    dispatchPassiveTrigger(
      PassiveTriggerEvent.counterChanged,
      eventVariables: {
        'previous_counter': previousValue.toDouble(),
        'current_counter': counter.value.toDouble(),
        'counter_change': (counter.value - previousValue).toDouble(),
      },
    );
  }

  // ===========================================================================
  // RESET
  // ===========================================================================

  void resetCounter(String counterId, {bool dispatchTriggers = true}) {
    setCounter(counterId, 0, dispatchTriggers: dispatchTriggers);
  }

  // ===========================================================================
  // HISTORIAL DE DADOS
  // ===========================================================================

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
      'race': race,

      // Nuevo sistema multiclase.
      'classes': classes.map((item) => item.toMap()).toList(),

      // Compatibilidad con instalaciones anteriores.
      'dndClass': primaryClass.name,
      'level': level,

      'abilities': abilities.toMap(),

      'currentHealth': currentHealth,

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

      'resources': resources.map((resource) => resource.toMap()).toList(),

      'effects': effects.map((effect) => effect.toMap()).toList(),

      'combatRound': combatRound,

      'turnActive': turnActive,

      'counters': counters.map((counter) => counter.toMap()).toList(),

      'criticalMinimumNaturalRoll': criticalMinimumNaturalRoll,
    };
  }

  factory Character.fromMap(Map<dynamic, dynamic> map) {
    final items = <CharacterItem>[];

    final rawItems = map['items'];

    if (rawItems is List) {
      for (final rawItem in rawItems) {
        if (rawItem == null) {
          continue;
        }

        try {
          items.add(CharacterItem.fromMap(Map<dynamic, dynamic>.from(rawItem)));
        } catch (_) {
          continue;
        }
      }
    }

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

    // -------------------------------------------------------------------------
    // RECURSOS PERSONALIZADOS
    // -------------------------------------------------------------------------

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

    // -------------------------------------------------------------------------
    // CLASES
    // -------------------------------------------------------------------------

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

    /*
     * Migración automática de personajes antiguos.
     */
    if (classes.isEmpty) {
      final rawLegacyClass = map['dndClass'] ?? map['characterClass'];

      classes.add(
        CharacterClassLevel(
          dndClass: DndClassData.fromString(rawLegacyClass?.toString()),
          level: (map['level'] as num?)?.toInt() ?? 1,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // ATRIBUTOS
    // -------------------------------------------------------------------------

    final rawAbilities = map['abilities'];

    final abilities = rawAbilities is Map
        ? AbilityScores.fromMap(Map<dynamic, dynamic>.from(rawAbilities))
        : AbilityScores();

    // -------------------------------------------------------------------------
    // SKILLS
    // -------------------------------------------------------------------------

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

    final effectTemplates = <CharacterEffect>[];

    final rawEffectTemplates = map['effectTemplates'];

    if (rawEffectTemplates is List) {
      for (final rawEffect in rawEffectTemplates) {
        if (rawEffect == null) {
          continue;
        }

        try {
          effectTemplates.add(
            CharacterEffect.fromMap(Map<dynamic, dynamic>.from(rawEffect)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    // -------------------------------------------------------------------------
    // SALVACIONES
    // -------------------------------------------------------------------------

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

    // -------------------------------------------------------------------------
    // ARMAS
    // -------------------------------------------------------------------------

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

    // -------------------------------------------------------------------------
    // HABILIDADES ACTIVAS
    // -------------------------------------------------------------------------

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

    // -------------------------------------------------------------------------
    // PASIVAS
    // -------------------------------------------------------------------------

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

    // -------------------------------------------------------------------------
    // DIARIO
    // -------------------------------------------------------------------------

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

    // -------------------------------------------------------------------------
    // HISTORIAL DE DADOS
    // -------------------------------------------------------------------------

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

    final combatRound = (map['combatRound'] as num?)?.toInt() ?? 1;

    final turnActive = map['turnActive'] == true;

    // -------------------------------------------------------------------------
    // CREAR PERSONAJE
    // -------------------------------------------------------------------------

    final character = Character(
      id: map['id']?.toString() ?? '',

      name: map['name']?.toString() ?? '',

      avatarPath: map['avatarPath']?.toString(),

      race: map['race']?.toString() ?? '',

      classes: classes,

      abilities: abilities,

      currentHealth: (map['currentHealth'] as num?)?.toInt(),

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

      resources: resources,

      effects: effects,

      combatRound: combatRound,

      turnActive: turnActive,

      counters: counters,

      criticalMinimumNaturalRoll:
          (map['criticalMinimumNaturalRoll'] as num?)?.toInt() ?? 20,
    );

    character.normalizeHealth();

    return character;
  }
}
