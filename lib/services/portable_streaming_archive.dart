import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'portable_image_bundle.dart';

/// Small streaming archive used by Asteria portable exports.
///
/// The serialized model stays in a compact JSON header while local images are
/// copied one by one after it. This mirrors the shop v4 strategy and avoids
/// Base64 and large in-memory export payloads.
class PortableStreamingArchive {
  const PortableStreamingArchive._();

  static Uint8List magic(String id) => Uint8List.fromList(utf8.encode('$id\n'));

  static Future<void> write({
    required File file,
    required Uint8List magicBytes,
    required Map<String, dynamic> root,
    required Map<String, dynamic> header,
  }) async {
    final detachedImages = await PortableImageBundle.detachFileReferences(root);

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

    final archiveHeader = <String, dynamic>{
      ...header,
      'root': root,
      'imageRefs': imageRefs,
      'imageExtensions': imageExtensions,
    };
    final headerBytes = utf8.encode(jsonEncode(archiveHeader));

    final output = await file.open(mode: FileMode.write);
    try {
      await output.writeFrom(magicBytes);
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
          if (chunk.isEmpty) {
            continue;
          }
          await output.writeFrom(chunk);
          written += chunk.length;
        }

        if (written != imageLength) {
          throw FileSystemException(
            'Una imagen cambió mientras se exportaba.',
            reference.file.path,
          );
        }
      }

      await output.flush();
    } finally {
      await output.close();
    }
  }

  static Future<bool> hasMagic(File file, Uint8List magicBytes) async {
    RandomAccessFile? input;
    try {
      input = await file.open(mode: FileMode.read);
      final bytes = await input.read(magicBytes.length);
      return _bytesEqual(bytes, magicBytes);
    } catch (_) {
      return false;
    } finally {
      if (input != null) {
        await input.close();
      }
    }
  }

  static Future<Map<String, dynamic>> read({
    required File file,
    required Uint8List magicBytes,
    required String namespace,
  }) async {
    final input = await file.open(mode: FileMode.read);
    final savedImages = <String, String>{};

    try {
      final foundMagic = await _readExact(input, magicBytes.length);
      if (!_bytesEqual(foundMagic, magicBytes)) {
        throw const FormatException('El archivo de Asteria no es válido.');
      }

      final headerLength = await _readUint32(input);
      if (headerLength <= 0 || headerLength > 64 * 1024 * 1024) {
        throw const FormatException('La cabecera del archivo no es válida.');
      }

      final decoded = jsonDecode(
        utf8.decode(await _readExact(input, headerLength)),
      );
      if (decoded is! Map) {
        throw const FormatException('La cabecera del archivo no es válida.');
      }
      final header = Map<String, dynamic>.from(decoded);
      if (header['root'] is! Map) {
        throw const FormatException('El archivo está incompleto.');
      }

      final imageRefs = header['imageRefs'] is Map
          ? Map<String, dynamic>.from(header['imageRefs'] as Map)
          : <String, dynamic>{};
      final imageExtensions = header['imageExtensions'] is Map
          ? Map<String, dynamic>.from(header['imageExtensions'] as Map)
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
      final safeNamespace = namespace.replaceAll(
        RegExp(r'[^a-zA-Z0-9_-]+'),
        '_',
      );

      for (var i = 0; i < imageCount; i++) {
        final keyLength = await _readUint32(input);
        if (keyLength <= 0 || keyLength > 1024 * 1024) {
          throw const FormatException('Clave de imagen no válida.');
        }
        final key = utf8.decode(await _readExact(input, keyLength));
        final imageLength = await _readUint64(input);

        final ext = _safeExtension(imageExtensions[key]?.toString() ?? 'img');
        final imageFile = File(
          '${imageDir.path}/${safeNamespace}_${batchId}_$i.$ext',
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
            // Keep the original import exception.
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

      final root = Map<String, dynamic>.from(header['root'] as Map);
      PortableImageBundle.restoreFilePathsInto(root, restoredPaths);
      header['root'] = root;
      return header;
    } finally {
      await input.close();
    }
  }

  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
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

  static Future<Uint8List> _readExact(RandomAccessFile file, int length) async {
    if (length < 0) {
      throw const FormatException('Longitud de archivo no válida.');
    }
    final result = Uint8List(length);
    var offset = 0;
    while (offset < length) {
      final chunk = await file.read(length - offset);
      if (chunk.isEmpty) {
        throw const FormatException('El archivo está incompleto.');
      }
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return result;
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
    if (candidate.isEmpty || candidate.length > 8) {
      return 'img';
    }
    return candidate;
  }
}
