import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AvatarStorageService {
  static Future<String> saveAvatar({
    required String characterId,
    required String sourcePath,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('No se encuentra la imagen seleccionada', sourcePath);
    }

    final directory = await getApplicationDocumentsDirectory();
    final avatarsDirectory = Directory(path.join(directory.path, 'avatars'));
    await avatarsDirectory.create(recursive: true);

    // Use a new filename for each selection to prevent stale FileImage caches
    // and avoid deleting the original avatar before saving the replacement.
    final extension = path.extension(sourcePath).toLowerCase();
    final safeExtension = ['.jpg', '.jpeg', '.png', '.webp'].contains(extension)
        ? extension
        : '.jpg';
    final targetPath = path.join(
      avatarsDirectory.path,
      '${characterId}_${DateTime.now().microsecondsSinceEpoch}$safeExtension',
    );
    final saved = await source.copy(targetPath);
    if (!await saved.exists() || await saved.length() == 0) {
      throw FileSystemException('No se pudo guardar el avatar', targetPath);
    }
    return saved.path;
  }

  static Future<void> deleteAvatar(String? avatarPath) async {
    if (avatarPath == null || avatarPath.isEmpty) return;
    final file = File(avatarPath);
    if (await file.exists()) await file.delete();
  }
}
