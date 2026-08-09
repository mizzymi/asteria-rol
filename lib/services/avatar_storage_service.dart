import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AvatarStorageService {
  static Future<String> saveAvatar({
    required String characterId,
    required String sourcePath,
  }) async {
    final directory = await getApplicationDocumentsDirectory();

    final avatarsDirectory = Directory(path.join(directory.path, 'avatars'));

    if (!await avatarsDirectory.exists()) {
      await avatarsDirectory.create(recursive: true);
    }

    final extension = path.extension(sourcePath);

    final safeExtension = extension.isEmpty ? '.jpg' : extension;

    final targetPath = path.join(
      avatarsDirectory.path,
      '$characterId$safeExtension',
    );

    final source = File(sourcePath);

    final existing = File(targetPath);

    if (await existing.exists()) {
      await existing.delete();
    }

    final savedFile = await source.copy(targetPath);

    return savedFile.path;
  }

  static Future<void> deleteAvatar(String? avatarPath) async {
    if (avatarPath == null || avatarPath.isEmpty) {
      return;
    }

    final file = File(avatarPath);

    if (await file.exists()) {
      await file.delete();
    }
  }
}
