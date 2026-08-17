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
    return baseAbilityModifier(ability) + passiveAbilityModifierBonus(ability);
  }

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

  int get initiative => dexterityModifier + passiveInitiativeBonus;

  int get calculatedArmorClass {
    final armor = equippedArmor;

    /*
   * Sin armadura:
   * 10 + DES
   */
    if (armor == null || armor.armorCategory == null) {
      return 10 + dexterityModifier;
    }

    switch (armor.armorCategory!) {
      /*
     * Ligera:
     *
     * CA base + toda DES
     */
      case ArmorCategory.light:
        return armor.armorBaseClass + dexterityModifier;

      /*
     * Media:
     *
     * CA base + DES
     * máximo +2
     */
      case ArmorCategory.medium:
        final dexBonus = dexterityModifier > 2 ? 2 : dexterityModifier;

        return armor.armorBaseClass + dexBonus;

      /*
     * Pesada:
     *
     * Solo CA base.
     */
      case ArmorCategory.heavy:
        return armor.armorBaseClass;
    }
  }

  int get totalSpeed => speed + passiveSpeedBonus;

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

    return total < 1 ? 1 : total;
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

    if (effect.addAbilityModifierToEffect) {
      result += abilityModifier(ability.abilityType);
    }

    return result;
  }

  DiceCalculationResult rollAbilityEffectPart(
    CharacterAbility ability,
    AbilityEffect effect, {
    bool critical = false,
  }) {
    return DicePoolRoller.roll(
      pools: effect.dicePools,
      modifier: abilityEffectModifier(ability, effect),
      critical:
          critical &&
          ability.requiresAttackRoll &&
          !effect.usesSavingThrow &&
          effect.effectType == AbilityEffectType.damage,
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
        passiveSkillBonus(skill);
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
        passiveSavingThrowBonus(ability);
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

  int attackBonus(Weapon weapon) {
    final modifier = abilityModifier(weapon.attackAbility);

    final proficiency = weapon.proficient ? proficiencyBonus : 0;

    return modifier + proficiency + weapon.magicBonus + passiveAttackBonus;
  }

  int damageModifier(Weapon weapon) {
    final modifier = abilityModifier(weapon.attackAbility);

    return modifier + weapon.magicBonus;
  }

  String attackBonusText(Weapon weapon) {
    final bonus = attackBonus(weapon);

    return bonus >= 0 ? '+$bonus' : '$bonus';
  }

  String damageText(Weapon weapon) {
    final modifier = damageModifier(weapon);

    if (modifier == 0) {
      return '${weapon.damageDice} ${weapon.damageType}';
    }

    final modifierText = modifier > 0 ? '+ $modifier' : '- ${modifier.abs()}';

    return '${weapon.damageDice} $modifierText ${weapon.damageType}';
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

  // ===========================================================================
  // HABILIDADES ACTIVAS
  // ===========================================================================

  int characterAbilityAttackBonus(CharacterAbility ability) {
    final modifier = abilityModifier(ability.abilityType);

    final proficiency = ability.proficient ? proficiencyBonus : 0;

    return modifier + proficiency + ability.attackBonus + passiveAttackBonus;
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
    return DicePoolRoller.roll(
      pools: ability.dicePools,
      modifier: characterAbilityEffectModifier(ability),
      critical: critical && ability.effectType == AbilityEffectType.damage,
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
    );

    character.normalizeHealth();

    return character;
  }
}
