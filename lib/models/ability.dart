import 'package:rol/models/character_effect.dart';

import 'dice_pool.dart';
import 'skill.dart';
import 'ability_effect_part.dart';

enum AbilityActionType { action, bonusAction, reaction, passive }

enum AbilityTargetType {
  self,
  external,
  selfOrExternal,
  multipleExternal,
  areaIncludingSelf,
  areaExcludingSelf,
}

extension AbilityTargetTypeData on AbilityTargetType {
  String get label {
    switch (this) {
      case AbilityTargetType.self:
        return 'Uno mismo';

      case AbilityTargetType.external:
        return 'Objetivo externo';

      case AbilityTargetType.selfOrExternal:
        return 'Uno mismo u otro';

      case AbilityTargetType.multipleExternal:
        return 'Varios objetivos externos';

      case AbilityTargetType.areaIncludingSelf:
        return 'Área incluyendo al personaje';

      case AbilityTargetType.areaExcludingSelf:
        return 'Área excluyendo al personaje';
    }
  }

  bool get canIncludeSelf {
    switch (this) {
      case AbilityTargetType.self:
      case AbilityTargetType.selfOrExternal:
      case AbilityTargetType.areaIncludingSelf:
        return true;

      case AbilityTargetType.external:
      case AbilityTargetType.multipleExternal:
      case AbilityTargetType.areaExcludingSelf:
        return false;
    }
  }

  bool get canIncludeExternalTargets {
    switch (this) {
      case AbilityTargetType.self:
        return false;

      case AbilityTargetType.external:
      case AbilityTargetType.selfOrExternal:
      case AbilityTargetType.multipleExternal:
      case AbilityTargetType.areaIncludingSelf:
      case AbilityTargetType.areaExcludingSelf:
        return true;
    }
  }

  bool get supportsMultipleTargets {
    switch (this) {
      case AbilityTargetType.multipleExternal:
      case AbilityTargetType.areaIncludingSelf:
      case AbilityTargetType.areaExcludingSelf:
        return true;

      case AbilityTargetType.self:
      case AbilityTargetType.external:
      case AbilityTargetType.selfOrExternal:
        return false;
    }
  }
}

enum AbilityTargetResolutionMode { shared, independent }

extension AbilityTargetResolutionModeData on AbilityTargetResolutionMode {
  String get label {
    switch (this) {
      case AbilityTargetResolutionMode.shared:
        return 'Resolución compartida';

      case AbilityTargetResolutionMode.independent:
        return 'Resolución independiente';
    }
  }
}

extension AbilityActionTypeData on AbilityActionType {
  String get label {
    switch (this) {
      case AbilityActionType.action:
        return 'Acción';

      case AbilityActionType.bonusAction:
        return 'Acción adicional';

      case AbilityActionType.reaction:
        return 'Reacción';

      case AbilityActionType.passive:
        return 'Pasiva';
    }
  }
}

enum AbilityEffectType { damage, healing, none }

extension AbilityEffectTypeData on AbilityEffectType {
  String get label {
    switch (this) {
      case AbilityEffectType.damage:
        return 'Daño';

      case AbilityEffectType.healing:
        return 'Curación';

      case AbilityEffectType.none:
        return 'Sin daño/curación';
    }
  }
}

enum SaveSuccessEffect { full, half, none }

extension SaveSuccessEffectData on SaveSuccessEffect {
  String get label {
    switch (this) {
      case SaveSuccessEffect.full:
        return 'Daño completo';

      case SaveSuccessEffect.half:
        return 'Mitad';

      case SaveSuccessEffect.none:
        return 'Sin daño';
    }
  }
}

// ============================================================================
// ABILITY EFFECT
// ============================================================================

class AbilityEffect {
  String id;

  String name;

  AbilityEffectType effectType;

  // ==========================================================================
  // CAMPOS LEGACY
  //
  // Se mantienen para poder cargar datos antiguos.
  //
  // El sistema moderno debe trabajar principalmente con:
  //
  // parts
  // ==========================================================================

  List<DicePool> dicePools;

  Map<AbilityType, int> abilityModifierMultipliers;

  int effectBonus;

  String effectTypeName;

  bool legacyAddAbilityModifier;

  // ==========================================================================
  // SISTEMA MODERNO
  // ==========================================================================

  List<AbilityEffectPart> parts;

  // ==========================================================================
  // TIRADA DE SALVACIÓN
  // ==========================================================================

  bool usesSavingThrow;

  AbilityType savingThrowAbility;

  int saveDcBonus;

  SaveSuccessEffect saveSuccessEffect;

  AbilityEffect({
    required this.id,
    this.name = '',
    this.effectType = AbilityEffectType.damage,
    List<DicePool>? dicePools,
    Map<AbilityType, int>? abilityModifierMultipliers,
    this.legacyAddAbilityModifier = false,
    this.effectBonus = 0,
    this.effectTypeName = '',
    this.usesSavingThrow = false,
    this.savingThrowAbility = AbilityType.dexterity,
    this.saveDcBonus = 0,
    this.saveSuccessEffect = SaveSuccessEffect.half,
    List<AbilityEffectPart>? parts,
  }) : dicePools = dicePools ?? [],
       parts = parts ?? [],
       abilityModifierMultipliers = abilityModifierMultipliers ?? {};

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  bool get hasEffect {
    if (effectType == AbilityEffectType.none) {
      return false;
    }

    // Sistema moderno.
    if (parts.any((part) => part.hasValue)) {
      return true;
    }

    // Compatibilidad legacy.
    return dicePools.isNotEmpty ||
        abilityModifierMultipliers.values.any((value) => value != 0) ||
        effectBonus != 0 ||
        legacyAddAbilityModifier;
  }

  bool get dealsDamage {
    return effectType == AbilityEffectType.damage;
  }

  bool get heals {
    return effectType == AbilityEffectType.healing;
  }

  String get diceNotation {
    // Sistema moderno.
    if (parts.isNotEmpty) {
      final notations = parts
          .where((part) => part.diceNotation.isNotEmpty)
          .map((part) => part.diceNotation)
          .toList();

      if (notations.isNotEmpty) {
        return notations.join(' + ');
      }
    }

    // Compatibilidad legacy.
    if (dicePools.isEmpty) {
      return '';
    }

    return dicePools.map((pool) => pool.notation).join(' + ');
  }

  // ==========================================================================
  // SERIALIZACIÓN
  // ==========================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,

      'name': name,

      'effectType': effectType.name,

      // Legacy.
      'dicePools': dicePools.map((pool) => pool.toMap()).toList(),

      'abilityModifierMultipliers': {
        for (final entry in abilityModifierMultipliers.entries)
          entry.key.name: entry.value,
      },

      'addAbilityModifierToEffect': legacyAddAbilityModifier,

      'effectBonus': effectBonus,

      'effectTypeName': effectTypeName,

      // Moderno.
      'parts': parts.map((part) => part.toMap()).toList(),

      // Salvación.
      'usesSavingThrow': usesSavingThrow,

      'savingThrowAbility': savingThrowAbility.name,

      'saveDcBonus': saveDcBonus,

      'saveSuccessEffect': saveSuccessEffect.name,
    };
  }

  factory AbilityEffect.fromMap(Map<dynamic, dynamic> map) {
    // ========================================================================
    // DADOS LEGACY
    // ========================================================================

    final pools = <DicePool>[];

    final rawPools = map['dicePools'];

    if (rawPools is List) {
      for (final rawPool in rawPools) {
        if (rawPool is! Map) {
          continue;
        }

        try {
          pools.add(DicePool.fromMap(Map<dynamic, dynamic>.from(rawPool)));
        } catch (_) {
          continue;
        }
      }
    }

    // ========================================================================
    // PARTES MODERNAS
    // ========================================================================

    final parts = <AbilityEffectPart>[];

    final rawParts = map['parts'];

    if (rawParts is List) {
      for (final rawPart in rawParts) {
        if (rawPart is! Map) {
          continue;
        }

        try {
          parts.add(
            AbilityEffectPart.fromMap(Map<dynamic, dynamic>.from(rawPart)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    // ========================================================================
    // MODIFICADORES LEGACY
    // ========================================================================

    final abilityModifierMultipliers = <AbilityType, int>{};

    final rawMultipliers = map['abilityModifierMultipliers'];

    if (rawMultipliers is Map) {
      final multiplierMap = Map<dynamic, dynamic>.from(rawMultipliers);

      for (final ability in AbilityType.values) {
        final value = (multiplierMap[ability.name] as num?)?.toInt() ?? 0;

        if (value != 0) {
          abilityModifierMultipliers[ability] = value;
        }
      }
    }

    final legacyAddAbilityModifier =
        map['addAbilityModifierToEffect'] as bool? ?? false;

    final effectBonus = (map['effectBonus'] as num?)?.toInt() ?? 0;

    final effectTypeName = map['effectTypeName']?.toString() ?? '';

    // ========================================================================
    // MIGRACIÓN LOCAL
    //
    // Si no existen parts pero sí información legacy que podemos migrar
    // sin necesitar conocer el atributo principal de CharacterAbility,
    // creamos una parte.
    //
    // El caso legacyAddAbilityModifier se termina de resolver más abajo
    // desde CharacterAbility.fromMap(), porque allí sí conocemos abilityType.
    // ========================================================================

    if (parts.isEmpty &&
        (pools.isNotEmpty ||
            abilityModifierMultipliers.isNotEmpty ||
            effectBonus != 0)) {
      parts.add(
        AbilityEffectPart(
          id: '${map['id']}_part_0',

          dicePools: List<DicePool>.from(pools),

          abilityModifierMultipliers: Map<AbilityType, int>.from(
            abilityModifierMultipliers,
          ),

          flatBonus: effectBonus,

          typeName: effectTypeName,
        ),
      );
    }

    return AbilityEffect(
      id: map['id']?.toString() ?? '',

      name: map['name']?.toString() ?? '',

      effectType: AbilityEffectType.values.firstWhere(
        (item) => item.name == map['effectType'],
        orElse: () => AbilityEffectType.damage,
      ),

      dicePools: pools,

      abilityModifierMultipliers: abilityModifierMultipliers,

      legacyAddAbilityModifier: legacyAddAbilityModifier,

      effectBonus: effectBonus,

      effectTypeName: effectTypeName,

      usesSavingThrow: map['usesSavingThrow'] as bool? ?? false,

      savingThrowAbility: AbilityType.values.firstWhere(
        (item) => item.name == map['savingThrowAbility'],
        orElse: () => AbilityType.dexterity,
      ),

      saveDcBonus: (map['saveDcBonus'] as num?)?.toInt() ?? 0,

      saveSuccessEffect: SaveSuccessEffect.values.firstWhere(
        (item) => item.name == map['saveSuccessEffect'],
        orElse: () => SaveSuccessEffect.half,
      ),

      parts: parts,
    );
  }
}

// ============================================================================
// CHARACTER ABILITY
// ============================================================================

class CharacterAbility {
  String id;

  String name;

  String description;

  AbilityActionType actionType;

  // ==========================================================================
  // ATAQUE
  // ==========================================================================

  bool requiresAttackRoll;

  AbilityType abilityType;

  bool proficient;

  /// Bonus plano adicional a la tirada de ataque.
  int attackBonus;

  /// Tirada natural mínima que produce crítico.
  ///
  /// 20 = 20
  /// 19 = 19-20
  /// 18 = 18-20
  int criticalMinimumNaturalRoll;

  // ==========================================================================
  // CAMPOS LEGACY DE EFECTO
  //
  // Se mantienen para poder leer personajes/habilidades antiguas.
  //
  // El sistema moderno debe usar `effects`.
  // ==========================================================================

  AbilityEffectType effectType;

  /// Permite cosas como:
  /// 2d6 + 1d8
  List<DicePool> dicePools;

  /// Suma el modificador del atributo al daño/curación.
  bool addAbilityModifierToEffect;

  /// Bonus plano adicional.
  int effectBonus;

  /// Fuego, cortante, radiante...
  /// Para curación se puede dejar vacío.
  String effectTypeName;

  bool usesSavingThrow;

  AbilityType savingThrowAbility;

  int saveDcBonus;

  List<CharacterEffect> linkedEffects;
  // ==========================================================================
  // SISTEMA MODERNO
  // ==========================================================================

  List<AbilityEffect> effects;

  // ==========================================================================
  // RECURSOS
  // ==========================================================================

  /// ID del recurso del personaje que consume.
  ///
  /// null o vacío = no consume recursos.
  String? resourceId;

  /// Cantidad consumida al utilizar la habilidad.
  int resourceCost;

  // ==========================================================================
  // USOS
  // ==========================================================================

  /// 0 = usos ilimitados.
  int maxUses;

  int currentUses;

  String notes;

  // ==========================================================================
  // OBJETIVOS
  // ==========================================================================

  AbilityTargetType targetType;

  AbilityTargetResolutionMode targetResolutionMode;

  CharacterAbility({
    required this.id,
    required this.name,
    this.description = '',
    this.actionType = AbilityActionType.action,
    this.targetType = AbilityTargetType.external,
    this.targetResolutionMode = AbilityTargetResolutionMode.shared,
    this.requiresAttackRoll = false,
    this.abilityType = AbilityType.strength,
    this.proficient = true,
    this.attackBonus = 0,
    this.criticalMinimumNaturalRoll = 20,
    this.effectType = AbilityEffectType.none,
    List<DicePool>? dicePools,
    this.addAbilityModifierToEffect = true,
    this.effectBonus = 0,
    this.effectTypeName = '',
    this.usesSavingThrow = false,
    this.savingThrowAbility = AbilityType.dexterity,
    this.saveDcBonus = 0,
    this.maxUses = 0,
    this.currentUses = 0,
    this.resourceId,
    this.resourceCost = 0,
    List<AbilityEffect>? effects,
    List<CharacterEffect>? linkedEffects,
    this.notes = '',
  }) : dicePools = List<DicePool>.from(dicePools ?? []),
       effects = List<AbilityEffect>.from(effects ?? []),
       linkedEffects = List<CharacterEffect>.from(linkedEffects ?? []);

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  bool get hasLimitedUses {
    return maxUses > 0;
  }

  bool get hasLinkedEffects {
    return linkedEffects.isNotEmpty;
  }

  bool get hasEffect {
    // Sistema moderno.
    if (effects.isNotEmpty) {
      return effects.any((effect) => effect.hasEffect);
    }

    // Compatibilidad legacy.
    return effectType != AbilityEffectType.none &&
        (dicePools.isNotEmpty ||
            addAbilityModifierToEffect ||
            effectBonus != 0);
  }

  bool get dealsDamage {
    // Sistema moderno.
    if (effects.isNotEmpty) {
      return effects.any((effect) => effect.dealsDamage);
    }

    // Compatibilidad legacy.
    return effectType == AbilityEffectType.damage;
  }

  bool get heals {
    // Sistema moderno.
    if (effects.isNotEmpty) {
      return effects.any((effect) => effect.heals);
    }

    // Compatibilidad legacy.
    return effectType == AbilityEffectType.healing;
  }

  String get diceNotation {
    // Sistema moderno.
    if (effects.isNotEmpty) {
      final notations = effects
          .where((effect) => effect.diceNotation.isNotEmpty)
          .map((effect) => effect.diceNotation)
          .toList();

      if (notations.isNotEmpty) {
        return notations.join(' + ');
      }
    }

    // Compatibilidad legacy.
    if (dicePools.isEmpty) {
      return '';
    }

    return dicePools.map((pool) => pool.notation).join(' + ');
  }

  bool get usesResource {
    return resourceId != null &&
        resourceId!.trim().isNotEmpty &&
        resourceCost > 0;
  }

  int get maximumDiceValue {
    if (effects.isNotEmpty) {
      var total = 0;

      for (final effect in effects) {
        for (final part in effect.parts) {
          total += part.dicePools.fold<int>(
            0,
            (sum, pool) => sum + pool.maximum,
          );
        }
      }

      return total;
    }

    return dicePools.fold<int>(0, (sum, pool) => sum + pool.maximum);
  }

  // ==========================================================================
  // SERIALIZACIÓN
  // ==========================================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,

      'name': name,

      'description': description,

      'actionType': actionType.name,

      'requiresAttackRoll': requiresAttackRoll,

      'abilityType': abilityType.name,

      'targetType': targetType.name,

      'targetResolutionMode': targetResolutionMode.name,

      'proficient': proficient,

      'attackBonus': attackBonus,

      'criticalMinimumNaturalRoll': criticalMinimumNaturalRoll,

      // Legacy.
      'effectType': effectType.name,

      'dicePools': dicePools.map((pool) => pool.toMap()).toList(),

      'addAbilityModifierToEffect': addAbilityModifierToEffect,

      'effectBonus': effectBonus,

      'effectTypeName': effectTypeName,

      'usesSavingThrow': usesSavingThrow,

      'savingThrowAbility': savingThrowAbility.name,

      'saveDcBonus': saveDcBonus,

      // Moderno.
      'effects': effects.map((effect) => effect.toMap()).toList(),

      // Usos.
      'maxUses': maxUses,

      'currentUses': currentUses,

      // Recurso.
      'resourceId': resourceId,

      'resourceCost': resourceCost,

      'notes': notes,

      'linkedEffects': linkedEffects.map((effect) => effect.toMap()).toList(),
    };
  }

  factory CharacterAbility.fromMap(Map<dynamic, dynamic> map) {
    // ========================================================================
    // ATRIBUTO PRINCIPAL
    //
    // Lo obtenemos antes porque lo necesitaremos para migraciones legacy.
    // ========================================================================

    final ability = AbilityType.values.firstWhere(
      (item) => item.name == map['abilityType'],
      orElse: () => AbilityType.strength,
    );

    // ========================================================================
    // DADOS LEGACY
    // ========================================================================

    final pools = <DicePool>[];

    final rawPools = map['dicePools'];

    if (rawPools is List) {
      for (final rawPool in rawPools) {
        if (rawPool is! Map) {
          continue;
        }

        try {
          pools.add(DicePool.fromMap(Map<dynamic, dynamic>.from(rawPool)));
        } catch (_) {
          continue;
        }
      }
    }

    // ========================================================================
    // COMPATIBILIDAD MUY ANTIGUA
    //
    // damageDice = "2d6"
    // ========================================================================

    if (pools.isEmpty) {
      final oldDice = map['damageDice']?.toString() ?? '';

      final parsed = _parseLegacyDice(oldDice);

      if (parsed != null) {
        pools.add(parsed);
      }
    }

    // ========================================================================
    // TIPO DE EFECTO LEGACY
    // ========================================================================

    final storedEffect = map['effectType']?.toString();

    AbilityEffectType effectType;

    if (storedEffect != null) {
      effectType = AbilityEffectType.values.firstWhere(
        (item) => item.name == storedEffect,
        orElse: () => AbilityEffectType.none,
      );
    } else {
      // Datos muy antiguos.
      effectType = pools.isNotEmpty
          ? AbilityEffectType.damage
          : AbilityEffectType.none;
    }

    // ========================================================================
    // VALORES LEGACY
    // ========================================================================

    final legacyAddModifier =
        map['addAbilityModifierToEffect'] as bool? ??
        map['addAbilityToDamage'] as bool? ??
        true;

    final legacyEffectBonus =
        (map['effectBonus'] as num?)?.toInt() ??
        (map['damageBonus'] as num?)?.toInt() ??
        0;

    final legacyEffectTypeName =
        map['effectTypeName']?.toString() ??
        map['damageType']?.toString() ??
        '';

    final legacyUsesSavingThrow = map['usesSavingThrow'] as bool? ?? false;

    final legacySavingThrowAbility = AbilityType.values.firstWhere(
      (item) => item.name == map['savingThrowAbility'],
      orElse: () => AbilityType.dexterity,
    );

    final legacySaveDcBonus = (map['saveDcBonus'] as num?)?.toInt() ?? 0;

    // ========================================================================
    // EFECTOS MODERNOS
    // ========================================================================

    final effects = <AbilityEffect>[];

    final rawEffects = map['effects'];

    if (rawEffects is List) {
      for (final rawEffect in rawEffects) {
        if (rawEffect is! Map) {
          continue;
        }

        try {
          effects.add(
            AbilityEffect.fromMap(Map<dynamic, dynamic>.from(rawEffect)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    // ========================================================================
    // NORMALIZACIÓN DE EFECTOS YA EXISTENTES
    //
    // Puede ocurrir que una versión anterior guardase:
    //
    // legacyAddAbilityModifier = true
    //
    // pero todavía no hubiese convertido ese modificador a:
    //
    // abilityModifierMultipliers
    //
    // Como aquí sí conocemos el atributo principal de la habilidad,
    // podemos terminar correctamente la migración.
    // ========================================================================

    for (var effectIndex = 0; effectIndex < effects.length; effectIndex++) {
      final currentEffect = effects[effectIndex];

      if (!currentEffect.legacyAddAbilityModifier) {
        continue;
      }

      // Si ya existe el atributo en alguna parte,
      // no volvemos a añadirlo.
      final alreadyHasAbilityModifier = currentEffect.parts.any(
        (part) =>
            part.abilityModifierMultipliers.values.any((value) => value != 0),
      );

      if (alreadyHasAbilityModifier) {
        currentEffect.legacyAddAbilityModifier = false;

        continue;
      }

      // Si no existe ninguna parte todavía,
      // creamos una.
      if (currentEffect.parts.isEmpty) {
        currentEffect.parts.add(
          AbilityEffectPart(
            id: '${currentEffect.id}_part_0',

            dicePools: List<DicePool>.from(currentEffect.dicePools),

            abilityModifierMultipliers: {ability: 1},

            flatBonus: currentEffect.effectBonus,

            typeName: currentEffect.effectTypeName,
          ),
        );
      } else {
        // Si la parte ya existe por dados/bonus,
        // añadimos el atributo a la primera.
        currentEffect.parts.first.abilityModifierMultipliers[ability] = 1;
      }

      currentEffect.legacyAddAbilityModifier = false;
    }

    // ========================================================================
    // MIGRACIÓN COMPLETA DE HABILIDAD ANTIGUA
    //
    // Antes solo se migraba si había dados.
    //
    // Eso rompía habilidades como:
    //
    // +FUE
    // +5
    // FUE + 5
    //
    // Ahora cualquiera de esos casos genera Effect + Part.
    // ========================================================================

    final hasLegacyEffect =
        effectType != AbilityEffectType.none &&
        (pools.isNotEmpty || legacyAddModifier || legacyEffectBonus != 0);

    if (effects.isEmpty && hasLegacyEffect) {
      final part = AbilityEffectPart(
        id: '${map['id']}_effect_0_part_0',

        dicePools: List<DicePool>.from(pools),

        abilityModifierMultipliers: legacyAddModifier ? {ability: 1} : {},

        flatBonus: legacyEffectBonus,

        typeName: legacyEffectTypeName,
      );

      effects.add(
        AbilityEffect(
          id: '${map['id']}_effect_0',

          name: '',

          effectType: effectType,

          // Guardamos también los valores legacy
          // por compatibilidad.
          dicePools: List<DicePool>.from(pools),

          abilityModifierMultipliers: legacyAddModifier ? {ability: 1} : {},

          legacyAddAbilityModifier: false,

          effectBonus: legacyEffectBonus,

          effectTypeName: legacyEffectTypeName,

          parts: [part],

          usesSavingThrow: legacyUsesSavingThrow,

          savingThrowAbility: legacySavingThrowAbility,

          saveDcBonus: legacySaveDcBonus,

          saveSuccessEffect: SaveSuccessEffect.half,
        ),
      );
    }

    // ========================================================================
    // EFECTOS VINCULADOS
    // ========================================================================

    final linkedEffects = <CharacterEffect>[];

    final rawLinkedEffects = map['linkedEffects'];

    if (rawLinkedEffects is List) {
      for (final rawEffect in rawLinkedEffects) {
        if (rawEffect is! Map) {
          continue;
        }

        try {
          linkedEffects.add(
            CharacterEffect.fromMap(Map<dynamic, dynamic>.from(rawEffect)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    // ========================================================================
    // RESULTADO
    // ========================================================================

    return CharacterAbility(
      id: map['id']?.toString() ?? '',

      name: map['name']?.toString() ?? '',

      description: map['description']?.toString() ?? '',

      actionType: AbilityActionType.values.firstWhere(
        (item) => item.name == map['actionType'],
        orElse: () => AbilityActionType.action,
      ),

      targetType: AbilityTargetType.values.firstWhere(
        (item) => item.name == map['targetType'],
        orElse: () => AbilityTargetType.external,
      ),

      targetResolutionMode: AbilityTargetResolutionMode.values.firstWhere(
        (item) => item.name == map['targetResolutionMode'],
        orElse: () => AbilityTargetResolutionMode.shared,
      ),

      criticalMinimumNaturalRoll:
          (map['criticalMinimumNaturalRoll'] as num?)?.toInt() ?? 20,

      requiresAttackRoll: map['requiresAttackRoll'] as bool? ?? false,

      abilityType: ability,

      proficient: map['proficient'] as bool? ?? true,

      attackBonus: (map['attackBonus'] as num?)?.toInt() ?? 0,

      // Legacy.
      effectType: effectType,

      dicePools: pools,

      addAbilityModifierToEffect: legacyAddModifier,

      effectBonus: legacyEffectBonus,

      effectTypeName: legacyEffectTypeName,

      usesSavingThrow: legacyUsesSavingThrow,

      savingThrowAbility: legacySavingThrowAbility,

      saveDcBonus: legacySaveDcBonus,

      // Moderno.
      effects: effects,

      // Usos.
      maxUses: (map['maxUses'] as num?)?.toInt() ?? 0,

      currentUses: (map['currentUses'] as num?)?.toInt() ?? 0,

      // Recurso.
      resourceId: map['resourceId']?.toString(),

      resourceCost: (map['resourceCost'] as num?)?.toInt() ?? 0,

      notes: map['notes']?.toString() ?? '',

      linkedEffects: linkedEffects,
    );
  }

  // ==========================================================================
  // DADOS LEGACY
  // ==========================================================================

  static DicePool? _parseLegacyDice(String value) {
    final clean = value.trim().toLowerCase();

    final match = RegExp(r'^(\d+)d(\d+)$').firstMatch(clean);

    if (match == null) {
      return null;
    }

    final count = int.tryParse(match.group(1) ?? '');

    final sides = int.tryParse(match.group(2) ?? '');

    if (count == null || sides == null || count <= 0 || sides <= 0) {
      return null;
    }

    return DicePool(count: count, sides: sides);
  }
}
