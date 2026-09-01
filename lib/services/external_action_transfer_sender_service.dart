import '../models/action_apply_result.dart';
import '../models/action_resolution_result.dart';
import '../models/action_target_result.dart';
import '../models/external_action_confirmation_context.dart';
import '../models/external_action_transfer.dart';

import 'external_action_transfer_storage_service.dart';

class ExternalActionTransferSenderService {
  const ExternalActionTransferSenderService();

  Future<ExternalActionTransfer> createPending({
    required ActionResolutionResult resolution,
    required ExternalTargetOutcome outcome,
  }) async {
    // =========================================================================
    // CREAR TRANSFERENCIA
    // =========================================================================

    final transfer = ExternalActionTransfer.pending(outcome);

    // =========================================================================
    // BUSCAR EL RESULTADO RESUELTO DEL OBJETIVO
    // =========================================================================

    ActionTargetResult? resolvedTarget;

    for (final candidate in resolution.externalTargetResults) {
      if (candidate.target.id == outcome.targetId) {
        resolvedTarget = candidate;
        break;
      }
    }

    if (resolvedTarget == null) {
      throw StateError(
        'No existe el objetivo externo ${outcome.targetId} en la resolución.',
      );
    }

    // =========================================================================
    // CREAR CONTEXTO PARA LA FUTURA CONFIRMACIÓN
    // =========================================================================

    final context = ExternalActionConfirmationContext(
      transferId: transfer.transferId,

      targetId: resolvedTarget.target.id,

      targetLabel: resolvedTarget.target.label ?? '',

      eventVariables: resolution.eventVariablesForTarget(resolvedTarget.target),

      resolvedDamage: resolvedTarget.damage,

      resolvedHealing: resolvedTarget.healing,

      resolvedEffectCount: resolvedTarget.effects.length,
    );

    // =========================================================================
    // GUARDAR CONTEXTO
    //
    // Esto permite cerrar Asteria y recibir la confirmación mucho después.
    // =========================================================================

    await ExternalActionTransferStorageService.saveConfirmationContext(context);

    return transfer;
  }
}
