import '../character.dart';
import '../passive.dart';
import '../skill.dart';

import 'formula_context.dart';

class CharacterFormulaContext {
  const CharacterFormulaContext._();

  static FormulaContext fromCharacter(
    Character character, {
    CharacterPassive? passive,
    Map<String, double> eventVariables = const {},
    Map<String, double> extraVariables = const {},
    Map<String, FormulaResourceSnapshot> resourceSnapshots = const {},
    FormulaResourceResolver? resourceResolver,
    FormulaResourceResolver? baseResourceResolver,
    FormulaCounterResolver? counterResolver,
  }) {
    final variables = <String, double>{
      // =====================================================================
      // NIVEL
      // =====================================================================
      'level': character.level.toDouble(),

      // =====================================================================
      // VIDA ACTUAL / EFECTIVA
      // =====================================================================
      'health': character.currentHealth.toDouble(),

      'max_health': character.maxHealth.toDouble(),

      'health_percent': character.maxHealth <= 0
          ? 0
          : (character.currentHealth / character.maxHealth) * 100,

      // =====================================================================
      // VIDA BASE
      // =====================================================================
      'base_max_health': character.baseMaxHealth.toDouble(),

      // =====================================================================
      // ATRIBUTOS BASE
      // =====================================================================
      'fue_base': character.abilities.strength.toDouble(),
      'des_base': character.abilities.dexterity.toDouble(),
      'con_base': character.abilities.constitution.toDouble(),
      'int_base': character.abilities.intelligence.toDouble(),
      'sab_base': character.abilities.wisdom.toDouble(),
      'car_base': character.abilities.charisma.toDouble(),

      // =====================================================================
      // ATRIBUTOS EFECTIVOS
      //
      // Ahora mismo coinciden con los base porque todavía no hemos añadido
      // modificadores de puntuación de atributo mediante fórmulas.
      //
      // Los dejamos separados desde ya para no cambiar la sintaxis después.
      // =====================================================================
      'fue': character.abilities.strength.toDouble(),
      'des': character.abilities.dexterity.toDouble(),
      'con': character.abilities.constitution.toDouble(),
      'int': character.abilities.intelligence.toDouble(),
      'sab': character.abilities.wisdom.toDouble(),
      'car': character.abilities.charisma.toDouble(),

      // =====================================================================
      // MODIFICADORES BASE
      // =====================================================================
      'fue_base_mod': character
          .baseAbilityModifier(AbilityType.strength)
          .toDouble(),

      'des_base_mod': character
          .baseAbilityModifier(AbilityType.dexterity)
          .toDouble(),

      'con_base_mod': character
          .baseAbilityModifier(AbilityType.constitution)
          .toDouble(),

      'int_base_mod': character
          .baseAbilityModifier(AbilityType.intelligence)
          .toDouble(),

      'sab_base_mod': character
          .baseAbilityModifier(AbilityType.wisdom)
          .toDouble(),

      'car_base_mod': character
          .baseAbilityModifier(AbilityType.charisma)
          .toDouble(),

      // =====================================================================
      // MODIFICADORES EFECTIVOS
      // =====================================================================
      'fue_mod': character.abilityModifier(AbilityType.strength).toDouble(),

      'des_mod': character.abilityModifier(AbilityType.dexterity).toDouble(),

      'con_mod': character.abilityModifier(AbilityType.constitution).toDouble(),

      'int_mod': character.abilityModifier(AbilityType.intelligence).toDouble(),

      'sab_mod': character.abilityModifier(AbilityType.wisdom).toDouble(),

      'car_mod': character.abilityModifier(AbilityType.charisma).toDouble(),
    };

    // =========================================================================
    // CARGAS DE LA PASIVA ACTUAL
    // =========================================================================

    if (passive != null) {
      variables['passive_enabled'] = passive.enabled ? 1 : 0;

      if (passive.hasCharges) {
        variables['charges'] = passive.currentCharges.toDouble();

        if (!passive.hasUnlimitedCharges) {
          variables['max_charges'] = passive.maxCharges.toDouble();

          variables['charges_percent'] = passive.maxCharges <= 0
              ? 0
              : (passive.currentCharges / passive.maxCharges) * 100;
        }
      }
    }

    // =========================================================================
    // VARIABLES DEL EVENTO
    //
    // Más adelante aquí entraremos con cosas como:
    //
    // damage_received
    // raw_damage
    // previous_health
    // current_health
    // previous_resource
    // current_resource
    // turn
    //
    // No las hardcodeamos todavía.
    // =========================================================================

    for (final entry in eventVariables.entries) {
      variables[entry.key] = entry.value;
    }

    // =========================================================================
    // VARIABLES EXTRA
    //
    // Esto nos permite ampliar un contexto concreto sin modificar esta clase.
    // Muy útil para previews, simulador y acciones futuras.
    // =========================================================================

    for (final entry in extraVariables.entries) {
      variables[entry.key] = entry.value;
    }

    // =========================================================================
    // RECURSOS
    // =========================================================================

    final resources = <String, FormulaResourceValue>{};

    for (final entry in resourceSnapshots.entries) {
      final snapshot = entry.value;

      resources[entry.key] = FormulaResourceValue(
        baseCurrentValue: snapshot.baseCurrentValue,
        baseMaxValue: snapshot.baseMaxValue,
        currentValue: snapshot.currentValue,
        maxValue: snapshot.maxValue,
      );
    }

    final counters = <String, double>{
      for (final counter in character.counters)
        counter.id: counter.value.toDouble(),
    };

    return FormulaContext(
      variables: variables,
      resources: resources,
      counters: counters,
      resourceResolver: resourceResolver,
      baseResourceResolver: baseResourceResolver,
      counterResolver: counterResolver,
    );
  }
}
