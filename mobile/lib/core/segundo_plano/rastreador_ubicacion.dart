import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../notificaciones/canales_notificacion.dart';
import '../rumbo/reglas_rumbo.dart';
import '../theme/tokens.dart';
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

/// Un dato del GPS al llegar (para dibujar la moto propia en vivo).
class PosicionEnVivo {
  const PosicionEnVivo({
    required this.punto,
    required this.en,
    this.rumbo,
    this.velocidad,
  });

  /// Metros por segundo, tal como llegan del GPS.
  final double? velocidad;
  final LatLng punto;
  final DateTime en;

  /// Rumbo del GPS en grados (null si no es fiable: detenido o sin dato).
  final double? rumbo;
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

  /// Cada dato del GPS apenas llega: el mapa del conductor dibuja su moto con
  /// esto, sin esperar la respuesta del servidor (que puede tardar).
  Stream<PosicionEnVivo> get posiciones;
}

class RastreadorGeolocator implements RastreadorUbicacion {
  StreamSubscription<Position>? _sub;
  final _posiciones = StreamController<PosicionEnVivo>.broadcast();

  @override
  Stream<PosicionEnVivo> get posiciones => _posiciones.stream;
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
        notificationIcon: const AndroidResource(name: IconosAviso.pequeno),
        color: NexaColors.cyan,
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
        // En moto, el rumbo del GPS vale desde ~8 km/h.
        _posiciones.add(
          PosicionEnVivo(
            punto: _ultima!,
            en: _ultimaEn!,
            velocidad: p.speed,
            rumbo: p.speed >= 2.2 && p.heading >= 0 ? p.heading : null,
          ),
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

  final _posiciones = StreamController<PosicionEnVivo>.broadcast();

  @override
  Stream<PosicionEnVivo> get posiciones => _posiciones.stream;

  /// Simula un dato del GPS.
  void emitir(LatLng p, {double? rumbo}) {
    ultima = p;
    ultimaEn = DateTime.now();
    _posiciones.add(PosicionEnVivo(punto: p, en: ultimaEn!, rumbo: rumbo));
  }

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
