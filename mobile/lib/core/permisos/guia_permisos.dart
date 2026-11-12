import '../../features/auth/domain/auth.dart';
import '../network/token_storage.dart';
import '../notificaciones/notificaciones_locales.dart';
import 'permisos_dispositivo.dart';

/// Pantallas de permisos (diseño Figma, sección «Permisos, avisos…»).
enum PasoPermiso {
  /// N01: notificaciones, tras iniciar sesión.
  notificaciones('/permisos/notificaciones'),

  /// N02: ubicación «al usar la app».
  ubicacion('/permisos/ubicacion'),

  /// N03: ubicación en segundo plano, solo el conductor.
  segundoPlano('/c/permisos/segundo-plano'),

  /// E01: sin permiso de ubicación (negado para siempre o rechazado).
  sinUbicacion('/permisos/sin-ubicacion');

  const PasoPermiso(this.ruta);
  final String ruta;
}

/// Lo que se sabe del teléfono en un momento dado. [ubicacion] es null si no
/// se pudo leer (sin plugin, en pruebas): entonces no se muestra nada.
class EstadoPermisos {
  const EstadoPermisos({
    required this.notificacionesDisponibles,
    required this.notificacionesPermitidas,
    required this.ubicacion,
    required this.vistos,
  });

  final bool notificacionesDisponibles;
  final bool notificacionesPermitidas;
  final EstadoUbicacion? ubicacion;

  /// Pantallas que el usuario ya vio (no se repiten aunque haya dicho «Ahora
  /// no»; se vuelven a ofrecer solo cuando hacen falta para una acción).
  final Set<PasoPermiso> vistos;
}

/// Reglas puras: qué pantalla toca en cada momento. Cada permiso se pide
/// cuando se entiende para qué sirve, nunca todos al abrir la app.
abstract final class ReglasPermisos {
  /// Al llegar al inicio después de iniciar sesión.
  static PasoPermiso? alEntrar(Rol rol, EstadoPermisos e) {
    if (e.notificacionesDisponibles &&
        !e.notificacionesPermitidas &&
        !e.vistos.contains(PasoPermiso.notificaciones)) {
      return PasoPermiso.notificaciones;
    }
    // El pasajero la necesita para pedir viaje; el conductor, al conectarse.
    if (rol == Rol.pasajero &&
        e.ubicacion == EstadoUbicacion.sinPermiso &&
        !e.vistos.contains(PasoPermiso.ubicacion)) {
      return PasoPermiso.ubicacion;
    }
    return null;
  }

  /// Antes de una acción que exige ubicación (pedir viaje, ponerse en línea).
  /// Siempre se ofrece aunque ya la haya visto: sin ubicación no se puede.
  static PasoPermiso? paraUsarUbicacion(EstadoUbicacion? ubicacion) =>
      switch (ubicacion) {
        EstadoUbicacion.sinPermiso => PasoPermiso.ubicacion,
        EstadoUbicacion.denegadaSiempre => PasoPermiso.sinUbicacion,
        _ => null,
      };

  /// Al ponerse en línea con la ubicación ya concedida: la primera vez se
  /// explica el segundo plano. Puede conducir sin él.
  static PasoPermiso? segundoPlano(EstadoPermisos e) =>
      e.ubicacion == EstadoUbicacion.alUsar &&
          !e.vistos.contains(PasoPermiso.segundoPlano)
      ? PasoPermiso.segundoPlano
      : null;
}

/// Lee el estado del teléfono y recuerda qué pantallas ya se vieron.
class GuiaPermisos {
  GuiaPermisos({
    required this.permisos,
    required this.notificaciones,
    required this.store,
  });

  final PermisosDispositivo permisos;
  final NotificacionesLocales notificaciones;
  final SecureStore store;

  static String _clave(PasoPermiso p) => 'permiso_visto_${p.name}';

  Future<EstadoPermisos> estado() async {
    EstadoUbicacion? ubicacion;
    try {
      ubicacion = await permisos.ubicacion();
    } on Object {
      ubicacion = null;
    }
    var permitidas = false;
    try {
      permitidas = await notificaciones.permitidas();
    } on Object {
      permitidas = false;
    }
    final vistos = <PasoPermiso>{};
    for (final p in PasoPermiso.values) {
      if (await store.read(_clave(p)) == '1') vistos.add(p);
    }
    return EstadoPermisos(
      notificacionesDisponibles: notificaciones.disponible,
      notificacionesPermitidas: permitidas,
      ubicacion: ubicacion,
      vistos: vistos,
    );
  }

  Future<void> marcarVisto(PasoPermiso paso) => store.write(_clave(paso), '1');
}
