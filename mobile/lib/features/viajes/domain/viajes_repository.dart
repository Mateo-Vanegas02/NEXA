import '../../../core/sin_conexion/reglas_sin_conexion.dart';
import 'perfil_pasajero.dart';
import 'oferta_activa.dart';
import 'servicio.dart';

abstract interface class PasajeroRepository {
  Future<PerfilPasajero> perfil();

  /// Precio del viaje según el servidor (valida la zona de servicio).
  Future<Cotizacion> cotizar(Coordenada origen, Coordenada destino);
  Future<Servicio> solicitar(SolicitudViaje solicitud);
  Future<Servicio> cancelar(String id);

  /// Suma [incremento] COP de extra voluntario mientras el viaje espera conductor.
  Future<void> subirExtra(String id, int incremento);

  /// Posición del conductor del viaje, o `null` si aún no reportó una.
  Future<PosicionViaje?> posicionConductor(String id);

  /// El pasajero reporta dónde está mientras su conductor va en camino.
  Future<void> reportarUbicacion(String id, Coordenada posicion);
  Future<List<Servicio>> historial();

  /// Id de la solicitud que espera conductor o del viaje aceptado/en curso
  /// del pasajero (para retomarlo al abrir la app), o `null`.
  Future<String?> viajeAbiertoId();

  /// Ola del despacho y tope del extra de la solicitud que espera conductor;
  /// null si ya no hay una.
  Future<OfertaActiva?> ofertaActiva();
  Future<Servicio> detalle(String id);
  /// [factores]: códigos de `FactoresCalificacion` (se guardan aparte del
  /// comentario).
  Future<Servicio> calificar(
    String id,
    double calificacion,
    String comentarios, {
    List<String> factores = const [],
  });
  Future<DesglosePasajero> desglose(String id);
}

abstract interface class ConductorRepository {
  Future<List<Servicio>> disponibles({double? lat, double? lng});

  /// El conductor en línea reporta dónde está. Con un viaje aceptado o en curso
  /// el servidor responde con la fase, distancia y ETA; si no, devuelve `null`.
  Future<PosicionViaje?> reportarUbicacion(
    Coordenada posicion, {
    required bool disponible,
  });

  /// Viaje aceptado o en curso del conductor (para retomarlo), o `null`.
  Future<Servicio?> viajeActivo();

  /// Dónde está el pasajero mientras el conductor va a recogerlo, o `null`.
  Future<PosicionPasajero?> ubicacionPasajero(String id);

  /// "Llegué": el servidor verifica que esté a ≤ 50 m de la recogida (409 si no).
  /// [llave] (idempotencia) y [ocurridoEn] sirven para enviarlo tras un corte
  /// de señal sin repetirlo y con la hora en que se tocó el botón.
  Future<Servicio> llegue(
    String id,
    Coordenada posicion, {
    String? llave,
    DateTime? ocurridoEn,
  });

  /// Posiciones guardadas sin señal, con su hora (`POST /conductor/ubicacion/lote`).
  Future<void> reportarLote(List<PuntoGuardado> puntos);

  Future<SaldoConductor> saldo({int dias = 30});

  Future<Servicio> aceptar(String id);
  Future<Servicio> iniciar(String id, {String? llave, DateTime? ocurridoEn});
  Future<Servicio> finalizar(String id, {String? llave, DateTime? ocurridoEn});
  Future<Servicio> cancelar(String id);
  Future<List<Servicio>> enCurso();
  Future<List<Servicio>> historial();
  Future<List<Ingreso>> ingresos({String? periodo});
  Future<DesgloseConductor> desglose(String id);

  /// El conductor califica al pasajero (estrellas, comentario y códigos de
  /// `FactoresCalificacion.delConductor`).
  Future<void> calificar(
    String id,
    double calificacion,
    String comentarios, {
    List<String> factores = const [],
  });
}
