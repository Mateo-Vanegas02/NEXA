/// Cuándo y con qué ritmo la app sigue usando el GPS con la pantalla apagada.
///
/// Solo hay trabajo en segundo plano cuando el negocio lo necesita (plan de
/// segundo plano, fase 3): el conductor en línea o en un viaje y el pasajero
/// mientras busca conductor o su conductor va por él. Fuera de eso el servicio
/// está apagado.
enum ModoSegundoPlano {
  apagado,

  /// Conductor en línea sin viaje: posición para no perder su ola.
  enLinea,

  /// Conductor con un viaje aceptado o en curso.
  enViaje,

  /// Pasajero esperando que un conductor acepte (máx. 10 min: luego la
  /// solicitud vence). Mantiene viva la app con la pantalla apagada para
  /// enterarse al instante y muestra «Buscando conductor».
  pasajeroBuscando,

  /// Pasajero con el conductor en camino (hasta que inicia el viaje).
  pasajeroEnCamino,
}

/// Parámetros del GPS para cada modo.
class AjustesRastreo {
  const AjustesRastreo({
    required this.intervalo,
    required this.distanciaMetros,
    required this.altaPrecision,
  });

  /// Cada cuánto el sistema entrega una posición.
  final Duration intervalo;

  /// Movimiento mínimo para entregar una posición nueva.
  final int distanciaMetros;

  /// Alta precisión solo cuando hay un viaje (gasta más batería).
  final bool altaPrecision;
}

abstract final class ReglasSegundoPlano {
  static ModoSegundoPlano conductor({
    required bool enLinea,
    required bool conViaje,
  }) {
    if (conViaje) return ModoSegundoPlano.enViaje;
    return enLinea ? ModoSegundoPlano.enLinea : ModoSegundoPlano.apagado;
  }

  /// El pasajero solo comparte su posición mientras el conductor va por él.
  static ModoSegundoPlano pasajero({
    required bool conductorEnCamino,
    bool buscando = false,
  }) {
    if (conductorEnCamino) return ModoSegundoPlano.pasajeroEnCamino;
    return buscando
        ? ModoSegundoPlano.pasajeroBuscando
        : ModoSegundoPlano.apagado;
  }

  static AjustesRastreo? ajustes(ModoSegundoPlano modo) => switch (modo) {
    ModoSegundoPlano.apagado => null,
    // El servidor olvida la posición a los 45 s: 15 s la mantiene vigente.
    ModoSegundoPlano.enLinea => const AjustesRastreo(
      intervalo: Duration(seconds: 15),
      distanciaMetros: 30,
      altaPrecision: false,
    ),
    // Rediseño 2026: cada segundo o 3 m, para que la moto se deslice en el
    // mapa en vez de saltar (antes 3 s / 10 m).
    ModoSegundoPlano.enViaje => const AjustesRastreo(
      intervalo: Duration(seconds: 1),
      distanciaMetros: 3,
      altaPrecision: true,
    ),
    // Solo mantiene viva la app: el GPS va en su ritmo más económico.
    ModoSegundoPlano.pasajeroBuscando => const AjustesRastreo(
      intervalo: Duration(seconds: 30),
      distanciaMetros: 50,
      altaPrecision: false,
    ),
    // El conductor ve al pasajero moverse mientras camina a la esquina.
    ModoSegundoPlano.pasajeroEnCamino => const AjustesRastreo(
      intervalo: Duration(seconds: 2),
      distanciaMetros: 5,
      altaPrecision: true,
    ),
  };

  /// Una posición del rastreador sirve si es reciente; si no, se pide una
  /// nueva al GPS.
  static bool vigente(DateTime? tomada, DateTime ahora) =>
      tomada != null && ahora.difference(tomada) <= const Duration(seconds: 20);

  /// Con la app en segundo plano y sin viaje, el conductor reporta cada tres
  /// ciclos de sondeo (15 s en vez de 5 s) para ahorrar batería y datos.
  static bool saltarCiclo({
    required bool primerPlano,
    required bool conViaje,
    required int ciclo,
  }) => !primerPlano && !conViaje && ciclo % 3 != 0;

  /// Cambiar de modo reinicia el servicio en primer plano; Android 14 no deja
  /// iniciarlo de ubicación desde segundo plano, así que con la app oculta
  /// solo se permite apagarlo. El cambio pendiente se aplica al volver (p. ej.
  /// si el conductor acepta con la app oculta, sigue el servicio de «buscando»
  /// y solo cambia el texto de la notificación a «Carlos va por ti»).
  static bool puedeCambiar({
    required ModoSegundoPlano actual,
    required ModoSegundoPlano nuevo,
    required bool primerPlano,
  }) => primerPlano || nuevo == ModoSegundoPlano.apagado;
}
