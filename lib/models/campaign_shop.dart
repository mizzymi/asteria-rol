import 'item_definition.dart';

enum CampaignShopCurrencyKind { resource, item }

class CampaignShopProduct {
  String id;
  ItemDefinition definition;
  int price;
  bool prohibited;

  CampaignShopProduct({
    required this.id,
    required this.definition,
    this.price = 0,
    this.prohibited = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'definition': definition.toMap(),
    'price': price,
    'prohibited': prohibited,
  };

  factory CampaignShopProduct.fromMap(Map<dynamic, dynamic> map) {
    return CampaignShopProduct(
      id: map['id']?.toString() ?? '',
      definition: ItemDefinition.fromMap(
        Map<dynamic, dynamic>.from(map['definition'] as Map? ?? const {}),
      ),
      price: (map['price'] as num?)?.toInt() ?? 0,
      prohibited: map['prohibited'] == true,
    );
  }
}

class CampaignShop {
  String id;
  String name;
  String description;
  CampaignShopCurrencyKind currencyKind;
  String currencyName;
  ItemDefinition? currencyItem;
  List<CampaignShopProduct> products;

  CampaignShop({
    required this.id,
    required this.name,
    this.description = '',
    this.currencyKind = CampaignShopCurrencyKind.resource,
    this.currencyName = 'Oro',
    this.currencyItem,
    List<CampaignShopProduct>? products,
  }) : products = products ?? <CampaignShopProduct>[];

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'currencyKind': currencyKind.name,
    'currencyName': currencyName,
    'currencyItem': currencyItem?.toMap(),
    'products': products.map((e) => e.toMap()).toList(),
  };

  factory CampaignShop.fromMap(Map<dynamic, dynamic> map) {
    final rawProducts = map['products'];
    return CampaignShop(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Tienda',
      description: map['description']?.toString() ?? '',
      currencyKind: CampaignShopCurrencyKind.values.firstWhere(
        (e) => e.name == map['currencyKind']?.toString(),
        orElse: () => CampaignShopCurrencyKind.resource,
      ),
      currencyName: map['currencyName']?.toString() ?? 'Oro',
      currencyItem: map['currencyItem'] is Map
          ? ItemDefinition.fromMap(
              Map<dynamic, dynamic>.from(map['currencyItem'] as Map),
            )
          : null,
      products: rawProducts is List
          ? rawProducts
                .whereType<Map>()
                .map(
                  (e) => CampaignShopProduct.fromMap(
                    Map<dynamic, dynamic>.from(e),
                  ),
                )
                .toList()
          : <CampaignShopProduct>[],
    );
  }
}
