import 'perfil_pasajero.dart';
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
  Future<Servicio> detalle(String id);
  Future<Servicio> calificar(
    String id,
    double calificacion,
    String comentarios,
  );
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
  Future<Servicio> llegue(String id, Coordenada posicion);

  Future<SaldoConductor> saldo({int dias = 30});

  Future<Servicio> aceptar(String id);
  Future<Servicio> iniciar(String id);
  Future<Servicio> finalizar(String id);
  Future<Servicio> cancelar(String id);
  Future<List<Servicio>> enCurso();
  Future<List<Servicio>> historial();
  Future<List<Ingreso>> ingresos({String? periodo});
  Future<DesgloseConductor> desglose(String id);
}
