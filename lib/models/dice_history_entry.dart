class DiceHistoryEntry {
  String id;

  String label;

  String notation;

  List<int> rolls;

  int modifier;

  int total;

  DateTime createdAt;

  DiceHistoryEntry({
    required this.id,
    required this.label,
    required this.notation,
    required this.rolls,
    required this.modifier,
    required this.total,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'notation': notation,
      'rolls': rolls,
      'modifier': modifier,
      'total': total,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DiceHistoryEntry.fromMap(Map<dynamic, dynamic> map) {
    final rawRolls = map['rolls'];

    final rolls = <int>[];

    if (rawRolls is List) {
      for (final value in rawRolls) {
        if (value is num) {
          rolls.add(value.toInt());
        }
      }
    }

    return DiceHistoryEntry(
      id: map['id']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      notation: map['notation']?.toString() ?? '',
      rolls: rolls,
      modifier: (map['modifier'] as num?)?.toInt() ?? 0,
      total: (map['total'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
