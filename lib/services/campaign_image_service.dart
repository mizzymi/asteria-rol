import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class CampaignImageService {
  static Future<String> saveImage({
    required String campaignId,
    required String sourcePath,
  }) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(path.join(root.path, 'campaign_images'));
    if (!await directory.exists()) await directory.create(recursive: true);

    final extension = path.extension(sourcePath).isEmpty
        ? '.jpg'
        : path.extension(sourcePath);
    final target = path.join(directory.path, '$campaignId$extension');
    final file = File(target);
    if (await file.exists()) await file.delete();
    return (await File(sourcePath).copy(target)).path;
  }

  static Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    final file = File(imagePath);
    if (await file.exists()) await file.delete();
  }
}
