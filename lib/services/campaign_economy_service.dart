import '../models/campaign.dart';
import '../models/campaign_shop.dart';
import '../models/character.dart';
import '../models/character_resource.dart';
import 'character_storage_service.dart';

class CampaignEconomyService {
  const CampaignEconomyService._();

  static String resourceIdFor(String campaignId, String currencyName) {
    final normalized = currencyName.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    return 'campaign_${campaignId}_currency_$normalized';
  }

  static Future<void> ensureCharacterCurrencies(
    Character character,
    Campaign campaign,
  ) async {
    var changed = false;
    for (final shop in campaign.shops) {
      if (shop.currencyKind != CampaignShopCurrencyKind.resource) continue;
      final name = shop.currencyName.trim().isEmpty
          ? 'Oro'
          : shop.currencyName.trim();
      final id = resourceIdFor(campaign.id, name);
      final exists = character.resources.any(
        (r) => r.id == id || r.name.toLowerCase() == name.toLowerCase(),
      );
      if (exists) continue;
      character.resources.add(
        CharacterResource(
          id: id,
          name: name,
          currentValue: 0,
          hasMaximum: false,
          visible: true,
          spendable: true,
        ),
      );
      changed = true;
    }
    if (changed) await CharacterStorageService.saveCharacter(character);
  }

  static Future<void> syncCampaignCurrencies(Campaign campaign) async {
    final characters = CharacterStorageService.getCharacters()
        .where((c) => c.campaignId == campaign.id)
        .toList();
    for (final character in characters) {
      await ensureCharacterCurrencies(character, campaign);
    }
  }
}
