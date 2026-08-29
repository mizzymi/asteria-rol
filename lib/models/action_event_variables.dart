abstract final class ActionEventVariables {
  // ===========================================================================
  // TARGET
  // ===========================================================================

  static const actionTargetCount = 'action_target_count';

  static const affectedActionTargetCount = 'affected_action_target_count';

  static const externalAffectedTargetCount = 'external_affected_target_count';

  static const targetIndex = 'target_index';

  static const targetIsSelf = 'target_is_self';

  static const targetIsExternal = 'target_is_external';

  // ===========================================================================
  // ATTACK
  // ===========================================================================

  static const attackRoll = 'attack_roll';

  static const attackTotal = 'attack_total';

  static const critical = 'critical';

  // ===========================================================================
  // DAMAGE
  // ===========================================================================

  static const damage = 'damage';

  static const resolvedDamage = 'resolved_damage';

  static const damageApplied = 'damage_applied';

  static const damageResolved = 'damage_resolved';

  static const damageConfirmed = 'damage_confirmed';

  // ===========================================================================
  // HEALING
  // ===========================================================================

  static const healing = 'healing';

  static const resolvedHealing = 'resolved_healing';

  static const healingApplied = 'healing_applied';

  static const healingResolved = 'healing_resolved';

  static const healingConfirmed = 'healing_confirmed';

  // ===========================================================================
  // EFFECTS
  // ===========================================================================

  static const effectApplied = 'effect_applied';

  static const effectReceived = 'effect_received';

  static const effectResolved = 'effect_resolved';

  static const effectConfirmed = 'effect_confirmed';

  static const effectsApplied = 'effects_applied';

  static const resolvedEffectCount = 'resolved_effect_count';

  // ===========================================================================
  // HEALTH
  // ===========================================================================
  static const healthChange = 'health_change';

  static const healthBefore = 'health_before';

  static const healthAfter = 'health_after';

  static const targetHealthBefore = 'target_health_before';

  static const targetHealthAfter = 'target_health_after';

  static const externalHealthChanged = 'external_health_changed';

  static const externalChangedAnything = 'external_changed_anything';

  // ===========================================================================
  // COUNTS
  // ===========================================================================

  static const targetCount = 'target_count';

  static const externalTargetCount = 'external_target_count';

  static const affectedTargetCount = 'affected_target_count';

  // ===========================================================================
  // DEATH
  // ===========================================================================

  static const death = 'death';

  static const enemyKilled = 'enemy_killed';

  // ===========================================================================
  // COMBAT
  // ===========================================================================

  static const round = 'round';

  static const turnActive = 'turn_active';
}
