import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class PetImageService {
  const PetImageService._();

  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1800,
    );

    if (picked == null) return null;

    final directory = await getApplicationDocumentsDirectory();
    final imagesDirectory = Directory('${directory.path}/pet_images');

    if (!await imagesDirectory.exists()) {
      await imagesDirectory.create(recursive: true);
    }

    final parts = picked.path.split('.');
    final extension = parts.length > 1 ? parts.last.toLowerCase() : 'jpg';
    final fileName = 'pet_${DateTime.now().microsecondsSinceEpoch}.$extension';
    final destination = File('${imagesDirectory.path}/$fileName');

    await File(picked.path).copy(destination.path);
    return destination.path;
  }

  static Future<void> deleteImage(String imagePath) async {
    if (imagePath.isEmpty) return;
    final file = File(imagePath);
    if (await file.exists()) await file.delete();
  }
}
