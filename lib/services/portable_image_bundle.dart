import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Embeds every local image path found in a serialized Asteria map and can
/// restore those images on another device. This intentionally works on maps so
/// nested item/ability/passive/pet images are included automatically.
class PortableImageBundle {
  const PortableImageBundle._();

  static bool _isImagePathKey(String key) {
    final lower = key.toLowerCase();
    return lower == 'imagepath' || lower == 'avatarpath' || lower.endsWith('imagepath');
  }

  static Future<Map<String, String>> extractFrom(Map<String, dynamic> root) async {
    final images = <String, String>{};

    Future<void> walk(dynamic node, List<String> path) async {
      if (node is Map) {
        for (final rawKey in node.keys.toList()) {
          final key = rawKey.toString();
          final value = node[rawKey];
          final nextPath = [...path, key];
          if (_isImagePathKey(key) && value is String && value.trim().isNotEmpty) {
            final file = File(value);
            if (await file.exists()) {
              try {
                images[_pathKey(nextPath)] = base64Encode(await file.readAsBytes());
              } catch (_) {}
            }
            node[rawKey] = '';
          } else {
            await walk(value, nextPath);
          }
        }
      } else if (node is List) {
        for (var i = 0; i < node.length; i++) {
          await walk(node[i], [...path, '#$i']);
        }
      }
    }

    await walk(root, const []);
    return images;
  }

  static Future<void> restoreInto(
    Map<String, dynamic> root,
    Map<String, dynamic> rawImages, {
    String namespace = 'import',
  }) async {
    final images = rawImages.map((key, value) => MapEntry(key, value?.toString() ?? ''));

    Future<void> walk(dynamic node, List<String> path) async {
      if (node is Map) {
        for (final rawKey in node.keys.toList()) {
          final key = rawKey.toString();
          final value = node[rawKey];
          final nextPath = [...path, key];
          if (_isImagePathKey(key)) {
            final encoded = images[_pathKey(nextPath)];
            if (encoded != null && encoded.isNotEmpty) {
              try {
                final bytes = base64Decode(encoded);
                node[rawKey] = await _saveBytes(bytes, namespace);
              } catch (_) {
                node[rawKey] = '';
              }
            }
          } else {
            await walk(value, nextPath);
          }
        }
      } else if (node is List) {
        for (var i = 0; i < node.length; i++) {
          await walk(node[i], [...path, '#$i']);
        }
      }
    }

    await walk(root, const []);
  }

  static String _pathKey(List<String> path) => path.map(Uri.encodeComponent).join('/');

  static Future<String> _saveBytes(Uint8List bytes, String namespace) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/imported_images');
    if (!await dir.exists()) await dir.create(recursive: true);
    final ext = _extension(bytes);
    final safeNamespace = namespace.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    final file = File(
      '${dir.path}/${safeNamespace}_${DateTime.now().microsecondsSinceEpoch}_$ext',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static String _extension(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'png';
    }
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'jpg';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return 'webp';
    }
    return 'img';
  }
}
