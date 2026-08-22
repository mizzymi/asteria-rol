import 'dart:math';
import 'package:rol/models/ability_effect_part.dart';

import 'character_resource.dart';
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

  List<DamageBonus> get activeDamageBonuses {
    final result = <DamageBonus>[];

    for (final passive in enabledPassives) {
      result.addAll(passive.damageBonuses);
    }

    for (final effect in enabledEffects) {
      result.addAll(effect.damageBonuses);
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

    for (final bonus in activeDamageBonuses) {
      if (!bonus.hasDamage) {
        continue;
      }

      results.add(rollDamageBonus(bonus, critical: critical));
    }

    return results;
  }

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
    resource.consume(amount);
  }

  void restoreResource(CharacterResource resource, int amount) {
    resource.restore(amount);
  }

  void restoreResourceFull(CharacterResource resource) {
    resource.restoreFull();
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
  // ATRIBUTOS / MODIFICADORES
  // ===========================================================================

  /// Modificador natural del atributo, sin pasivas.
  ///
  /// Ejemplo:
  /// SAB 16 = +3
  int baseAbilityModifier(AbilityType ability) {
    return abilities.modifierByType(ability);
  }

  /// Modificador efectivo del atributo.
  ///
  /// Incluye:
  /// - modificador natural
  /// - bonus de pasivas
  /// - bonus de objetos equipados
  ///
  /// Ejemplo:
  /// SAB 16 = +3
  /// Pasiva = +1 SAB
  /// Resultado = +4
  int abilityModifier(AbilityType ability) {
    return baseAbilityModifier(ability) +
        passiveAbilityModifierBonus(ability) +
        effectAbilityModifierBonus(ability);
  }

  int get strengthModifier => abilityModifier(AbilityType.strength);

  int get dexterityModifier => abilityModifier(AbilityType.dexterity);

  int get constitutionModifier => abilityModifier(AbilityType.constitution);

  int get intelligenceModifier => abilityModifier(AbilityType.intelligence);

  int get wisdomModifier => abilityModifier(AbilityType.wisdom);

  int get charismaModifier => abilityModifier(AbilityType.charisma);

  int effectAbilityModifierBonus(AbilityType ability) {
    return enabledEffects.fold<int>(
      0,
      (sum, effect) => sum + (effect.abilityModifierBonuses[ability] ?? 0),
    );
  }

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

  int damageBonusModifier(DamageBonus bonus) {
    return bonus.flatBonus +
        calculateAbilityMultipliers(bonus.abilityModifierMultipliers);
  }

  DamageBonusResult rollDamageBonus(
    DamageBonus bonus, {
    bool critical = false,
  }) {
    final baseModifier = damageBonusModifier(bonus);

    /*
   * Crítico Asteria:
   *
   * máximo dados
   * + tirada
   * + modificador
   * + modificador
   */
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

  /// Vida máxima del personaje.
  ///
  /// Cada nivel aporta:
  ///
  /// dado de vida de la clase + modificador de Constitución
  ///
  /// Ejemplo:
  ///
  /// Guerrero d10
  /// CON +3
  /// Nivel 5
  ///
  /// (10 + 3) × 5 = 65 PG
  ///
  /// En multiclase cada nivel utiliza el dado de vida
  /// correspondiente a esa clase.
  int get maxHealth {
    if (classes.isEmpty) {
      return 1 + passiveMaxHealthBonus;
    }

    final conMod = constitutionModifier;

    int total = 0;

    for (final classLevel in classes) {
      final levels = classLevel.level < 1 ? 1 : classLevel.level;

      final hitDie = classLevel.dndClass.hitDie;

      /*
     * Vida obtenida por cada nivel
     * de esta clase.
     */
      final healthPerLevel = hitDie + conMod;

      /*
     * Cada nivel debe proporcionar
     * como mínimo 1 PG.
     */
      final safeHealthPerLevel = healthPerLevel < 1 ? 1 : healthPerLevel;

      total += safeHealthPerLevel * levels;
    }

    /*
   * Las pasivas que aumentan la vida máxima
   * se añaden al total final.
   */
    total += passiveMaxHealthBonus;
    total += effectMaxHealthBonus;

    return total < 1 ? 1 : total;
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

  void heal(int amount) {
    if (amount <= 0) {
      return;
    }

    currentHealth += amount;

    normalizeHealth();
  }

  void takeDamage(int amount) {
    if (amount <= 0) {
      return;
    }

    currentHealth -= amount;

    normalizeHealth();
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

  HealingBonusResult rollHealingBonus(HealingBonus bonus) {
    final modifier =
        bonus.flatBonus +
        calculateAbilityMultipliers(bonus.abilityModifierMultipliers);

    final roll = DicePoolRoller.roll(
      pools: bonus.dicePools,

      modifier: modifier,

      critical: false,
    );

    return HealingBonusResult(bonus: bonus, roll: roll);
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

    final modifier =
        bonus.flatBonus +
        calculateAbilityMultipliers(bonus.abilityModifierMultipliers);

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

  DiceCalculationResult rollAbilityEffectPart(
    AbilityEffectPart part, {
    bool critical = false,
  }) {
    final abilityModifier = calculateAbilityMultipliers(
      part.abilityModifierMultipliers,
    );

    final resourceModifier = calculateResourceValueMultipliers(
      part.resourceValueMultipliers,
    );

    final baseModifier = part.flatBonus + abilityModifier + resourceModifier;

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

        parts.add(WeaponDamagePartResult(damage: damage, roll: roll));
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
  // PASIVAS
  // ===========================================================================

  int passiveAbilityModifierBonus(AbilityType ability) {
    return enabledPassives.fold<int>(
      0,
      (sum, passive) => sum + (passive.abilityModifierBonuses[ability] ?? 0),
    );
  }

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
    return enabledPassives.fold<int>(
      0,
      (sum, passive) => sum + passive.armorClassBonus,
    );
  }

  int get passiveInitiativeBonus {
    return enabledPassives.fold<int>(
      0,
      (sum, passive) => sum + passive.initiativeBonus,
    );
  }

  int get passiveSpeedBonus {
    return enabledPassives.fold<int>(
      0,
      (sum, passive) => sum + passive.speedBonus,
    );
  }

  int get passiveMaxHealthBonus {
    return enabledPassives.fold<int>(
      0,
      (sum, passive) => sum + passive.maxHealthBonus,
    );
  }

  int get passiveAttackBonus {
    return enabledPassives.fold<int>(
      0,
      (sum, passive) => sum + passive.attackBonus,
    );
  }

  int passiveSkillBonus(DndSkill skill) {
    return enabledPassives.fold<int>(
      0,
      (sum, passive) => sum + (passive.skillBonuses[skill] ?? 0),
    );
  }

  int passiveSavingThrowBonus(AbilityType ability) {
    return enabledPassives.fold<int>(
      0,
      (sum, passive) => sum + (passive.savingThrowBonuses[ability] ?? 0),
    );
  }

  void addPassive(CharacterPassive passive) {
    passives.add(passive);
  }

  void removePassive(String id) {
    passives.removeWhere((passive) => passive.id == id);
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
    );

    character.normalizeHealth();

    return character;
  }
}
