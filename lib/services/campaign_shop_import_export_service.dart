import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/campaign_shop.dart';
import '../models/item_definition.dart';
import 'portable_image_bundle.dart';

class CampaignShopImportExportService {
  const CampaignShopImportExportService._();

  static const String formatType = 'asteria-shop';
  static const int formatVersion = 3;

  static Future<File> createExportFile(CampaignShop shop) async {
    final shopMap = Map<String, dynamic>.from(shop.toMap());
    shopMap['id'] = '';
    final images = await PortableImageBundle.extractFrom(
      shopMap,
      deduplicate: true,
    );

    final payload = {
      'type': formatType,
      'version': formatVersion,
      'shop': shopMap,
      'images': images,
    };
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_safeName(shop.name)}.asteria-shop');
    final encoded = utf8.encode(jsonEncode(payload));
    final compressed = gzip.encode(encoded);
    await file.writeAsBytes(compressed, flush: true);
    return file;
  }

  static Future<void> shareShop(CampaignShop shop) async {
    final file = await createExportFile(shop);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/octet-stream')],
        subject: 'Tienda de Asteria: ${shop.name}',
        text: 'Importa esta tienda en una campaña de Asteria.',
      ),
    );
  }

  static Future<CampaignShop?> pickAndImportShop() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.single.path;
    if (path == null || path.isEmpty) return null;
    return importFromFile(File(path));
  }

  static Future<CampaignShop> importFromFile(File file) async {
    final bytes = await file.readAsBytes();
    final raw = _decodeExportBytes(bytes);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) throw const FormatException('El archivo de tienda no es válido.');
    final root = Map<String, dynamic>.from(decoded);
    if (root['type'] != formatType) {
      throw const FormatException('El archivo no es una tienda de Asteria.');
    }
    final version = (root['version'] as num?)?.toInt() ?? 0;
    if (version <= 0 || version > formatVersion) {
      throw FormatException('Versión de tienda no compatible: $version');
    }
    if (root['shop'] is! Map) throw const FormatException('La tienda está incompleta.');

    if (version >= 2) {
      final shopMap = Map<String, dynamic>.from(root['shop'] as Map);
      if (root['images'] is Map) {
        await PortableImageBundle.restoreInto(
          shopMap,
          Map<String, dynamic>.from(root['images'] as Map),
          namespace: 'shop',
        );
      }
      final imported = CampaignShop.fromMap(Map<dynamic, dynamic>.from(shopMap));
      imported.id = 'shop_${DateTime.now().microsecondsSinceEpoch}';
      for (var i = 0; i < imported.products.length; i++) {
        imported.products[i].id = 'shop_product_${DateTime.now().microsecondsSinceEpoch}_$i';
      }
      return imported;
    }

    // Compatibilidad con tiendas v1, que guardaban solo la imagen principal de cada objeto.
    final shopMap = Map<String, dynamic>.from(root['shop'] as Map);
    final importedProducts = <CampaignShopProduct>[];
    final rawProducts = shopMap['products'];
    if (rawProducts is List) {
      for (final raw in rawProducts.whereType<Map>()) {
        final productMap = Map<String, dynamic>.from(raw);
        if (productMap['definition'] is! Map) continue;
        var definition = ItemDefinition.fromMap(
          Map<dynamic, dynamic>.from(productMap['definition'] as Map),
        );
        definition = definition.copyWith(
          imagePath: await _saveLegacyImage(
            definition.id,
            productMap['image']?.toString(),
          ),
        );
        importedProducts.add(CampaignShopProduct(
          id: 'shop_product_${DateTime.now().microsecondsSinceEpoch}_${importedProducts.length}',
          definition: definition,
          price: (productMap['price'] as num?)?.toInt() ?? 0,
        ));
      }
    }

    ItemDefinition? currencyItem;
    if (shopMap['currencyItem'] is Map) {
      currencyItem = ItemDefinition.fromMap(
        Map<dynamic, dynamic>.from(shopMap['currencyItem'] as Map),
      );
      currencyItem = currencyItem.copyWith(
        imagePath: await _saveLegacyImage(
          currencyItem.id,
          shopMap['currencyItemImage']?.toString(),
        ),
      );
    }

    return CampaignShop(
      id: 'shop_${DateTime.now().microsecondsSinceEpoch}',
      name: shopMap['name']?.toString() ?? 'Tienda importada',
      description: shopMap['description']?.toString() ?? '',
      currencyKind: CampaignShopCurrencyKind.values.firstWhere(
        (e) => e.name == shopMap['currencyKind']?.toString(),
        orElse: () => CampaignShopCurrencyKind.resource,
      ),
      currencyName: shopMap['currencyName']?.toString() ?? 'Oro',
      currencyItem: currencyItem,
      products: importedProducts,
    );
  }


  static String _decodeExportBytes(List<int> bytes) {
    if (bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B) {
      return utf8.decode(gzip.decode(bytes));
    }
    return utf8.decode(bytes);
  }

  static Future<String> _saveLegacyImage(String itemId, String? encoded) async {
    if (encoded == null || encoded.isEmpty) return '';
    try {
      final bytes = base64Decode(encoded);
      final dir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${dir.path}/item_images');
      if (!await imageDir.exists()) await imageDir.create(recursive: true);
      final file = File(
        '${imageDir.path}/shop_${_safeName(itemId)}_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return '';
    }
  }

  static String _safeName(String value) {
    final result = value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return result.isEmpty ? 'asteria_shop' : result;
  }
}
