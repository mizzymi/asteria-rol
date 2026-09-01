import 'dart:convert';
import 'dart:math';

import 'action_effect_result.dart';
import 'character_effect.dart';
import 'passive_trigger_external_result.dart';
import 'character_effect_trigger_external_result.dart';
import 'action_apply_result.dart';
import 'external_action_outcome.dart';

// =============================================================================
// TIPO
// =============================================================================

enum ExternalActionTransferType { pendingOutcome, confirmedOutcome }

// =============================================================================
// TRANSFER
// =============================================================================

class ExternalActionTransfer {
  static const int currentVersion = 1;

  final int version;

  /// Identifica de forma única esta resolución externa.
  ///
  /// El pending y su confirmed correspondiente comparten el mismo ID.
  final String transferId;

  final ExternalActionTransferType type;

  final ExternalTargetOutcome? pendingOutcome;

  final ExternalActionOutcome? confirmedOutcome;

  const ExternalActionTransfer._({
    required this.version,
    required this.transferId,
    required this.type,
    this.pendingOutcome,
    this.confirmedOutcome,
  });

  // ===========================================================================
  // PENDING
  // ===========================================================================

  factory ExternalActionTransfer.pending(ExternalTargetOutcome outcome) {
    return ExternalActionTransfer._(
      version: currentVersion,
      transferId: _newTransferId(),
      type: ExternalActionTransferType.pendingOutcome,
      pendingOutcome: outcome,
    );
  }

  // ===========================================================================
  // CONFIRMED
  //
  // IMPORTANTE:
  //
  // reutiliza el transferId del pending original.
  // ===========================================================================

  factory ExternalActionTransfer.confirmed({
    required String transferId,
    required ExternalActionOutcome outcome,
  }) {
    final normalizedId = transferId.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError.value(
        transferId,
        'transferId',
        'La confirmación necesita el ID de la transferencia original.',
      );
    }

    return ExternalActionTransfer._(
      version: currentVersion,
      transferId: normalizedId,
      type: ExternalActionTransferType.confirmedOutcome,
      confirmedOutcome: outcome,
    );
  }

  // ===========================================================================
  // ESTADO
  // ===========================================================================

  bool get isPending {
    return type == ExternalActionTransferType.pendingOutcome;
  }

  bool get isConfirmed {
    return type == ExternalActionTransferType.confirmedOutcome;
  }

  // ===========================================================================
  // MAP
  // ===========================================================================

  Map<String, dynamic> toMap() {
    final payload = switch (type) {
      ExternalActionTransferType.pendingOutcome => pendingOutcome?.toMap(),

      ExternalActionTransferType.confirmedOutcome => confirmedOutcome?.toMap(),
    };

    if (payload == null) {
      throw StateError('La transferencia no contiene payload.');
    }

    return {
      'version': version,
      'transferId': transferId,
      'type': type.name,
      'payload': payload,
    };
  }

  factory ExternalActionTransfer.fromMap(Map<dynamic, dynamic> map) {
    final version = (map['version'] as num?)?.toInt() ?? 0;

    if (version <= 0) {
      throw StateError('Versión de transferencia inválida.');
    }

    if (version > currentVersion) {
      throw StateError(
        'Esta transferencia pertenece a una versión más nueva de Asteria.',
      );
    }

    final transferId = map['transferId']?.toString().trim() ?? '';

    if (transferId.isEmpty) {
      throw StateError('La transferencia no contiene transferId.');
    }

    final rawType = map['type']?.toString();

    final type = ExternalActionTransferType.values.firstWhere(
      (value) => value.name == rawType,
      orElse: () {
        throw StateError('Tipo de transferencia externo desconocido.');
      },
    );

    final rawPayload = map['payload'];

    if (rawPayload is! Map) {
      throw StateError('La transferencia no contiene un payload válido.');
    }

    final payload = Map<dynamic, dynamic>.from(rawPayload);

    switch (type) {
      case ExternalActionTransferType.pendingOutcome:
        return ExternalActionTransfer._(
          version: version,
          transferId: transferId,
          type: type,
          pendingOutcome: ExternalTargetOutcome.fromMap(payload),
        );

      case ExternalActionTransferType.confirmedOutcome:
        return ExternalActionTransfer._(
          version: version,
          transferId: transferId,
          type: type,
          confirmedOutcome: ExternalActionOutcome.fromMap(payload),
        );
    }
  }

  // ===========================================================================
  // JSON
  // ===========================================================================

  String toJson() {
    return jsonEncode(toMap());
  }

  factory ExternalActionTransfer.fromJson(String source) {
    final decoded = jsonDecode(source);

    if (decoded is! Map) {
      throw StateError(
        'El texto no contiene una transferencia válida de Asteria.',
      );
    }

    return ExternalActionTransfer.fromMap(Map<dynamic, dynamic>.from(decoded));
  }

  // ===========================================================================
  // ID
  // ===========================================================================

  static String _newTransferId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    final random = Random.secure().nextInt(0x7fffffff);

    return 'asteria_${timestamp}_$random';
  }
}
