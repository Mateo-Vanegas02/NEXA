import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../rumbo/reglas_rumbo.dart';
import 'modo_segundo_plano.dart';

/// Texto de la notificación fija mientras se usa el GPS en segundo plano
/// (Android la exige para el servicio en primer plano).
class AvisoRastreo {
  const AvisoRastreo({
    required this.titulo,
    required this.texto,
    required this.canal,
  });
  final String titulo;
  final String texto;
  final String canal;
}

/// Sigue la posición del teléfono con el ritmo de cada modo y la deja a mano
/// ([ultima]). En Android corre como servicio en primer plano de tipo
/// ubicación, con su notificación fija: así sigue con la pantalla apagada.
abstract class RastreadorUbicacion {
  Future<void> iniciar(ModoSegundoPlano modo, AvisoRastreo aviso);
  Future<void> detener();
  LatLng? get ultima;
  DateTime? get ultimaEn;

  /// Rumbo y velocidad del último dato (para girar el mapa en marcha).
  MovimientoGps? get movimiento;
}

class RastreadorGeolocator implements RastreadorUbicacion {
  StreamSubscription<Position>? _sub;
  LatLng? _ultima;
  DateTime? _ultimaEn;
  MovimientoGps? _movimiento;

  @override
  MovimientoGps? get movimiento => _movimiento;

  @override
  LatLng? get ultima => _ultima;

  @override
  DateTime? get ultimaEn => _ultimaEn;

  @override
  Future<void> iniciar(ModoSegundoPlano modo, AvisoRastreo aviso) async {
    await detener();
    final ajustes = ReglasSegundoPlano.ajustes(modo);
    if (ajustes == null || kIsWeb || !Platform.isAndroid) return;
    final settings = AndroidSettings(
      accuracy: ajustes.altaPrecision
          ? LocationAccuracy.high
          : LocationAccuracy.medium,
      distanceFilter: ajustes.distanciaMetros,
      intervalDuration: ajustes.intervalo,
      foregroundNotificationConfig: ForegroundNotificationConfig(
        notificationTitle: aviso.titulo,
        notificationText: aviso.texto,
        notificationChannelName: aviso.canal,
        enableWakeLock: true,
        setOngoing: true,
      ),
    );
    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (p) {
        _ultima = LatLng(p.latitude, p.longitude);
        _ultimaEn = DateTime.now();
        _movimiento = MovimientoGps(
          rumbo: p.heading,
          velocidad: p.speed,
          precisionRumbo: p.headingAccuracy,
          en: _ultimaEn!,
        );
      },
      // Un error del GPS no detiene el servicio: el siguiente dato lo repone.
      onError: (Object _) {},
      cancelOnError: false,
    );
  }

  @override
  Future<void> detener() async {
    await _sub?.cancel();
    _sub = null;
  }
}

/// Para pruebas y plataformas sin GPS: registra lo que se le pide.
class RastreadorEnMemoria implements RastreadorUbicacion {
  final List<ModoSegundoPlano> iniciados = [];
  int detenidos = 0;
  ModoSegundoPlano activo = ModoSegundoPlano.apagado;

  @override
  LatLng? ultima;

  @override
  DateTime? ultimaEn;

  @override
  MovimientoGps? movimiento;

  @override
  Future<void> iniciar(ModoSegundoPlano modo, AvisoRastreo aviso) async {
    iniciados.add(modo);
    activo = modo;
  }

  @override
  Future<void> detener() async {
    detenidos++;
    activo = ModoSegundoPlano.apagado;
  }
}
