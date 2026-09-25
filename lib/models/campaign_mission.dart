class CampaignMission {
  String id;
  String title;
  String description;
  bool completed;
  List<String> acceptedCharacterIds;

  CampaignMission({
    required this.id,
    required this.title,
    this.description = '',
    this.completed = false,
    List<String>? acceptedCharacterIds,
  }) : acceptedCharacterIds = acceptedCharacterIds ?? <String>[];

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'completed': completed,
        'acceptedCharacterIds': acceptedCharacterIds,
      };

  factory CampaignMission.fromMap(Map<dynamic, dynamic> map) {
    final rawIds = map['acceptedCharacterIds'];
    return CampaignMission(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Misión',
      description: map['description']?.toString() ?? '',
      completed: map['completed'] as bool? ?? false,
      acceptedCharacterIds: rawIds is List
          ? rawIds.map((e) => e.toString()).toList()
          : <String>[],
    );
  }
}
