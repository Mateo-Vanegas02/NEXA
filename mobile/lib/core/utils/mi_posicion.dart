import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Posición GPS actual del usuario, o `null` si no hay permiso, el GPS está
/// apagado o tarda demasiado. No pide permisos (eso lo hace `ubicacionProvider`
/// al abrir el mapa). Sobrescribible en tests.
final miPosicionProvider = Provider<Future<LatLng?> Function()>(
  (ref) => () async {
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
