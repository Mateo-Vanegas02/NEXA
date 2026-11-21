import 'dart:async' show TimeoutException;
import 'dart:io' show Platform;

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permiso de ubicación del teléfono, en los términos que usa NEXA.
enum EstadoUbicacion {
  /// Nunca se pidió o se negó una vez: el sistema todavía muestra su cuadro.
  sinPermiso,

  /// Se negó para siempre: solo se cambia en los ajustes del teléfono.
  denegadaSiempre,

  /// «Mientras se usa la app».
  alUsar,

  /// «Todo el tiempo» (segundo plano; solo lo pide el conductor).
  siempre,
}

extension EstadoUbicacionX on EstadoUbicacion {
  bool get concedida =>
      this == EstadoUbicacion.alUsar || this == EstadoUbicacion.siempre;
}

/// Permisos del teléfono detrás de una interfaz, para probar las pantallas sin
/// el plugin. Ningún método pide nada por su cuenta al abrir la app: cada uno
/// se llama desde su pantalla (N02, N03, E01).
abstract class PermisosDispositivo {
  Future<EstadoUbicacion> ubicacion();

  /// Cuadro del sistema «al usar la app».
  Future<EstadoUbicacion> pedirUbicacion();

  /// «Todo el tiempo». En Android 11+ el sistema abre la página de ajustes de
  /// la app, donde el usuario elige «Permitir todo el tiempo».
  Future<EstadoUbicacion> pedirSegundoPlano();

  Future<void> abrirAjustesApp();
}

class PermisosGeolocator implements PermisosDispositivo {
  const PermisosGeolocator();

  static EstadoUbicacion _traducir(LocationPermission p) => switch (p) {
    LocationPermission.always => EstadoUbicacion.siempre,
    LocationPermission.whileInUse => EstadoUbicacion.alUsar,
    LocationPermission.deniedForever => EstadoUbicacion.denegadaSiempre,
    LocationPermission.denied ||
    LocationPermission.unableToDetermine => EstadoUbicacion.sinPermiso,
  };

  @override
  Future<EstadoUbicacion> ubicacion() async =>
      _traducir(await Geolocator.checkPermission());

  @override
  Future<EstadoUbicacion> pedirUbicacion() async =>
      _traducir(await Geolocator.requestPermission());

  @override
  Future<EstadoUbicacion> pedirSegundoPlano() async {
    final actual = await ubicacion();
    if (actual != EstadoUbicacion.alUsar) return actual;
    if (Platform.isAndroid) {
      // No se usa Geolocator.requestPermission(): pide FINE + COARSE +
      // BACKGROUND en la misma solicitud, y desde Android 11 el sistema ignora
      // las solicitudes que mezclan primer y segundo plano (no sale nada y el
      // Future puede no terminar nunca). Aquí se pide SOLO
      // ACCESS_BACKGROUND_LOCATION: Android abre la página de ubicación de la
      // app con la opción «Permitir todo el tiempo».
      try {
        await Permission.locationAlways.request().timeout(
          const Duration(minutes: 2),
        );
      } on TimeoutException {
        // Se vuelve a leer el estado abajo.
      }
      return ubicacion();
    }
    return _traducir(await Geolocator.requestPermission());
  }

  @override
  Future<void> abrirAjustesApp() async {
    await Geolocator.openAppSettings();
  }
}

/// Permisos fijos para pruebas y para el modo demostración.
class PermisosFijos implements PermisosDispositivo {
  PermisosFijos(this.estado, {this.alPedir, this.alPedirSegundoPlano});

  EstadoUbicacion estado;

  /// Lo que «responde» el usuario al cuadro del sistema.
  final EstadoUbicacion? alPedir;
  final EstadoUbicacion? alPedirSegundoPlano;
  int ajustesAbiertos = 0;

  @override
  Future<EstadoUbicacion> ubicacion() async => estado;

  @override
  Future<EstadoUbicacion> pedirUbicacion() async => estado = alPedir ?? estado;

  @override
  Future<EstadoUbicacion> pedirSegundoPlano() async =>
      estado = alPedirSegundoPlano ?? estado;

  @override
  Future<void> abrirAjustesApp() async => ajustesAbiertos++;
}
