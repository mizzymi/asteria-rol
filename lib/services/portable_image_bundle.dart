import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class PortableImageFileReference {
  const PortableImageFileReference({
    required this.key,
    required this.file,
  });

  final String key;
  final File file;
}

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

  /// Detaches local image paths from [root] without reading the image bytes.
  ///
  /// This is intended for streaming export formats: the serialized model is
  /// made portable immediately, while callers can copy each returned file to
  /// the export one at a time without ever keeping all images in memory.
  static Future<List<PortableImageFileReference>> detachFileReferences(
    Map<String, dynamic> root,
  ) async {
    final references = <PortableImageFileReference>[];

    Future<void> walk(dynamic node, List<String> path) async {
      if (node is Map) {
        for (final rawKey in node.keys.toList()) {
          final key = rawKey.toString();
          final value = node[rawKey];
          final nextPath = [...path, key];

          if (_isImagePathKey(key)) {
            if (value is String && value.trim().isNotEmpty) {
              final file = _fileFromStoredPath(value.trim());
              if (file != null) {
                try {
                  final stat = await file.stat();
                  if (stat.type == FileSystemEntityType.file && stat.size > 0) {
                    references.add(
                      PortableImageFileReference(
                        key: _pathKey(nextPath),
                        file: file,
                      ),
                    );
                  }
                } catch (_) {
                  // Ignore broken or inaccessible paths. The exported model
                  // remains valid; it will simply have no image at this key.
                }
              }
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
    return references;
  }

  /// Restores image paths previously detached from a serialized model.
  ///
  /// [pathsByKey] maps the same recursive bundle keys used by
  /// [detachFileReferences] to files already written on the destination
  /// device. Missing keys are left blank so source-device paths can never leak
  /// into an imported model.
  static void restoreFilePathsInto(
    Map<String, dynamic> root,
    Map<String, String> pathsByKey,
  ) {
    void walk(dynamic node, List<String> path) {
      if (node is Map) {
        for (final rawKey in node.keys.toList()) {
          final key = rawKey.toString();
          final value = node[rawKey];
          final nextPath = [...path, key];

          if (_isImagePathKey(key)) {
            node[rawKey] = pathsByKey[_pathKey(nextPath)] ?? '';
          } else {
            walk(value, nextPath);
          }
        }
      } else if (node is List) {
        for (var i = 0; i < node.length; i++) {
          walk(node[i], [...path, '#$i']);
        }
      }
    }

    walk(root, const []);
  }

  static Future<Map<String, String>> extractFrom(
    Map<String, dynamic> root, {
    bool deduplicate = false,
  }) async {
    final images = <String, String>{};
    final canonicalByEncoded = <String, String>{};

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
                    final pathKey = _pathKey(nextPath);
                    final encoded = base64Encode(bytes);
                    if (deduplicate) {
                      final canonicalKey = canonicalByEncoded[encoded];
                      if (canonicalKey != null) {
                        images[pathKey] = '@ref:$canonicalKey';
                      } else {
                        canonicalByEncoded[encoded] = pathKey;
                        images[pathKey] = encoded;
                      }
                    } else {
                      images[pathKey] = encoded;
                    }
                  }
                } catch (_) {
                  // A broken/unreadable local path must never make the whole
                  // character/shop/item export fail.
                }
              }
            }

            // Never export a device-specific path. The importer will replace
            // this with the restored path on the destination device.
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
            final encoded = _resolveEncodedImage(
              images,
              _pathKey(nextPath),
            );
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


  static String? _resolveEncodedImage(
    Map<String, String> images,
    String key, [
    Set<String>? visited,
  ]) {
    final value = images[key];
    if (value == null || value.isEmpty) return value;
    if (!value.startsWith('@ref:')) return value;

    final target = value.substring(5);
    if (target.isEmpty) return null;
    final seen = visited ?? <String>{};
    if (!seen.add(key)) return null;
    return _resolveEncodedImage(images, target, seen);
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
