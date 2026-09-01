import '../models/action_apply_result.dart';
import '../models/character.dart';
import '../models/external_action_transfer.dart';

import 'character_storage_service.dart';
import 'external_action_applier.dart';
import 'external_action_transfer_storage_service.dart';

class ExternalActionTransferReceiverService {
  final Character character;

  const ExternalActionTransferReceiverService({required this.character});

  // ===========================================================================
  // RECIBIR
  // ===========================================================================

  Future<ExternalActionTransfer> receive(
    ExternalActionTransfer transfer,
  ) async {
    // =========================================================================
    // VALIDAR TRANSFERENCIA
    // =========================================================================

    final pending = _validatePendingTransfer(transfer);

    // =========================================================================
    // EVITAR DOBLE APLICACIÓN
    // =========================================================================

    final alreadyReceived =
        await ExternalActionTransferStorageService.hasReceived(
          transfer.transferId,
        );

    if (alreadyReceived) {
      throw StateError('Este resultado externo ya fue aplicado anteriormente.');
    }

    // =========================================================================
    // APLICAR SOBRE EL PERSONAJE LOCAL
    // =========================================================================

    final applier = ExternalActionApplier(character: character);

    final appliedOutcome = applier.apply(pending);

    // =========================================================================
    // PERSISTIR PERSONAJE
    // =========================================================================

    await CharacterStorageService.saveCharacter(character);

    // =========================================================================
    // MARCAR TRANSFER COMO CONSUMIDO
    // =========================================================================

    await ExternalActionTransferStorageService.markReceived(
      transfer.transferId,
    );

    // =========================================================================
    // CREAR CONFIRMACIÓN
    //
    // Conserva el mismo transferId.
    // =========================================================================

    return ExternalActionTransfer.confirmed(
      transferId: transfer.transferId,
      outcome: appliedOutcome,
    );
  }

  // ===========================================================================
  // VALIDACIÓN
  // ===========================================================================

  ExternalTargetOutcome _validatePendingTransfer(
    ExternalActionTransfer transfer,
  ) {
    // -------------------------------------------------------------------------
    // ID
    // -------------------------------------------------------------------------

    if (transfer.transferId.trim().isEmpty) {
      throw StateError('La transferencia no contiene un ID válido.');
    }

    // -------------------------------------------------------------------------
    // TIPO
    // -------------------------------------------------------------------------

    if (!transfer.isPending) {
      throw StateError(
        'La transferencia recibida no contiene un resultado pendiente.',
      );
    }

    final pending = transfer.pendingOutcome;

    if (pending == null) {
      throw StateError('La transferencia pendiente no contiene resultado.');
    }

    // -------------------------------------------------------------------------
    // TARGET
    // -------------------------------------------------------------------------

    if (pending.targetId.trim().isEmpty) {
      throw StateError('El resultado externo no contiene un objetivo válido.');
    }

    // -------------------------------------------------------------------------
    // CANTIDADES
    // -------------------------------------------------------------------------

    if (pending.damage < 0) {
      throw StateError('El daño externo no puede ser negativo.');
    }

    if (pending.healing < 0) {
      throw StateError('La curación externa no puede ser negativa.');
    }

    // -------------------------------------------------------------------------
    // CONTENIDO VACÍO
    // -------------------------------------------------------------------------

    if (!pending.hasPendingApplication) {
      throw StateError('El resultado externo no contiene nada que aplicar.');
    }

    // -------------------------------------------------------------------------
    // EFECTOS
    // -------------------------------------------------------------------------

    final effectIds = <String>{};

    for (final effectResult in pending.effects) {
      final effect = effectResult.template;

      final effectId = effect.id.trim();

      if (effectId.isEmpty) {
        throw StateError('La transferencia contiene un efecto sin ID.');
      }

      if (!effectIds.add(effectId)) {
        throw StateError(
          'La transferencia contiene el efecto '
          '"$effectId" más de una vez.',
        );
      }
    }

    return pending;
  }

  // ===========================================================================
  // ESTADO
  // ===========================================================================

  Future<bool> wasAlreadyReceived(String transferId) {
    return ExternalActionTransferStorageService.hasReceived(transferId);
  }
}
