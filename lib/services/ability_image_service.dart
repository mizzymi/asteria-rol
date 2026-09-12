import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Guarda imágenes de habilidades y pasivas dentro de los documentos de la app.
/// La imagen original de la galería no se modifica.
class AbilityImageService {
  const AbilityImageService._();

  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 1800,
    );

    if (picked == null) return null;

    final directory = await getApplicationDocumentsDirectory();
    final imagesDirectory = Directory('${directory.path}/ability_images');
    if (!await imagesDirectory.exists()) {
      await imagesDirectory.create(recursive: true);
    }

    final parts = picked.path.split('.');
    final extension = parts.length > 1 ? parts.last.toLowerCase() : 'jpg';
    final fileName =
        'ability_${DateTime.now().microsecondsSinceEpoch}.$extension';
    final destination = File('${imagesDirectory.path}/$fileName');
    await File(picked.path).copy(destination.path);
    return destination.path;
  }
}
