import 'dart:math';

import '../errors/app_exception.dart';

/// Acciones del conductor que se pueden hacer sin señal y se envían después.
/// Las que dependen de otros en ese momento (pedir, aceptar, subir el extra,
/// cancelar) no se encolan: se bloquean con aviso.
enum TipoPendiente { llegue, iniciar, finalizar }

/// Una acción hecha sin señal, en la cola del teléfono.
class AccionPendiente {
  const AccionPendiente({
    required this.llave,
    required this.tipo,
    required this.servicioId,
    required this.ocurridoEn,
    this.latitud,
    this.longitud,
    this.intentos = 0,
  });

  /// Llave de idempotencia: el servidor no repite la acción si llega dos veces.
  final String llave;
  final TipoPendiente tipo;
  final String servicioId;

  /// Cuándo tocó el botón (el servidor la acepta dentro de su tolerancia).
  final DateTime ocurridoEn;

  /// Posición del «Llegué» (el servidor la verifica igual que en línea).
  final double? latitud;
  final double? longitud;
  final int intentos;
}

/// Posición del conductor guardada sin señal.
class PuntoGuardado {
  const PuntoGuardado({
    required this.latitud,
    required this.longitud,
    required this.tomadoEn,
    this.id,
  });

  final int? id;
  final double latitud;
  final double longitud;
  final DateTime tomadoEn;

  Map<String, Object> toJson() => {
    'latitud': latitud,
    'longitud': longitud,
    'ocurridoEn': tomadoEn.toUtc().toIso8601String(),
  };
}

/// Qué hacer con una acción de la cola según la respuesta del servidor.
enum ResultadoEnvio {
  /// Hecha (o ya estaba hecha): sale de la cola.
  enviada,

  /// El servidor dice que ya no aplica (409, 400, 403, 404…): sale de la cola
  /// y se avisa; gana el servidor.
  rechazada,

  /// Sin señal, error del servidor o aún en proceso: se reintenta más tarde.
  reintentar,
}

/// Reglas puras del modo sin conexión (sin base de datos ni red).
abstract final class ReglasSinConexion {
  /// Puntos de GPS que se guardan como máximo (los más viejos se descartan).
  static const maxPuntos = 1000;

  /// Puntos por envío (el servidor acepta hasta 500).
  static const puntosPorLote = 500;

  /// Llave de idempotencia nueva: 24 caracteres hexadecimales al azar.
  static String nuevaLlave([Random? azar]) {
    final r = azar ?? Random.secure();
    return List.generate(24, (_) => r.nextInt(16).toRadixString(16)).join();
  }

  /// ¿El error fue por falta de señal (no hubo respuesta del servidor)?
  static bool esFaltaDeRed(Object error) =>
      AppException.from(error).kind == ErrorKind.red;

  static ResultadoEnvio resultado(Object? error) {
    if (error == null) return ResultadoEnvio.enviada;
    final e = AppException.from(error);
    if (e.kind == ErrorKind.red) return ResultadoEnvio.reintentar;
    final codigo = e.statusCode;
    if (codigo == null || codigo >= 500) return ResultadoEnvio.reintentar;
    // 409 «ya se está procesando» (otro reintento a la vez): esperar.
    if (codigo == 409 && e.mensaje.contains('procesando')) {
      return ResultadoEnvio.reintentar;
    }
    // 401 cierra la sesión por su cuenta; lo demás es «ya no aplica».
    return codigo == 401 ? ResultadoEnvio.reintentar : ResultadoEnvio.rechazada;
  }

  /// Parte la lista en envíos de [tam].
  static List<List<T>> lotes<T>(List<T> puntos, [int tam = puntosPorLote]) => [
    for (var i = 0; i < puntos.length; i += tam)
      puntos.sublist(i, min(i + tam, puntos.length)),
  ];
}
