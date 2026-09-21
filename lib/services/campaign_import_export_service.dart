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
    final file = File(
      '${dir.path}/${_safeName(campaign.name)}.asteria-campaign',
    );
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
    final version = (map['version'] as num?)?.toInt() ?? 0;
    if (version <= 0 || version > formatVersion) {
      throw FormatException('Versión de campaña no compatible: $version');
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

  /// Importa una campaña portable como una copia independiente.
  ///
  /// Se regeneran los IDs de la campaña y de todas sus fichas para evitar
  /// sobrescribir datos existentes cuando se importa una campaña exportada
  /// desde este mismo dispositivo. El contenido y las imágenes se conservan.
  static Future<({Campaign campaign, List<Character> characters})>
  importPortableAsCopy(String raw) async {
    final decoded = await decodePortable(raw);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final newCampaignId = 'campaign_$stamp';

    final characterIdMap = <String, String>{};
    final newCharacterIds = <String>[];
    for (var i = 0; i < decoded.characters.length; i++) {
      final newId = 'character_${stamp}_$i';
      newCharacterIds.add(newId);
      final oldId = decoded.characters[i].id;
      if (oldId.isNotEmpty) characterIdMap[oldId] = newId;
    }

    final campaignMap = Map<String, dynamic>.from(decoded.campaign.toMap());
    campaignMap['id'] = newCampaignId;
    _remapCharacterReferences(campaignMap, characterIdMap);
    final campaign = Campaign.fromMap(Map<dynamic, dynamic>.from(campaignMap));

    final characters = <Character>[];
    for (var i = 0; i < decoded.characters.length; i++) {
      final characterMap = Map<String, dynamic>.from(
        decoded.characters[i].toMap(),
      );
      characterMap['id'] = newCharacterIds[i];
      characterMap['campaignId'] = newCampaignId;
      _remapCharacterReferences(characterMap, characterIdMap);
      characters.add(
        Character.fromMap(Map<dynamic, dynamic>.from(characterMap)),
      );
    }

    return (campaign: campaign, characters: characters);
  }

  /// Importa una campaña conservando los IDs del archivo exportado.
  ///
  /// Esto permite reconocer posteriores importaciones de la misma campaña y
  /// actualizarla en lugar de crear copias con IDs distintos.
  static Future<({Campaign campaign, List<Character> characters})>
  importPortable(String raw) async {
    return decodePortable(raw);
  }

  static Future<({Campaign campaign, List<Character> characters})> importFile(
    File file,
  ) async {
    return importPortable(await file.readAsString());
  }

  static Future<({Campaign campaign, List<Character> characters})>
  importFileAsCopy(File file) async {
    return importPortableAsCopy(await file.readAsString());
  }

  static void _remapCharacterReferences(
    dynamic node,
    Map<String, String> idMap,
  ) {
    if (node is Map) {
      for (final key in node.keys.toList()) {
        final keyText = key.toString();
        final value = node[key];
        if (keyText == 'characterId' && value is String) {
          node[key] = idMap[value] ?? value;
          continue;
        }
        if (keyText == 'acceptedCharacterIds' && value is List) {
          node[key] = value
              .map((id) => idMap[id.toString()] ?? id.toString())
              .toList();
          continue;
        }
        _remapCharacterReferences(value, idMap);
      }
      return;
    }
    if (node is List) {
      for (final value in node) {
        _remapCharacterReferences(value, idMap);
      }
    }
  }

  static String _safeName(String value) {
    final safe = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    return safe.isEmpty ? 'campana' : safe;
  }
}
