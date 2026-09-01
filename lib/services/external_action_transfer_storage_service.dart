import 'package:hive_flutter/hive_flutter.dart';

import '../models/external_action_confirmation_context.dart';

class ExternalActionTransferStorageService {
  static const String _boxName = 'external_action_transfers';

  static const String _receivedPrefix = 'received_';

  static const String _confirmedPrefix = 'confirmed_';

  static const String _contextPrefix = 'context_';

  static Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }

    return Hive.openBox(_boxName);
  }

  // ===========================================================================
  // PENDING RECIBIDO/APLICADO
  //
  // Lo usa la Asteria objetivo.
  // ===========================================================================

  static Future<bool> hasReceived(String transferId) async {
    final box = await _openBox();

    return box.containsKey('$_receivedPrefix$transferId');
  }

  static Future<void> markReceived(String transferId) async {
    final box = await _openBox();

    await box.put(
      '$_receivedPrefix$transferId',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ===========================================================================
  // CONTEXTO DE CONFIRMACIÓN
  // ===========================================================================

  static Future<void> saveConfirmationContext(
    ExternalActionConfirmationContext context,
  ) async {
    final box = await _openBox();

    await box.put('$_contextPrefix${context.transferId}', context.toMap());
  }

  static Future<ExternalActionConfirmationContext?> getConfirmationContext(
    String transferId,
  ) async {
    final box = await _openBox();

    final raw = box.get('$_contextPrefix$transferId');

    if (raw is! Map) {
      return null;
    }

    try {
      return ExternalActionConfirmationContext.fromMap(
        Map<dynamic, dynamic>.from(raw),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeConfirmationContext(String transferId) async {
    final box = await _openBox();

    await box.delete('$_contextPrefix$transferId');
  }

  // ===========================================================================
  // CONFIRMACIÓN PROCESADA
  //
  // Lo usa la Asteria origen.
  // ===========================================================================

  static Future<bool> hasConfirmed(String transferId) async {
    final box = await _openBox();

    return box.containsKey('$_confirmedPrefix$transferId');
  }

  static Future<void> markConfirmed(String transferId) async {
    final box = await _openBox();

    await box.put(
      '$_confirmedPrefix$transferId',
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
