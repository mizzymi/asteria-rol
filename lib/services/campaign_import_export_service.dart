import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/campaign.dart';
import '../models/character.dart';
import 'character_storage_service.dart';
import 'portable_image_bundle.dart';
import 'portable_streaming_archive.dart';

/// Exporta una campaña portable con el mismo enfoque streaming de las tiendas.
/// Las imágenes se escriben de una en una y nunca se convierten todas a Base64
/// en memoria.
class CampaignImportExportService {
  const CampaignImportExportService._();

  static const String formatType = 'asteria-campaign';
  static const int formatVersion = 2;
  static final _binaryMagic = PortableStreamingArchive.magic(
    'ASTERIA_CAMPAIGN_V2',
  );

  static Future<File> createExportFile(
    Campaign campaign, {
    bool includePlayerCharacters = true,
  }) async {
    final allCharacters = CharacterStorageService.getCharacters()
        .where((c) => c.campaignId == campaign.id)
        .toList();

    final excludedPlayerIds = includePlayerCharacters
        ? <String>{}
        : allCharacters
              .where((c) => c.ownerType == 'player')
              .map((c) => c.id)
              .where((id) => id.isNotEmpty)
              .toSet();

    final characters = includePlayerCharacters
        ? allCharacters
        : allCharacters.where((c) => c.ownerType != 'player').toList();

    final campaignMap = Map<String, dynamic>.from(campaign.toMap());
    if (excludedPlayerIds.isNotEmpty) {
      _removeCharacterReferences(campaignMap, excludedPlayerIds);
    }

    final root = <String, dynamic>{
      'campaign': campaignMap,
      'characters': characters
          .map((c) => Map<String, dynamic>.from(c.toMap()))
          .toList(),
    };

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/${_safeName(campaign.name)}.asteria-campaign',
    );

    await PortableStreamingArchive.write(
      file: file,
      magicBytes: _binaryMagic,
      root: root,
      header: <String, dynamic>{
        'type': formatType,
        'version': formatVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'characterScope': includePlayerCharacters ? 'all' : 'masterOnly',
      },
    );

    return file;
  }

  static Future<void> shareCampaign(
    Campaign campaign, {
    bool includePlayerCharacters = true,
  }) async {
    final file = await createExportFile(
      campaign,
      includePlayerCharacters: includePlayerCharacters,
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/octet-stream')],
        subject: 'Campaña de Asteria: ${campaign.name}',
        text: includePlayerCharacters
            ? 'Campaña completa de Asteria con sus imágenes incluidas.'
            : 'Campaña de Máster de Asteria, sin fichas de jugadores.',
      ),
    );
  }

  /// Compatibilidad con exportaciones JSON antiguas.
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

    return _modelsFromRoot(root);
  }

  static Future<({Campaign campaign, List<Character> characters})>
  _decodeBinary(File file) async {
    final header = await PortableStreamingArchive.read(
      file: file,
      magicBytes: _binaryMagic,
      namespace: 'campaign',
    );
    if (header['type'] != formatType ||
        (header['version'] as num?)?.toInt() != formatVersion) {
      throw const FormatException(
        'El archivo no es una campaña de Asteria v2.',
      );
    }
    return _modelsFromRoot(Map<String, dynamic>.from(header['root'] as Map));
  }

  static ({Campaign campaign, List<Character> characters}) _modelsFromRoot(
    Map<String, dynamic> root,
  ) {
    if (root['campaign'] is! Map) {
      throw const FormatException('La campaña está incompleta.');
    }
    final campaign = Campaign.fromMap(
      Map<dynamic, dynamic>.from(root['campaign'] as Map),
    );
    final characters = root['characters'] is List
        ? (root['characters'] as List)
              .whereType<Map>()
              .map((e) => Character.fromMap(Map<dynamic, dynamic>.from(e)))
              .toList()
        : <Character>[];
    return (campaign: campaign, characters: characters);
  }

  /// Importa una campaña portable como una copia independiente.
  static Future<({Campaign campaign, List<Character> characters})>
  importPortableAsCopy(String raw) async {
    return _asCopy(await decodePortable(raw));
  }

  static ({Campaign campaign, List<Character> characters}) _asCopy(
    ({Campaign campaign, List<Character> characters}) decoded,
  ) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final newCampaignId = 'campaign_$stamp';

    final characterIdMap = <String, String>{};
    final newCharacterIds = <String>[];
    for (var i = 0; i < decoded.characters.length; i++) {
      final newId = 'character_${stamp}_$i';
      newCharacterIds.add(newId);
      final oldId = decoded.characters[i].id;
      if (oldId.isNotEmpty) {
        characterIdMap[oldId] = newId;
      }
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

  /// Compatibilidad API con importaciones desde texto JSON antiguas.
  static Future<({Campaign campaign, List<Character> characters})>
  importPortable(String raw) async {
    return decodePortable(raw);
  }

  static Future<({Campaign campaign, List<Character> characters})> importFile(
    File file,
  ) async {
    if (await PortableStreamingArchive.hasMagic(file, _binaryMagic)) {
      return _decodeBinary(file);
    }
    return importPortable(await file.readAsString());
  }

  static Future<({Campaign campaign, List<Character> characters})>
  importFileAsCopy(File file) async {
    final decoded = await importFile(file);
    return _asCopy(decoded);
  }

  static void _removeCharacterReferences(dynamic node, Set<String> ids) {
    if (node is Map) {
      for (final key in node.keys.toList()) {
        final keyText = key.toString();
        final value = node[key];
        if (keyText == 'characterId' &&
            value is String &&
            ids.contains(value)) {
          node[key] = '';
          continue;
        }
        if (keyText == 'acceptedCharacterIds' && value is List) {
          node[key] = value
              .where((id) => !ids.contains(id.toString()))
              .toList();
          continue;
        }
        _removeCharacterReferences(value, ids);
      }
      return;
    }
    if (node is List) {
      for (final value in node) {
        _removeCharacterReferences(value, ids);
      }
    }
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
