import 'package:flutter/material.dart';

import '../models/campaign.dart';
import '../models/campaign_shop.dart';
import '../services/campaign_storage_service.dart';
import 'campaign_shop_detail_screen.dart';

/// Compatibility entry point for opening a campaign shop by id.
///
/// The actual shop UI and purchase flow live in [CampaignShopDetailScreen].
class CampaignShopScreen extends StatelessWidget {
  final Campaign campaign;
  final String shopId;

  const CampaignShopScreen({
    super.key,
    required this.campaign,
    required this.shopId,
  });

  @override
  Widget build(BuildContext context) {
    final latestCampaign =
        CampaignStorageService.getCampaign(campaign.id) ?? campaign;

    CampaignShop? currentShop;
    for (final candidate in latestCampaign.shops) {
      if (candidate.id == shopId) {
        currentShop = candidate;
        break;
      }
    }

    if (currentShop == null) {
      return const Scaffold(
        body: Center(child: Text('Tienda no encontrada')),
      );
    }

    return CampaignShopDetailScreen(
      campaign: latestCampaign,
      shop: currentShop,
    );
  }
}
