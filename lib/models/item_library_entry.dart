import '../models/item.dart';

class ItemLibraryEntry {
  String id;

  CharacterItem item;

  DateTime createdAt;

  DateTime updatedAt;

  ItemLibraryEntry({
    required this.id,
    required this.item,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item': item.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ItemLibraryEntry.fromMap(Map<dynamic, dynamic> map) {
    return ItemLibraryEntry(
      id: map['id']?.toString() ?? '',
      item: CharacterItem.fromMap(
        Map<dynamic, dynamic>.from(map['item'] ?? {}),
      ),
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
