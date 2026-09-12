import '../../../models/passive.dart';

extension PassiveTriggerEventUi on PassiveTriggerEvent {
  String get label {
    switch (this) {
      case PassiveTriggerEvent.healthChanged:
        return 'Al cambiar la vida';

      case PassiveTriggerEvent.resourceChanged:
        return 'Al cambiar un recurso';

      case PassiveTriggerEvent.chargeChanged:
        return 'Al cambiar una carga';

      case PassiveTriggerEvent.counterChanged:
        return 'Al cambiar un contador';

      case PassiveTriggerEvent.damageReceived:
        return 'Al recibir daño';

      case PassiveTriggerEvent.damageDealt:
        return 'Al causar daño';

      case PassiveTriggerEvent.healingReceived:
        return 'Al recibir curación';

      case PassiveTriggerEvent.healingDealt:
        return 'Al realizar una curación';

      case PassiveTriggerEvent.effectApplied:
        return 'Al aplicar un efecto';

      case PassiveTriggerEvent.effectReceived:
        return 'Al recibir un efecto';

      case PassiveTriggerEvent.attackHit:
        return 'Al impactar un ataque';

      case PassiveTriggerEvent.attackMiss:
        return 'Al fallar un ataque';

      case PassiveTriggerEvent.criticalHit:
        return 'Al realizar un crítico';

      case PassiveTriggerEvent.characterDied:
        return 'Al morir';

      case PassiveTriggerEvent.enemyKilled:
        return 'Al matar un enemigo';

      case PassiveTriggerEvent.turnStarted:
        return 'Al empezar turno';

      case PassiveTriggerEvent.turnEnded:
        return 'Al terminar turno';

      case PassiveTriggerEvent.roundStarted:
        return 'Al empezar una ronda';

      case PassiveTriggerEvent.roundEnded:
        return 'Al terminar una ronda';

      case PassiveTriggerEvent.manual:
        return 'Activación manual';

      case PassiveTriggerEvent.custom:
        return 'Evento personalizado';
    }
  }
}

extension PassiveTriggerActionUi on PassiveTriggerActionType {
  String get label {
    switch (this) {
      case PassiveTriggerActionType.addResource:
        return 'Añadir recurso';

      case PassiveTriggerActionType.subtractResource:
        return 'Gastar recurso';

      case PassiveTriggerActionType.setResource:
        return 'Establecer recurso';

      case PassiveTriggerActionType.addCharge:
        return 'Añadir carga';

      case PassiveTriggerActionType.subtractCharge:
        return 'Gastar carga';

      case PassiveTriggerActionType.applyEffect:
        return 'Aplicar efecto';

      case PassiveTriggerActionType.removeEffect:
        return 'Eliminar efecto';

      case PassiveTriggerActionType.dealDamage:
        return 'Causar daño';

      case PassiveTriggerActionType.heal:
        return 'Curar';

      case PassiveTriggerActionType.mitigateDamage:
        return 'Mitigar daño';

      case PassiveTriggerActionType.incrementCounter:
        return 'Incrementar contador';

      case PassiveTriggerActionType.setCounter:
        return 'Establecer contador';
    }
  }
}

extension PassiveTriggerModeUi on PassiveTriggerMode {
  String get label {
    switch (this) {
      case PassiveTriggerMode.once:
        return 'Ejecutar una vez';

      case PassiveTriggerMode.whileCondition:
        return 'Mientras se cumpla';
    }
  }

  String get description {
    switch (this) {
      case PassiveTriggerMode.once:
        return 'La acción se ejecuta cuando ocurre '
            'el evento y se cumple la condición.';

      case PassiveTriggerMode.whileCondition:
        return 'La condición se reevalúa para '
            'mantener el estado persistente.';
    }
  }
}
