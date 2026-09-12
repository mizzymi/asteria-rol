class Campaign {
  final String id;
  String name;
  String description;
  String? imagePath;
  DateTime createdAt;

  Campaign({
    required this.id,
    required this.name,
    this.description = '',
    this.imagePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'imagePath': imagePath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Campaign.fromMap(Map<dynamic, dynamic> map) {
    return Campaign(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Campaña',
      description: map['description']?.toString() ?? '',
      imagePath: map['imagePath']?.toString(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? ''),
    );
  }
}
