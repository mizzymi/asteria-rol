import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/campaign.dart';
import '../models/character.dart';
import 'character_storage_service.dart';
import 'portable_image_bundle.dart';

/// Exporta una campaña completa de forma portable.
/// Incluye la imagen de campaña, tiendas y todos sus objetos, PJ, NPC,
/// hosts de criaturas, mascotas y cualquier imagen anidada en objetos,
/// habilidades y pasivas.
class CampaignImportExportService {
  const CampaignImportExportService._();

  static const String formatType = 'asteria-campaign';
  static const int formatVersion = 1;

  static Future<File> createExportFile(Campaign campaign) async {
    final characters = CharacterStorageService.getCharacters()
        .where((c) => c.campaignId == campaign.id)
        .toList();

    final root = <String, dynamic>{
      'campaign': Map<String, dynamic>.from(campaign.toMap()),
      'characters': characters
          .map((c) => Map<String, dynamic>.from(c.toMap()))
          .toList(),
    };

    // Una única pasada recursiva recoge TODAS las imágenes de todo el árbol.
    final images = await PortableImageBundle.extractFrom(root);
    final payload = <String, dynamic>{
      'type': formatType,
      'version': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      ...root,
      'images': images,
    };

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_safeName(campaign.name)}.asteria-campaign');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    return file;
  }

  static Future<void> shareCampaign(Campaign campaign) async {
    final file = await createExportFile(campaign);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Campaña de Asteria: ${campaign.name}',
        text: 'Campaña completa de Asteria con sus imágenes incluidas.',
      ),
    );
  }

  /// Utilidad preparada para la importación completa: restaura todas las
  /// imágenes antes de reconstruir los modelos.
  static Future<({Campaign campaign, List<Character> characters})>
      decodePortable(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Archivo de campaña inválido.');
    }
    final map = Map<String, dynamic>.from(decoded);
    if (map['type'] != formatType || map['campaign'] is! Map) {
      throw const FormatException('El archivo no es una campaña de Asteria.');
    }

    final root = <String, dynamic>{
      'campaign': Map<String, dynamic>.from(map['campaign'] as Map),
      'characters': map['characters'] is List
          ? (map['characters'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[],
    };
    if (map['images'] is Map) {
      await PortableImageBundle.restoreInto(
        root,
        Map<String, dynamic>.from(map['images'] as Map),
        namespace: 'campaign',
      );
    }

    final campaign = Campaign.fromMap(
      Map<dynamic, dynamic>.from(root['campaign'] as Map),
    );
    final characters = (root['characters'] as List)
        .whereType<Map>()
        .map((e) => Character.fromMap(Map<dynamic, dynamic>.from(e)))
        .toList();
    return (campaign: campaign, characters: characters);
  }

  static String _safeName(String value) {
    final safe = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    return safe.isEmpty ? 'campana' : safe;
  }
}
