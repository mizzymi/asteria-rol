import 'package:hive_flutter/hive_flutter.dart';

import '../models/campaign.dart';
import 'character_storage_service.dart';

class CampaignStorageService {
  static const String boxName = 'campaigns';

  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    await _migrateExistingCharacters();
  }

  static Box get _box => Hive.box(boxName);

  static List<Campaign> getCampaigns() {
    final result = <Campaign>[];
    for (final value in _box.values) {
      if (value is! Map) continue;
      try {
        final campaign = Campaign.fromMap(Map<dynamic, dynamic>.from(value));
        if (campaign.id.isNotEmpty) result.add(campaign);
      } catch (_) {}
    }
    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  static Campaign? getCampaign(String id) {
    final value = _box.get(id);
    if (value is! Map) return null;
    try {
      return Campaign.fromMap(Map<dynamic, dynamic>.from(value));
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveCampaign(Campaign campaign) async {
    await _box.put(campaign.id, campaign.toMap());
  }

  static Future<void> deleteCampaign(String id) async {
    await _box.delete(id);
  }

  static Future<void> _migrateExistingCharacters() async {
    final characters = CharacterStorageService.getCharacters();
    if (characters.isEmpty ||
        characters.every(
          (c) => c.campaignId != null && c.campaignId!.isNotEmpty,
        )) {
      return;
    }

    var campaigns = getCampaigns();
    Campaign target;
    if (campaigns.isEmpty) {
      target = Campaign(
        id: 'campaign_${DateTime.now().microsecondsSinceEpoch}',
        name: 'Mi aventura',
        description:
            'Campaña creada automáticamente para tus personajes actuales.',
      );
      await saveCampaign(target);
      campaigns = [target];
    } else {
      target = campaigns.first;
    }

    for (final character in characters) {
      if (character.campaignId == null || character.campaignId!.isEmpty) {
        character.campaignId = target.id;
        await CharacterStorageService.saveCharacter(character);
      }
    }
  }
}
