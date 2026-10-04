import 'package:flutter/material.dart';

@immutable
class AsteriaSemanticColors
    extends ThemeExtension<AsteriaSemanticColors> {
  final Color stats;
  final Color abilities;
  final Color effects;
  final Color counters;
  final Color items;
  final Color story;
  final Color journal;
  final Color dice;
  final Color knowledge;
  final Color combat;
  final Color rest;
  final Color notes;

  const AsteriaSemanticColors({
    required this.stats,
    required this.abilities,
    required this.effects,
    required this.counters,
    required this.items,
    required this.story,
    required this.journal,
    required this.dice,
    required this.knowledge,
    required this.combat,
    required this.rest,
    required this.notes,
  });

  factory AsteriaSemanticColors.asteria(ColorScheme scheme) {
    return AsteriaSemanticColors(
      stats: scheme.primary,
      abilities: scheme.primary,
      effects: scheme.primary,
      counters: scheme.primary,
      items: scheme.primary,
      story: scheme.primary,
      journal: scheme.primary,
      dice: scheme.primary,
      knowledge: scheme.primary,
      combat: scheme.primary,
      rest: scheme.primary,
      notes: scheme.primary,
    );
  }

  factory AsteriaSemanticColors.rainbow(Brightness brightness) {
    final dark = brightness == Brightness.dark;

    Color tone(Color light, Color darkColor) => dark ? darkColor : light;

    return AsteriaSemanticColors(
      stats: tone(const Color(0xFFD81B60), const Color(0xFFFF5C93)),
      abilities: tone(const Color(0xFFD32F2F), const Color(0xFFFF6B6B)),
      effects: tone(const Color(0xFFEF6C00), const Color(0xFFFFA24A)),
      counters: tone(const Color(0xFF9A7B00), const Color(0xFFFFD54F)),
      items: tone(const Color(0xFF2E7D32), const Color(0xFF66D17A)),
      story: tone(const Color(0xFF00897B), const Color(0xFF4DD0C8)),
      journal: tone(const Color(0xFF007C91), const Color(0xFF4CC9E8)),
      dice: tone(const Color(0xFF1565C0), const Color(0xFF64A8FF)),
      knowledge: tone(const Color(0xFF6A1B9A), const Color(0xFFC77DFF)),
      combat: tone(const Color(0xFF3949AB), const Color(0xFF8C9EFF)),
      rest: tone(const Color(0xFF8E24AA), const Color(0xFFD980FA)),
      notes: tone(const Color(0xFFC2185B), const Color(0xFFFF80AB)),
    );
  }

  @override
  AsteriaSemanticColors copyWith({
    Color? stats,
    Color? abilities,
    Color? effects,
    Color? counters,
    Color? items,
    Color? story,
    Color? journal,
    Color? dice,
    Color? knowledge,
    Color? combat,
    Color? rest,
    Color? notes,
  }) {
    return AsteriaSemanticColors(
      stats: stats ?? this.stats,
      abilities: abilities ?? this.abilities,
      effects: effects ?? this.effects,
      counters: counters ?? this.counters,
      items: items ?? this.items,
      story: story ?? this.story,
      journal: journal ?? this.journal,
      dice: dice ?? this.dice,
      knowledge: knowledge ?? this.knowledge,
      combat: combat ?? this.combat,
      rest: rest ?? this.rest,
      notes: notes ?? this.notes,
    );
  }

  @override
  AsteriaSemanticColors lerp(
    covariant ThemeExtension<AsteriaSemanticColors>? other,
    double t,
  ) {
    if (other is! AsteriaSemanticColors) {
      return this;
    }

    return AsteriaSemanticColors(
      stats: Color.lerp(stats, other.stats, t) ?? stats,
      abilities: Color.lerp(abilities, other.abilities, t) ?? abilities,
      effects: Color.lerp(effects, other.effects, t) ?? effects,
      counters: Color.lerp(counters, other.counters, t) ?? counters,
      items: Color.lerp(items, other.items, t) ?? items,
      story: Color.lerp(story, other.story, t) ?? story,
      journal: Color.lerp(journal, other.journal, t) ?? journal,
      dice: Color.lerp(dice, other.dice, t) ?? dice,
      knowledge: Color.lerp(knowledge, other.knowledge, t) ?? knowledge,
      combat: Color.lerp(combat, other.combat, t) ?? combat,
      rest: Color.lerp(rest, other.rest, t) ?? rest,
      notes: Color.lerp(notes, other.notes, t) ?? notes,
    );
  }
}
