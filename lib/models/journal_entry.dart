enum JournalEntryType {
  session,
  quest,
  discovery,
  npc,
  combat,
  location,
  personal,
  other,
}

extension JournalEntryTypeData on JournalEntryType {
  String get label {
    switch (this) {
      case JournalEntryType.session:
        return 'Sesión';
      case JournalEntryType.quest:
        return 'Misión';
      case JournalEntryType.discovery:
        return 'Descubrimiento';
      case JournalEntryType.npc:
        return 'NPC';
      case JournalEntryType.combat:
        return 'Combate';
      case JournalEntryType.location:
        return 'Lugar';
      case JournalEntryType.personal:
        return 'Personal';
      case JournalEntryType.other:
        return 'Otro';
    }
  }
}

class JournalEntry {
  String id;
  String title;
  String content;

  JournalEntryType type;

  String dateText;
  String sessionText;

  bool important;

  String notes;

  JournalEntry({
    required this.id,
    required this.title,
    this.content = '',
    this.type = JournalEntryType.session,
    this.dateText = '',
    this.sessionText = '',
    this.important = false,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.name,
      'dateText': dateText,
      'sessionText': sessionText,
      'important': important,
      'notes': notes,
    };
  }

  factory JournalEntry.fromMap(Map<dynamic, dynamic> map) {
    return JournalEntry(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      type: JournalEntryType.values.firstWhere(
        (item) => item.name == map['type']?.toString(),
        orElse: () => JournalEntryType.session,
      ),
      dateText: map['dateText']?.toString() ?? '',
      sessionText: map['sessionText']?.toString() ?? '',
      important: map['important'] == true,
      notes: map['notes']?.toString() ?? '',
    );
  }
}
