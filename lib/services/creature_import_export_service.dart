import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/pet.dart';
import 'portable_image_bundle.dart';

/// Portable creature sheets can be imported as master creatures or pets.
class CreatureImportExportService {
  const CreatureImportExportService._();

  static Future<void> shareCreature(Pet pet, {required bool asPet}) async {
    final root = <String, dynamic>{
      'pet': Map<String, dynamic>.from(pet.toMap()),
    };
    final images = await PortableImageBundle.extractFrom(root);
    final directory = await getTemporaryDirectory();
    final safeName = pet.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File(
      '${directory.path}/${safeName.isEmpty ? 'creature' : safeName}_${asPet ? 'mascota' : 'criatura'}.asteria-creature',
    );
    await file.writeAsString(
      jsonEncode({
        'format': 'asteria_creature',
        'version': 1,
        'role': asPet ? 'pet' : 'masterCreature',
        ...root,
        'images': images,
      }),
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: '${pet.name} — ${asPet ? 'mascota' : 'criatura del Máster'}',
      ),
    );
  }

  static Future<Pet> importCreature(File file) async {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map ||
        decoded['format'] != 'asteria_creature' ||
        decoded['pet'] is! Map) {
      throw const FormatException('El archivo no es una criatura de Asteria.');
    }
    final root = <String, dynamic>{
      'pet': Map<String, dynamic>.from(decoded['pet'] as Map),
    };
    if (decoded['images'] is Map) {
      await PortableImageBundle.restoreInto(
        root,
        Map<String, dynamic>.from(decoded['images'] as Map),
        namespace: 'creature',
      );
    }
    final petMap = Map<String, dynamic>.from(root['pet'] as Map);
    petMap['id'] = 'pet_${DateTime.now().microsecondsSinceEpoch}';
    return Pet.fromMap(petMap);
  }
}
