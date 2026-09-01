class CharacterContentFolder {
  String id;
  String name;

  /// null = carpeta raíz.
  String? parentId;

  CharacterContentFolder({required this.id, required this.name, this.parentId});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'parentId': parentId};
  }

  factory CharacterContentFolder.fromMap(Map<dynamic, dynamic> map) {
    return CharacterContentFolder(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      parentId: map['parentId']?.toString(),
    );
  }
}
