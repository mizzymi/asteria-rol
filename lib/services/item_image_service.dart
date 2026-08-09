import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ItemImageService {
  const ItemImageService._();

  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1600,
    );

    if (picked == null) {
      return null;
    }

    final directory = await getApplicationDocumentsDirectory();

    final imagesDirectory = Directory('${directory.path}/item_images');

    if (!await imagesDirectory.exists()) {
      await imagesDirectory.create(recursive: true);
    }

    final extension = picked.path.split('.').last.toLowerCase();

    final fileName = 'item_${DateTime.now().microsecondsSinceEpoch}.$extension';

    final destination = File('${imagesDirectory.path}/$fileName');

    await File(picked.path).copy(destination.path);

    return destination.path;
  }

  static Future<void> deleteImage(String path) async {
    if (path.isEmpty) {
      return;
    }

    final file = File(path);

    if (await file.exists()) {
      await file.delete();
    }
  }
}
