import 'package:flutter/material.dart';

@immutable
class AsteriaSemanticColors
    extends ThemeExtension<AsteriaSemanticColors> {
  final bool isRainbow;
  final Color stats;
  final Color abilities;
  final Color effects;
  final Color counters;
  final Color items;
  final Color story;
  final Color journal;
  final Color resources;
  final Color dice;
  final Color knowledge;
  final Color combat;
  final Color rest;
  final Color notes;

  // Roles de interfaz para que Rainbow pueda colorear acciones y contenido
  // sin alterar las paletas propias de atributos y recursos individuales.
  final Color positive;
  final Color negative;
  final Color neutral;
  final Color condition;
  final Color grid;
  final Color settings;
  final Color library;
  final Color importAction;
  final Color shop;
  final Color create;
  final Color edit;
  final Color exportAction;
  final Color delete;

  const AsteriaSemanticColors({
    required this.isRainbow,
    required this.stats,
    required this.abilities,
    required this.effects,
    required this.counters,
    required this.items,
    required this.story,
    required this.journal,
    required this.resources,
    required this.dice,
    required this.knowledge,
    required this.combat,
    required this.rest,
    required this.notes,
    required this.positive,
    required this.negative,
    required this.neutral,
    required this.condition,
    required this.grid,
    required this.settings,
    required this.library,
    required this.importAction,
    required this.shop,
    required this.create,
    required this.edit,
    required this.exportAction,
    required this.delete,
  });

  factory AsteriaSemanticColors.asteria(ColorScheme scheme) {
    return AsteriaSemanticColors(
      isRainbow: false,
      stats: scheme.primary,
      abilities: scheme.primary,
      effects: scheme.primary,
      counters: scheme.primary,
      items: scheme.primary,
      story: scheme.primary,
      journal: scheme.primary,
      resources: scheme.primary,
      dice: scheme.primary,
      knowledge: scheme.primary,
      combat: scheme.primary,
      rest: scheme.primary,
      notes: scheme.primary,
      positive: scheme.tertiary,
      negative: scheme.error,
      neutral: scheme.secondary,
      condition: scheme.primary,
      grid: scheme.primary,
      settings: scheme.primary,
      library: scheme.primary,
      importAction: scheme.primary,
      shop: scheme.primary,
      create: scheme.primary,
      edit: scheme.primary,
      exportAction: scheme.primary,
      delete: scheme.error,
    );
  }

  factory AsteriaSemanticColors.rainbow(Brightness brightness) {
    final dark = brightness == Brightness.dark;

    Color tone(Color light, Color darkColor) => dark ? darkColor : light;

    return AsteriaSemanticColors(
      isRainbow: true,
      stats: tone(const Color(0xFFD81B60), const Color(0xFFFF5C93)),
      abilities: tone(const Color(0xFFD32F2F), const Color(0xFFFF6B6B)),
      effects: tone(const Color(0xFFEF6C00), const Color(0xFFFFA24A)),
      counters: tone(const Color(0xFF9A7B00), const Color(0xFFFFD54F)),
      items: tone(const Color(0xFF2E7D32), const Color(0xFF66D17A)),
      story: tone(const Color(0xFF00897B), const Color(0xFF4DD0C8)),
      journal: tone(const Color(0xFF007C91), const Color(0xFF4CC9E8)),
      resources: tone(const Color(0xFF00897B), const Color(0xFF5CE1C4)),
      dice: tone(const Color(0xFF1565C0), const Color(0xFF64A8FF)),
      knowledge: tone(const Color(0xFF6A1B9A), const Color(0xFFC77DFF)),
      combat: tone(const Color(0xFF3949AB), const Color(0xFF8C9EFF)),
      rest: tone(const Color(0xFF8E24AA), const Color(0xFFD980FA)),
      notes: tone(const Color(0xFFC2185B), const Color(0xFFFF80AB)),
      positive: tone(const Color(0xFF2E7D32), const Color(0xFF69E07D)),
      negative: tone(const Color(0xFFC62828), const Color(0xFFFF6B6B)),
      neutral: tone(const Color(0xFF7B1FA2), const Color(0xFFC77DFF)),
      condition: tone(const Color(0xFFF9A825), const Color(0xFFFFD54F)),
      grid: tone(const Color(0xFF7B1FA2), const Color(0xFFC77DFF)),
      settings: tone(const Color(0xFF1565C0), const Color(0xFF64A8FF)),
      library: tone(const Color(0xFF00897B), const Color(0xFF4DD0C8)),
      importAction: tone(const Color(0xFF2E7D32), const Color(0xFF69E07D)),
      shop: tone(const Color(0xFFF9A825), const Color(0xFFFFD54F)),
      create: tone(const Color(0xFFD81B60), const Color(0xFFFF5C93)),
      edit: tone(const Color(0xFFEF6C00), const Color(0xFFFFA24A)),
      exportAction: tone(const Color(0xFF3949AB), const Color(0xFF8C9EFF)),
      delete: tone(const Color(0xFFC62828), const Color(0xFFFF6B6B)),
    );
  }

  @override
  AsteriaSemanticColors copyWith({
    bool? isRainbow,
    Color? stats,
    Color? abilities,
    Color? effects,
    Color? counters,
    Color? items,
    Color? story,
    Color? journal,
    Color? resources,
    Color? dice,
    Color? knowledge,
    Color? combat,
    Color? rest,
    Color? notes,
    Color? positive,
    Color? negative,
    Color? neutral,
    Color? condition,
    Color? grid,
    Color? settings,
    Color? library,
    Color? importAction,
    Color? shop,
    Color? create,
    Color? edit,
    Color? exportAction,
    Color? delete,
  }) {
    return AsteriaSemanticColors(
      isRainbow: isRainbow ?? this.isRainbow,
      stats: stats ?? this.stats,
      abilities: abilities ?? this.abilities,
      effects: effects ?? this.effects,
      counters: counters ?? this.counters,
      items: items ?? this.items,
      story: story ?? this.story,
      journal: journal ?? this.journal,
      resources: resources ?? this.resources,
      dice: dice ?? this.dice,
      knowledge: knowledge ?? this.knowledge,
      combat: combat ?? this.combat,
      rest: rest ?? this.rest,
      notes: notes ?? this.notes,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      neutral: neutral ?? this.neutral,
      condition: condition ?? this.condition,
      grid: grid ?? this.grid,
      settings: settings ?? this.settings,
      library: library ?? this.library,
      importAction: importAction ?? this.importAction,
      shop: shop ?? this.shop,
      create: create ?? this.create,
      edit: edit ?? this.edit,
      exportAction: exportAction ?? this.exportAction,
      delete: delete ?? this.delete,
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
      isRainbow: t < 0.5 ? isRainbow : other.isRainbow,
      stats: Color.lerp(stats, other.stats, t) ?? stats,
      abilities: Color.lerp(abilities, other.abilities, t) ?? abilities,
      effects: Color.lerp(effects, other.effects, t) ?? effects,
      counters: Color.lerp(counters, other.counters, t) ?? counters,
      items: Color.lerp(items, other.items, t) ?? items,
      story: Color.lerp(story, other.story, t) ?? story,
      journal: Color.lerp(journal, other.journal, t) ?? journal,
      resources: Color.lerp(resources, other.resources, t) ?? resources,
      dice: Color.lerp(dice, other.dice, t) ?? dice,
      knowledge: Color.lerp(knowledge, other.knowledge, t) ?? knowledge,
      combat: Color.lerp(combat, other.combat, t) ?? combat,
      rest: Color.lerp(rest, other.rest, t) ?? rest,
      notes: Color.lerp(notes, other.notes, t) ?? notes,
      positive: Color.lerp(positive, other.positive, t) ?? positive,
      negative: Color.lerp(negative, other.negative, t) ?? negative,
      neutral: Color.lerp(neutral, other.neutral, t) ?? neutral,
      condition: Color.lerp(condition, other.condition, t) ?? condition,
      grid: Color.lerp(grid, other.grid, t) ?? grid,
      settings: Color.lerp(settings, other.settings, t) ?? settings,
      library: Color.lerp(library, other.library, t) ?? library,
      importAction:
          Color.lerp(importAction, other.importAction, t) ?? importAction,
      shop: Color.lerp(shop, other.shop, t) ?? shop,
      create: Color.lerp(create, other.create, t) ?? create,
      edit: Color.lerp(edit, other.edit, t) ?? edit,
      exportAction:
          Color.lerp(exportAction, other.exportAction, t) ?? exportAction,
      delete: Color.lerp(delete, other.delete, t) ?? delete,
    );
  }
}
