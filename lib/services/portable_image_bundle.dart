import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Makes Asteria exports portable between devices.
///
/// Every local image referenced anywhere inside a serialized model is embedded
/// in the export as base64. During import the bytes are written into the new
/// device's application documents directory and the serialized path is replaced
/// with that new local path before the model is reconstructed.
///
/// Working recursively on maps means this also covers nested content such as:
/// character -> pets -> abilities/passives and inventory -> items ->
/// abilities/passives, as well as shop -> products -> item content.
class PortableImageBundle {
  const PortableImageBundle._();

  static bool _isImagePathKey(String key) {
    final lower = key.toLowerCase();
    if (lower == 'imagepath' || lower == 'avatarpath') return true;

    // Keep the bundle future-proof for visual fields added later without
    // accidentally treating alignment/metadata fields as files.
    return lower.endsWith('imagepath') ||
        lower.endsWith('avatarpath') ||
        lower.endsWith('portraitpath') ||
        lower.endsWith('coverpath') ||
        lower.endsWith('photopath') ||
        lower.endsWith('thumbnailpath') ||
        lower.endsWith('iconpath') ||
        lower.endsWith('bannerpath') ||
        lower.endsWith('backgroundpath');
  }

  static Future<Map<String, String>> extractFrom(
    Map<String, dynamic> root,
  ) async {
    final images = <String, String>{};

    Future<void> walk(dynamic node, List<String> path) async {
      if (node is Map) {
        for (final rawKey in node.keys.toList()) {
          final key = rawKey.toString();
          final value = node[rawKey];
          final nextPath = [...path, key];

          if (_isImagePathKey(key)) {
            if (value is String && value.trim().isNotEmpty) {
              final file = _fileFromStoredPath(value.trim());
              if (file != null && await file.exists()) {
                try {
                  final bytes = await file.readAsBytes();
                  if (bytes.isNotEmpty) {
                    images[_pathKey(nextPath)] = base64Encode(bytes);
                  }
                } catch (_) {
                  // Keep walking. We only clear the local path when its bytes
                  // were actually embedded in the portable JSON.
                }
              }
            }

            // IMPORTANT: do not silently erase an image from the JSON when its
            // file cannot be read. Older exports did that, so an item could
            // visibly have an image in Asteria but be exported with an empty
            // imagePath and without bytes in `images`.
            //
            // When embedding succeeds we clear the device-specific path as
            // before. If it fails, keep the original value in the JSON. This
            // makes the problem explicit and, at minimum, preserves same-device
            // compatibility instead of destroying the only image reference.
            if (images.containsKey(_pathKey(nextPath))) {
              node[rawKey] = '';
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
    return images;
  }

  static Future<void> restoreInto(
    Map<String, dynamic> root,
    Map<String, dynamic> rawImages, {
    String namespace = 'import',
  }) async {
    final images = rawImages.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );

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
                node[rawKey] = await _saveBytes(
                  base64Decode(encoded),
                  namespace,
                );
              } catch (_) {
                node[rawKey] = '';
              }
            } else {
              // Old path values are useless on another device. Keep the model
              // safe rather than leaving a path pointing at the source device.
              node[rawKey] = '';
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

  static File? _fileFromStoredPath(String value) {
    try {
      final uri = Uri.tryParse(value);
      if (uri != null && uri.scheme == 'file') return File.fromUri(uri);
      return File(value);
    } catch (_) {
      return null;
    }
  }

  static String _pathKey(List<String> path) =>
      path.map(Uri.encodeComponent).join('/');

  static Future<String> _saveBytes(Uint8List bytes, String namespace) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/imported_images');
    if (!await dir.exists()) await dir.create(recursive: true);

    final ext = _extension(bytes);
    final safeNamespace = namespace.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]+'),
      '_',
    );
    final file = File(
      '${dir.path}/${safeNamespace}_${DateTime.now().microsecondsSinceEpoch}.$ext',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static String _extension(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'jpg';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'webp';
    }
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return 'gif';
    }
    return 'img';
  }
}
