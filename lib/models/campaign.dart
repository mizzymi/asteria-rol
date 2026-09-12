import 'campaign_shop.dart';
import 'campaign_mission.dart';

class Campaign {
  final String id;
  String name;
  String description;
  String? imagePath;
  DateTime createdAt;
  List<CampaignShop> shops;
  List<CampaignMission> missions;

  Campaign({
    required this.id,
    required this.name,
    this.description = '',
    this.imagePath,
    DateTime? createdAt,
    List<CampaignShop>? shops,
    List<CampaignMission>? missions,
  }) : shops = shops ?? <CampaignShop>[],
       missions = missions ?? <CampaignMission>[],
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'imagePath': imagePath,
        'createdAt': createdAt.toIso8601String(),
        'shops': shops.map((e) => e.toMap()).toList(),
        'missions': missions.map((e) => e.toMap()).toList(),
      };

  factory Campaign.fromMap(Map<dynamic, dynamic> map) {
    return Campaign(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Campaña',
      description: map['description']?.toString() ?? '',
      imagePath: map['imagePath']?.toString(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? ''),
      shops: map['shops'] is List
          ? (map['shops'] as List)
              .whereType<Map>()
              .map((e) => CampaignShop.fromMap(Map<dynamic, dynamic>.from(e)))
              .toList()
          : <CampaignShop>[],
      missions: map['missions'] is List
          ? (map['missions'] as List)
              .whereType<Map>()
              .map((e) => CampaignMission.fromMap(Map<dynamic, dynamic>.from(e)))
              .toList()
          : <CampaignMission>[],
    );
  }
}
