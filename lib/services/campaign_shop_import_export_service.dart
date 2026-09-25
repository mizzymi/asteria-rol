import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/campaign_shop.dart';
import '../models/item_definition.dart';
import 'portable_image_bundle.dart';

class CampaignShopImportExportService {
  const CampaignShopImportExportService._();

  static const String formatType = 'asteria-shop';
  static const int formatVersion = 4;
  static final Uint8List _binaryMagic = Uint8List.fromList(
    utf8.encode('ASTERIA_SHOP_V4\n'),
  );

  /// Creates the v4 shop export as a streaming binary archive.
  ///
  /// Older versions assembled every image as Base64, then JSON-encoded the
  /// complete payload, and finally compressed that second large copy. A shop
  /// with many high-resolution images could therefore need several times its
  /// final file size in RAM and trigger Android's Out of Memory guard.
  ///
  /// V4 writes the small JSON model first and then copies each image directly
  /// from disk into the export. At no point are all image bytes held in memory.
  static Future<File> createExportFile(CampaignShop shop) async {
    final shopMap = Map<String, dynamic>.from(shop.toMap());
    shopMap['id'] = '';

    final detachedImages = await PortableImageBundle.detachFileReferences(
      shopMap,
    );

    final canonicalByFile = <String, String>{};
    final imageRefs = <String, String>{};
    final imageExtensions = <String, String>{};
    final uniqueImages = <PortableImageFileReference>[];

    for (final reference in detachedImages) {
      String identity;
      try {
        identity = await reference.file.resolveSymbolicLinks();
      } catch (_) {
        identity = reference.file.absolute.path;
      }

      var canonicalKey = canonicalByFile[identity];
      if (canonicalKey == null) {
        canonicalKey = reference.key;
        canonicalByFile[identity] = canonicalKey;
        uniqueImages.add(reference);
        imageExtensions[canonicalKey] = _safeExtension(reference.file.path);
      }
      imageRefs[reference.key] = canonicalKey;
    }

    final header = <String, dynamic>{
      'type': formatType,
      'version': formatVersion,
      'shop': shopMap,
      'imageRefs': imageRefs,
      'imageExtensions': imageExtensions,
    };
    final headerBytes = utf8.encode(jsonEncode(header));

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_safeName(shop.name)}.asteria-shop');
    final output = await file.open(mode: FileMode.write);

    try {
      await output.writeFrom(_binaryMagic);
      await _writeUint32(output, headerBytes.length);
      await output.writeFrom(headerBytes);
      await _writeUint32(output, uniqueImages.length);

      for (final reference in uniqueImages) {
        final keyBytes = utf8.encode(reference.key);
        final imageLength = await reference.file.length();

        await _writeUint32(output, keyBytes.length);
        await output.writeFrom(keyBytes);
        await _writeUint64(output, imageLength);

        var written = 0;
        await for (final chunk in reference.file.openRead()) {
          if (chunk.isEmpty) continue;
          await output.writeFrom(chunk);
          written += chunk.length;
        }

        if (written != imageLength) {
          throw FileSystemException(
            'La imagen cambió mientras se exportaba.',
            reference.file.path,
          );
        }
      }

      await output.flush();
    } finally {
      await output.close();
    }

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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.single.path;
    if (path == null || path.isEmpty) return null;
    return importFromFile(File(path));
  }

  static Future<CampaignShop> importFromFile(File file) async {
    if (await _isBinaryV4(file)) {
      return _importBinaryV4(file);
    }

    // Compatibility with v1-v3 JSON exports. These formats were already in
    // circulation, so they remain importable even though new exports use the
    // streaming v4 archive.
    final bytes = await file.readAsBytes();
    final raw = _decodeLegacyExportBytes(bytes);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('El archivo de tienda no es válido.');
    }
    final root = Map<String, dynamic>.from(decoded);
    if (root['type'] != formatType) {
      throw const FormatException('El archivo no es una tienda de Asteria.');
    }
    final version = (root['version'] as num?)?.toInt() ?? 0;
    if (version <= 0 || version > formatVersion) {
      throw FormatException('Versión de tienda no compatible: $version');
    }
    if (root['shop'] is! Map) {
      throw const FormatException('La tienda está incompleta.');
    }

    if (version >= 2) {
      final shopMap = Map<String, dynamic>.from(root['shop'] as Map);
      if (root['images'] is Map) {
        await PortableImageBundle.restoreInto(
          shopMap,
          Map<String, dynamic>.from(root['images'] as Map),
          namespace: 'shop',
        );
      }
      return _withFreshIds(shopMap);
    }

    // Compatibility with v1 shops, which only stored each item's main image.
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
        importedProducts.add(
          CampaignShopProduct(
            id: 'shop_product_${DateTime.now().microsecondsSinceEpoch}_${importedProducts.length}',
            definition: definition,
            price: (productMap['price'] as num?)?.toInt() ?? 0,
          ),
        );
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

  static Future<CampaignShop> _importBinaryV4(File file) async {
    final input = await file.open(mode: FileMode.read);
    final savedImages = <String, String>{};

    try {
      final magic = await _readExact(input, _binaryMagic.length);
      if (!_bytesEqual(magic, _binaryMagic)) {
        throw const FormatException('El archivo de tienda no es válido.');
      }

      final headerLength = await _readUint32(input);
      if (headerLength <= 0 || headerLength > 64 * 1024 * 1024) {
        throw const FormatException('La cabecera de la tienda no es válida.');
      }

      final headerRaw = utf8.decode(await _readExact(input, headerLength));
      final decoded = jsonDecode(headerRaw);
      if (decoded is! Map) {
        throw const FormatException('La cabecera de la tienda no es válida.');
      }
      final root = Map<String, dynamic>.from(decoded);
      if (root['type'] != formatType ||
          (root['version'] as num?)?.toInt() != formatVersion ||
          root['shop'] is! Map) {
        throw const FormatException('El archivo no es una tienda de Asteria v4.');
      }

      final imageRefs = root['imageRefs'] is Map
          ? Map<String, dynamic>.from(root['imageRefs'] as Map)
          : <String, dynamic>{};
      final imageExtensions = root['imageExtensions'] is Map
          ? Map<String, dynamic>.from(root['imageExtensions'] as Map)
          : <String, dynamic>{};

      final imageCount = await _readUint32(input);
      if (imageCount > 100000) {
        throw const FormatException('El archivo contiene demasiadas imágenes.');
      }

      final docs = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${docs.path}/imported_images');
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      final batchId = DateTime.now().microsecondsSinceEpoch;

      for (var i = 0; i < imageCount; i++) {
        final keyLength = await _readUint32(input);
        if (keyLength <= 0 || keyLength > 1024 * 1024) {
          throw const FormatException('Clave de imagen no válida.');
        }
        final key = utf8.decode(await _readExact(input, keyLength));
        final imageLength = await _readUint64(input);

        final ext = _safeExtension(
          imageExtensions[key]?.toString() ?? 'img',
        );
        final imageFile = File(
          '${imageDir.path}/shop_${batchId}_$i.$ext',
        );
        final imageOutput = await imageFile.open(mode: FileMode.write);

        try {
          var remaining = imageLength;
          while (remaining > 0) {
            final amount = remaining > 64 * 1024 ? 64 * 1024 : remaining;
            final chunk = await _readExact(input, amount);
            await imageOutput.writeFrom(chunk);
            remaining -= chunk.length;
          }
          await imageOutput.flush();
        } catch (_) {
          try {
            await imageFile.delete();
          } catch (_) {
            // Ignore cleanup errors; the original import error is more useful.
          }
          rethrow;
        } finally {
          await imageOutput.close();
        }

        savedImages[key] = imageFile.path;
      }

      final restoredPaths = <String, String>{};
      for (final entry in imageRefs.entries) {
        final canonicalKey = entry.value?.toString() ?? '';
        final restoredPath = savedImages[canonicalKey];
        if (restoredPath != null && restoredPath.isNotEmpty) {
          restoredPaths[entry.key] = restoredPath;
        }
      }

      final shopMap = Map<String, dynamic>.from(root['shop'] as Map);
      PortableImageBundle.restoreFilePathsInto(shopMap, restoredPaths);
      return _withFreshIds(shopMap);
    } finally {
      await input.close();
    }
  }

  static CampaignShop _withFreshIds(Map<String, dynamic> shopMap) {
    final imported = CampaignShop.fromMap(
      Map<dynamic, dynamic>.from(shopMap),
    );
    final stamp = DateTime.now().microsecondsSinceEpoch;
    imported.id = 'shop_$stamp';
    for (var i = 0; i < imported.products.length; i++) {
      imported.products[i].id = 'shop_product_${stamp}_$i';
    }
    return imported;
  }

  static Future<bool> _isBinaryV4(File file) async {
    RandomAccessFile? input;
    try {
      input = await file.open(mode: FileMode.read);
      final bytes = await input.read(_binaryMagic.length);
      return _bytesEqual(bytes, _binaryMagic);
    } catch (_) {
      return false;
    } finally {
      if (input != null) {
        await input.close();
      }
    }
  }

  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static Future<void> _writeUint32(RandomAccessFile file, int value) async {
    final data = ByteData(4)..setUint32(0, value, Endian.big);
    await file.writeFrom(data.buffer.asUint8List());
  }

  static Future<void> _writeUint64(RandomAccessFile file, int value) async {
    final data = ByteData(8)..setUint64(0, value, Endian.big);
    await file.writeFrom(data.buffer.asUint8List());
  }

  static Future<int> _readUint32(RandomAccessFile file) async {
    final bytes = await _readExact(file, 4);
    return ByteData.sublistView(bytes).getUint32(0, Endian.big);
  }

  static Future<int> _readUint64(RandomAccessFile file) async {
    final bytes = await _readExact(file, 8);
    return ByteData.sublistView(bytes).getUint64(0, Endian.big);
  }

  static Future<Uint8List> _readExact(
    RandomAccessFile file,
    int length,
  ) async {
    if (length < 0) {
      throw const FormatException('Longitud de archivo no válida.');
    }
    final result = Uint8List(length);
    var offset = 0;
    while (offset < length) {
      final chunk = await file.read(length - offset);
      if (chunk.isEmpty) {
        throw const FormatException('El archivo de tienda está incompleto.');
      }
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return result;
  }

  static String _decodeLegacyExportBytes(List<int> bytes) {
    if (bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B) {
      return utf8.decode(gzip.decode(bytes));
    }
    return utf8.decode(bytes);
  }

  static Future<String> _saveLegacyImage(
    String itemId,
    String? encoded,
  ) async {
    if (encoded == null || encoded.isEmpty) return '';
    try {
      final bytes = base64Decode(encoded);
      final dir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${dir.path}/item_images');
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      final file = File(
        '${imageDir.path}/shop_${_safeName(itemId)}_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return '';
    }
  }

  static String _safeExtension(String value) {
    var candidate = value.trim().toLowerCase();
    final slash = candidate.lastIndexOf(RegExp(r'[/\\]'));
    if (slash >= 0 && slash + 1 < candidate.length) {
      candidate = candidate.substring(slash + 1);
    }
    final dot = candidate.lastIndexOf('.');
    if (dot >= 0 && dot + 1 < candidate.length) {
      candidate = candidate.substring(dot + 1);
    }
    candidate = candidate.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (candidate.isEmpty || candidate.length > 8) return 'img';
    return candidate;
  }

  static String _safeName(String value) {
    final result = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return result.isEmpty ? 'asteria_shop' : result;
  }
}
