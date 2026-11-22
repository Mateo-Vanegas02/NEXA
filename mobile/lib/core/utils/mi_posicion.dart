import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../providers.dart';
import '../segundo_plano/modo_segundo_plano.dart';
import '../segundo_plano/rastreador_ubicacion.dart';

/// Posición GPS actual del usuario, o `null` si no hay permiso, el GPS está
/// apagado o tarda demasiado. No pide permisos (eso lo hacen las pantallas de
/// permisos). Si el rastreador de segundo plano tiene una posición reciente, la
/// usa (funciona con la pantalla apagada). Sobrescribible en tests.
final miPosicionProvider = Provider<Future<LatLng?> Function()>(
  (ref) => () async {
    final rastreador = ref.read(rastreadorProvider);
    final reciente = rastreador.ultima;
    if (reciente != null &&
        ReglasSegundoPlano.vigente(rastreador.ultimaEn, DateTime.now())) {
      return reciente;
    }
    try {
      final permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return null;
      }
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 5),
        ),
      );
      return LatLng(p.latitude, p.longitude);
    } on Object {
      return null;
    }
  },
);

/// Cada dato del GPS apenas llega (solo mientras el rastreador corre: en línea,
/// con viaje o con el conductor en camino). El mapa del conductor dibuja su
/// moto con esto, a 1 dato por segundo, sin esperar al servidor.
final posicionEnVivoProvider = StreamProvider<PosicionEnVivo>(
  (ref) => ref.watch(rastreadorProvider).posiciones,
);
