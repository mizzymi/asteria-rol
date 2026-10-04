class CharacterContentFolder {
  final String id;
  String name;
  String? parentId;
  final bool isItemFolder;

  CharacterContentFolder({
    required this.id,
    required this.name,
    this.parentId,
    this.isItemFolder = false,
  });

  CharacterContentFolder copyWith({
    String? id,
    String? name,
    String? Function()? parentId,
    bool? isItemFolder,
  }) {
    return CharacterContentFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId != null ? parentId() : this.parentId,
      isItemFolder: isItemFolder ?? this.isItemFolder,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'parentId': parentId,
    'isItemFolder': isItemFolder,
  };

  factory CharacterContentFolder.fromMap(Map<dynamic, dynamic> map) {
    return CharacterContentFolder(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      parentId: map['parentId'] as String?,
      isItemFolder: map['isItemFolder'] as bool? ?? false,
    );
  }
}
